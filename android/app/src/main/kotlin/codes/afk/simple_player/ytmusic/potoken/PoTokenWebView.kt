package codes.afk.simple_player.ytmusic.potoken

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.webkit.ConsoleMessage
import android.webkit.JavascriptInterface
import android.webkit.RenderProcessGoneDetail
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.annotation.MainThread
import androidx.collection.ArrayMap
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import okhttp3.Headers.Companion.toHeaders
import okhttp3.OkHttpClient
import okhttp3.RequestBody.Companion.toRequestBody
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.Collections
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

private const val TAG = "PoTokenWebView"
private const val GOOGLE_API_KEY = "AIzaSyDyT5W0Jh49F30Pqqtyfdf7pDLFKLJoAnw"
private const val REQUEST_KEY = "O43z0dpjhgX20SCx4KAo"
private const val USER_AGENT =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " +
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.3"
private const val JS_IFACE = "PoTokenWebView"
private const val INIT_TIMEOUT_MS = 45_000L
private const val GEN_TIMEOUT_MS  = 15_000L

/**
 * Runs Google's BotGuard JS in a sandboxed WebView to mint PO tokens.
 * Exact same logic as sunoh — package updated to codes.afk.simple_player.
 */
class PoTokenWebView private constructor(
    context: Context,
    private val continuation: Continuation<PoTokenWebView>,
) {
    private val webView = WebView(context)
    private val scope   = MainScope()
    private val initResumed = AtomicBoolean(false)

    @Volatile var isDead: Boolean = false; private set
    @Volatile private var closed = false

    private val pending = Collections.synchronizedMap(ArrayMap<String, Continuation<String>>())
    private val counter = java.util.concurrent.atomic.AtomicLong()
    private val errHandler = CoroutineExceptionHandler { _, t -> onInitError(t) }
    private lateinit var expiresAt: Instant

    init {
        val s = webView.settings
        @Suppress("SetJavaScriptEnabled") s.javaScriptEnabled = true
        s.userAgentString = USER_AGENT
        s.blockNetworkLoads = true
        webView.addJavascriptInterface(this, JS_IFACE)

        webView.webChromeClient = object : WebChromeClient() {
            override fun onConsoleMessage(m: ConsoleMessage): Boolean {
                val msg = m.message()
                if (msg.contains("Uncaught")) {
                    val fmt = "\"$msg\" (${m.sourceId()}:${m.lineNumber()})"
                    if (initResumed.get()) {
                        isDead = true; close()
                        popAll().forEach { (_, c) -> runCatching { c.resumeWithException(PoTokenException(fmt)) } }
                    } else {
                        onInitError(BadWebViewException(fmt))
                        popAll().forEach { (_, c) -> runCatching { c.resumeWithException(BadWebViewException(fmt)) } }
                    }
                }
                return super.onConsoleMessage(m)
            }
        }
        webView.webViewClient = object : WebViewClient() {
            @androidx.annotation.RequiresApi(android.os.Build.VERSION_CODES.O)
            override fun onRenderProcessGone(v: WebView, d: RenderProcessGoneDetail): Boolean {
                isDead = true
                val ex = PoTokenException("render gone (crash=${runCatching { d.didCrash() }.getOrNull()})")
                onInitError(ex)
                popAll().forEach { (_, c) -> runCatching { c.resumeWithException(ex) } }
                return true
            }
        }
    }

    private fun loadHtml() {
        scope.launch(errHandler) {
            val html = withContext(Dispatchers.IO) {
                webView.context.assets.open("po_token.html").bufferedReader().use { it.readText() }
            }
            val patched = html.replaceFirst("</script>", "\n$JS_IFACE.downloadAndRunBotguard()</script>")
            webView.loadDataWithBaseURL("https://www.youtube.com", patched, "text/html", "utf-8", null)
        }
    }

    @JavascriptInterface fun downloadAndRunBotguard() {
        request("https://www.youtube.com/api/jnn/v1/Create", "[ \"$REQUEST_KEY\" ]") { body ->
            val data = parseChallengeData(body)
            webView.evaluateJavascript("""try{data=$data;runBotGuard(data).then(function(r){this.webPoSignalOutput=r.webPoSignalOutput;$JS_IFACE.onBotguard(r.botguardResponse)},function(e){$JS_IFACE.onInitErr(e+"\n"+e.stack)})}catch(e){$JS_IFACE.onInitErr(e+"\n"+e.stack)}""", null)
        }
    }

    @JavascriptInterface fun onInitErr(e: String) = onInitError(buildExceptionForJsError(e))

    @JavascriptInterface fun onBotguard(resp: String) {
        request("https://www.youtube.com/api/jnn/v1/GenerateIT", "[ \"$REQUEST_KEY\", \"$resp\" ]") { body ->
            try {
                val (token, expSec) = parseIntegrityTokenData(body)
                expiresAt = Instant.now().plusSeconds(expSec).minus(10, ChronoUnit.MINUTES)
                webView.evaluateJavascript("""try{this.integrityToken=$token;createPoTokenMinter(webPoSignalOutput,integrityToken).then(function(){$JS_IFACE.onMinterReady()}).catch(function(e){$JS_IFACE.onInitErr(e+"\n"+(e.stack||''))})}catch(e){$JS_IFACE.onInitErr(e+"\n"+e.stack)}""", null)
            } catch (e: Exception) { onInitError(PoTokenException("parseIntegrityTokenData: ${e.message}")) }
        }
    }

    @JavascriptInterface fun onMinterReady() {
        if (initResumed.compareAndSet(false, true)) continuation.resume(this)
    }

    suspend fun generatePoToken(id: String): String {
        if (isDead || closed) throw PoTokenException("WebView is dead/closed")
        val key = "$id#${counter.incrementAndGet()}"
        return try {
            withTimeout(GEN_TIMEOUT_MS) { genInternal(id, key) }
        } catch (e: TimeoutCancellationException) {
            isDead = true; popOne(key)
            throw PoTokenException("poToken timeout")
        }
    }

    private suspend fun genInternal(id: String, key: String): String =
        withContext(Dispatchers.Main) {
            suspendCancellableCoroutine { cont ->
                pending[key] = cont
                webView.evaluateJavascript("""(function(){var k="$key";try{var u=${stringToU8(id)};obtainPoToken(u).then(function(p){$JS_IFACE.onPoToken(k,p.join(","))}).catch(function(e){$JS_IFACE.onPoTokenErr(k,e+"\n"+(e.stack||''))})}catch(e){$JS_IFACE.onPoTokenErr(k,e+"\n"+e.stack)}})()""", null)
            }
        }

    @JavascriptInterface fun onPoTokenErr(key: String, e: String) =
        popOne(key)?.resumeWithException(PoTokenException(e))

    @JavascriptInterface fun onPoToken(key: String, csv: String) {
        val tok = try { u8ToBase64(csv) } catch (t: Throwable) { popOne(key)?.resumeWithException(t); return }
        popOne(key)?.resume(tok)
    }

    val isExpired get() = Instant.now().isAfter(expiresAt)

    private fun popOne(k: String) = pending.remove(k)
    private fun popAll(): Map<String, Continuation<String>> = pending.toMap().also { pending.clear() }

    private fun request(url: String, data: String, handle: (String) -> Unit) {
        scope.launch(errHandler) {
            val req = okhttp3.Request.Builder().post(data.toRequestBody())
                .headers(mapOf("User-Agent" to USER_AGENT, "Accept" to "application/json",
                    "Content-Type" to "application/json+protobuf",
                    "x-goog-api-key" to GOOGLE_API_KEY, "x-user-agent" to "grpc-web-javascript/0.1").toHeaders())
                .url(url).build()
            val (code, body) = withContext(Dispatchers.IO) {
                http.newCall(req).execute().use { r -> r.code to if (r.code == 200) r.body?.string() else null }
            }
            if (body.isNullOrEmpty()) onInitError(PoTokenException("botguard response empty (code=$code)"))
            else handle(body)
        }
    }

    private fun onInitError(e: Throwable) {
        close()
        if (initResumed.compareAndSet(false, true)) runCatching { continuation.resumeWithException(e) }
    }

    fun close() {
        if (closed) return; closed = true; scope.cancel()
        if (Looper.myLooper() == Looper.getMainLooper()) destroy()
        else Handler(Looper.getMainLooper()).post { destroy() }
    }

    @MainThread private fun destroy() {
        runCatching { webView.clearHistory(); webView.clearCache(true); webView.loadUrl("about:blank"); webView.onPause(); webView.removeAllViews(); webView.destroy() }
    }

    companion object {
        private val http = OkHttpClient.Builder().build()

        suspend fun create(ctx: Context): PoTokenWebView {
            var created: PoTokenWebView? = null
            try {
                return withTimeout(INIT_TIMEOUT_MS) {
                    withContext(Dispatchers.Main) {
                        suspendCancellableCoroutine { cont ->
                            val wv = PoTokenWebView(ctx, cont); created = wv; wv.loadHtml()
                        }
                    }
                }
            } catch (e: TimeoutCancellationException) {
                closeQ(created); throw PoTokenException("PoTokenWebView init timed out")
            } catch (e: CancellationException) { closeQ(created); throw e }
        }

        private suspend fun closeQ(wv: PoTokenWebView?) {
            if (wv == null) return
            withContext(NonCancellable + Dispatchers.Main) { wv.initResumed.set(true); wv.close() }
        }
    }
}
