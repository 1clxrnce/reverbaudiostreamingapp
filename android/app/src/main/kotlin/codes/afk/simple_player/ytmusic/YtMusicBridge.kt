package codes.afk.simple_player.ytmusic

import android.content.Context
import android.util.Log
import codes.afk.simple_player.ytmusic.potoken.PoTokenGenerator
import com.metrolist.innertubex.InnerTube
import com.metrolist.innertubex.InnerTubeLogLevel
import com.metrolist.innertubex.InnerTubeLogger
import com.metrolist.innertubex.cipher.PlayerConfigRepository
import com.metrolist.innertubex.cipher.RemotePlayerConfigStore
import com.metrolist.innertubex.cipher.YouTubeCipherService
import com.metrolist.innertubex.extraction.AudioQuality
import com.metrolist.innertubex.extraction.ContentHints
import com.metrolist.innertubex.extraction.InnerTubeExtractor
import com.metrolist.innertubex.extraction.PoTokenResult
import com.metrolist.innertubex.extraction.TokenProvider
import com.metrolist.innertubex.extraction.TokenProviderCapabilities
import com.metrolist.innertubex.extraction.YtConfigParserImpl
import com.metrolist.innertubex.extraction.generateClientPlaybackNonce
import com.metrolist.innertubex.extraction.strategy.PoTokenProviderKind
import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.plugins.compression.ContentEncoding
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.serialization.kotlinx.json.json
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.Json

/**
 * YouTube Music stream resolver — same implementation as sunoh's YtMusicBridge.
 *
 * Why it must live in Kotlin:
 *   YouTube gates music-catalog tracks behind BotGuard. Clearing it requires a
 *   PO token minted by running Google's JS in a real WebView. Dart can't do that.
 *   So resolution lives here and Dart just receives a plain googlevideo.com URL.
 *
 * SABR is explicitly refused (allowSabr=false) so mpv always gets a plain URL.
 */
object YtMusicBridge {
    private const val TAG = "YtMusicBridge"
    private const val WARMUP_VIDEO = "jNQXAC9IVRw"

    private lateinit var appCtx: Context
    private val mutex = Mutex()

    @Volatile private var bundle: Bundle? = null
    private data class Bundle(val http: HttpClient, val innerTube: InnerTube, val extractor: InnerTubeExtractor)

    fun initialize(context: Context) { appCtx = context.applicationContext }

    private val poTokenGen: PoTokenGenerator by lazy { PoTokenGenerator(appCtx) }

    private val logger = InnerTubeLogger { e ->
        val d = if (e.details.isEmpty()) "" else e.details.entries.joinToString(" [", "]") { "${it.key}=${it.value}" }
        val m = e.message + d
        when (e.level) {
            InnerTubeLogLevel.DEBUG -> Log.d(e.tag, m)
            InnerTubeLogLevel.INFO  -> Log.i(e.tag, m)
            InnerTubeLogLevel.WARN  -> Log.w(e.tag, m)
            InnerTubeLogLevel.ERROR -> Log.e(e.tag, m)
        }
    }

    // Bridges our WebView minter onto InnerTubeX's TokenProvider contract.
    // Returning null is fine — extractor walks its client ladder for one that
    // doesn't need a token, so a dead WebView is not fatal.
    private val tokenProvider = object : TokenProvider {
        override val capabilities = TokenProviderCapabilities(
            providers = setOf(PoTokenProviderKind.WEB_BOTGUARD),
            usesWebView = true,
        )
        override suspend fun getPoToken(videoId: String, visitorData: String, cookie: String?): PoTokenResult? =
            poTokenGen.getWebClientPoToken(videoId, visitorData)?.let {
                PoTokenResult(playerRequestToken = it.playerRequestPoToken, streamingDataToken = it.streamingDataPoToken, visitorData = visitorData)
            }
        override suspend fun close() = poTokenGen.close()
    }

    private suspend fun bundle(): Bundle {
        bundle?.let { return it }
        return mutex.withLock {
            bundle?.let { return@withLock it }
            val http = HttpClient(OkHttp) {
                expectSuccess = false  // InnerTubeX reads non-2xx responses itself
                install(ContentNegotiation) {
                    json(Json { ignoreUnknownKeys = true; explicitNulls = false; encodeDefaults = true })
                }
                install(ContentEncoding) { gzip(0.9F); deflate(0.8F) }
                engine { config { connectTimeout(30, TimeUnit.SECONDS); readTimeout(60, TimeUnit.SECONDS); retryOnConnectionFailure(true) } }
            }
            val innerTube = InnerTube(httpClient = http)
            val cfgStore = RemotePlayerConfigStore(http, PlayerConfigRepository.disabled(), logger)
            val extractor = InnerTubeExtractor(
                configParser = YtConfigParserImpl(http, innerTube, cfgStore, logger),
                cipherService = YouTubeCipherService(http, cfgStore, logger),
                innerTube = innerTube,
                tokenProvider = tokenProvider,
                logger = logger,
            )
            Bundle(http, innerTube, extractor).also { bundle = it }
        }
    }

    /** Pre-warms the WebView at startup so first play doesn't pay the cold-start cost. */
    suspend fun prewarm() {
        runCatching { bundle().extractor.prewarm() }.onFailure { Log.w(TAG, "prewarm: ${it.message}") }
        runCatching { poTokenGen.getWebClientPoToken(WARMUP_VIDEO, "") }.onFailure { Log.w(TAG, "potoken warm: ${it.message}") }
    }

    /**
     * Resolves [videoId] to a playable audio URL.
     * Returns the same map shape as sunoh — Dart deserializes it with YtMusicStream.fromMap().
     */
    suspend fun resolve(videoId: String, quality: String): Map<String, Any?> {
        val hints = ContentHints(wantVideo = false)
            .withStreamCapabilities(allowHls = false, allowSabr = false, allowBoundedRange = true)
        val stream = bundle().extractor.extract(
            videoId = videoId,
            hints = hints,
            audioQuality = when (quality) { "high" -> AudioQuality.HIGH; "data" -> AudioQuality.LOW; else -> AudioQuality.AUTO },
            clientPlaybackNonce = generateClientPlaybackNonce(),
        ) ?: error("no playable stream for $videoId")

        check(stream.sabrBootstrap == null) { "SABR stream cannot be played by mpv" }
        val url = stream.audioUrl ?: error("stream has no audio url")

        return mapOf(
            "url"                 to url,
            "headers"             to stream.headers,
            "itag"                to stream.itag,
            "mimeType"            to stream.mimeType,
            "bitrate"             to stream.bitrate,
            "contentLength"       to stream.contentLengthBytes,
            "loudnessDb"          to stream.loudnessDb,
            "clientName"          to stream.clientName,
            "expiresAtMs"         to stream.expiresAt?.toEpochMilliseconds(),
            "requireBoundedRange" to (stream.requireBoundedRange ?: false),
            "rangeChunkSizeBytes" to (stream.rangeChunkSizeBytes ?: 0),
            "useRangeChunks"      to (stream.useRangeChunks ?: false),
        )
    }
}
