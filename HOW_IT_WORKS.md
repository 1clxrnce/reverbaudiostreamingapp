# How Reverb Works — The Full Breakdown

This doc explains the logic and the actual code behind how the app finds music, gets a stream URL, and plays it. Written so anyone can follow along.

---

## The Big Picture

When you search for a song and tap it, three things happen in order:

```
1. Search      → ask YouTube Music for a list of songs matching your query
2. Resolve     → get the actual audio stream URL for the song you tapped
3. Stream      → feed that URL to the audio player and play it
```

Each of these is handled by a different part of the code. Let's go through them one by one.

---

## Part 1 — Search

### Where the code lives
`lib/api/ytmusic_api.dart` and `lib/api/ytmusic_renderers.dart`

### What actually happens

YouTube Music has a hidden internal API called **InnerTube**. It's what the YouTube Music website itself uses in your browser. It's not a public API — there's no documentation — but people have reverse engineered how it works.

The search endpoint is:
```
POST https://music.youtube.com/youtubei/v1/search
```

The app sends a request to this URL with a body that looks like this:

```dart
// from ytmusic_api.dart
final res = await _dio.post(
  '$_kBase/search?prettyPrint=false',
  data: {
    ...context,          // tells YouTube "I'm the YouTube Music web app"
    'query': query,      // your search text e.g. "drake god's plan"
    'params': _kSongsParam, // a filter that says "songs only, no videos"
  },
);
```

The `context` block is important. YouTube checks it to decide what format to respond in:

```dart
// this makes the request look like it came from the YouTube Music website
Map<String, dynamic> get _ctx => {
  'context': {
    'client': {
      'clientName': 'WEB_REMIX',   // WEB_REMIX = YouTube Music web client
      'clientVersion': '1.20260101.01.00',
      'hl': 'en',   // language: english
      'gl': 'US',   // region: US
    },
  },
};
```

The `_kSongsParam` is an opaque base64 string:
```dart
const _kSongsParam = 'EgWKAQIIAWoKEAoQAxAEEAkQBQ%3D%3D';
```
You don't need to understand what's inside it — it's just a filter code YouTube recognises that means "give me songs only." Without it you'd get a mix of videos, playlists, and albums too.

---

### Parsing the response

YouTube responds with a massive wall of deeply nested JSON. It's not clean or simple. The response has layers like:

```
contents
  → tabbedSearchResultsRenderer
    → tabs[0]
      → tabRenderer
        → content
          → sectionListRenderer
            → contents[]
              → musicShelfRenderer
                → contents[]
                  → musicResponsiveListItemRenderer   ← this is one song
```

The code in `ytmusic_renderers.dart` navigates all of this. The `_dig` helper is used constantly to safely walk down these nested paths without crashing:

```dart
// instead of writing body['contents']?['tabbedSearchResultsRenderer']?['tabs'] every time
// you just write:
_dig(body, ['contents', 'tabbedSearchResultsRenderer', 'tabs'])

// if any key is missing along the way it returns null instead of crashing
T? _dig<T>(dynamic root, List<String> path) {
  dynamic cur = root;
  for (final k in path) {
    if (cur is! Map) return null;  // stop if we hit something that isn't a map
    cur = cur[k];
  }
  return cur is T ? cur : null;
}
```

Once it finds a song item, it extracts the info:

```dart
Song? _parseItem(Map<String, dynamic> m) {
  final id    = _extractId(m);     // the YouTube video ID e.g. "dQw4w9WgXcQ"
  final title = _flexText(m, 0);   // column 0 = song title
  final artist= _flexText(m, 1);   // column 1 = artist name
  // thumbnail url, fixed to high resolution (explained below)
  // duration parsed from "3:45" format to seconds
}
```

The result is a clean `Song` object:

```dart
class Song {
  final String id;          // "dQw4w9WgXcQ"
  final String title;       // "Never Gonna Give You Up"
  final String artist;      // "Rick Astley"
  final String? artwork;    // "https://lh3.googleusercontent.com/..."
  final int? durationSec;   // 213
}
```

---

### The artwork fix

YouTube thumbnail URLs look like this:
```
https://lh3.googleusercontent.com/abc123=w226-h226-l90-rj
```

That `=w226-h226` part is the size. 226×226 pixels is tiny — that's why the album art was blurry on the full player screen. The fix is simple: replace the size with a bigger one:

```dart
String _hqThumb(String url) {
  final sizeToken = RegExp(r'=w\d+-h\d+(-[^?]*)?$');
  if (sizeToken.hasMatch(url)) {
    return url.replaceFirst(sizeToken, '=w576-h576'); // 226 → 576
  }
  return url;
}
```

Same image, same CDN, just a bigger size. No extra cost.

---

## Part 2 — Resolving the Stream URL

