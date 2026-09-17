// splash_screen.dart
// Animated splash screen that shows the logo when the app launches.

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // Animation controller runs for 1.2 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fade in from 0 to 1 opacity
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Scale from 0.8 to 1.0 (slight zoom in)
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Start the animation
    _controller.forward();

    // Navigate to search screen after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/search');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              'assets/logo 12 black and white.png',
              width: MediaQuery.of(context).size.width * 0.6,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
