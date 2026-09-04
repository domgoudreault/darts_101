// Flutter basics
import 'package:flutter/material.dart';

// Global enum representing supported game modes
enum GlobalGameType {
  halfIt(
    tileType: 'games', tileCode: 'half-it', tileColor: Color(0xFF29B6F6), tileBackgroundColor: Color(0xFF81D4FA),
    tileDisplayName: 'Half-It Game', minNbrPlayers: 2, minNbrTeams: 2, maxNbrPlayers: 12, maxNbrTeams: 6,
    playWithPlayers: true, playWithTeams: true, oddNbrPlayers: true, oddNbrTeams: true, nbrLives: 0, nbrRounds: 0,
  ),
  aroundClock(
    tileType: 'games', tileCode: 'around-clock', tileColor: Color(0xFF26A69A), tileBackgroundColor: Color(0xFF80CBC4),
    tileDisplayName: 'Around the Clock (skip the numbers) Game', minNbrPlayers: 2, minNbrTeams: 2, maxNbrPlayers: 12, maxNbrTeams: 6,
    playWithPlayers: true, playWithTeams: true, oddNbrPlayers: true, oddNbrTeams: true, nbrLives: 0, nbrRounds: 0,
  ),
  sevenDarts(
    tileType: 'games', tileCode: '7-darts', tileColor: Color(0xFF66BB6A), tileBackgroundColor: Color(0xFFA5D6A7),
    tileDisplayName: '7 Darts Game', minNbrPlayers: 2, minNbrTeams: 2, maxNbrPlayers: 12, maxNbrTeams: 6,
    playWithPlayers: true, playWithTeams: true, oddNbrPlayers: true, oddNbrTeams: true, nbrLives: 0, nbrRounds: 3,
  ),
  allFives(
    tileType: 'games', tileCode: 'all-fives', tileColor: Color(0xFFCE93D8), tileBackgroundColor: Color(0xFFE1BEE7),
    tileDisplayName: 'All Fives / 51 by 5\'s Game', minNbrPlayers: 2, minNbrTeams: 2, maxNbrPlayers: 12, maxNbrTeams: 6,
    playWithPlayers: true, playWithTeams: true, oddNbrPlayers: true, oddNbrTeams: true, nbrLives: 0, nbrRounds: 0,
  ),
  killers(
    tileType: 'games', tileCode: 'killers', tileColor: Color(0xFF9E9E9E), tileBackgroundColor: Color(0xFFEEEEEE),
    tileDisplayName: 'Killers Game', minNbrPlayers: 2, minNbrTeams: 2, maxNbrPlayers: 12, maxNbrTeams: 6,
    playWithPlayers: true, playWithTeams: true, oddNbrPlayers: true, oddNbrTeams: true, nbrLives: 7, nbrRounds: 0,
  ),
  suddenDeath(
    tileType: 'games', tileCode: 'sudden-death', tileColor: Color(0xFFB71C1C), tileBackgroundColor: Color(0xFFEF5350),
    tileDisplayName: 'Sudden Death Game', minNbrPlayers: 3, minNbrTeams: 3, maxNbrPlayers: 12, maxNbrTeams: 6,
    playWithPlayers: true, playWithTeams: true, oddNbrPlayers: true, oddNbrTeams: true, nbrLives: 0, nbrRounds: 0,
  ),
  buildUp(
    tileType: 'games', tileCode: 'build-up', tileColor: Color(0xFF7E57C2), tileBackgroundColor: Color(0xFFB39DDB),
    tileDisplayName: 'Team Build-up Game', minNbrPlayers: 4, minNbrTeams: 0, maxNbrPlayers: 12, maxNbrTeams: 0,
    playWithPlayers: true, playWithTeams: false, oddNbrPlayers: false, oddNbrTeams: false, nbrLives: 0, nbrRounds: 0,
  );

  final String tileType;
  final String tileCode;
  final Color tileColor;
  final Color tileBackgroundColor;
  final String tileDisplayName;
  final int minNbrPlayers;
  final int minNbrTeams;
  final int maxNbrPlayers;
  final int maxNbrTeams;
  final bool playWithPlayers;
  final bool playWithTeams;
  final bool oddNbrPlayers;
  final bool oddNbrTeams;
  final int nbrLives;
  final int nbrRounds;

  const GlobalGameType({
    required this.tileType,
    required this.tileCode,
    required this.tileColor,
    required this.tileBackgroundColor,
    required this.tileDisplayName,
    required this.minNbrPlayers,
    required this.minNbrTeams,
    required this.maxNbrPlayers,
    required this.maxNbrTeams,
    required this.playWithPlayers,
    required this.playWithTeams,
    required this.oddNbrPlayers,
    required this.oddNbrTeams,
    required this.nbrLives,
    required this.nbrRounds,
  });

  static GlobalGameType getTile(String tileCode) {
    return GlobalGameType.values.firstWhere(
      (e) => e.tileCode == tileCode,
      orElse: () => GlobalGameType.halfIt,
    );
  }
}

// Global enum representing supported game modes
enum GlobalSettingType {
  players(tileType: 'settings', tileCode: 'players',
    tileColor: Color(0xFFFF7043), tileBackgroundColor: Color(0xFFFFCCBC), tilePickerColor: Color(0xFFF4511E),
    tileDisplayName: 'Players Management'
  ),
  teams(tileType: 'settings', tileCode: 'teams',
    tileColor: Color(0xFF5C6BC0), tileBackgroundColor: Color(0xFF9FA8DA), tilePickerColor: Color(0xFF3949AB),
    tileDisplayName: 'Teams Management'
  );

  final String tileType;
  final String tileCode;
  final Color tileColor;
  final Color tileBackgroundColor;
  final Color tilePickerColor;
  final String tileDisplayName;

  const GlobalSettingType({
    required this.tileType,
    required this.tileCode,
    required this.tileColor,
    required this.tileBackgroundColor,
    required this.tilePickerColor,
    required this.tileDisplayName
  });

  static GlobalSettingType getTile(String tileCode) {
    return GlobalSettingType.values.firstWhere(
      (tile) => tile.tileCode == tileCode,
      orElse: () => GlobalSettingType.players,
    );
  }
}

// Global enum representing device display tiers
enum GlobalEnumDisplayMode {
  display05SmallPhone,
  display10CompactPhone,
  display15MediumTablet,
  display20LargeLapDesk,
  display25Ultra4K,
}

// App-wide display state holder initialized at startup or on build
class GlobalAppDisplay {
  static late GlobalEnumDisplayMode displayMode;
  static late double height;
  static late double width;
  static late double safeHeight;
  static late double safeWidth;
  static late double carouselTileSize;

  // Call this once when screen size is resolved to set global display context
  static GlobalEnumDisplayMode updateDisplayMode(BuildContext context) {
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
(GlobalEnumDisplayMode displayMode, double carouselTileSize) getDisplayMode(double screenWidth) {
  if (screenWidth < 700) {    
    return (GlobalEnumDisplayMode.display05SmallPhone, 256.0);
  } else if (screenWidth < 960) {
    return (GlobalEnumDisplayMode.display10CompactPhone, 256.0);
  } else if (screenWidth < 1500) {
    return (GlobalEnumDisplayMode.display15MediumTablet, 512.0); // Fits your 1408dp Galaxy S10 Lite Tablet
  } else if (screenWidth < 1920) {
    return (GlobalEnumDisplayMode.display20LargeLapDesk, 768.0);
  } else {
    return (GlobalEnumDisplayMode.display25Ultra4K, 1024.0);
  }
}