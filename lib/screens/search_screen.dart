// search_screen.dart
// Search screen with filter toggle (All/Songs/Artists)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ytmusic_api.dart';
import '../providers.dart';
import '../widgets/add_to_playlist_sheet.dart';
import 'artist_screen.dart';
import 'player_screen.dart';

// ── Navigation helper ─────────────────────────────────────────────────────────

Route<void> _playerRoute() => PageRouteBuilder<void>(
  pageBuilder: (_, _a, _b) => const PlayerScreen(),
  transitionsBuilder: (_, animation, _c, child) {
    final tween = Tween(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(position: animation.drive(tween), child: child);
  },
  transitionDuration: const Duration(milliseconds: 380),
);

// ── SearchScreen ──────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _State();
}

class _State extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  SearchType _searchType = SearchType.all; // Default to all

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(String v) => setState(() => _query = v.trim());

  void _tap(List<Song> songs, int i) {
    HapticFeedback.lightImpact();
    ref.read(handlerProvider).play(songs, i);
    Navigator.push(context, _playerRoute());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        toolbarHeight: 84,
        title: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Pop all routes until we reach home
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: Image.asset(
            'assets/logo 12 black and white.png',
            height: 56,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFFFFFFFF)),
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/favorites');
            },
            tooltip: 'Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.library_music, color: Colors.white),
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/playlists');
            },
            tooltip: 'Playlists',
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/profile');
            },
            tooltip: 'Profile',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            120,
          ), // Increased for filter chips
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: _submit,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: const Color(0xFFFFFFFF),
                  decoration: InputDecoration(
                    hintText:
                        'Search for ${_searchType == SearchType.all
                            ? 'songs or artists'
                            : _searchType == SearchType.songs
                            ? 'songs'
                            : 'artists'}',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6E6E7E),
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF14141F),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFAAAAAA),
                      size: 22,
                    ),
                    suffixIcon: _ctrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFFAAAAAA),
                            ),
                            iconSize: 20,
                            onPressed: () {
                              _ctrl.clear();
                              _submit('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _searchType == SearchType.all,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _searchType = SearchType.all);
                        if (_query.isNotEmpty) _submit(_query);
                      },
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'Songs',
                      isSelected: _searchType == SearchType.songs,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _searchType = SearchType.songs);
                        if (_query.isNotEmpty) _submit(_query);
                      },
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'Artists',
                      isSelected: _searchType == SearchType.artists,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _searchType = SearchType.artists);
                        if (_query.isNotEmpty) _submit(_query);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _Results(
              query: _query,
              searchType: _searchType,
              onSongTap: _tap,
            ),
          ),
          _MiniBar(),
        ],
      ),
    );
  }
} // ── Filter Chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF14141F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : const Color(0xFF6E6E7E).withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
// ── Results ───────────────────────────────────────────────────────────────────

class _Results extends ConsumerWidget {
  const _Results({
    required this.query,
    required this.searchType,
    required this.onSongTap,
  });

  final String query;
  final SearchType searchType;
  final void Function(List<Song>, int) onSongTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Search for ${searchType == SearchType.all
              ? 'songs or artists'
              : searchType == SearchType.songs
              ? 'songs'
              : 'artists'}',
          style: const TextStyle(color: Color(0xFF6E6E7E)),
        ),
      );
    }
    // Show artists if searching for artists or all
    if (searchType == SearchType.artists || searchType == SearchType.all) {
      return _ArtistAndSongResults(
        query: query,
        searchType: searchType,
        onSongTap: onSongTap,
      );
    }
    // Songs only
    final state = ref.watch(searchProvider(query));
    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFFFFF)),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Text(
              'No songs found',
              style: TextStyle(color: Color(0xFF6E6E7E)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 4),
          itemCount: songs.length,
          itemBuilder: (ctx, i) =>
              _SongTile(song: songs[i], onTap: () => onSongTap(songs, i)),
        );
      },
    );
  }
}

// ── Artist and Song Results (for "All" filter) ────────────────────────────────

class _ArtistAndSongResults extends ConsumerWidget {
  const _ArtistAndSongResults({
    required this.query,
    required this.searchType,
    required this.onSongTap,
  });

