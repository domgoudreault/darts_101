// Flutter basics
import 'package:flutter/material.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

List<TblPlayer> gSelectedPlayers = [];
List<TblTeam> gSelectedTeams = [];

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

// Global enum representing Players Rosters Grid Config
enum GlobalPlayersGridConfig {
  playerSlot1(position: 1, bgColor: Color(0xFF2196F3)),
  playerSlot2(position: 2, bgColor: Color(0xFFE53935)),
  playerSlot3(position: 3, bgColor: Color.fromARGB(255, 255, 170, 41)),
  playerSlot4(position: 4, bgColor: Color.fromARGB(255, 147, 206, 84)),
  playerSlot5(position: 5, bgColor: Color(0xFF3F51B5)),
  playerSlot6(position: 6, bgColor: Color(0xFF8E24AA)),
  playerSlot7(position: 7, bgColor: Color.fromARGB(255, 201, 165, 8)),
  playerSlot8(position: 8, bgColor: Color(0xFFFF7043)),
  playerSlot9(position: 9, bgColor: Color(0xFF00897B)),
  playerSlot10(position: 10, bgColor: Color.fromARGB(255, 18, 90, 22)),
  playerSlot11(position: 11, bgColor: Color(0xFF00ACC1)),
  playerSlot12(position: 12, bgColor: Color(0xFFD81B60));
  
  final int position;
  final Color bgColor;

  const GlobalPlayersGridConfig({
    required this.position,
    required this.bgColor,
  });
}

enum GlobalTeamsGridConfig {
  teamSlot1(position: 1, bgColor: Color(0xFF3F51B5)),
  teamSlot2(position: 2, bgColor: Color(0xFFE53935)),
  teamSlot3(position: 3, bgColor: Color(0xFFFF7043)),
  teamSlot4(position: 4, bgColor: Color.fromARGB(255, 147, 206, 84)),
  teamSlot5(position: 5, bgColor: Color(0xFF8E24AA)),
  teamSlot6(position: 6, bgColor: Color(0xFFD81B60));
  
  final int position;
  final Color bgColor;

  const GlobalTeamsGridConfig({
    required this.position,
    required this.bgColor,
  });
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