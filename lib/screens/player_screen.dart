import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ytmusic_api.dart';
import '../audio/audio_handler.dart';
import '../providers.dart';

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
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
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

            // ── Artwork ───────────────────────────────────────────────
            AspectRatio(
              aspectRatio: 1,
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

            const Spacer(flex: 1),

            // ── Title / artist ────────────────────────────────────────
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

            // ── Seek bar ──────────────────────────────────────────────
            _SeekBar(h: h),

            const SizedBox(height: 28),

            // ── Transport controls ────────────────────────────────────
            _Controls(h: h),

            const SizedBox(height: 32),

            // ── Volume slider ─────────────────────────────────────────
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
          // Previous
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded),
            color: Colors.white,
            iconSize: 44,
            onPressed: h.previous,
          ),

          // Play / pause — big white circle
          GestureDetector(
            onTap: playing ? h.pause : h.resume,
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 36,
              ),
            ),
          ),

          // Next
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
