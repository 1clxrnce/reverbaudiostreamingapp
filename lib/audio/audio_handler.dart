// Audio handler — drives mpv's internal playlist.
//
// Exact same architecture as sunoh's SunohAudioHandler:
//
//   1. Songs are enqueued as placeholder Media('sunoh-song://<videoId>').
//      mpv never opens that URI — it fires Hook.load first.
//
//   2. The on_load hook intercepts every playlist entry:
//      - Reads stream-open-filename → decodes videoId
//      - Calls YtMusicChannel.resolve() (via the native MethodChannel)
//      - Writes the real googlevideo.com URL back to stream-open-filename
//      - Sets http-header-fields so the CDN accepts the signed URL
//      - Calls continueHook() so mpv proceeds
//
//   3. audio_session wires OS audio focus / headphone-unplug handling.

import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../api/ytmusic_api.dart';
import '../api/ytmusic_channel.dart';

const _kScheme = 'sunoh-song://';

class AudioHandler {
  AudioHandler() {
    _player = _buildPlayer();
    _player.stream.hook.listen(_onHook);
    _player.stream.playing.listen((v) => _playing.value = v);
    _player.stream.position.listen((v) => _position.value = v);
    _player.stream.duration.listen((v) => _duration.value = v);
    _player.stream.playlist.listen(_syncQueue);
    unawaited(_initSession());
  }

  late final Player _player;
  final _byId = <String, Song>{};

  final _current = ValueNotifier<Song?>(null);
  final _playing = ValueNotifier<bool>(false);
  final _position = ValueNotifier<Duration>(Duration.zero);
  final _duration = ValueNotifier<Duration>(Duration.zero);
  final _queue = ValueNotifier<List<Song>>(const []);
  final _volume = ValueNotifier<double>(100.0);

  ValueListenable<Song?> get current => _current;
  ValueListenable<bool> get playing => _playing;
  ValueListenable<Duration> get position => _position;
  ValueListenable<Duration> get duration => _duration;
  ValueListenable<List<Song>> get queue => _queue;
  ValueListenable<double> get volume => _volume;

  Player _buildPlayer() {
    final p = Player(
      configuration: const PlayerConfiguration(
        autoPlay: true,
        initialVolume: 100.0,
        logLevel: LogLevel.info,
      ),
    );

    p.registerHook(Hook.load, timeout: const Duration(seconds: 10));
    return p;
  }

  Future<void> _onHook(MpvHookEvent event) async {
    if (event.hook != Hook.load) {
      _player.continueHook(event.id);
      return;
    }
    try {
      // 1. Read which URI mpv is trying to open
      final raw = await _player.getRawProperty('stream-open-filename') ?? '';
      final id = _idFromUri(raw);
      if (id == null) return;

      final song = _byId[id];
      if (song == null) {
        debugPrint('[audio] hook: no song for id "$id"');
        return;
      }

      debugPrint('[audio] resolving ${song.id} "${song.title}"');

      final yt = await YtMusicChannel.instance.resolve(song.id);
      if (yt == null) {
        debugPrint('[audio] resolve returned null for ${song.id}');
        return;
      }

      await _applyHeaders(yt.headers);

      await _player.setRawProperty('stream-open-filename', yt.url);
      debugPrint('[audio] resolved → ${yt.url.substring(0, 60)}…');
    } catch (e, st) {
      debugPrint('[audio] hook error: $e\n$st');
    } finally {
      _player.continueHook(event.id);
    }
  }

  Future<void> _applyHeaders(Map<String, String>? headers) async {
    final value = (headers == null || headers.isEmpty)
        ? ''
        : headers.entries
              .where((e) => !e.key.contains(',') && !e.value.contains(','))
              .map((e) => '${e.key}: ${e.value}')
              .join(',');
    try {
      await _player.setRawProperty('http-header-fields', value);
    } catch (e) {
      debugPrint('[audio] http-header-fields error: $e');
    }
  }

  void _syncQueue(Playlist pl) {
    final songs = pl.items
        .map((m) => _byId[_idFromUri(m.uri)])
        .whereType<Song>()
        .toList();
    _queue.value = songs;
    final idx = pl.index;
    if (idx >= 0 && idx < songs.length) _current.value = songs[idx];
  }

  /// Start playing [songs] from [startIndex].
  /// Each song is queued as a placeholder — the on_load hook resolves it.
  Future<void> play(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    for (final s in songs) {
      _byId[s.id] = s;
    }
    _current.value = songs[startIndex.clamp(0, songs.length - 1)];
    await _player.openAll(
      songs.map((s) => Media(s.placeholderUri)).toList(),
      index: startIndex.clamp(0, songs.length - 1),
      play: true,
    );
  }

  Future<void> resume() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> next() => _player.next();
  Future<void> previous() => _player.previous();
  Future<void> seek(Duration pos) => _player.seek(pos);

  Future<void> setVolume(double vol) async {
    final clamped = vol.clamp(0.0, 100.0);
    _volume.value = clamped;
    await _player.setVolume(clamped);
  }

  // ── Audio session ─────────────────────────────────────────────────────

  Future<void> _initSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      session.interruptionEventStream.listen((e) {
        if (e.begin) {
          _player.pause();
        } else if (e.type != AudioInterruptionType.unknown)
          _player.play();
      });
      session.becomingNoisyEventStream.listen((_) => _player.pause());
    } catch (e) {
      debugPrint('[audio] session init failed (non-fatal): $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String? _idFromUri(String uri) {
    if (!uri.startsWith(_kScheme)) return null;
    final id = uri.substring(_kScheme.length);
    return id.isEmpty ? null : id;
  }

  void dispose() {
    _player.dispose();
    _current.dispose();
    _playing.dispose();
    _position.dispose();
    _duration.dispose();
    _queue.dispose();
    _volume.dispose();
  }
}
