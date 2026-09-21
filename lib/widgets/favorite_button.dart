// favorite_button.dart
// Reusable heart button for favoriting songs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/ytmusic_api.dart';
import '../providers.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.song,
    this.size = 28,
    this.color = Colors.white,
  });

  final Song song;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    // Not signed in - show disabled heart
    if (user == null) {
      return IconButton(
        icon: Icon(
          Icons.favorite_border,
          size: size,
          color: color.withOpacity(0.3),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sign in to save favorites'),
              action: SnackBarAction(
                label: 'Sign In',
                onPressed: () {
                  Navigator.pushNamed(context, '/sign-in');
                },
              ),
            ),
          );
        },
      );
    }

    // Signed in - show interactive heart
    final isFavoriteAsync = ref.watch(isFavoriteProvider(song.id));

    return isFavoriteAsync.when(
      data: (isFavorite) => IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: size,
          color: isFavorite ? Colors.redAccent : color,
        ),
        onPressed: () async {
          try {
            await ref
                .read(firestoreServiceProvider)
                .toggleFavorite(user.uid, song);
            
            // Refresh the provider
            ref.invalidate(isFavoriteProvider(song.id));
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite
                        ? 'Removed from favorites'
                        : 'Added to favorites',
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor:
                      isFavorite ? Colors.grey[800] : Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
      loading: () => IconButton(
        icon: Icon(
          Icons.favorite_border,
          size: size,
          color: color.withOpacity(0.5),
        ),
        onPressed: null,
      ),
      error: (e, _) => IconButton(
        icon: Icon(
          Icons.favorite_border,
          size: size,
          color: color.withOpacity(0.3),
        ),
        onPressed: null,
      ),
    );
  }
}
