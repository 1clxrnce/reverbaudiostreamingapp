// audio_handler.dart
// This is the music player engine — the most important file in the app.
// It controls everything: play, pause, skip, seek, volume.
//
// The clever part is HOW it streams music:
//   1. Songs get queued with FAKE placeholder URLs like "sunoh-song://dQw4w9WgXcQ"
//   2. mpv tries to open that fake URL
//   3. Before mpv opens it, it fires a "hook" (a pause-and-ask event)
//   4. We intercept the hook, call Kotlin to get the REAL YouTube stream URL
//   5. We swap the fake URL for the real one
//   6. mpv continues and plays the real stream
//
// This means the whole playlist queues instantly — mpv only fetches a real URL
// when it's actually about to play that song.

import 'dart:async'; // for unawaited() — fire-and-forget async calls

import 'package:audio_session/audio_session.dart'; // handles headphone unplug + phone call interruptions
import 'package:flutter/foundation.dart'; // debugPrint for logging
import 'package:mpv_audio_kit/mpv_audio_kit.dart'; // mpv audio player — the actual playback engine

import '../api/ytmusic_api.dart'; // Song class
import '../api/ytmusic_channel.dart'; // YtMusicChannel — the bridge to Kotlin for stream URLs

// The fake URL scheme we use as a placeholder
// Every song gets a URL like "sunoh-song://dQw4w9WgXcQ" until the real one is fetched
const _kScheme = 'sunoh-song://';

class AudioHandler {
  // Constructor — runs when AudioHandler() is called in main.dart
  AudioHandler() {
    _player = _buildPlayer(); // create and configure the mpv player

    // listen for hook events — fires when mpv is about to open a URL
    // this is where we intercept and swap fake URLs for real ones
    _player.stream.hook.listen(_onHook);

    // mirror mpv's internal state into our ValueNotifiers
    // when mpv says "now playing", _playing.value becomes true — and the UI updates automatically
    _player.stream.playing.listen((v) => _playing.value = v);

    // when mpv's playback position changes (e.g. every second), update _position
    // this drives the seek bar moving in real time
    _player.stream.position.listen((v) => _position.value = v);

    // when mpv knows the total duration of the song, update _duration
    _player.stream.duration.listen((v) => _duration.value = v);

    // when mpv's playlist changes (new song, skip), update the queue and current song
    _player.stream.playlist.listen(_syncQueue);

    // start the audio session setup in the background (headphone unplug, phone calls)
    // unawaited = fire and forget — don't wait for it, just let it run
    unawaited(_initSession());
  }

  late final Player
  _player; // the mpv player instance — created in _buildPlayer()

  // A dictionary that maps video IDs to Song objects
  // e.g. {"dQw4w9WgXcQ": Song(id:"dQw4w9WgXcQ", title:"Never Gonna...")}
  // Used in the hook to look up song info by ID when mpv fires
  final _byId = <String, Song>{};

  // ── ValueNotifiers — observable state ────────────────────────────────────────
  // ValueNotifier is like a variable that screams "I CHANGED!" to any widget watching it
  // When the value changes, any ValueListenableBuilder in the UI automatically rebuilds

  final _current = ValueNotifier<Song?>(
    null,
  ); // which song is playing right now
  final _playing = ValueNotifier<bool>(
    false,
  ); // is it currently playing (true) or paused (false)
  final _position = ValueNotifier<Duration>(
    Duration.zero,
  ); // current playback time e.g. 1:23
  final _duration = ValueNotifier<Duration>(
    Duration.zero,
  ); // total song length e.g. 3:45
  final _queue = ValueNotifier<List<Song>>(
    const [],
  ); // all songs in the current playlist
  final _volume = ValueNotifier<double>(100.0); // volume from 0 to 100

  // ── Public read-only getters ─────────────────────────────────────────────────
  // Other parts of the app can WATCH these but can't write to them directly
  // This keeps the audio handler in full control of its own state

  ValueListenable<Song?> get current => _current;
  ValueListenable<bool> get playing => _playing;
  ValueListenable<Duration> get position => _position;
  ValueListenable<Duration> get duration => _duration;
  ValueListenable<List<Song>> get queue => _queue;
  ValueListenable<double> get volume => _volume;

  // ── Player setup ──────────────────────────────────────────────────────────────

