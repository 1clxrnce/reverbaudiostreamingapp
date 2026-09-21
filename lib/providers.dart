// providers.dart
// Think of this file as the app's shared storage.
// It creates objects (HTTP client, search API, audio player) that every screen can use.
// Riverpod providers are how those objects get shared — any widget can ask for them.

import 'package:dio/dio.dart'; // Dio is the HTTP client used to make web requests
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod is the state management library

import 'api/ytmusic_api.dart'; // the YouTube Music search API class
import 'audio/audio_handler.dart'; // the music player class
import 'services/auth_service.dart'; // Firebase authentication
import 'services/firestore_service.dart'; // Firestore database

// Export Playlist so other files can use it
export 'services/firestore_service.dart' show Playlist;

// ── dioProvider ──────────────────────────────────────────────────────────────
// Creates ONE shared HTTP client for the whole app.
// Any code that needs to make a web request uses this same client.
// Setting timeouts here means we never hang forever waiting for YouTube to respond.
final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(
        seconds: 15,
      ), // give up trying to connect after 15 seconds
      receiveTimeout: const Duration(
        seconds: 30,
      ), // give up waiting for the response after 30 seconds
    ),
  ),
);

// ── apiProvider ──────────────────────────────────────────────────────────────
// Creates ONE shared YouTube Music search API object.
// It takes the HTTP client from dioProvider and passes it in.
// Any widget that needs to search for songs uses this.
final apiProvider = Provider<YtMusicApi>(
  (ref) => YtMusicApi(
    ref.watch(dioProvider),
  ), // ref.watch(dioProvider) gets the Dio instance above
);

// ── handlerProvider ──────────────────────────────────────────────────────────
// This is a PLACEHOLDER — it throws an error on purpose if nothing overrides it.
// The real AudioHandler is created in main.dart and injected via overrideWithValue().
// This pattern ensures there's always exactly one audio player for the whole app.
final handlerProvider = Provider<AudioHandler>((ref) {
  // if someone forgets to override this in main(), they get a clear error message
  throw UnimplementedError('handlerProvider must be overridden in main()');
});

// ── searchProvider ────────────────────────────────────────────────────────────
// A search provider that takes a query string and returns a list of songs.
// FutureProvider handles loading/error/done states automatically.
// .family means each unique query string gets its own cached result.
// So searching "drake" and "rihanna" both have separate results stored.
final searchProvider = FutureProvider.family<List<Song>, String>((ref, query) {
  // if the search box is empty, return an empty list immediately — no need to call YouTube
  if (query.isEmpty) return Future.value(const []);

  // otherwise, use the search API to ask YouTube Music for songs matching the query
  // ref.watch(apiProvider) gets the YtMusicApi instance created above
  return ref.watch(apiProvider).searchSongs(query);
});

// ── authServiceProvider ───────────────────────────────────────────────────────
// Provides the authentication service for sign in/sign up/sign out
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── firestoreServiceProvider ──────────────────────────────────────────────────
// Provides the Firestore service for playlists, favorites, history
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

// ── authStateProvider ─────────────────────────────────────────────────────────
// Stream of current user — rebuilds UI when user signs in/out
final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── userPlaylistsProvider ─────────────────────────────────────────────────────
// Stream of user's playlists — updates in real-time when playlists change
final userPlaylistsProvider = StreamProvider((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(<Playlist>[]);

  return ref.watch(firestoreServiceProvider).getUserPlaylists(user.uid);
});

// ── userFavoritesProvider ─────────────────────────────────────────────────────
// Stream of user's favorite songs — updates in real-time
final userFavoritesProvider = StreamProvider((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(<Song>[]);

  return ref.watch(firestoreServiceProvider).getUserFavorites(user.uid);
});

// ── isFavoriteProvider ────────────────────────────────────────────────────────
// Check if a specific song is favorited
final isFavoriteProvider = FutureProvider.family<bool, String>((
  ref,
  songId,
) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;

  return ref.watch(firestoreServiceProvider).isFavorite(user.uid, songId);
});
