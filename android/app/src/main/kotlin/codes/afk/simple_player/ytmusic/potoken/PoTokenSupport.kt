package codes.afk.simple_player.ytmusic.potoken

import android.util.Log
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull

// ── Logging shim (replaces Timber so we don't need that dep) ─────────────────

internal fun logD(tag: String, msg: String) = Log.d(tag, msg)
internal fun logW(tag: String, msg: String) = Log.w(tag, msg)
internal fun logE(tag: String, msg: String) = Log.e(tag, msg)

// ── Exceptions ────────────────────────────────────────────────────────────────

class PoTokenException(message: String) : Exception(message)
class BadWebViewException(message: String) : Exception(message)

// ── Result returned to YtMusicBridge ─────────────────────────────────────────

data class PoTokenResult(
    val playerRequestPoToken: String,
    val streamingDataPoToken: String,
)

// ── JavaScript helpers ────────────────────────────────────────────────────────

/** Converts a String to a JS Uint8Array literal. */
internal fun stringToU8(s: String): String {
    val bytes = s.encodeToByteArray()
    return "new Uint8Array([${bytes.joinToString(",") { (it.toInt() and 0xFF).toString() }}])"
}

/** Converts a comma-separated list of byte values (from JS) to base-64. */
internal fun u8ToBase64(csv: String): String {
    val bytes = csv.split(",").map { it.trim().toInt().toByte() }.toByteArray()
    return android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP)
}

internal fun parseChallengeData(body: String): String =
    Json.parseToJsonElement(body).jsonArray[0].toString()

internal fun parseIntegrityTokenData(body: String): Pair<String, Long> {
    val arr = Json.parseToJsonElement(body).jsonArray
    val token = arr[0].toString()
    val expiry = arr.getOrNull(1)?.jsonPrimitive?.longOrNull ?: 21_600L
    return Pair(token, expiry)
}

internal fun buildExceptionForJsError(error: String): Exception =
    if (error.contains("SyntaxError") || error.contains("ReferenceError"))
        BadWebViewException(error)
    else
        PoTokenException(error)
