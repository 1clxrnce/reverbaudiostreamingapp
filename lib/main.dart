// main.dart
// This is the first file that runs when the app opens.
// It sets up the app, starts background tasks, and launches the UI.

import 'package:flutter/material.dart'; // Flutter's UI toolkit — buttons, colors, text, etc.
import 'package:flutter/services.dart'; // lets us control the Android status bar appearance
import 'package:flutter_riverpod/flutter_riverpod.dart'; // state management — shares data across the app

import 'api/ytmusic_channel.dart'; // the bridge that talks to Android native code (Kotlin)
import 'audio/audio_handler.dart'; // the music player engine
import 'providers.dart'; // shared objects like the audio handler and search API
import 'screens/search_screen.dart'; // the first screen the user sees
import 'screens/splash_screen.dart'; // the splash screen with logo animation

// main() is the entry point — Dart runs this first when the app starts
Future<void> main() async {
  // Flutter needs this before you do anything before runApp()
  // It makes sure Flutter's engine is ready to use
  WidgetsFlutterBinding.ensureInitialized();

  // Style the Android system UI (status bar at the top, nav bar at the bottom)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors
          .transparent, // status bar has no background — blends into the app
      statusBarIconBrightness: Brightness
          .light, // clock/battery icons are white (visible on dark bg)
      systemNavigationBarColor: Color(
        0xFF0B0B0D,
      ), // bottom nav bar matches the app's near-black color
      systemNavigationBarIconBrightness:
          Brightness.light, // back/home icons are white too
    ),
  );

  // Start warming up the hidden WebView in the background RIGHT NOW
  // YouTube needs a WebView to generate a security token before it gives us a stream URL
  // This takes 2-5 seconds cold, so we start it before the user even searches anything
  // It runs in the background — the app doesn't wait for it to finish
  YtMusicChannel.instance.prewarm();

  // Create ONE music player that the whole app shares
  // Every screen (search, player) uses this exact same instance
  final handler = AudioHandler();

  // Start the app
  // ProviderScope is required by Riverpod — it wraps the whole app and makes
  // shared data available to every widget inside it
  runApp(
    ProviderScope(
      // overrides replaces the placeholder handlerProvider with our real handler
      // without this, any widget that asks for the handler would crash
      overrides: [handlerProvider.overrideWithValue(handler)],
      child: const App(), // start building the UI
    ),
  );
}

// App is the root widget — it sets the theme and decides what screen shows first
class App extends StatelessWidget {
  const App({
    super.key,
  }); // super.key is Flutter boilerplate for widget identity

  @override
  Widget build(BuildContext context) {
    // MaterialApp is Flutter's standard app wrapper
    // It sets up navigation, theme, and the home screen
    return MaterialApp(
      title: 'Reverb', // app name shown in Android's recent apps list
      debugShowCheckedModeBanner:
          false, // removes the red DEBUG banner in the top-right corner
      // theme defines how the whole app looks
      theme: ThemeData(
        brightness: Brightness.dark, // dark mode everywhere
        scaffoldBackgroundColor: const Color(
          0xFF0B0B0D,
        ), // near-black default background for every screen
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF0B0B0D), // cards and sheets also near-black
          primary: Colors.white, // primary accent color is white
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(
            0xFF0B0B0D,
          ), // top bar matches the background — no contrast line
          elevation: 0, // no shadow under the app bar
        ),
      ),

      // Start with splash screen, then navigate to search
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}
