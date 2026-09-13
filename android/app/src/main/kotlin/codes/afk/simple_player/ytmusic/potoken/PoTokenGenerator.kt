package codes.afk.simple_player.ytmusic.potoken

import android.content.Context
import android.webkit.CookieManager
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout

/**
 * Manages a PoTokenWebView session and mints per-video PO tokens.
 * Same logic as sunoh — package updated to codes.afk.simple_player.
 */
class PoTokenGenerator(context: Context) {
    private val TAG = "PoTokenGenerator"
    private val ctx = context.applicationContext
    private val webViewOk by lazy { runCatching { CookieManager.getInstance() }.isSuccess }
    private var badImpl = false

    private val lock = Mutex()
    private var sessionId: String? = null
    private var streamingPot: String? = null
    private var wv: PoTokenWebView? = null

    suspend fun getWebClientPoToken(videoId: String, sid: String): PoTokenResult? {
        if (!webViewOk || badImpl) return null
        return try {
            withTimeout(8_000L) { getToken(videoId, sid, recreate = false) }
        } catch (e: TimeoutCancellationException) {
            logW(TAG, "poToken timeout"); clear(); null
        } catch (e: CancellationException) { throw e }
        catch (e: BadWebViewException) { badImpl = true; null }
        catch (e: Exception) { logE(TAG, "poToken error: ${e::class.simpleName}"); throw e }
    }

    suspend fun close() = clear()

    private suspend fun clear() = lock.withLock {
        try { withContext(Dispatchers.Main) { wv?.close() } } catch (_: Exception) {}
        wv = null; streamingPot = null; sessionId = null
    }

    private suspend fun getToken(videoId: String, sid: String, recreate: Boolean): PoTokenResult {
        val (gen, sPot, wasRecreated) = lock.withLock {
            val should = recreate || wv == null || wv!!.isExpired || wv!!.isDead || sessionId != sid
            if (should) {
                withContext(Dispatchers.Main) { wv?.close() }
                wv = null; streamingPot = null; sessionId = null
                val newWv = PoTokenWebView.create(ctx)
                val pot = try { newWv.generatePoToken(sid) }
                          catch (t: Throwable) { runCatching { newWv.close() }; throw t }
                wv = newWv; streamingPot = pot; sessionId = sid
            }
            Triple(wv!!, streamingPot!!, should)
        }
        val playerPot = try {
            gen.generatePoToken(videoId)
        } catch (t: Throwable) {
            if (wasRecreated) throw t
            logE(TAG, "gen failed, recreating WebView")
            return getToken(videoId, sid, recreate = true)
        }
        return PoTokenResult(playerRequestPoToken = sPot, streamingDataPoToken = playerPot)
    }
}