  final String query;
  final SearchType searchType;
  final void Function(List<Song>, int) onSongTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiProvider);
    return FutureBuilder<Map<String, dynamic>>(
      future:
          Future.wait([
            if (searchType != SearchType.artists)
              api.searchSongs(query, type: searchType),
            if (searchType != SearchType.songs) api.searchArtists(query),
          ]).then(
            (results) => {
              'songs': searchType != SearchType.artists
                  ? results[0] as List<Song>
                  : <Song>[],
              'artists': searchType != SearchType.songs
                  ? results[searchType == SearchType.all ? 1 : 0]
                        as List<Artist>
                  : <Artist>[],
            },
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFFFFF)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        final data = snapshot.data!;
        final songs = data['songs'] as List<Song>;
        final artists = data['artists'] as List<Artist>;
        if (songs.isEmpty && artists.isEmpty) {
          return const Center(
            child: Text(
              'No results found',
              style: TextStyle(color: Color(0xFF6E6E7E)),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // Artists section
            if (artists.isNotEmpty) ...[
              Container(
                color: const Color(0xFF14141F),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Artists',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ...artists.map((artist) => _ArtistTile(artist: artist)),
              if (songs.isNotEmpty) const SizedBox(height: 8),
            ],
            // Songs section
            if (songs.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  artists.isEmpty ? 16 : 8,
                  16,
                  8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Songs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ...songs.asMap().entries.map(
                (entry) => _SongTile(
                  song: entry.value,
                  onTap: () => onSongTap(songs, entry.key),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Artist Tile ────────────────────────────────────────────────────────────────
class _ArtistTile extends StatelessWidget {
  const _ArtistTile({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArtistScreen(artist: artist)),
          );
        },
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Artist avatar with shadow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: artist.artwork != null
                      ? CachedNetworkImage(
                          imageUrl: artist.artwork!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 300),
                          fadeInCurve: Curves.easeOut,
                          placeholder: (_, __) => _placeholder,
                          errorWidget: (_, __, ___) => _placeholder,
                        )
                      : _placeholder,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (artist.subscriberCount != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        artist.subscriberCount!,
                        style: const TextStyle(
                          color: Color(0xFFB4B4C8),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFAAAAAA),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _placeholder = Container(
    width: 60,
    height: 60,
    color: const Color(0xFF14141F),
    child: const Icon(Icons.person, color: Color(0xFFAAAAAA), size: 32),
  );
}

// ── Song Tile ─────────────────────────────────────────────────────────────────
class _SongTile extends StatelessWidget {
  const _SongTile({required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Artwork
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.artwork != null
                      ? CachedNetworkImage(
                          imageUrl: song.artwork!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 300),
                          fadeInCurve: Curves.easeOut,
                          placeholder: (_, _) => _ph,
                          errorWidget: (_, _, _) => _ph,
                        )
                      : _ph,
                ),
              ),
              const SizedBox(width: 16),
              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist.isEmpty ? 'Unknown artist' : song.artist,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Duration and menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (song.durationSec != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _fmt(Duration(seconds: song.durationSec!)),
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFFAAAAAA),
                  size: 20,
                ),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddToPlaylistSheet(song: song),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _ph = Container(
    width: 56,
    height: 56,
    color: const Color(0xFF14141F),
    child: const Icon(Icons.music_note, color: Color(0xFFAAAAAA), size: 28),
  );

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:${m.padLeft(2, '0')}:$s' : '$m:$s';
  }
}

// ── Mini Bar ──────────────────────────────────────────────────────────────────
class _MiniBar extends ConsumerWidget {
  const _MiniBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(handlerProvider);
    return ValueListenableBuilder<Song?>(
      valueListenable: h.current,
      builder: (_, song, _) {
        if (song == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, _playerRoute());
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF14141F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: song.artwork != null
                              ? CachedNetworkImage(
                                  imageUrl: song.artwork!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  fadeInDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                  fadeInCurve: Curves.easeOut,
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFF14141F),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Color(0xFFAAAAAA),
                                    size: 20,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist.isEmpty ? 'Unknown' : song.artist,
                                style: const TextStyle(
                                  color: Color(0xFFB4B4C8),
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: h.playing,
                          builder: (_, playing, _) => IconButton(
                            icon: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: const Color(0xFFFFFFFF),
                              size: 28,
                            ),
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              playing ? h.pause() : h.resume();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Color(0xFFFFFFFF),
                            size: 28,
                          ),
                          padding: const EdgeInsets.all(10),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            h.next();
                          },
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<Duration>(
                    valueListenable: h.position,
                    builder: (_, pos, _) => ValueListenableBuilder<Duration>(
                      valueListenable: h.duration,
                      builder: (_, dur, _) {
                        final progress = dur.inMilliseconds > 0
                            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(
                                0.0,
                                1.0,
                              )
                            : 0.0;
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 2.5,
                          backgroundColor: const Color(0xFF14141F),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFFFFF),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
