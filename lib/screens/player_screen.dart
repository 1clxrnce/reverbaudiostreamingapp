// player_screen.dart
// Full-screen music player — artwork, title, seek bar, controls, volume.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ytmusic_api.dart';
import '../audio/audio_handler.dart';
import '../providers.dart';
import '../widgets/favorite_button.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(handlerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 72, // Taller AppBar for bigger logo
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/logo 12 black and white.png',
          height: 48,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          // Heart button for current song
          ValueListenableBuilder<Song?>(
            valueListenable: h.current,
            builder: (_, song, _) {
              if (song == null) return const SizedBox.shrink();
              return FavoriteButton(song: song);
            },
          ),
        ],
      ),
      body: SafeArea(child: _Body(h: h)),
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
      builder: (_, song, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // ── Album artwork with Hero + drop shadow ──────────────────
            // Hero tag matches search_screen so artwork morphs on open.
            Hero(
              tag: song != null ? 'artwork-${song.id}' : 'artwork-none',
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    // Layered shadows: a wide soft glow + a tighter darker one.
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: Offset(0, 16),
                      ),
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: song?.artwork != null
                        ? CachedNetworkImage(
                            imageUrl: song!.artwork!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => _artPh,
                            errorWidget: (_, _, _) => _artPh,
                          )
                        : _artPh,
                  ),
                ),
              ),
            ),

            const Spacer(flex: 1),

            // ── Song title and artist ──────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song?.title ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  song == null || song.artist.isEmpty
                      ? 'Unknown artist'
                      : song.artist,
                  style: const TextStyle(color: Colors.white54, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            const SizedBox(height: 28),
            _SeekBar(h: h),
            const SizedBox(height: 28),
            _Controls(h: h),
            const SizedBox(height: 32),
            _VolumeBar(h: h),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  static final _artPh = Container(
    color: const Color(0xFF1C1C1E),
    child: const Icon(Icons.music_note, color: Colors.white12, size: 72),
  );
}

// ── Seek bar ──────────────────────────────────────────────────────────────────

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
      builder: (_, pos, _) => ValueListenableBuilder<Duration>(
        valueListenable: h.duration,
        builder: (_, dur, _) {
          final max = dur.inMilliseconds.toDouble();
          final val = max > 0
              ? pos.inMilliseconds.toDouble().clamp(0.0, max)
              : 0.0;

          return Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.5,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white12,
                ),
                child: Slider(
                  value: val,
                  min: 0,
                  max: max > 0 ? max : 1,
                  onChanged: max > 0
                      ? (v) => h.seek(Duration(milliseconds: v.toInt()))
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(pos),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _fmt(dur),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
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

// ── Transport controls ────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({required this.h});
  final AudioHandler h;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: h.playing,
      builder: (_, playing, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded),
            color: Colors.white,
            iconSize: 44,
            onPressed: h.previous,
          ),

          // ── Animated play/pause button ──
          // _PlayButton handles the scale animation internally.
          _PlayButton(playing: playing, onTap: playing ? h.pause : h.resume),

          IconButton(
            icon: const Icon(Icons.skip_next_rounded),
            color: Colors.white,
            iconSize: 44,
            onPressed: h.next,
          ),
        ],
      ),
    );
  }
}

// Animated play/pause circle — scales down briefly on each tap for tactile feel.
class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.playing, required this.onTap});
  final bool playing;
  final VoidCallback onTap;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    // Scales from 1.0 down to 0.88 on press, then springs back.
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
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
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.black,
            size: 36,
          ),
        ),
      ),
    );
  }
}

// ── Volume bar ────────────────────────────────────────────────────────────────

class _VolumeBar extends StatelessWidget {
  const _VolumeBar({required this.h});
  final AudioHandler h;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: h.volume,
      builder: (_, vol, _) => Row(
        children: [
          Icon(
            vol == 0 ? Icons.volume_off_rounded : Icons.volume_down_rounded,
            color: Colors.white38,
            size: 20,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white54,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white54,
                overlayColor: Colors.white12,
              ),
              child: Slider(
                value: vol,
                min: 0,
                max: 100,
                onChanged: (v) => h.setVolume(v),
              ),
            ),
          ),
          const Icon(Icons.volume_up_rounded, color: Colors.white38, size: 20),
        ],
      ),
    );
  }
}
