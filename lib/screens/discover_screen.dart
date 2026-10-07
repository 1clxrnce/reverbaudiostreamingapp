// discover_screen.dart
// Display top 5 trending songs from YouTube Music

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/ytmusic_api.dart';
import '../providers.dart';
import 'player_screen.dart';

// Provider for trending songs
final trendingSongsProvider = FutureProvider<List<Song>>((ref) async {
  return ref.read(apiProvider).getTrendingSongs();
});

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingSongsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: const Text(
            'Discover',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: trendingAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return _EmptyState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFFFFF).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Color(0xFFFFFFFF),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'TRENDING NOW',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Top 5 Songs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The hottest tracks right now',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Song List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: songs.length,
                  itemBuilder: (ctx, i) => _TrendingSongTile(
                    rank: i + 1,
                    song: songs[i],
                    onTap: () {
                      ref.read(handlerProvider).play(songs, i);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlayerScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFFFFF)),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load trending songs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(trendingSongsProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFFFFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Play All FAB
      floatingActionButton: trendingAsync.value != null &&
              trendingAsync.value!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.read(handlerProvider).play(trendingAsync.value!, 0);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                );
              },
              backgroundColor: const Color(0xFFFFFFFF),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                'Play All',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off, size: 80, color: Colors.white24),
            SizedBox(height: 24),
            Text(
              'No trending songs available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for hot tracks',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trending Song Tile ─────────────────────────────────────────────────────

class _TrendingSongTile extends StatelessWidget {
  const _TrendingSongTile({
    required this.rank,
    required this.song,
    required this.onTap,
  });

  final int rank;
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFFFFFFFF).withOpacity(0.3),
          highlightColor: const Color(0xFFFFFFFF).withOpacity(0.1),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF14141F),
                  const Color(0xFF14141F).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: rank <= 3
                    ? const Color(0xFFFFFFFF).withOpacity(0.3)
                    : Colors.transparent,
                width: rank <= 3 ? 1.5 : 0,
              ),
              boxShadow: [
                if (rank <= 3)
                  BoxShadow(
                    color: const Color(0xFFFFFFFF).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank Badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: rank <= 3
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFCCCCCC),
                              ],
                            )
                          : null,
                      color: rank > 3 ? const Color(0xFF1E1E2E) : null,
                      shape: BoxShape.circle,
                      boxShadow: rank <= 3
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFFFFFFFF).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: rank <= 3 ? 18 : 16,
                          fontWeight:
                              rank <= 3 ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: song.artwork != null
                        ? CachedNetworkImage(
                            imageUrl: song.artwork!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 300),
                            placeholder: (_, __) => Container(
                              width: 64,
                              height: 64,
                              color: const Color(0xFF1E1E2E),
                              child: const Center(
                                child: Icon(
                                  Icons.music_note,
                                  size: 28,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 64,
                              height: 64,
                              color: const Color(0xFF1E1E2E),
                              child: const Center(
                                child: Icon(
                                  Icons.music_note,
                                  size: 28,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            color: const Color(0xFF1E1E2E),
                            child: const Center(
                              child: Icon(
                                Icons.music_note,
                                size: 28,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),

                  // Song Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist.isEmpty ? 'Unknown artist' : song.artist,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Play Icon
                  Icon(
                    Icons.play_circle_filled,
                    color: rank <= 3
                        ? const Color(0xFFFFFFFF)
                        : Colors.white54,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
