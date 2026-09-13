import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/ytmusic_channel.dart';
import 'audio/audio_handler.dart';
import 'providers.dart';
import 'screens/search_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0B0D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Pre-warm the BotGuard WebView — same fire-and-forget call as sunoh.
  // Moves the ~2-5 s cold WebView spin-up off the user's first tap.
  YtMusicChannel.instance.prewarm();

  // Single AudioHandler instance shared across the whole app
  final handler = AudioHandler();

  runApp(
    ProviderScope(
      overrides: [handlerProvider.overrideWithValue(handler)],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0D),
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF0B0B0D),
          primary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0B0D),
          elevation: 0,
        ),
      ),
      home: const SearchScreen(),
    );
  }
}
