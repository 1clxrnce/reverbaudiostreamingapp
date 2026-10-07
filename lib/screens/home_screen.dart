// home_screen.dart
// Main home screen with personalized recommendations and search

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../api/ytmusic_api.dart';
import '../providers.dart';
import '../widgets/add_to_playlist_sheet.dart';
import 'discover_screen.dart'; // For trendingSongsProvider
import 'player_screen.dart';

// ── Navigation helper ─────────────────────────────────────────────────────────

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

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Debounced search: wait 300ms after user stops typing before updating UI
    _searchCtrl.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _submit(String v) => setState(() => _query = v.trim());

  void _tap(List<Song> songs, int i) {
    HapticFeedback.lightImpact();
    ref.read(handlerProvider).play(songs, i);
    Navigator.push(context, _playerRoute());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isSearching
                  ? _SearchResults(query: _query, onTap: _tap)
                  : _HomeContent(
                      onTap: _tap,
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        await Future.delayed(const Duration(milliseconds: 800));
                        if (mounted) setState(() {});
                      },
                    ),
            ),
            _MiniBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo and actions
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // If searching, exit search mode
                  if (_isSearching) {
                    _searchCtrl.clear();
                    _submit('');
                    setState(() => _isSearching = false);
                  } else {
                    // Otherwise pop all routes until home
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
                child: Image.asset(
                  'assets/logo 12 black and white.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                iconSize: 24,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/favorites');
                },
                tooltip: 'Favorites',
              ),
              IconButton(
                icon: const Icon(Icons.library_music, color: Colors.white),
                iconSize: 24,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/playlists');
                },
                tooltip: 'Playlists',
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                iconSize: 24,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/profile');
                },
                tooltip: 'Profile',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar with back button when searching
          Row(
            children: [
              if (_isSearching)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _searchCtrl.clear();
                    _submit('');
                    setState(() => _isSearching = false);
                  },
                  tooltip: 'Back to home',
                ),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (v) {
                    _submit(v);
                    setState(() => _isSearching = true);
                  },
                  onTap: () => setState(() => _isSearching = true),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, albums...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF14141F),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.white54,
                      size: 22,
                    ),
                    suffixIcon: _isSearching && _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                            iconSize: 20,
                            onPressed: () {
                              _searchCtrl.clear();
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
            ],
          ),
        ],
      ),
    );
  }
}

// ── Home Content ──────────────────────────────────────────────────────────────

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.onTap, required this.onRefresh});
  final void Function(List<Song>, int) onTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.white,
      backgroundColor: const Color(0xFF14141F),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _TrendingSection(onTap: onTap),
          const SizedBox(height: 24),
          if (user != null) _QuickAccessSection(onTap: onTap),
          if (user != null) const SizedBox(height: 24),
          _RecentlyPlayedSection(onTap: onTap),
          const SizedBox(height: 24),
          _MyPlaylistsSection(onTap: onTap),
          if (user == null) ...[const SizedBox(height: 24), _WelcomeSection()],
        ],
      ),
    );
  }
}

// ── Trending Section ──────────────────────────────────────────────────────────

