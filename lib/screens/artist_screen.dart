// artist_screen.dart
// Display artist information and all their songs

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ytmusic_api.dart';
import '../providers.dart';
import 'player_screen.dart';

// Provider for fetching artist songs
final artistSongsProvider = FutureProvider.autoDispose
    .family<List<Song>, String>((ref, artistId) async {
      final api = ref.watch(apiProvider);
      return api.getArtistSongs(artistId);
    });

class ArtistScreen extends ConsumerWidget {
  const ArtistScreen({super.key, required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(artistSongsProvider(artist.id));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          // Artist header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0F),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Artist image
                  if (artist.artwork != null)
                    CachedNetworkImage(
                      imageUrl: artist.artwork!,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 300),
                      fadeInCurve: Curves.easeOut,
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0A0A0F).withOpacity(0.7),
                          const Color(0xFF0A0A0F),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // Artist info
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (artist.subscriberCount != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            artist.subscriberCount!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Songs list
          songsAsync.when(
            data: (songs) {
              if (songs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.music_off,
                          size: 64,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No songs found',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      // Play all button
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            ref.read(handlerProvider).play(songs, 0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PlayerScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    }

                    final songIndex = index - 1;
                    return _SongTile(
                      song: songs[songIndex],
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(handlerProvider).play(songs, songIndex);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PlayerScreen(),
                          ),
                        );
                      },
                    );
                  },
                  childCount: songs.length + 1, // +1 for play all button
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
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
                      'Error: $error',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Song Tile ──────────────────────────────────────────────────────────────

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
        splashColor: Colors.white24,
        highlightColor: Colors.white12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.artwork != null
                    ? CachedNetworkImage(
                        imageUrl: song.artwork!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 300),
                        fadeInCurve: Curves.easeOut,
                        placeholder: (_, __) => _placeholder,
                        errorWidget: (_, __, ___) => _placeholder,
                      )
                    : _placeholder,
              ),
              const SizedBox(width: 14),
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
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist.isEmpty ? 'Unknown artist' : song.artist,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Duration
              if (song.durationSec != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _formatDuration(Duration(seconds: song.durationSec!)),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static final _placeholder = Container(
    width: 52,
    height: 52,
    color: const Color(0xFF14141F),
    child: const Icon(Icons.music_note, color: Colors.white24, size: 24),
  );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
