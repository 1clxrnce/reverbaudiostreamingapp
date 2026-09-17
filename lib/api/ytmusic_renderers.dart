// ytmusic_renderers.dart
// This file takes the raw messy JSON that YouTube returns and turns it into clean Song objects.
// YouTube's API response is deeply nested — this file digs through all of it.
// It's split from ytmusic_api.dart just to keep things organised.

part of 'ytmusic_api.dart'; // shares scope with ytmusic_api.dart — can use Song, _kBase, etc.

// Tool to fix HTML-encoded text — e.g. "Don&#39;t Stop" becomes "Don't Stop"
final _unescape = HtmlUnescape();

// Helper: converts any value to a string and fixes HTML encoding
// "d" stands for "decode" — used on song titles and artist names
String _d(Object? v) => _unescape.convert((v ?? '').toString());

// ── Entry point ───────────────────────────────────────────────────────────────

// Takes the full raw JSON body from YouTube's search response
// Returns a list of Song objects — one for each song found
List<Song> _parseSongs(Map<String, dynamic> body) {
  final out = <Song>[]; // start with empty list, fill it as we go

  // YouTube groups results into "shelves" (sections)
  // Loop through each shelf, then through each item inside it
  for (final shelf in _shelves(body)) {
    for (final raw in _list(shelf['contents'])) {
      // 'contents' is the list of items in this shelf

      // Each song item is wrapped in 'musicResponsiveListItemRenderer'
      // If this key doesn't exist, it's not a song — skip it
      final item = _asMap(raw)['musicResponsiveListItemRenderer'];
      if (item == null) continue; // 'continue' means skip to the next item

      // Try to parse this item into a Song object
      final song = _parseItem(_asMap(item));

      // Only add it to the list if parsing succeeded (not null)
      if (song != null) out.add(song);
    }
  }

  return out; // return the complete list of songs
}

// ── Shelf extraction ──────────────────────────────────────────────────────────

// YouTube wraps search results in "shelves" (sections of results)
// This function finds all those shelves regardless of which JSON structure YouTube used
// YouTube sometimes returns results in different structures depending on login status
List<Map<String, dynamic>> _shelves(Map<String, dynamic> body) {
  final out = <Map<String, dynamic>>[];

  // Path 1: YouTube Music web layout with tabs
  // Navigate: body → contents → tabbedSearchResultsRenderer → tabs
  final tabs = _list(
    _dig(body, ['contents', 'tabbedSearchResultsRenderer', 'tabs']),
  );
  if (tabs.isNotEmpty) {
    // get the contents from the first tab
    final contents = _list(
      _dig(tabs.first, [
        'tabRenderer',
        'content',
        'sectionListRenderer',
        'contents',
      ]),
    );
    // look through each content block for a music shelf
    for (final c in contents) {
      // 'musicShelfRenderer' is the normal one, 'musicCardShelfRenderer' is an alternate
      final shelf =
          _asMap(c)['musicShelfRenderer'] ?? // try the normal shelf
          _asMap(c)['musicCardShelfRenderer']; // fall back to card shelf
      if (shelf != null) out.add(_asMap(shelf));
    }
  }

  // Path 2: simpler fallback structure (used when not logged in)
  // If path 1 found nothing, try a simpler path through sectionListRenderer directly
  if (out.isEmpty) {
    final contents = _list(
      _dig(body, ['contents', 'sectionListRenderer', 'contents']),
    );
    for (final c in contents) {
      final shelf = _asMap(c)['musicShelfRenderer'];
      if (shelf != null) out.add(_asMap(shelf));
    }
  }

  return out;
}

// ── Item parsing ──────────────────────────────────────────────────────────────

