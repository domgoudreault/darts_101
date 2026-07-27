import 'package:flutter/material.dart';

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

  // Call this once when screen size is resolved to set global display context
  static DisplayMode updateDisplayMode(BuildContext context) {
    // Reads screen dimensions dynamically (supports device switches & rotations)
    final size = MediaQuery.sizeOf(context);
    height = size.height;
    width = size.width;
    displayMode = getDisplayMode(width);

    return displayMode;
  }
}

// Core function evaluating physical width against breakpoints
DisplayMode getDisplayMode(double screenWidth) {
  if (screenWidth < 700) {
    return DisplayMode.display05SmallPhone;
  } else if (screenWidth < 960) {
    return DisplayMode.display10CompactPhone;
  } else if (screenWidth < 1500) {
    return DisplayMode.display15MediumTablet; // Fits your 1408dp Galaxy S10 Lite Tablet
  } else if (screenWidth < 1920) {
    return DisplayMode.display20LargeLapDesk;
  } else {
    return DisplayMode.display25Ultra4K;
  }
}