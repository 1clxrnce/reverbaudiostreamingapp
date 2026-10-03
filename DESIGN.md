# Reverb - Design Direction

## Identity
A lightweight, focused music player for Android. Clean and straightforward, prioritizing playback functionality over visual complexity.

**Brand Name**: REVERB (official name, all caps)  
**Logo**: `assets/logo 12 black and white.png` (final)

## Personality
- **Functional**: Every element serves the music playback experience
- **Uncluttered**: Minimal decoration, maximum usability
- **Smooth & Fast**: Responsive interactions, no lag, immediate feedback
- **Adaptive**: Player screen blends with album artwork colors

## Palette (Dark + White + Adaptive)
**Purpose**: White provides maximum clarity and contrast. Player screen adapts to artwork for visual connection to the music.

### Static Screens (Search, Splash)
- **Background Dark**: `#0A0A0F` (near-black with blue undertone)
- **Surface Dark**: `#14141F` (slightly lighter cards/containers)
- **Primary White**: `#FFFFFF` (pure white for active states, controls)
- **Text Primary**: `#FFFFFF` (pure white for titles)
- **Text Secondary**: `#B4B4C8` (light gray-purple for metadata)
- **Text Dim**: `#6E6E7E` (dim gray for timestamps)

### Dynamic Player Screen
- **Background**: Extracts dominant color from album artwork
- **Blend**: 25% artwork color + 75% dark base
- **Gradient**: Artwork color at top → dark at bottom
- **Transition**: 800ms smooth fade between songs
- **Fallback**: Dark `#0A0A0F` if extraction fails

**Antislop compliance**: 
- White controls provide clarity (not decoration)
- Dynamic background serves a purpose: visual connection to artwork (C-1)
- Gradient is functional: maintains readability while adding immersion

## Typography
- System default font for maximum readability
- Clear hierarchy: song titles prominent, metadata secondary
- Consistent sizing across screens

## Mood
Smooth, fast, focused. White controls provide instant visual clarity. Player screen creates emotional connection by blending with artwork colors. The app feels clean, professional, and alive.

## Dials (Part 3 of antislop)
- **ENERGY**: 3 (dynamic backgrounds add energy while staying controlled)
- **RHYTHM**: 2 (consistent spacing, gentle variation)
- **MOTION**: 2 (smooth transitions, 800ms color fade)

## Flutter-Specific Guidelines
- Follow Material Design principles
- Use standard Material widgets where appropriate
- Ensure proper state management for audio playback
- Responsive layouts that work across different Android screen sizes
- Proper handling of audio focus and background playback
