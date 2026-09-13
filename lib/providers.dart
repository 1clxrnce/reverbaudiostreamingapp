import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/ytmusic_api.dart';
import 'audio/audio_handler.dart';

// Dio — shared HTTP client for InnerTube search
final dioProvider = Provider<Dio>((ref) => Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 30),
)));

// YtMusicApi — InnerTube search (Dart-direct, no proxy)
final apiProvider = Provider<YtMusicApi>((ref) => YtMusicApi(ref.watch(dioProvider)));

// AudioHandler singleton — overridden in main()
final handlerProvider = Provider<AudioHandler>((ref) {
  throw UnimplementedError('handlerProvider must be overridden in main()');
});

// Search results — FutureProvider.family keyed on the query string
final searchProvider = FutureProvider.family<List<Song>, String>((ref, query) {
  if (query.isEmpty) return Future.value(const []);
  return ref.watch(apiProvider).searchSongs(query);
});
