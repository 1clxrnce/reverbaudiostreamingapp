// search_screen.dart
// Main screen: search bar, results list, mini now-playing bar.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ytmusic_api.dart';
import '../providers.dart';
import '../widgets/add_to_playlist_sheet.dart';
import 'player_screen.dart';

// ── Navigation helper ─────────────────────────────────────────────────────────

// Slide-up transition used everywhere we open the player.
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

  @override
  void initState() {
    super.initState();
    // Rebuild whenever the text changes so the X button appears/disappears
    // reactively on every keystroke — not only after a submit.
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(String v) => setState(() => _query = v.trim());

  void _tap(List<Song> songs, int i) {
    ref.read(handlerProvider).play(songs, i);
    Navigator.push(context, _playerRoute());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F), // dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        toolbarHeight: 84,
        title: Image.asset(
          'assets/logo 12 black and white.png',
          height: 56,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
              color: Color(0xFF9D4EDD),
            ), // purple icon
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
            tooltip: 'Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.library_music, color: Colors.white),
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.pushNamed(context, '/playlists'),
            tooltip: 'Playlists',
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _ctrl,
              onSubmitted: _submit,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: const Color(0xFF9D4EDD), // purple cursor
              decoration: InputDecoration(
                hintText: 'Search for a song',
                hintStyle: const TextStyle(
                  color: Color(0xFF6E6E7E),
                  fontSize: 16,
                ),
                filled: true,
                fillColor: const Color(0xFF14141F), // surface dark
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF6B4C9A), // purple subtle
                  size: 22,
                ),
                // Clear button appears on every keystroke
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF6B4C9A)),
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
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _Results(query: _query, onTap: _tap),
          ),
          _MiniBar(),
        ],
      ),
    );
  }
}

// ── Results ───────────────────────────────────────────────────────────────────

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.onTap});
  final String query;
  final void Function(List<Song>, int) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Search for a song above',
          style: TextStyle(color: Color(0xFF6E6E7E)), // dim text
        ),
      );
    }

    final state = ref.watch(searchProvider(query));
    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9D4EDD),
        ), // purple spinner
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
              'No results',
              style: TextStyle(color: Color(0xFF6E6E7E)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 4),
          itemCount: songs.length,
          itemBuilder: (ctx, i) =>
              _Tile(song: songs[i], onTap: () => onTap(songs, i)),
        );
      },
    );
  }
}

// ── Song tile ─────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  const _Tile({required this.song, required this.onTap});
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF9D4EDD).withOpacity(0.15), // purple splash
        highlightColor: const Color(0xFF9D4EDD).withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                // Hero tag matches the one in PlayerScreen so artwork morphs on open.
                child: Hero(
                  tag: 'artwork-${song.id}',
                  child: song.artwork != null
                      ? CachedNetworkImage(
                          imageUrl: song.artwork!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 300),
                          fadeInCurve: Curves.easeOut,
                          placeholder: (_, _) => _ph,
                          errorWidget: (_, _, _) => _ph,
                        )
                      : _ph,
                ),
              ),
              const SizedBox(width: 14),
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
                        fontSize: 15,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist.isEmpty ? 'Unknown artist' : song.artist,
                      style: const TextStyle(
                        color: Color(0xFFB4B4C8), // light gray-purple
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (song.durationSec != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _fmt(Duration(seconds: song.durationSec!)),
                    style: const TextStyle(
                      color: Color(0xFF6E6E7E),
                      fontSize: 12,
                    ), // dim gray
                  ),
                ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF6B4C9A), // purple subtle
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
    width: 52,
    height: 52,
    color: const Color(0xFF14141F), // surface dark
    child: const Icon(
      Icons.music_note,
      color: Color(0xFF6B4C9A),
      size: 24,
    ), // purple icon
  );

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:${m.padLeft(2, '0')}:$s' : '$m:$s';
  }
}

// ── Mini now-playing bar ──────────────────────────────────────────────────────

class _MiniBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(handlerProvider);

    return ValueListenableBuilder<Song?>(
      valueListenable: h.current,
      builder: (_, song, _) {
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => Navigator.push(context, _playerRoute()),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF14141F), // surface dark
              borderRadius: BorderRadius.circular(12),
            ),
            // ClipRRect so the progress strip respects the rounded corners.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Main row: artwork | title+artist | controls ──
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Artwork — Hero tag matches the current song so it
                        // morphs into the full artwork on the player screen.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Hero(
                            tag: 'artwork-${song.id}',
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
                                    color: const Color(
                                      0xFF14141F,
                                    ), // surface dark
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Color(0xFF6B4C9A), // purple
                                      size: 20,
                                    ),
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
                                  color: Color(0xFFB4B4C8), // light gray-purple
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
                              color: const Color(0xFF9D4EDD), // purple
                              size: 28,
                            ),
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            onPressed: playing ? h.pause : h.resume,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Color(0xFF9D4EDD), // purple
                            size: 28,
                          ),
                          padding: const EdgeInsets.all(10),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: h.next,
                        ),
                      ],
                    ),
                  ),

                  // ── Seek progress strip ──
                  // A thin bar that fills left-to-right as the song plays.
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
                          backgroundColor: const Color(
                            0xFF14141F,
                          ), // surface dark
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF9D4EDD), // purple progress
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
