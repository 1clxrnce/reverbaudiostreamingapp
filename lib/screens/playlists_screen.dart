// playlists_screen.dart
// View and manage user playlists

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(userPlaylistsProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text(
          'Playlists',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            // Not signed in
            return _SignInPrompt();
          }

          // Signed in - show playlists
          return playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return _EmptyState(
                  onCreatePlaylist: () =>
                      _showCreatePlaylistDialog(context, ref),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: playlists.length,
                itemBuilder: (ctx, i) => _PlaylistCard(
                  playlist: playlists[i],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PlaylistDetailScreen(playlist: playlists[i]),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error loading playlists: $e',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
      floatingActionButton: authState.value != null
          ? FloatingActionButton(
              onPressed: () => _showCreatePlaylistDialog(context, ref),
              backgroundColor: Colors.white,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (ctx) => _CreatePlaylistDialog());
  }
}

// ── Sign In Prompt ─────────────────────────────────────────────────────────

class _SignInPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music, size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            const Text(
              'Sign in to create playlists',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your playlists will sync across all your devices',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/sign-in');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.queue_music, size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            const Text(
              'No playlists yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first playlist to get started',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreatePlaylist,
              icon: const Icon(Icons.add),
              label: const Text('Create Playlist'),
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
          ],
        ),
      ),
    );
  }
}

// ── Playlist Card ──────────────────────────────────────────────────────────

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.onTap});

  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Use custom cover if set, otherwise use first song artwork
    final coverImage =
        playlist.coverUrl ??
        (playlist.songs.isNotEmpty && playlist.songs.first.artwork != null
            ? playlist.songs.first.artwork
            : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showCoverOptions(context),
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white24,
        highlightColor: Colors.white12,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF14141F),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artwork or placeholder
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: coverImage != null
                          ? CachedNetworkImage(
                              imageUrl: coverImage,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 300),
                              fadeInCurve: Curves.easeOut,
                              placeholder: (_, __) => Container(
                                color: const Color(0xFF14141F),
                                child: const Center(
                                  child: Icon(
                                    Icons.queue_music,
                                    size: 64,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF14141F),
                                child: const Center(
                                  child: Icon(
                                    Icons.queue_music,
                                    size: 64,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF14141F),
                              child: const Center(
                                child: Icon(
                                  Icons.queue_music,
                                  size: 64,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                    ),
                    // Custom cover indicator
                    if (playlist.coverUrl != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.image,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Info section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCoverOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14141F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CoverOptionsSheet(playlist: playlist),
    );
  }
}

// ── Create Playlist Dialog ─────────────────────────────────────────────────

class _CreatePlaylistDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreatePlaylistDialog> createState() =>
      _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<_CreatePlaylistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    // Close dialog immediately for instant feel
    Navigator.pop(context);

    // Show instant feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating "$name"...'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        await ref.read(firestoreServiceProvider).createPlaylist(user.uid, name);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Created "$name"')),
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
                const Icon(Icons.error, color: Colors.white),
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
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF14141F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Playlist name',
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF14141F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _create(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _create,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// ── Cover Options Sheet ────────────────────────────────────────────────────

class _CoverOptionsSheet extends ConsumerWidget {
  const _CoverOptionsSheet({required this.playlist});
  final Playlist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Playlist Cover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Pick from songs
                if (playlist.songs.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Choose from songs',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showSongArtworkPicker(context, ref);
                    },
                  ),

                // Enter URL
                ListTile(
                  leading: const Icon(Icons.link, color: Colors.white),
                  title: const Text(
                    'Enter image URL',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showUrlDialog(context, ref);
                  },
                ),

                // Remove cover
                if (playlist.coverUrl != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Remove custom cover',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeCover(ref);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSongArtworkPicker(BuildContext context, WidgetRef ref) {
    final songsWithArtwork = playlist.songs
        .where((s) => s.artwork != null)
        .toList();

    if (songsWithArtwork.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No songs with artwork in this playlist'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Choose Cover',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: songsWithArtwork.length,
            itemBuilder: (ctx, i) {
              final song = songsWithArtwork[i];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _updateCover(ref, song.artwork!);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(song.artwork!, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showUrlDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Image URL', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'https://example.com/image.jpg',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF14141F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (url) {
            if (url.trim().isNotEmpty) {
              Navigator.pop(ctx);
              _updateCover(ref, url.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                _updateCover(ref, url);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromDevice(WidgetRef ref) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // For now, we'll use the local file path as the URL
        // In a production app, you'd upload this to Firebase Storage
        _updateCover(ref, image.path);

        // Show a message that this is a local image
        if (ref.context.mounted) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            const SnackBar(
              content: Text(
                'Local image set (upload to cloud storage for persistence)',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _updateCover(WidgetRef ref, String url) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        await ref
            .read(firestoreServiceProvider)
            .updatePlaylistCover(user.uid, playlist.id, url);
      }
    } catch (e) {
      debugPrint('Error updating cover: $e');
    }
  }

  Future<void> _removeCover(WidgetRef ref) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        await ref
            .read(firestoreServiceProvider)
            .updatePlaylistCover(user.uid, playlist.id, null);
      }
    } catch (e) {
      debugPrint('Error removing cover: $e');
    }
  }
}