class _TrendingSection extends ConsumerWidget {
  const _TrendingSection({required this.onTap});
  final void Function(List<Song>, int) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingSongsProvider);

    return trendingAsync.when(
      data: (songs) {
        if (songs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trending Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 190,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: songs.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _TrendingSongCard(
                    song: songs[i],
                    rank: i + 1,
                    onTap: () => onTap(songs, i),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (e, __) {
        debugPrint('[Home] Trending error: $e');
        return const SizedBox.shrink();
      },
    );
  }
}

class _TrendingSongCard extends StatelessWidget {
  const _TrendingSongCard({
    required this.song,
    required this.rank,
    required this.onTap,
  });

  final Song song;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 145,
          decoration: BoxDecoration(
            color: const Color(0xFF14141F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artwork with rank badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: song.artwork != null
                        ? CachedNetworkImage(
                            imageUrl: song.artwork!,
                            width: 140,
                            height: 110,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 140,
                            height: 110,
                            color: const Color(0xFF1E1E2E),
                            child: const Icon(
                              Icons.music_note_rounded,
                              size: 40,
                              color: Colors.white24,
                            ),
                          ),
                  ),
                  // Rank badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Song info
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist.isEmpty ? 'Unknown' : song.artist,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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

// ── Quick Access Section ──────────────────────────────────────────────────────

class _QuickAccessSection extends ConsumerWidget {
  const _QuickAccessSection({required this.onTap});
  final void Function(List<Song>, int) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Access',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _QuickAccessCard(
                icon: Icons.favorite,
                label: 'Favorites',
                color: Colors.white,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/favorites');
                },
              ),
              const SizedBox(width: 12),
              _QuickAccessCard(
                icon: Icons.library_music,
                label: 'Playlists',
                color: Colors.white,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/playlists');
                },
              ),
              const SizedBox(width: 12),
              _QuickAccessCard(
                icon: Icons.explore,
                label: 'Discover',
                color: Colors.white,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/discover');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatefulWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<_QuickAccessCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF14141F),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 40),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recently Played Section ───────────────────────────────────────────────────

class _RecentlyPlayedSection extends ConsumerStatefulWidget {
  const _RecentlyPlayedSection({required this.onTap});
  final void Function(List<Song>, int) onTap;

  @override
  ConsumerState<_RecentlyPlayedSection> createState() =>
      _RecentlyPlayedSectionState();
}

class _RecentlyPlayedSectionState extends ConsumerState<_RecentlyPlayedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final historyAsync = ref.watch(userHistoryProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: historyAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: _EmptyState(
                icon: Icons.history,
                title: 'No history yet',
                subtitle: 'Songs you play will appear here',
              ),
            );
          }

          debugPrint(
            '[home] Displaying ${songs.length} songs: ${songs.map((s) => s.title).join(", ")}',
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Recently Played',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: songs.length,
                  itemBuilder: (ctx, i) => _SongCard(
                    song: songs[i],
                    onTap: () => widget.onTap(songs, i),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => _SkeletonLoader(title: 'Recently Played'),
        error: (error, stackTrace) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _ErrorState(
              title: 'Recently Played',
              message: 'Could not load history: ${error.toString()}',
              onRetry: () => ref.invalidate(
                StreamProvider.autoDispose(
                  (ref) => ref
                      .read(firestoreServiceProvider)
                      .getUserHistory(user.uid, limit: 10),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── My Playlists Section ──────────────────────────────────────────────────────

class _MyPlaylistsSection extends ConsumerWidget {
  const _MyPlaylistsSection({required this.onTap});
  final void Function(List<Song>, int) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final playlistsAsync = ref.watch(userPlaylistsProvider);

    return playlistsAsync.when(
      data: (playlists) {
        for (final p in playlists) {}

        if (playlists.isEmpty) {
          return _EmptyState(
            icon: Icons.queue_music,
            title: 'No playlists yet',
            subtitle: 'Create your first playlist to organize your music',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Playlists',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${playlists.length} ${playlists.length == 1 ? 'playlist' : 'playlists'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: playlists.length,
                itemBuilder: (ctx, i) => _PlaylistCard(
                  playlist: playlists[i],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      '/playlists',
                      arguments: playlists[i].id,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () {
        return _SkeletonLoader(title: 'My Playlists');
      },
      error: (error, stackTrace) {
        return _ErrorState(
          title: 'My Playlists',
          message: 'Could not load playlists',
          onRetry: () => ref.invalidate(
            StreamProvider.autoDispose(
              (ref) =>
                  ref.read(firestoreServiceProvider).getUserPlaylists(user.uid),
            ),
          ),
        );
      },
    );
  }
}

// ── Playlist Card ─────────────────────────────────────────────────────────────

class _PlaylistCard extends ConsumerWidget {
  const _PlaylistCard({required this.playlist, required this.onTap});
  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: playlist.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: playlist.coverUrl!,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 300),
                      fadeInCurve: Curves.easeOut,
                      placeholder: (_, __) => _buildDefaultCover(),
                      errorWidget: (_, __, ___) => _buildDefaultCover(),
                    )
                  : _buildDefaultCover(),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              playlist.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Song count
            Text(
              '${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    // Get first 4 songs with artwork
    final songsWithArt = playlist.songs
        .where((s) => s.artwork != null && s.artwork!.isNotEmpty)
        .take(4)
        .toList();

    if (songsWithArt.isEmpty) {
      // No songs with artwork - show placeholder
      return Container(
        width: 140,
        height: 140,
        color: const Color(0xFF14141F),
        child: const Center(
          child: Icon(Icons.queue_music, color: Colors.white24, size: 48),
        ),
      );
    }

    // Build grid based on number of songs
    return SizedBox(
      width: 140,
      height: 140,
      child: _buildArtworkGrid(songsWithArt),
    );
  }

  Widget _buildArtworkGrid(List<Song> songs) {
    if (songs.length == 1) {
      // Single artwork - full size
      return CachedNetworkImage(
        imageUrl: songs[0].artwork!,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeInCurve: Curves.easeOut,
      );
    } else if (songs.length == 2) {
      // Two artworks - side by side
      return Row(
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: songs[0].artwork!,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              fadeInCurve: Curves.easeOut,
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: CachedNetworkImage(
              imageUrl: songs[1].artwork!,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              fadeInCurve: Curves.easeOut,
            ),
          ),
        ],
      );
    } else if (songs.length == 3) {
      // Three artworks - one on left, two stacked on right
      return Row(
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: songs[0].artwork!,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              fadeInCurve: Curves.easeOut,
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: songs[1].artwork!,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                    fadeInCurve: Curves.easeOut,
                  ),
                ),
                const SizedBox(height: 1),
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: songs[2].artwork!,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                    fadeInCurve: Curves.easeOut,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Four artworks - 2x2 grid
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: songs[index].artwork!,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 300),
            fadeInCurve: Curves.easeOut,
          );
        },
      );
    }
  }

  static final _placeholder = Container(
    width: 140,
    height: 140,
    decoration: BoxDecoration(
      color: const Color(0xFF14141F),
      borderRadius: BorderRadius.circular(4), // Slightly rounded for cards
    ),
    child: const Icon(Icons.queue_music, color: Colors.white24, size: 40),
  );
}

