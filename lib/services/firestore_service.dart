// firestore_service.dart
// Handles all Firestore database operations - playlists, favorites, history

import 'package:cloud_firestore/cloud_firestore.dart';
import '../api/ytmusic_api.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Playlists ──────────────────────────────────────────────────────────

  // Get all playlists for a user (real-time stream)
  Stream<List<Playlist>> getUserPlaylists(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Playlist.fromFirestore(doc)).toList());
  }

  // Create a new playlist
  Future<void> createPlaylist(String userId, String name) async {
    await _db.collection('users').doc(userId).collection('playlists').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'songs': [],
    });
  }

  // Add song to playlist
  Future<void> addSongToPlaylist(
    String userId,
    String playlistId,
    Song song,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc(playlistId)
        .update({
      'songs': FieldValue.arrayUnion([song.toMap()])
    });
  }

  // Remove song from playlist
  Future<void> removeSongFromPlaylist(
    String userId,
    String playlistId,
    Song song,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc(playlistId)
        .update({
      'songs': FieldValue.arrayRemove([song.toMap()])
    });
  }

  // Delete playlist
  Future<void> deletePlaylist(String userId, String playlistId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc(playlistId)
        .delete();
  }

  // Rename playlist
  Future<void> renamePlaylist(
    String userId,
    String playlistId,
    String newName,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc(playlistId)
        .update({'name': newName});
  }

  // ── Favorites ──────────────────────────────────────────────────────────

  // Get all favorites for a user (real-time stream)
  Stream<List<Song>> getUserFavorites(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Song.fromMap(doc.data())).toList());
  }

  // Check if song is favorited
  Future<bool> isFavorite(String userId, String songId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(songId)
        .get();
    return doc.exists;
  }

  // Add song to favorites
  Future<void> addToFavorites(String userId, Song song) async {
    final data = song.toMap();
    data['addedAt'] = FieldValue.serverTimestamp();
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(song.id)
        .set(data);
  }

  // Remove song from favorites
  Future<void> removeFromFavorites(String userId, String songId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(songId)
        .delete();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String userId, Song song) async {
    final isFav = await isFavorite(userId, song.id);
    if (isFav) {
      await removeFromFavorites(userId, song.id);
    } else {
      await addToFavorites(userId, song);
    }
  }

  // ── Listen History ─────────────────────────────────────────────────────

  // Record a play event
  Future<void> recordPlay(String userId, Song song) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(song.id)
        .set({
      ...song.toMap(),
      'lastPlayedAt': FieldValue.serverTimestamp(),
      'playCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Get listen history (real-time stream)
  Stream<List<Song>> getUserHistory(String userId, {int limit = 50}) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('history')
        .orderBy('lastPlayedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Song.fromMap(doc.data())).toList());
  }
}

// ── Playlist Model ─────────────────────────────────────────────────────────

class Playlist {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.songs,
  });

  factory Playlist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Playlist(
      id: doc.id,
      name: data['name'] ?? 'Untitled',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      songs: (data['songs'] as List<dynamic>?)
              ?.map((s) => Song.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