  // Creates and configures the mpv player
  Player _buildPlayer() {
    final p = Player(
      configuration: const PlayerConfiguration(
        autoPlay: true, // start playing as soon as a song is loaded
        initialVolume: 100.0, // start at full volume
        logLevel: LogLevel.info, // log info messages (useful for debugging)
      ),
    );

    // Register the on_load hook — this is what lets us intercept URL loading
    // Without this, mpv would try to open the fake sunoh-song:// URL directly and fail
    // timeout: if we don't respond within 10 seconds, mpv gives up waiting
    p.registerHook(Hook.load, timeout: const Duration(seconds: 10));

    return p;
  }

  // ── The hook — the heart of the whole streaming system ───────────────────────
  //
  // Called every time mpv is about to open a URL.
  // For fake sunoh-song:// URLs, we fetch the real URL and swap it in.
  // For any other URL (e.g. already a real URL), we just let mpv continue.

  Future<void> _onHook(MpvHookEvent event) async {
    // if this hook isn't a "load" event, we don't care — just let mpv continue
    if (event.hook != Hook.load) {
      _player.continueHook(event.id); // tell mpv: "ok, nothing to do, carry on"
      return;
    }

    try {
      // ── Step 1: read which URL mpv is trying to open ──
      // 'stream-open-filename' is mpv's property for the current URL being opened
      final raw = await _player.getRawProperty('stream-open-filename') ?? '';
      // raw = "sunoh-song://dQw4w9WgXcQ"

      // strip "sunoh-song://" off the front to get just the video ID
      // if it doesn't start with our scheme, _idFromUri returns null (it's not our fake URL)
      final id = _idFromUri(raw);
      if (id == null) {
        return; // not our URL — nothing to do (continueHook fires in finally)
      }

      // ── Step 2: look up the Song object ──
      // we stored all songs in _byId when play() was called
      final song = _byId[id];
      if (song == null) {
        // shouldn't happen, but log it if it does
        debugPrint('[audio] hook: no song for id "$id"');
        return;
      }

      debugPrint('[audio] resolving ${song.id} "${song.title}"');

      // ── Step 3: call Kotlin to get the real stream URL ──
      // This is the async call to the hidden WebView that generates the PO Token
      // and gets the real googlevideo.com URL back from YouTube
      final yt = await YtMusicChannel.instance.resolve(song.id);
      if (yt == null) {
        // Kotlin failed to resolve — log it, mpv will handle the error
        debugPrint('[audio] resolve returned null for ${song.id}');
        return;
      }

      // ── Step 4: set the HTTP headers ──
      // YouTube's CDN (the server that delivers the audio) checks these headers
      // If they're wrong or missing, the server returns a 403 Forbidden error
      // Must be set BEFORE changing the URL
      await _applyHeaders(yt.headers);

      // ── Step 5: swap the fake URL for the real one ──
      // This is the key step — overwrite stream-open-filename with the real URL
      // When mpv continues, it will open this real URL instead of the fake one
      await _player.setRawProperty('stream-open-filename', yt.url);
      debugPrint('[audio] resolved → ${yt.url.substring(0, 60)}…');
    } catch (e, st) {
      // log any unexpected errors — mpv will still get continueHook in the finally block
      debugPrint('[audio] hook error: $e\n$st');
    } finally {
      // ALWAYS release the hook so mpv doesn't stall forever waiting for us
      // 'finally' runs whether the try block succeeded or threw an error
      _player.continueHook(event.id);
    }
  }

  // Formats and writes the HTTP headers to mpv
  // mpv expects them as a single comma-separated string: "Key: Value,Key2: Value2"
  Future<void> _applyHeaders(Map<String, String>? headers) async {
    final value = (headers == null || headers.isEmpty)
        ? '' // if no headers, set empty string (clears any previous track's headers)
        : headers.entries
              // filter out any header where key or value contains a comma
              // (commas are the separator, so they'd break the format)
              .where((e) => !e.key.contains(',') && !e.value.contains(','))
              // format each header as "Key: Value"
              .map((e) => '${e.key}: ${e.value}')
              // join them all with commas → "Key1: Val1,Key2: Val2"
              .join(',');

    try {
      // write the formatted headers string to mpv's http-header-fields property
      await _player.setRawProperty('http-header-fields', value);
    } catch (e) {
      debugPrint('[audio] http-header-fields error: $e');
    }
  }

  // ── Queue sync ────────────────────────────────────────────────────────────────

