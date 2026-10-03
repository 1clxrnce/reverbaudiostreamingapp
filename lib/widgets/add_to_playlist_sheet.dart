// add_to_playlist_sheet.dart
// Bottom sheet for adding a song to a playlist

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/ytmusic_api.dart';
import '../providers.dart';

class AddToPlaylistSheet extends ConsumerWidget {
  const AddToPlaylistSheet({super.key, required this.song});
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(userPlaylistsProvider);
    final authState = ref.watch(authStateProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF14141F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Add to Playlist',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Playlist list
          Flexible(
            child: authState.when(
              data: (user) {
                if (user == null) {
                  return _SignInPrompt();
                }

                return playlistsAsync.when(
                  data: (playlists) {
                    if (playlists.isEmpty) {
                      return _EmptyState(
                        onCreatePlaylist: () {
                          Navigator.pop(context);
                          // Navigate to playlists screen to create one
                          Navigator.pushNamed(context, '/playlists');
                        },
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (ctx, i) => ListTile(
                        onTap: () async {
                          // Close sheet immediately for instant feel
                          Navigator.pop(context);

                          // Show instant feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Adding to ${playlists[i].name}...',
                              ),
                              duration: const Duration(milliseconds: 800),
                              backgroundColor: Colors.grey[800],
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          try {
                            // Background Firestore update
                            await ref
                                .read(firestoreServiceProvider)
                                .addSongToPlaylist(
                                  user.uid,
                                  playlists[i].id,
                                  song,
                                );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Added to ${playlists[i].name}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text('Error: $e')),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF14141F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.queue_music,
                            color: Colors.white54,
                          ),
                        ),
                        title: Text(
                          playlists[i].name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${playlists[i].songs.length} songs',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: const Icon(Icons.add, color: Colors.white54),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Sign In Prompt ─────────────────────────────────────────────────────────

class _SignInPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.library_music, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Sign in to create playlists',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/sign-in');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreatePlaylist});
  final VoidCallback onCreatePlaylist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.queue_music, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'No playlists yet',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCreatePlaylist,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('Create Playlist'),
          ),
        ],
      ),
    );
  }
}
