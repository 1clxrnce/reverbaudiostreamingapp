// favorites_screen.dart
// View and play favorite songs

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/ytmusic_api.dart';
import '../providers.dart';
import 'player_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  bool _isGridView = true; // true = grid, false = list

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(userFavoritesProvider);
    final authState = ref.watch(authStateProvider);

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
            'Favorites',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // View toggle button
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return _SignInPrompt();
          }

          return favoritesAsync.when(
            data: (favorites) {
              if (favorites.isEmpty) {
                return _EmptyState();
              }

              // Grid view
              if (_isGridView) {
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (ctx, i) => _FavoriteCard(
                    song: favorites[i],
                    onTap: () {
                      ref.read(handlerProvider).play(favorites, i);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlayerScreen()),
                      );
                    },
                    onRemove: () async {
                      await ref
                          .read(firestoreServiceProvider)
                          .removeFromFavorites(user.uid, favorites[i].id);
                    },
                  ),
                );
              }

              // List view
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: favorites.length,
                itemBuilder: (ctx, i) => _FavoriteListTile(
                  song: favorites[i],
                  onTap: () {
                    ref.read(handlerProvider).play(favorites, i);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()),
                    );
                  },
                  onRemove: () async {
                    await ref
                        .read(firestoreServiceProvider)
                        .removeFromFavorites(user.uid, favorites[i].id);
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error loading favorites: $e',
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
      floatingActionButton:
          authState.value != null &&
              favoritesAsync.value != null &&
              favoritesAsync.value!.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                ref.read(handlerProvider).play(favoritesAsync.value!, 0);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                );
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.play_arrow, color: Colors.black),
            )
          : null,
    );
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
            const Icon(Icons.favorite_border, size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            const Text(
              'Sign in to save favorites',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your favorites will sync across all your devices',
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
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.white24),
            SizedBox(height: 24),
            Text(
              'No favorites yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the heart icon on any song to save it here',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Favorite Card ──────────────────────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.song,
    required this.onTap,
    required this.onRemove,
  });

  final Song song;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              // Artwork
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: song.artwork != null
                          ? CachedNetworkImage(
                              imageUrl: song.artwork!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 300),
                              fadeInCurve: Curves.easeOut,
                              placeholder: (_, __) => Container(
                                color: const Color(0xFF14141F),
                                child: const Center(
                                  child: Icon(
                                    Icons.music_note,
                                    size: 64,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF14141F),
                                child: const Center(
                                  child: Icon(
                                    Icons.music_note,
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
                                  Icons.music_note,
                                  size: 64,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                    ),
                    // Heart icon overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onRemove,
                          customBorder: const CircleBorder(),
                          splashColor: Colors.white24,
                          child: Ink(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                          ),
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
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist.isEmpty ? 'Unknown artist' : song.artist,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ── Favorite List Tile (for List View) ────────────────────────────────────

class _FavoriteListTile extends StatelessWidget {
  const _FavoriteListTile({
    required this.song,
    required this.onTap,
    required this.onRemove,
  });

  final Song song;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF14141F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
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
                            fadeInCurve: Curves.easeOut,
                            placeholder: (_, __) => Container(
                              width: 56,
                              height: 56,
                              color: const Color(0xFF1E1E2E),
                              child: const Center(
                                child: Icon(
                                  Icons.music_note,
                                  size: 24,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: const Color(0xFF1E1E2E),
                              child: const Center(
                                child: Icon(
                                  Icons.music_note,
                                  size: 24,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: const Color(0xFF1E1E2E),
                            child: const Center(
                              child: Icon(
                                Icons.music_note,
                                size: 24,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),

                  // Song info
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

                  // Remove button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onRemove,
                      customBorder: const CircleBorder(),
                      splashColor: Colors.redAccent.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                      ),
                    ),
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