### Where the code lives
`lib/api/ytmusic_channel.dart` (Dart side)
`android/app/src/main/kotlin/.../ytmusic/YtMusicBridge.kt` (Android side)

### The problem

Having a video ID like `dQw4w9WgXcQ` doesn't mean you can play it. You need a direct audio file URL — something like:

```
https://rr1---sn-xxx.googlevideo.com/videoplayback?expire=...&sig=...
```

YouTube generates these URLs on demand and they expire after a few hours. To get one, you have to talk to YouTube's player API. But here's the catch:

**YouTube protects this with BotGuard.**

BotGuard is YouTube's anti-bot system. To prove you're a real user and not a bot, you need to generate a **PO Token** (Proof of Origin Token). YouTube only accepts tokens generated inside a real browser — it runs checks that a plain HTTP request can't pass.

Dart (Flutter) runs on its own runtime, not in a browser. So it can't generate a valid PO Token by itself.

### The solution — a hidden WebView

Android can run a **WebView** — basically an invisible mini browser embedded inside the app. The Kotlin code creates one, loads a special HTML/JavaScript page into it, and lets it run the same BotGuard JavaScript that YouTube runs in your real browser. The WebView generates a valid PO Token.

Then Kotlin uses that token to call YouTube's player API and gets back the real stream URL.

The Dart side of this bridge looks like:

```dart
// lib/api/ytmusic_channel.dart

// This is the "pipe" between Dart and Kotlin
// The string must match exactly what Kotlin registered on its side
static const _ch = MethodChannel('codes.afk.sunoh/ytmusic');

// Send a video ID to Kotlin, get back the stream URL
Future<YtMusicStream?> resolve(String videoId) async {
  final res = await _ch.invokeMethod<Map<Object?, Object?>>(
    'resolve',                              // method name Kotlin listens for
    {'videoId': videoId, 'quality': 'auto'} // data we send
  );
  return YtMusicStream.fromMap(res); // convert the result into a usable object
}
```

`MethodChannel` is Flutter's built-in system for Dart to talk to native Android/iOS code. You give it a channel name (like a phone number), call a method, and wait for the response.

The result comes back as a `YtMusicStream`:

```dart
class YtMusicStream {
  final String url;                  // the real googlevideo.com URL
  final Map<String, String> headers; // HTTP headers YouTube requires
  final DateTime? expiresAt;         // when the URL stops working
}
```

### Pre-warming

The WebView takes 2–5 seconds to cold-start. If you waited for it when you tapped your first song, there'd be a noticeable delay. So the app starts it early:

```dart
// main.dart — runs at startup, before you even open the app
YtMusicChannel.instance.prewarm();
```

This fires off and runs in the background. By the time you search for something and tap a song, the WebView is already warm and the resolve only takes about 1 second.

---

## Part 3 — Playing the Stream

### Where the code lives
`lib/audio/audio_handler.dart`

### The player

Under the hood, the app uses **mpv** as its audio engine (via the `mpv_audio_kit` Flutter package). mpv is the same engine used in desktop players like VLC. It's powerful — it handles gapless playback, HTTP streams, custom headers, and playlists natively.

### The placeholder trick

Here's the clever part. When you tap a song from the search results, the app doesn't wait for Kotlin to resolve the stream URL before starting playback. If it did, you'd sit staring at a loading spinner every time.

Instead, it uses placeholder URLs:

```dart
// every Song has a fake URL like "sunoh-song://dQw4w9WgXcQ"
String get placeholderUri => 'sunoh-song://$id';
```

The whole playlist is loaded into mpv immediately using these fake URLs:

```dart
Future<void> play(List<Song> songs, int startIndex) async {
  // store all songs in a map so we can look them up by ID later
  for (final s in songs) {
    _byId[s.id] = s;
  }
  // load the entire playlist at once using placeholder URLs
  await _player.openAll(
    songs.map((s) => Media(s.placeholderUri)).toList(),
    index: startIndex,
    play: true,
  );
}
```

mpv tries to open `sunoh-song://dQw4w9WgXcQ`. It doesn't know what that is. Normally it would error. But we registered a **hook** — an interceptor that fires before mpv opens any URL:

```dart
// registered when the player is created
p.registerHook(Hook.load, timeout: const Duration(seconds: 10));
```

### The hook — the heart of the whole thing

When mpv hits a `sunoh-song://` URL, it pauses and fires the hook event. The app catches it:

