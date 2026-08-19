import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Global enum representing device display tiers
enum DisplayMode {
  display05SmallPhone,
  display10CompactPhone,
  display15MediumTablet,
  display20LargeLapDesk,
  display25Ultra4K,
}

// App-wide display state holder initialized at startup or on build
class AppDisplay {
  static late DisplayMode displayMode;
  static late double height;
  static late double width;
  static late double safeHeight;
  static late double safeWidth;
  static late double carouselTileSize;

  // Call this once when screen size is resolved to set global display context
  static DisplayMode updateDisplayMode(BuildContext context) {
    // Reads raw screen dimensions dynamically (supports device switches & rotations)
    final size = MediaQuery.sizeOf(context);
    // Reads notch, status bar, and system gesture padding insets
    final padding = MediaQuery.paddingOf(context);

    height = size.height;
    width = size.width;

    // True safe printable screen area
    safeHeight = height - padding.top - padding.bottom;
    safeWidth = width - padding.left - padding.right;

    final (mode, tileSize) = getDisplayMode(width);
    displayMode = mode;
    carouselTileSize = tileSize;

    return displayMode;
  }
}

// Core function evaluating physical width against breakpoints
(DisplayMode displayMode, double carouselTileSize) getDisplayMode(double screenWidth) {
  if (screenWidth < 700) {    
    return (DisplayMode.display05SmallPhone, 256.0);
  } else if (screenWidth < 960) {
    return (DisplayMode.display10CompactPhone, 256.0);
  } else if (screenWidth < 1500) {
    return (DisplayMode.display15MediumTablet, 512.0); // Fits your 1408dp Galaxy S10 Lite Tablet
  } else if (screenWidth < 1920) {
    return (DisplayMode.display20LargeLapDesk, 768.0);
  } else {
    return (DisplayMode.display25Ultra4K, 1024.0);
  }
}

// Returns a retro arcade Text widget with a hard pixel drop shadow.
TextStyle gBuildArcadeTextStyle(
  double gFontSize, {
  FontWeight gFontWeight = FontWeight.normal,
  Color gTextColor = Colors.white,
  Color gShadowColor = Colors.black,
}) {
  return GoogleFonts.pressStart2p(
    fontSize: gFontSize,
    color: gTextColor,
    shadows: [
      Shadow(
        offset: const Offset(-2.0, 2.0),
        color: gShadowColor,
        blurRadius: 0.0,
      ),
    ],
  );
}