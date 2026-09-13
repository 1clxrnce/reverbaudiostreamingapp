part of 'ytmusic_api.dart';

final _unescape = HtmlUnescape();
String _d(Object? v) => _unescape.convert((v ?? '').toString());

// ── Entry point ───────────────────────────────────────────────────────────────

List<Song> _parseSongs(Map<String, dynamic> body) {
  final out = <Song>[];
  for (final shelf in _shelves(body)) {
    for (final raw in _list(shelf['contents'])) {
      final item = _asMap(raw)['musicResponsiveListItemRenderer'];
      if (item == null) continue;
      final song = _parseItem(_asMap(item));
      if (song != null) out.add(song);
    }
  }
  return out;
}

// ── Shelf extraction (mirrors sunoh's _searchShelves) ────────────────────────

List<Map<String, dynamic>> _shelves(Map<String, dynamic> body) {
  final out = <Map<String, dynamic>>[];

  // Path 1: tabbedSearchResultsRenderer
  final tabs = _list(_dig(body, ['contents', 'tabbedSearchResultsRenderer', 'tabs']));
  if (tabs.isNotEmpty) {
    final contents = _list(_dig(tabs.first, ['tabRenderer', 'content', 'sectionListRenderer', 'contents']));
    for (final c in contents) {
      final shelf = _asMap(c)['musicShelfRenderer'] ?? _asMap(c)['musicCardShelfRenderer'];
      if (shelf != null) out.add(_asMap(shelf));
    }
  }

  // Path 2: plain sectionListRenderer (unauthenticated fallback)
  if (out.isEmpty) {
    final contents = _list(_dig(body, ['contents', 'sectionListRenderer', 'contents']));
    for (final c in contents) {
      final shelf = _asMap(c)['musicShelfRenderer'];
      if (shelf != null) out.add(_asMap(shelf));
    }
  }

  return out;
}

// ── Item parsing ──────────────────────────────────────────────────────────────

Song? _parseItem(Map<String, dynamic> m) {
  final id = _extractId(m);
  if (id == null || id.isEmpty) return null;

  final title  = _flexText(m, 0);
  if (title.isEmpty) return null;
  final artist = _flexText(m, 1);

  // Artwork — last (largest) thumbnail
  String? artwork;
  final thumbs = _list(_dig(m, ['thumbnail', 'musicThumbnailRenderer', 'thumbnail', 'thumbnails']));
  if (thumbs.isNotEmpty && thumbs.last is Map) {
    artwork = (thumbs.last as Map)['url']?.toString();
  }

  // Duration — typically at flex column index 4, formatted as "3:45"
  final durText = _flexText(m, 4);
  final durationSec = _parseDuration(durText);

  return Song(
    id: id,
    title: _d(title),
    artist: _d(artist),
    artwork: artwork,
    durationSec: durationSec,
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String? _extractId(Map<String, dynamic> m) {
  // overlay path
  final overlay = _dig(m, ['overlay', 'musicItemThumbnailOverlayRenderer', 'content',
      'musicPlayButtonRenderer', 'playNavigationEndpoint']);
  if (overlay != null) {
    final id = _dig<String>(_asMap(overlay), ['watchEndpoint', 'videoId']);
    if (id != null && id.isNotEmpty) return id;
  }
  // flex column run endpoint
  for (final col in _list(m['flexColumns'])) {
    for (final run in _list(_dig(_asMap(col), ['musicResponsiveListItemFlexColumnRenderer', 'text', 'runs']))) {
      if (run is! Map) continue;
      final id = _dig<String>(_asMap(run), ['navigationEndpoint', 'watchEndpoint', 'videoId']);
      if (id != null && id.isNotEmpty) return id;
    }
  }
  return null;
}

String _flexText(Map<String, dynamic> m, int idx) {
  final cols = _list(m['flexColumns']);
  if (idx >= cols.length) return '';
  final runs = _list(_dig(_asMap(cols[idx]), ['musicResponsiveListItemFlexColumnRenderer', 'text', 'runs']));
  return runs.whereType<Map>().map((r) => r['text']?.toString() ?? '').join('');
}

int? _parseDuration(String text) {
  if (text.isEmpty) return null;
  final p = text.split(':');
  try {
    if (p.length == 2) return int.parse(p[0]) * 60 + int.parse(p[1]);
    if (p.length == 3) return int.parse(p[0]) * 3600 + int.parse(p[1]) * 60 + int.parse(p[2]);
  } catch (_) {}
  return null;
}

T? _dig<T>(dynamic root, List<String> path) {
  dynamic cur = root;
  for (final k in path) {
    if (cur is! Map) return null;
    cur = cur[k];
  }
  return cur is T ? cur : null;
}

List _list(dynamic v) => v is List ? v : const [];
Map<String, dynamic> _asMap(dynamic v) => v is Map ? v.cast<String, dynamic>() : const {};
