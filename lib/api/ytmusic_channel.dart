// Dart-side wrapper for the native YouTube Music stream resolver.
//
// This is a direct copy of sunoh's ytmusic_channel.dart — same channel name,
// same method names, same argument keys, same return map parsing.
//
// Why native: YouTube BotGuard needs a real WebView to mint PO tokens.
// Dart can't do that — resolution lives in Kotlin and we just receive a URL.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class YtMusicStream {
  const YtMusicStream({
    required this.url,
    required this.headers,
    this.expiresAt,
  });

  final String url;
  final Map<String, String> headers;
  final DateTime? expiresAt;

  static YtMusicStream? fromMap(Map<Object?, Object?>? m) {
    if (m == null) return null;
    final url = m['url'] as String?;
    if (url == null || url.isEmpty) return null;

    final headers = <String, String>{};
    final rawH = m['headers'];
    if (rawH is Map) {
      rawH.forEach((k, v) {
        if (k != null && v != null) headers[k.toString()] = v.toString();
      });
    }
    final ms = (m['expiresAtMs'] as num?)?.toInt();
    return YtMusicStream(
      url: url,
      headers: headers,
      expiresAt: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }
}

class YtMusicChannel {
  YtMusicChannel._();
  static final instance = YtMusicChannel._();

  // EXACT same channel name as sunoh — the Kotlin handler is registered here
  static const _ch = MethodChannel('codes.afk.sunoh/ytmusic');

  bool get _ok => defaultTargetPlatform == TargetPlatform.android;

  /// Pre-warm the BotGuard WebView at startup so first play is fast.
  Future<void> prewarm() async {
    if (!_ok) return;
    try {
      await _ch.invokeMethod<void>('prewarm');
      debugPrint('[ytmusic] prewarm done');
    } catch (e) {
      debugPrint('[ytmusic] prewarm failed (non-fatal): $e');
    }
  }

  /// Resolve [videoId] to a playable stream. Returns null on failure.
  Future<YtMusicStream?> resolve(String videoId, {String quality = 'auto'}) async {
    if (!_ok || videoId.isEmpty) return null;
    try {
      final res = await _ch.invokeMethod<Map<Object?, Object?>>(
        'resolve',
        {'videoId': videoId, 'quality': quality},
      );
      return YtMusicStream.fromMap(res);
    } on PlatformException catch (e) {
      debugPrint('[ytmusic] resolve failed $videoId: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[ytmusic] resolve error $videoId: $e');
      return null;
    }
  }
}
