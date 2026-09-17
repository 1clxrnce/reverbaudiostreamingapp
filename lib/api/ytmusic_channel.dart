// ytmusic_channel.dart
// This file is the Dart side of the bridge between Flutter and Android native code (Kotlin).
// Flutter can't generate YouTube's BotGuard security tokens on its own — only a real browser can.
// So we ask Kotlin to do it using a hidden WebView, then send the result back here.
//
// The communication pipe is called a "MethodChannel" — think of it like a phone line
// between Dart and Kotlin. You call a method by name and wait for the response.

import 'package:flutter/foundation.dart'; // debugPrint for logging
import 'package:flutter/services.dart'; // MethodChannel — Dart↔native communication

// Represents the resolved stream info that comes back from Kotlin
// Contains everything mpv needs to play the song
class YtMusicStream {
  const YtMusicStream({
    required this.url, // the real googlevideo.com audio stream URL
    required this.headers, // HTTP headers YouTube's CDN requires (User-Agent, etc.)
    this.expiresAt, // when the URL stops working (usually a few hours)
  });

  final String url;
  final Map<String, String> headers;
  final DateTime? expiresAt; // nullable — not always included

  // Converts the raw Map that Kotlin sends back into a proper YtMusicStream object
  // Returns null if the data is missing or invalid
  static YtMusicStream? fromMap(Map<Object?, Object?>? m) {
    if (m == null) return null; // nothing came back

    // extract the URL — if it's missing or empty, the whole thing is useless
    final url = m['url'] as String?;
    if (url == null || url.isEmpty) return null;

    // build the headers map — convert everything to String:String pairs
    final headers = <String, String>{};
    final rawH = m['headers']; // Kotlin sends headers as a generic Map
    if (rawH is Map) {
      rawH.forEach((k, v) {
        // skip any entry where key or value is null
        if (k != null && v != null) headers[k.toString()] = v.toString();
      });
    }

    // extract the expiry timestamp (in milliseconds since epoch)
    // convert it to a proper DateTime so we can compare it later if needed
    final ms = (m['expiresAtMs'] as num?)?.toInt();

    return YtMusicStream(
      url: url,
      headers: headers,
      expiresAt: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }
}

// The channel class — provides two methods: prewarm() and resolve()
// Uses a singleton pattern so there's only ever ONE instance of this class
class YtMusicChannel {
  YtMusicChannel._(); // private constructor — you can't do YtMusicChannel() from outside
  static final instance =
      YtMusicChannel._(); // the one shared instance the whole app uses

  // The MethodChannel is the actual pipe to Kotlin
  // The string name MUST match exactly what Kotlin registered — like dialing a phone number
  static const _ch = MethodChannel('codes.afk.sunoh/ytmusic');

  // Only run native code on Android — this would crash on other platforms
  bool get _ok => defaultTargetPlatform == TargetPlatform.android;

  // Pre-warm the hidden WebView at startup
  // The WebView needs 2-5 seconds to cold-start — doing it early means the first song loads faster
  // Called in main.dart right at startup, runs in the background
  Future<void> prewarm() async {
    if (!_ok) return; // skip on non-Android platforms

    try {
      // send "prewarm" to Kotlin — tells it to start loading the WebView now
      await _ch.invokeMethod<void>('prewarm');
      debugPrint('[ytmusic] prewarm done');
    } catch (e) {
      // if pre-warming fails, it's not fatal — first song will just load a bit slower
      debugPrint('[ytmusic] prewarm failed (non-fatal): $e');
    }
  }

  // Resolve a video ID into a real playable stream URL
  // This is the main call — happens every time a song needs to start playing
  // Returns null if resolution fails (so the app doesn't crash)
  Future<YtMusicStream?> resolve(
    String videoId, {
    String quality = 'auto',
  }) async {
    // bail early if not on Android or if the ID is empty
    if (!_ok || videoId.isEmpty) return null;

    try {
      // send "resolve" to Kotlin along with the video ID and desired quality
      // invokeMethod waits for Kotlin to finish and return a result
      final res = await _ch.invokeMethod<Map<Object?, Object?>>(
        'resolve', // method name Kotlin listens for
        {'videoId': videoId, 'quality': quality}, // data we send to Kotlin
      );

      // convert Kotlin's raw Map result into a YtMusicStream object
      return YtMusicStream.fromMap(res);
    } on PlatformException catch (e) {
      // PlatformException is what Kotlin throws when something goes wrong on the native side
      // e.g. network error, YouTube API error, WebView crash
      debugPrint('[ytmusic] resolve failed $videoId: ${e.message}');
      return null;
    } catch (e) {
      // catch anything else unexpected
      debugPrint('[ytmusic] resolve error $videoId: $e');
      return null;
    }
  }
}