  // Called whenever mpv's internal playlist changes (new song loaded, song skipped, etc.)
  // Rebuilds our queue list and updates the "current song" display
  void _syncQueue(Playlist pl) {
    // map each mpv playlist item back to a Song using its fake URI to get the ID
    final songs = pl.items
        .map((m) => _byId[_idFromUri(m.uri)]) // look up Song by videoId
        .whereType<Song>() // filter out any nulls
        .toList();

    _queue.value = songs; // update the queue (in case any widget is showing it)

    // update the current song based on which index is active in mpv's playlist
    final idx = pl.index;
    if (idx >= 0 && idx < songs.length) _current.value = songs[idx];
  }

  // ── Public playback controls ──────────────────────────────────────────────────

  // Start playing a list of songs from a specific index
  // Called when the user taps a song in the search results
  Future<void> play(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return; // nothing to play

    // store ALL songs in the lookup map so the hook can find them later by ID
    for (final s in songs) {
      _byId[s.id] = s;
    }

    // immediately update the "current song" display — UI shows the song name right away
    // even before mpv has started loading (clamp keeps the index in bounds)
    _current.value = songs[startIndex.clamp(0, songs.length - 1)];

    // load the ENTIRE playlist into mpv at once using placeholder URLs
    // mpv will start with the song at startIndex and play through the list
    // each song's real URL gets fetched via the hook when it's actually needed
    await _player.openAll(
      songs
          .map((s) => Media(s.placeholderUri))
          .toList(), // "sunoh-song://..." for each song
      index: startIndex.clamp(0, songs.length - 1), // which song to start with
      play: true, // start playing immediately
    );
  }

  Future<void> resume() => _player.play(); // resume playback
  Future<void> pause() => _player.pause(); // pause playback
  Future<void> next() => _player.next(); // skip to next song
  Future<void> previous() => _player.previous(); // go back to previous song
  Future<void> seek(Duration pos) =>
      _player.seek(pos); // jump to a position in the song

  // Set the volume (0 = mute, 100 = full)
  Future<void> setVolume(double vol) async {
    final clamped = vol.clamp(
      0.0,
      100.0,
    ); // make sure value stays between 0 and 100
    _volume.value = clamped; // update the notifier so the UI slider moves
    await _player.setVolume(clamped); // actually change the volume in mpv
  }

  // ── Audio session ─────────────────────────────────────────────────────────────

  // Sets up the OS audio session so Android treats this like a music app
  // Handles things like: phone calls coming in, headphones being unplugged
  Future<void> _initSession() async {
    try {
      final session = await AudioSession.instance;

      // tell Android: "this is a music app" — affects how Android routes audio
      // and manages audio focus with other apps
      await session.configure(const AudioSessionConfiguration.music());

      // listen for interruptions (e.g. a phone call comes in)
      session.interruptionEventStream.listen((e) {
        if (e.begin) {
          _player.pause(); // call started — pause the music
        } else if (e.type != AudioInterruptionType.unknown) {
          _player
              .play(); // call ended — resume (unless it was an unknown interruption)
        }
      });

      // "becoming noisy" = headphones were unplugged
      // auto-pause so music doesn't blast from the speaker unexpectedly
      session.becomingNoisyEventStream.listen((_) => _player.pause());
    } catch (e) {
      // if session setup fails, it's not fatal — playback still works
      // just without the fancy OS integration
      debugPrint('[audio] session init failed (non-fatal): $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  // Strips "sunoh-song://" off the front of a URI to get the video ID
  // e.g. "sunoh-song://dQw4w9WgXcQ" → "dQw4w9WgXcQ"
  // Returns null if the URI doesn't start with our fake scheme
  // (meaning it's already a real URL — we shouldn't touch it)
  String? _idFromUri(String uri) {
    if (!uri.startsWith(_kScheme)) return null; // not our fake URL
    final id = uri.substring(_kScheme.length); // strip the prefix
    return id.isEmpty
        ? null
        : id; // return null if nothing was after the prefix
  }

  // Clean up all resources when the handler is no longer needed
  // Prevents memory leaks — always dispose what you create
  void dispose() {
    _player.dispose(); // shut down mpv
    _current.dispose(); // release the ValueNotifier listeners
    _playing.dispose();
    _position.dispose();
    _duration.dispose();
    _queue.dispose();
    _volume.dispose();
  }
}