// ── Cover Options Sheet ───────────────────────────────────────────────────────

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (ctx, i) => Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141F),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141F),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9E9E9E), size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFF9E9E9E),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRetry();
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF14141F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Song Card ─────────────────────────────────────────────────────────────────

class _SongCard extends StatelessWidget {
  const _SongCard({
    required this.song,
    required this.onTap,
    this.showBadge = false,
  });
  final Song song;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork with optional badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    4,
                  ), // Slightly rounded for cards
                  child: song.artwork != null
                      ? CachedNetworkImage(
                          imageUrl: song.artwork!,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 300),
                          fadeInCurve: Curves.easeOut,
                          placeholder: (_, __) => _placeholder,
                          errorWidget: (_, __, ___) => _placeholder,
                        )
                      : _placeholder,
                ),
                // Favorite badge
                if (showBadge)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              song.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Artist
            Text(
              song.artist.isEmpty ? 'Unknown' : song.artist,
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static final _placeholder = Container(
    width: 140,
    height: 140,
    color: const Color(0xFF14141F),
    child: const Icon(Icons.music_note, color: Colors.white24, size: 40),
  );
}

// ── Welcome Section ───────────────────────────────────────────────────────────

class _WelcomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, color: Colors.white24, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Welcome to REVERB',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Sign in to save favorites and get personalized recommendations',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/sign-in');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Results ────────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.onTap});
  final String query;
  final void Function(List<Song>, int) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Type to search',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
      );
    }

    final state = ref.watch(searchProvider(query));
    return state.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFF9E9E9E), size: 48),
            const SizedBox(height: 16),
            Text(
              'Search failed',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, color: Color(0xFF9E9E9E), size: 48),
                SizedBox(height: 16),
                Text(
                  'No results',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                ),
              ],
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

// ── Song Tile ─────────────────────────────────────────────────────────────────

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
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
                        placeholder: (_, __) => _ph,
                        errorWidget: (_, __, ___) => _ph,
                      )
                    : _ph,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 13,
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
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white54,
                  size: 20,
                ),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  HapticFeedback.lightImpact();
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
    color: const Color(0xFF14141F),
    child: const Icon(Icons.music_note, color: Colors.white24, size: 24),
  );

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:${m.padLeft(2, '0')}:$s' : '$m:$s';
  }
}

// ── Mini Bar ──────────────────────────────────────────────────────────────────

class _MiniBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(handlerProvider);

    return ValueListenableBuilder<Song?>(
      valueListenable: h.current,
      builder: (_, song, __) {
        if (song == null) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, _playerRoute());
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF14141F),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              4,
                            ), // Slightly rounded
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
                                    color: const Color(0xFF14141F),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white24,
                                      size: 20,
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
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  song.artist.isEmpty ? 'Unknown' : song.artist,
                                  style: const TextStyle(
                                    color: Color(0xFF9E9E9E),
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
                            builder: (_, playing, __) => IconButton(
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              padding: const EdgeInsets.all(10),
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                playing ? h.pause() : h.resume();
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              h.next();
                            },
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<Duration>(
                      valueListenable: h.position,
                      builder: (_, pos, __) => ValueListenableBuilder<Duration>(
                        valueListenable: h.duration,
                        builder: (_, dur, __) {
                          final progress = dur.inMilliseconds > 0
                              ? (pos.inMilliseconds / dur.inMilliseconds).clamp(
                                  0.0,
                                  1.0,
                                )
                              : 0.0;
                          return LinearProgressIndicator(
                            value: progress,
                            minHeight: 2.5,
                            backgroundColor: const Color(0xFF14141F),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
