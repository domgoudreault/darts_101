import 'package:flutter/material.dart';

// Global enum representing device display tiers
enum DisplayMode {
  display01CompactPhone,
  display05MediumTablet,
  display10LargeLapDesk,
  display15Ultra4K,
}

// App-wide display state holder initialized at startup or on build
class AppDisplay {
  static late DisplayMode displayMode;
  static late double mediaQueryWidth;

  // Call this once when screen size is resolved to set global display context
  static void init(BuildContext context) {
    mediaQueryWidth = MediaQuery.of(context).size.width;
    displayMode = getDisplayMode(mediaQueryWidth);
  }
}

// Core function evaluating physical width against breakpoints
DisplayMode getDisplayMode(double screenWidth) {
  if (screenWidth < 900) {
    return DisplayMode.display01CompactPhone;
  } else if (screenWidth < 1500) {
    return DisplayMode.display05MediumTablet; // Fits your 1408dp Galaxy Tab
  } else if (screenWidth < 1920) {
    return DisplayMode.display10LargeLapDesk;
  } else {
    return DisplayMode.display15Ultra4K;
  }
}