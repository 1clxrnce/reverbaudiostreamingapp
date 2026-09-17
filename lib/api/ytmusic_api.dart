// ytmusic_api.dart
// This file handles searching YouTube Music.
// It talks directly to YouTube's internal API (called InnerTube) — no proxy, no third-party service.
// The search endpoint doesn't need BotGuard tokens, so plain Dart HTTP requests work fine here.

import 'package:dio/dio.dart'; // HTTP client for making web requests
import 'package:flutter/foundation.dart'; // gives us debugPrint — a safe version of print()
import 'package:html_unescape/html_unescape.dart'; // fixes HTML-encoded text like &amp; → &

// ytmusic_renderers.dart is split into a separate file to keep this file clean,
// but "part of" means they share the same scope — renderers can use Song, _kBase, etc.
part 'ytmusic_renderers.dart';

// ── Constants ────────────────────────────────────────────────────────────────

// The base URL for YouTube Music's internal API
// All requests go to subpaths under this URL
const _kBase = 'https://music.youtube.com/youtubei/v1';

// The client name we send to YouTube — "WEB_REMIX" means "YouTube Music web app"
// YouTube uses this to format the response correctly
const _kClient = 'WEB_REMIX';

// The version string of the YouTube Music web client we're pretending to be
// Has to match a version YouTube actually recognises
const _kVersion = '1.20260101.01.00';

// A special filter code that tells YouTube: return SONGS ONLY, not videos or playlists
// This is a base64-encoded value YouTube understands — you don't need to decode it
const _kSongsParam = 'EgWKAQIIAWoKEAoQAxAEEAkQBQ%3D%3D';

// ── Song model ────────────────────────────────────────────────────────────────
// This is the blueprint for what a "song" looks like in this app.
// Every search result gets turned into one of these.
class Song {
  const Song({
    required this.id, // required — a song without an ID is useless
    required this.title, // required — we always need a title to display
    required this.artist, // required — even if it's empty string
    this.artwork, // optional — some results have no thumbnail
    this.durationSec, // optional — some results have no duration info
  });

  // YouTube video ID — the short code in every YouTube URL e.g. "dQw4w9WgXcQ"
  // This is the key used everywhere — to resolve streams, look up songs, etc.
  final String id;

  // The song's display name e.g. "God's Plan"
  final String title;

  // The artist name e.g. "Drake"
  final String artist;

  // URL to the album/song artwork image
  // nullable — not every search result includes a thumbnail
  final String? artwork;

  // Total length of the song in seconds e.g. 213 for a 3:33 song
  // nullable — not every result includes duration
  final int? durationSec;

  // Convenience getter — converts raw seconds into a Dart Duration object
  // Returns null if we don't have duration info
  Duration? get duration =>
      durationSec == null ? null : Duration(seconds: durationSec!);

  // The fake placeholder URL we give to the audio player
  // e.g. "sunoh-song://dQw4w9WgXcQ"
  // mpv tries to open this, fires a hook, and we swap it for the real URL
  String get placeholderUri => 'sunoh-song://$id';

  @override
  String toString() => 'Song($id, "$title")'; // useful for debug logs
}

// ── YtMusicApi ────────────────────────────────────────────────────────────────
// The class that actually talks to YouTube Music's search API.
// Created once in providers.dart and shared across the whole app.
class YtMusicApi {
  YtMusicApi(this._dio); // takes a Dio HTTP client when created
  final Dio _dio; // stores it for use in the search method

  // The "context" block every InnerTube request needs in its body
  // It tells YouTube: "I'm the YouTube Music web client, english, US"
  // Without this YouTube either rejects the request or returns wrong data
  Map<String, dynamic> get _ctx => {
    'context': {
      'client': {
        'clientName': _kClient, // 'WEB_REMIX'
        'clientVersion': _kVersion, // the version string
        'hl': 'en', // language: english
        'gl': 'US', // region: United States
      },
    },
  };

  // The HTTP headers sent with every request
  // These make the request look like it came from the real YouTube Music website
  Options get _opts => Options(
    headers: {
      'Content-Type': 'application/json', // we're sending JSON data
      'X-Youtube-Client-Name':
          '67', // YouTube's internal ID for the WEB_REMIX client
      'X-Youtube-Client-Version':
          _kVersion, // must match the version in the context block
      'Origin':
          'https://music.youtube.com', // makes it look like a browser request from the YTM site
    },
    // treat any HTTP response under 500 as non-error
    // so a 404 doesn't throw an exception — only real server errors (500+) do
    validateStatus: (s) => s != null && s < 500,
  );

  // The main search function — called when the user types something and hits search
  // Returns a list of Song objects, or an empty list if something goes wrong
  Future<List<Song>> searchSongs(String query) async {
    // don't bother hitting YouTube if the query is blank or just spaces
    if (query.trim().isEmpty) return const [];

    try {
      // POST request to YouTube Music's search endpoint
      final res = await _dio.post<Map<String, dynamic>>(
        '$_kBase/search?prettyPrint=false', // prettyPrint=false = smaller/faster response
        data: {
          ..._ctx, // spread the context block in (like copy-pasting it here)
          'query': query, // the user's search text
          'params':
              _kSongsParam, // the filter that restricts results to songs only
        },
        options: _opts, // the HTTP headers defined above
      );

      // if YouTube returned nothing useful, return empty
      if (res.data == null) return const [];

      // pass the raw JSON response to _parseSongs (in ytmusic_renderers.dart)
      // which digs through the nested mess and returns clean Song objects
      return _parseSongs(res.data!);
    } catch (e) {
      // if anything goes wrong (no internet, YouTube error, etc.)
      // log it and return empty instead of crashing the app
      debugPrint('[ytmusic] search error: $e');
      return const [];
    }
  }
}
