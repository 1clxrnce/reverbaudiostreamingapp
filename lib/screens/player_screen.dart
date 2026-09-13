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
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing', style: TextStyle(color: Colors.white70, fontSize: 14)),
        centerTitle: true,
      ),
      body: SafeArea(child: _Body(h: h)),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.h});
  final AudioHandler h;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Song?>(
      valueListenable: h.current,
      builder: (_, song, __) => Column(
        children: [
          const SizedBox(height: 20),

          // ── Artwork ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: song?.artwork != null
                    ? CachedNetworkImage(imageUrl: song!.artwork!, fit: BoxFit.cover,
                        placeholder: (_, __) => _artPh, errorWidget: (_, __, ___) => _artPh)
                    : _artPh,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Title / artist ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(song?.title ?? '—',
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(song == null || song.artist.isEmpty ? 'Unknown artist' : song.artist,
                  style: const TextStyle(color: Colors.white54, fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Seek bar ──────────────────────────────────────────────────
          _SeekBar(h: h),
          const SizedBox(height: 16),

          // ── Controls ──────────────────────────────────────────────────
          _Controls(h: h),
        ],
      ),
    );
  }

  static final _artPh = Container(color: const Color(0xFF1C1C1E),
      child: const Icon(Icons.music_note, color: Colors.white12, size: 72));
}

// ── Seek bar ──────────────────────────────────────────────────────────────────

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.h});
  final AudioHandler h;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:${m.padLeft(2,'0')}:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: h.position,
      builder: (_, pos, __) => ValueListenableBuilder<Duration>(
        valueListenable: h.duration,
        builder: (_, dur, __) {
          final max = dur.inMilliseconds.toDouble();
          final val = max > 0 ? pos.inMilliseconds.toDouble().clamp(0.0, max) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_fmt(pos), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(_fmt(dur), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
              ),
            ]),
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
      builder: (_, playing, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.skip_previous_rounded), color: Colors.white, iconSize: 44, onPressed: h.previous),
          Container(
            width: 70, height: 70,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black),
              iconSize: 38,
              onPressed: playing ? h.pause : h.resume,
            ),
          ),
          IconButton(icon: const Icon(Icons.skip_next_rounded), color: Colors.white, iconSize: 44, onPressed: h.next),
        ],
      ),
    );
  }
}
