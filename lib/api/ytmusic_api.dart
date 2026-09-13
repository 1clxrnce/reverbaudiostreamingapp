// YouTube Music search — called directly from Dart to InnerTube.
//
// Same split as sunoh:
//   /youtubei/v1/search  → this file (no BotGuard needed, Dart is fine)
//   /youtubei/v1/player  → YtMusicBridge.kt (needs WebView for PO token)
//
// Uses WEB_REMIX client with the exact same constants as sunoh.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';

part 'ytmusic_renderers.dart';

const _kBase    = 'https://music.youtube.com/youtubei/v1';
const _kClient  = 'WEB_REMIX';
const _kVersion = '1.20260101.01.00';

// Songs-only search filter — exact same opaque param as sunoh
const _kSongsParam = 'EgWKAQIIAWoKEAoQAxAEEAkQBQ%3D%3D';

/// A song returned by search.
class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.artwork,
    this.durationSec,
  });

  /// YouTube videoId — used as the key everywhere.
  final String id;
  final String title;
  final String artist;
  final String? artwork;
  final int? durationSec;

  Duration? get duration =>
      durationSec == null ? null : Duration(seconds: durationSec!);

  /// The placeholder URI mpv will try to open.
  /// The on_load hook intercepts it and swaps in the real URL.
  String get placeholderUri => 'sunoh-song://$id';

  @override
  String toString() => 'Song($id, "$title")';
}

class YtMusicApi {
  YtMusicApi(this._dio);
  final Dio _dio;

  Map<String, dynamic> get _ctx => {
    'context': {
      'client': {
        'clientName': _kClient,
        'clientVersion': _kVersion,
        'hl': 'en',
        'gl': 'US',
      },
    },
  };

  Options get _opts => Options(
    headers: {
      'Content-Type': 'application/json',
      'X-Youtube-Client-Name': '67',
      'X-Youtube-Client-Version': _kVersion,
      'Origin': 'https://music.youtube.com',
    },
    validateStatus: (s) => s != null && s < 500,
  );

  /// Search for songs. POSTs to InnerTube /search with songs-only params.
  /// Same request shape as sunoh's YtMusicApi.searchSongs().
  Future<List<Song>> searchSongs(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$_kBase/search?prettyPrint=false',
        data: {..._ctx, 'query': query, 'params': _kSongsParam},
        options: _opts,
      );
      if (res.data == null) return const [];
      return _parseSongs(res.data!);
    } catch (e) {
      debugPrint('[ytmusic] search error: $e');
      return const [];
    }
  }
}
