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
        elevation: 0,
        title: const Text(
          'Trending',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: songs.length,
            itemBuilder: (ctx, i) => _TrendingSongTile(
              rank: i + 1,
              song: songs[i],
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(handlerProvider).play(songs, i);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                );
              },
            ),
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
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load trending songs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(trendingSongsProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            Icon(Icons.music_off, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'No trending songs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later',
              style: TextStyle(color: Colors.white54, fontSize: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF14141F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? Colors.white : const Color(0xFF1E1E2E),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank <= 3 ? Colors.black : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.artwork != null
                      ? CachedNetworkImage(
                          imageUrl: song.artwork!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 300),
                          placeholder: (_, __) => Container(
                            width: 56,
                            height: 56,
                            color: const Color(0xFF1E1E2E),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white24,
                              size: 24,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: const Color(0xFF1E1E2E),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white24,
                              size: 24,
                            ),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFF1E1E2E),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white24,
                            size: 24,
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist.isEmpty ? 'Unknown artist' : song.artist,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Play Icon
                const Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
