// search_screen.dart
// Main screen: search bar, results list, mini now-playing bar.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ytmusic_api.dart';
import '../providers.dart';
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
      backgroundColor: const Color(0xFF0B0B0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0D),
        toolbarHeight: 80, // Taller AppBar to accommodate bigger logo
        title: Image.asset(
          'assets/logo 12 black and white.png',
          height: 56,
          fit: BoxFit.contain,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              onSubmitted: _submit,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'What do you want to listen to?',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                // X button is now driven by the _ctrl listener above —
                // appears/disappears on every keystroke, not only after submit.
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () {
                          _ctrl.clear();
                          _submit('');
                        },
                      )
                    : null,
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
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final state = ref.watch(searchProvider(query));
    return state.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white54)),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Text('No results', style: TextStyle(color: Colors.white38)),
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        // Hero tag matches the one in PlayerScreen so artwork morphs on open.
        child: Hero(
          tag: 'artwork-${song.id}',
          child: song.artwork != null
              ? CachedNetworkImage(
                  imageUrl: song.artwork!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _ph,
                  errorWidget: (_, _, _) => _ph,
                )
              : _ph,
        ),
      ),
      title: Text(
        song.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist.isEmpty ? 'Unknown artist' : song.artist,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: song.durationSec != null
          ? Text(
              _fmt(Duration(seconds: song.durationSec!)),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            )
          : null,
    );
  }

  static final _ph = Container(
    width: 48,
    height: 48,
    color: const Color(0xFF2C2C2E),
    child: const Icon(Icons.music_note, color: Colors.white24, size: 22),
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
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(14),
            ),
            // ClipRRect so the progress strip respects the rounded corners.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Main row: artwork | title+artist | controls ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Artwork — Hero tag matches the current song so it
                        // morphs into the full artwork on the player screen.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Hero(
                            tag: 'artwork-${song.id}',
                            child: song.artwork != null
                                ? CachedNetworkImage(
                                    imageUrl: song.artwork!,
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 42,
                                    height: 42,
                                    color: const Color(0xFF2C2C2E),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white24,
                                      size: 18,
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
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist.isEmpty ? 'Unknown' : song.artist,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
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
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: playing ? h.pause : h.resume,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: h.next,
                        ),
                      ],
                    ),
                  ),

                  // ── Seek progress strip ──
                  // A thin 3 px bar that fills left-to-right as the song plays.
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
                          minHeight: 3,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white54,
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
