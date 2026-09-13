package codes.afk.simple_player

import codes.afk.simple_player.ytmusic.YtMusicBridge
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Exact same structure as sunoh's MainActivity:
 *   - Extends AudioServiceActivity (required by audio_service)
 *   - Registers the ytmusic MethodChannel under the SAME channel name as sunoh
 *     so the Dart-side YtMusicChannel wrapper works unchanged
 *   - "prewarm" and "resolve" methods dispatch to YtMusicBridge on ytScope
 */
class MainActivity : AudioServiceActivity() {

    // Tied to this Activity so a destroyed Activity cancels in-flight WebView calls
    private val ytScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        YtMusicBridge.initialize(applicationContext)

        // ── YouTube Music stream resolution ───────────────────────────────
        // Channel name is IDENTICAL to sunoh so the Dart YtMusicChannel
        // wrapper works without any changes at all.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "prewarm" -> {
                        ytScope.launch {
                            runCatching { YtMusicBridge.prewarm() }
                            withContext(Dispatchers.Main) { result.success(null) }
                        }
                    }

                    "resolve" -> {
                        val videoId = call.argument<String>("videoId")
                        if (videoId.isNullOrBlank()) {
                            result.error("bad_args", "videoId is required", null)
                            return@setMethodCallHandler
                        }
                        val quality = call.argument<String>("quality") ?: "auto"
                        ytScope.launch {
                            val outcome = runCatching { YtMusicBridge.resolve(videoId, quality) }
                            withContext(Dispatchers.Main) {
                                outcome
                                    .onSuccess  { result.success(it) }
                                    .onFailure  { result.error("resolve_failed", it.message ?: it::class.simpleName, null) }
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        // Exact same channel name as sunoh — the Dart wrapper is a direct copy
        const val CHANNEL = "codes.afk.sunoh/ytmusic"
    }
}
