// favorite_button.dart
// Reusable heart button for favoriting songs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/ytmusic_api.dart';
import '../providers.dart';

class FavoriteButton extends ConsumerStatefulWidget {
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
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  bool? _localState; // Local optimistic state
  bool _isProcessing = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isProcessing) return;

    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sign in to save favorites'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () => Navigator.pushNamed(context, '/sign-in'),
          ),
        ),
      );
      return;
    }

    // Get current state
    final isFavoriteAsync = ref.read(isFavoriteProvider(widget.song.id));
    final currentState = _localState ?? isFavoriteAsync.value ?? false;

    debugPrint(
      '[FavoriteButton] Toggle - User: ${user.uid}, Song: ${widget.song.title}',
    );
    debugPrint(
      '[FavoriteButton] Current state: $currentState -> ${!currentState}',
    );

    // Animate
    _animController.forward().then((_) => _animController.reverse());

    // Optimistic update
    setState(() {
      _localState = !currentState;
      _isProcessing = true;
    });

    try {
      // Save to Firestore
      await ref
          .read(firestoreServiceProvider)
          .toggleFavorite(user.uid, widget.song);

      debugPrint('[FavoriteButton] ✅ Success!');

      if (mounted) {
        setState(() {
          _localState = null; // Clear optimistic state
          _isProcessing = false;
        });
        // Invalidate provider to refresh from Firestore
        ref.invalidate(isFavoriteProvider(widget.song.id));
      }
    } catch (e) {
      debugPrint('[FavoriteButton] ❌ Error: $e');

      if (mounted) {
        // Revert on error
        setState(() {
          _localState = null;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      // Not signed in - disabled state
      return IconButton(
        icon: Icon(
          Icons.favorite_border,
          size: widget.size,
          color: widget.color.withOpacity(0.3),
        ),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: _toggle,
      );
    }

    // Get favorite state
    final isFavoriteAsync = ref.watch(isFavoriteProvider(widget.song.id));
    final isFavorite = _localState ?? isFavoriteAsync.value ?? false;

    return ScaleTransition(
      scale: _scaleAnim,
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: widget.size,
          color: isFavorite ? Colors.white : widget.color,
        ),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: _isProcessing ? null : _toggle,
      ),
    );
  }
}