// Takes one raw song item from YouTube's JSON and converts it into a Song object
// Returns null if we can't get the minimum required info (id + title)
Song? _parseItem(Map<String, dynamic> m) {
  // Try to find the video ID — without this we can't play anything
  final id = _extractId(m);
  if (id == null || id.isEmpty) return null; // no ID = useless, skip it

  // Get the song title from "flex column" 0 (YouTube's name for display columns)
  final title = _flexText(m, 0);
  if (title.isEmpty) return null; // no title = skip it

  // Get the artist name from flex column 1
  final artist = _flexText(m, 1);

  // ── Artwork ──
  // YouTube returns a list of thumbnails at different sizes
  // We take the LAST one because it's always the largest/highest quality
  // Then we swap the size token in the URL to get an even bigger version (576×576)
  String? artwork;
  final thumbs = _list(
    _dig(m, ['thumbnail', 'musicThumbnailRenderer', 'thumbnail', 'thumbnails']),
  );
  if (thumbs.isNotEmpty && thumbs.last is Map) {
    final raw = (thumbs.last as Map)['url']
        ?.toString(); // get the raw thumbnail URL
    artwork = raw == null ? null : _hqThumb(raw); // upgrade it to high-res
  }

  // ── Duration ──
  // Duration lives in flex column 4, formatted as "3:45"
  // _parseDuration converts that to raw seconds (e.g. 225)
  final durText = _flexText(m, 4);
  final durationSec = _parseDuration(durText);

  // Build and return the final Song object
  // _d() cleans up any HTML encoding in the title and artist
  return Song(
    id: id,
    title: _d(title),
    artist: _d(artist),
    artwork: artwork,
    durationSec: durationSec,
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// Finds the YouTube video ID inside a song item
// YouTube puts it in different places depending on the result type — so we check both
String? _extractId(Map<String, dynamic> m) {
  // Location 1: inside the thumbnail overlay (the play button that appears on hover)
  final overlay = _dig(m, [
    'overlay',
    'musicItemThumbnailOverlayRenderer',
    'content',
    'musicPlayButtonRenderer',
    'playNavigationEndpoint', // the "navigate to watch page" endpoint
  ]);
  if (overlay != null) {
    // watchEndpoint.videoId is where YouTube stores the ID here
    final id = _dig<String>(_asMap(overlay), ['watchEndpoint', 'videoId']);
    if (id != null && id.isNotEmpty) return id; // found it — return early
  }

  // Location 2: inside one of the text "runs" in the flex columns
  // Each column can have clickable text that links to a watch page
  for (final col in _list(m['flexColumns'])) {
    for (final run in _list(
      _dig(_asMap(col), [
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
      ]),
    )) {
      if (run is! Map) continue; // skip anything that isn't a map
      final id = _dig<String>(_asMap(run), [
        'navigationEndpoint',
        'watchEndpoint',
        'videoId',
      ]);
      if (id != null && id.isNotEmpty) return id; // found it
    }
  }

  return null; // couldn't find the ID anywhere
}

// Gets the text from a specific "flex column" in YouTube's layout
// Columns are indexed: 0 = song title, 1 = artist name, 4 = duration
// Each column can have multiple "runs" (text segments) — we join them together
String _flexText(Map<String, dynamic> m, int idx) {
  final cols = _list(m['flexColumns']); // get all columns
  if (idx >= cols.length) {
    return ''; // if the column doesn't exist, return empty
  }

  // get all text "runs" inside this column
  final runs = _list(
    _dig(_asMap(cols[idx]), [
      'musicResponsiveListItemFlexColumnRenderer',
      'text',
      'runs',
    ]),
  );

  // join all the text segments together into one string
  return runs.whereType<Map>().map((r) => r['text']?.toString() ?? '').join('');
}

// Converts a duration string like "3:45" or "1:03:45" into total seconds
// Returns null if the format is unrecognisable
int? _parseDuration(String text) {
  if (text.isEmpty) return null;

  final p = text.split(
    ':',
  ); // split on colon → ["3", "45"] or ["1", "03", "45"]
  try {
    if (p.length == 2) {
      // format: "mm:ss" — multiply minutes by 60 and add seconds
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }
    if (p.length == 3) {
      // format: "hh:mm:ss" — multiply hours by 3600, minutes by 60, add seconds
      return int.parse(p[0]) * 3600 + int.parse(p[1]) * 60 + int.parse(p[2]);
    }
  } catch (
    _
  ) {} // if parsing fails (e.g. non-numeric text), fall through and return null

  return null;
}

// Safely navigates deep into nested JSON by following a list of keys
// Instead of writing body['a']?['b']?['c'] every time, you write _dig(body, ['a','b','c'])
// Returns null (instead of crashing) if any key is missing along the way
T? _dig<T>(dynamic root, List<String> path) {
  dynamic cur = root; // start at the root of the JSON
  for (final k in path) {
    if (cur is! Map) return null; // if we hit something that isn't a map, stop
    cur = cur[k]; // go one level deeper
  }
  return cur is T
      ? cur
      : null; // return the value if it's the expected type, else null
}

// If something is a List, return it. If not (null, wrong type), return empty list.
// Prevents crashes when YouTube's JSON has an unexpected shape.
List _list(dynamic v) => v is List ? v : const [];

// If something is a Map, return it properly typed. If not, return empty map.
// Same idea as _list — avoids crashing on unexpected data.
Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? v.cast<String, dynamic>() : const {};

// Upgrades a YouTube thumbnail URL to a higher resolution version
// YouTube URLs end with a size token like =w226-h226 (226×226 pixels — too small for full screen)
// We replace it with =w576-h576 to get a crisp 576×576 image instead
// Same CDN, same image, just bigger — no extra cost
String _hqThumb(String url) {
  // regex that matches the size token at the end of the URL
  // \d+ means "one or more digits"
  final sizeToken = RegExp(r'=w\d+-h\d+(-[^?]*)?$');

  if (sizeToken.hasMatch(url)) {
    return url.replaceFirst(sizeToken, '=w576-h576'); // swap in our bigger size
  }

  return url; // if the URL doesn't have a size token, return it unchanged
}
