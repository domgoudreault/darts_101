// Flutter basics
import 'package:flutter/material.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Shared selection state used across the current league session.
// This intentionally persists across game screens so a user does not have to
// reselect the same players and teams for every game in the same night.
List<TblPlayer> gSelectedPlayers = <TblPlayer>[];
List<TblTeam> gSelectedTeams = <TblTeam>[];

enum GlobalFormMode { formAdd, formModify }

class GlobalLeagueSession {
  static void setPlayers(Iterable<TblPlayer> players) {
    gSelectedPlayers
      ..clear()
      ..addAll(players);
  }

  static void setTeams(Iterable<TblTeam> teams) {
    gSelectedTeams
      ..clear()
      ..addAll(teams);
  }

  static void clear() {
    gSelectedPlayers.clear();
    gSelectedTeams.clear();
  }

  static bool get hasPlayers => gSelectedPlayers.isNotEmpty;
  static bool get hasTeams => gSelectedTeams.isNotEmpty;
}

enum GlobalGameState { forwardState, backwardState }

// Global enum representing supported game modes
enum GlobalSettingType {
  players(
    tileType: 'settings',
    tileCode: 'players',
    tileColor: Color(0xFFFF7043),
    tileBackgroundColor: Color(0xFFFFCCBC),
    tilePickerColor: Color(0xFFF4511E),
    tileDisplayName: 'Players Management',
  ),
  teams(
    tileType: 'settings',
    tileCode: 'teams',
    tileColor: Color(0xFF5C6BC0),
    tileBackgroundColor: Color(0xFF9FA8DA),
    tilePickerColor: Color(0xFF3949AB),
    tileDisplayName: 'Teams Management',
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
    required this.tileDisplayName,
  });

  static final Map<String, GlobalSettingType> _tileMap = {
    for (final tile in GlobalSettingType.values) tile.tileCode: tile,
  };

  static GlobalSettingType getTile(String tileCode) {
    return _tileMap[tileCode] ?? GlobalSettingType.players;
  }
}

// Global enum representing Players Rosters Grid Config
enum GlobalPlayersGridConfig {
  playerSlot1(position: 1, bgColor: Color(0xFF2196F3)),
  playerSlot2(position: 2, bgColor: Color.fromARGB(255, 207, 20, 17)),
  playerSlot3(position: 3, bgColor: Color.fromARGB(255, 255, 144, 41)),
  playerSlot4(position: 4, bgColor: Color.fromARGB(255, 147, 206, 84)),
  playerSlot5(position: 5, bgColor: Color(0xFF3F51B5)),
  playerSlot6(position: 6, bgColor: Color(0xFF8E24AA)),
  playerSlot7(position: 7, bgColor: Color.fromARGB(255, 201, 165, 8)),
  playerSlot8(position: 8, bgColor: Color.fromARGB(255, 252, 70, 14)),
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

  const GlobalTeamsGridConfig({required this.position, required this.bgColor});
}

// App-wide display state holder initialized at startup or on build.
// It intentionally reflects the current window size so the UI stays responsive
// when the browser window or device orientation changes.
class GlobalAppDisplay {
  static late double height;
  static late double width;
  static late double safeHeight;
  static late double safeWidth;

  static void globalEnumDisplayMode(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    height = size.height;
    width = size.width;

    safeHeight = height - padding.top - padding.bottom;
    safeWidth = width - padding.left - padding.right;
  }
}