```dart
Future<void> _onHook(MpvHookEvent event) async {
  // 1. read which URL mpv is about to open
  final raw = await _player.getRawProperty('stream-open-filename');
  // raw = "sunoh-song://dQw4w9WgXcQ"

  // 2. strip off "sunoh-song://" to get just the video ID
  final id = _idFromUri(raw); // "dQw4w9WgXcQ"

  // 3. look up the Song object from our map
  final song = _byId[id];

  // 4. call Kotlin to resolve the real stream URL
  final yt = await YtMusicChannel.instance.resolve(song.id);
  // yt.url = "https://rr1---sn-xxx.googlevideo.com/videoplayback?..."

  // 5. set the HTTP headers YouTube's CDN requires
  await _applyHeaders(yt.headers);

  // 6. replace the fake URL with the real one
  await _player.setRawProperty('stream-open-filename', yt.url);

  // 7. tell mpv to continue — it now opens the real URL
  _player.continueHook(event.id);
}
```

Steps 1–6 happen invisibly. mpv just thinks it opened a normal URL. It has no idea a swap happened.

### Headers

YouTube signs its stream URLs for specific clients. The CDN (content delivery network) validates the `User-Agent` and other headers before serving the audio. If you just open the URL without headers, YouTube returns a 403 (forbidden) error.

The headers come back from Kotlin along with the URL and get written to mpv:

```dart
Future<void> _applyHeaders(Map<String, String>? headers) async {
  // mpv expects headers as a comma-separated string: "Key: Value,Key2: Value2"
  final value = headers!.entries
    .map((e) => '${e.key}: ${e.value}')
    .join(',');

  await _player.setRawProperty('http-header-fields', value);
}
```

---

## Part 4 — Keeping the UI in Sync

### ValueNotifier — how the UI stays up to date

The audio handler exposes its state through `ValueNotifier` objects:

```dart
final _current  = ValueNotifier<Song?>(null);   // what's playing now
final _playing  = ValueNotifier<bool>(false);   // is it playing or paused
final _position = ValueNotifier<Duration>(...); // current time e.g. 1:23
final _duration = ValueNotifier<Duration>(...); // total length e.g. 3:45
final _volume   = ValueNotifier<double>(100.0); // 0 to 100
```

These update in real time as mpv's state changes:

```dart
_player.stream.playing.listen((v)  => _playing.value = v);
_player.stream.position.listen((v) => _position.value = v);
_player.stream.duration.listen((v) => _duration.value = v);
```

In the UI, widgets wrap themselves in `ValueListenableBuilder` to react to these changes automatically:

```dart
// from player_screen.dart — the seek bar
ValueListenableBuilder<Duration>(
  valueListenable: h.position,   // watches position
  builder: (_, pos, _) {
    // this rebuilds every time position changes
    // so the slider moves smoothly as the song plays
  },
)
```

No manual refreshing. No `setState` calls on a timer. The moment mpv says the position changed, the slider moves.

---

## The Full Flow — Tap to Sound

```
You tap "Never Gonna Give You Up" in the search list
                    ↓
SearchScreen calls audio_handler.play(songs, index: 2)
                    ↓
AudioHandler stores all songs in _byId map
AudioHandler loads entire playlist with fake sunoh-song:// URLs
                    ↓
mpv starts, tries to open sunoh-song://dQw4w9WgXcQ
                    ↓
mpv fires on_load hook and PAUSES
                    ↓
_onHook() reads "sunoh-song://dQw4w9WgXcQ"
Strips scheme → videoId = "dQw4w9WgXcQ"
Looks up Song in _byId
                    ↓
YtMusicChannel.resolve("dQw4w9WgXcQ") called
Dart sends message to Kotlin via MethodChannel
                    ↓
Kotlin generates PO Token in hidden WebView
Kotlin calls YouTube player API with token
YouTube returns real stream URL + headers
Kotlin sends back to Dart
                    ↓
_onHook() writes real URL into stream-open-filename
_onHook() writes headers into http-header-fields
_onHook() calls continueHook() → mpv resumes
                    ↓
mpv opens the real googlevideo.com URL with correct headers
mpv starts buffering and playing the audio stream
                    ↓
_playing notifier → play button switches to pause icon
_position notifier → seek bar starts moving
_current notifier → artwork and title appear on screen
                    ↓
You hear the song
```

---

## Summary

| Step | File | What it does |
|---|---|---|
| Search | `ytmusic_api.dart` | POSTs to InnerTube, gets song list |
| Parse | `ytmusic_renderers.dart` | Turns messy JSON into clean Song objects |
| Bridge | `ytmusic_channel.dart` | Dart ↔ Kotlin communication |
| Token | `YtMusicBridge.kt` | WebView generates PO Token, resolves stream URL |
| Hook | `audio_handler.dart` | Intercepts mpv, swaps fake URL for real one |
| UI sync | `audio_handler.dart` | ValueNotifiers keep all screens up to date |
| Player UI | `player_screen.dart` | Shows artwork, seek bar, controls, volume |
| Search UI | `search_screen.dart` | Search bar, results list, mini now-playing bar |
