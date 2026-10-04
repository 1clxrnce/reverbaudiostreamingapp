// player_screen.dart
// Dramatically redesigned music player with smooth animations and beautiful layout

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import '../api/ytmusic_api.dart';
import '../audio/audio_handler.dart';
import '../providers.dart';
import '../widgets/favorite_button.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  Color _bgColor = const Color(0xFF0A0A0F);
  String? _lastArtworkUrl;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation for overall screen
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Slide animation for content
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _extractColor(String artworkUrl) async {
    if (_lastArtworkUrl == artworkUrl) return;

    try {
      final imageProvider = CachedNetworkImageProvider(artworkUrl);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100),
        maximumColorCount: 10,
      );

      if (mounted) {
        final extractedColor =
            paletteGenerator.dominantColor?.color ??
            paletteGenerator.vibrantColor?.color ??
            const Color(0xFF0A0A0F);

        setState(() {
          _bgColor = Color.lerp(const Color(0xFF0A0A0F), extractedColor, 0.3)!;
          _lastArtworkUrl = artworkUrl;
        });
      }
    } catch (e) {
      debugPrint('[PlayerScreen] Color extraction failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = ref.watch(handlerProvider);

    return ValueListenableBuilder<Song?>(
      valueListenable: h.current,
      builder: (context, song, _) {
        if (song?.artwork != null) {
          _extractColor(song!.artwork!);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _bgColor,
                const Color(0xFF0A0A0F),
                const Color(0xFF000000),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildAppBar(context),
                      Expanded(child: _Body(h: h)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          Text(
            'Now Playing',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.h});
  final AudioHandler h;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Song?>(
      valueListenable: h.current,
      builder: (_, song, __) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildArtwork(song),
              const SizedBox(height: 32),
              _buildSongInfo(context, song),
              const SizedBox(height: 32),
              _SeekBar(h: h),
              const SizedBox(height: 24),
              _Controls(h: h),
              const SizedBox(height: 20),
              _VolumeBar(h: h),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(Song? song) {
    return Hero(
      tag: song != null ? 'artwork-${song.id}' : 'artwork-none',
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  0,
                ), // Sharp edges - no rounding
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 50,
                    spreadRadius: 5,
                    offset: const Offset(0, 25),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  0,
                ), // Sharp edges - no rounding
                child: song?.artwork != null
                    ? CachedNetworkImage(
                        imageUrl: song!.artwork!,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 400),
                        fadeInCurve: Curves.easeOut,
                        placeholder: (_, __) => _artPlaceholder,
                        errorWidget: (_, __, ___) => _artPlaceholder,
                      )
                    : _artPlaceholder,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, Song? song) {
    return Column(
      children: [
        Text(
          song?.title ?? 'No track playing',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.2,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          song == null || song.artist.isEmpty ? 'Unknown artist' : song.artist,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        if (song != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FavoriteButton(song: song, size: 28, color: Colors.white),
              const SizedBox(width: 16),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showSongOptions(context, song);
                },
              ),
            ],
          ),
      ],
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _OptionTile(
              icon: Icons.playlist_add_rounded,
              title: 'Add to Playlist',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement add to playlist
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add to Playlist - Coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _OptionTile(
              icon: Icons.info_outline_rounded,
              title: 'Song Details',
              onTap: () {
                Navigator.pop(context);
                _showSongDetails(context, song);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSongDetails(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Song Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Title', value: song.title),
            const SizedBox(height: 12),
            _DetailRow(label: 'Artist', value: song.artist),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Duration',
              value: song.duration != null
                  ? _formatDuration(song.duration!)
                  : 'Unknown',
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Video ID', value: song.id),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static final _artPlaceholder = Container(
    decoration: BoxDecoration(
      color: const Color(0xFF14141F),
      borderRadius: BorderRadius.circular(0), // Sharp edges - no rounding
    ),
    child: const Center(
      child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 100),
    ),
  );
}

// ── Seek Bar ──────────────────────────────────────────────────────────────────

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.h});
  final AudioHandler h;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:${m.padLeft(2, '0')}:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: h.position,
      builder: (_, pos, __) => ValueListenableBuilder<Duration>(
        valueListenable: h.duration,
        builder: (_, dur, __) {
          final max = dur.inMilliseconds.toDouble();
          final val = max > 0
              ? pos.inMilliseconds.toDouble().clamp(0.0, max)
              : 0.0;

          return Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 5,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                    elevation: 2,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.15),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.15),
                ),
                child: Slider(
                  value: val,
                  min: 0,
                  max: max > 0 ? max : 1,
                  onChanged: max > 0
                      ? (v) {
                          HapticFeedback.selectionClick();
                          h.seek(Duration(milliseconds: v.toInt()));
                        }
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(pos),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _fmt(dur),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Controls ──────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({required this.h});
  final AudioHandler h;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: h.playing,
      builder: (_, playing, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ControlButton(
            icon: Icons.skip_previous_rounded,
            size: 40,
            onPressed: () {
              HapticFeedback.mediumImpact();
              h.previous();
            },
          ),
          const SizedBox(width: 32),
          _PlayPauseButton(
            playing: playing,
            onTap: () {
              HapticFeedback.mediumImpact();
              playing ? h.pause() : h.resume();
            },
          ),
          const SizedBox(width: 32),
          _ControlButton(
            icon: Icons.skip_next_rounded,
            size: 40,
            onPressed: () {
              HapticFeedback.mediumImpact();
              h.next();
            },
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onPressed,
  });

  final IconData icon;
  final double size;
  final VoidCallback onPressed;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton>
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
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    widget.onPressed();
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, color: Colors.white, size: widget.size),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  const _PlayPauseButton({required this.playing, required this.onTap});
  final bool playing;
  final VoidCallback onTap;

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _ctrl.forward();
    widget.onTap();
    await _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Icon(
            widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.black,
            size: 42,
          ),
        ),
      ),
    );
  }
}

// ── Volume Bar ────────────────────────────────────────────────────────────────

class _VolumeBar extends StatelessWidget {
  const _VolumeBar({required this.h});
  final AudioHandler h;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: h.volume,
      builder: (_, vol, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(
              vol == 0 ? Icons.volume_off_rounded : Icons.volume_down_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 22,
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: Colors.white.withOpacity(0.8),
                  inactiveTrackColor: Colors.white.withOpacity(0.15),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.15),
                ),
                child: Slider(
                  value: vol,
                  min: 0,
                  max: 100,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    h.setVolume(v);
                  },
                ),
              ),
            ),
            Icon(
              Icons.volume_up_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Option Tile ───────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

// ── Detail Row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
