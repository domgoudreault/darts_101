// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_score.dart';
import 'package:darts_101/database/tbl_game_options.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
import 'package:darts_101/helpers_dartboard.dart';

Widget gBuildGameHalfItRankingWidget({
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required bool isPlayerMode,
  required double responsiveTile,
}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: responsiveTile * 0.012,
      vertical: responsiveTile * 0.010,
    ),
    decoration: BoxDecoration(
      color: Colors.grey.shade800.withAlpha(150),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(responsiveTile * 0.03),
        bottomRight: Radius.circular(responsiveTile * 0.03),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: isPlayerMode
              ? buildGameHalfItPlayersRankingList(
                  gameConfig: gameConfig,
                  gamesScoresBox: gamesScoresBox,
                  gameOptions: gameOptions,
                  gamePlayers: gamePlayers,
                  responsiveTile: responsiveTile,
                )
              : buildGameHalfItTeamsRankingList(
                  gameConfig: gameConfig,
                  gamesScoresBox: gamesScoresBox,
                  gameOptions: gameOptions,
                  gamePlayers: gamePlayers,
                  gameTeams: gameTeams,
                  responsiveTile: responsiveTile,
                ),
        ),
      ],
    ),
  );
}

Widget buildGameHalfItPlayersRankingList({
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required double responsiveTile,
}) {
  // Gather latest score for each player
  final List<({TblPlayer player, int score, Color color, int originalIdx})>
  playerScores = [];

  for (var entry in gamePlayers) {
    final pRecords = gamesScoresBox.values
        .where((s) => s.fldGame == gameConfig && s.fldPlayer == entry.player)
        .toList();

    final score = pRecords.isNotEmpty
        ? pRecords.last.fldScorePlayerSnapshot
        : gameOptions.fldStartingScore;
    playerScores.add((
      player: entry.player,
      score: score,
      color: entry.playerColor,
      originalIdx: entry.originalIndex,
    ));
  }

  // Sort descending by score
  playerScores.sort((a, b) => b.score.compareTo(a.score));

  return ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: playerScores.length,
    itemBuilder: (context, index) {
      final item = playerScores[index];
      return Container(
        padding: EdgeInsets.symmetric(
          vertical: responsiveTile * 0.010,
          horizontal: responsiveTile * 0.015,
        ),
        margin: EdgeInsets.only(bottom: responsiveTile * 0.013),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withAlpha(170),
          borderRadius: BorderRadius.circular(responsiveTile * 0.015),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                index == 0
                    ? Text(
                        "${index + 1}.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontSize: responsiveTile * 0.0425,
                        ),
                      )
                    : Text(
                        "${index + 1}.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsiveTile * 0.04,
                        ),
                      ),

                SizedBox(width: responsiveTile * 0.005),

                index == 0
                    ? Text(
                        item.player.fldNickName,
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveTile * 0.0425,
                        ),
                      )
                    : Text(
                        item.player.fldNickName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: responsiveTile * 0.04,
                        ),
                      ),
              ],
            ),

            index == 0
                ? Text(
                    "${item.score}",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: responsiveTile * 0.0425,
                    ),
                  )
                : Text(
                    "${item.score}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: responsiveTile * 0.04,
                    ),
                  ),
          ],
        ),
      );
    },
  );
}

Widget buildGameHalfItTeamsRankingList({
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required double responsiveTile,
}) {
  if (gameTeams.isEmpty) return const SizedBox.shrink();

  final List<({TblTeam team, int score, Color color})> teamScores = [];

  for (var entry in gameTeams) {
    final teamPlayerNames = entry.team.fldPlayers
        .map((p) => p.fldNickName)
        .toSet();
    final tRecords = gamesScoresBox.values
        .where(
          (s) =>
              s.fldGame == gameConfig &&
              teamPlayerNames.contains(s.fldPlayer.fldNickName),
        )
        .toList();

    final score = tRecords.isNotEmpty
        ? (tRecords.last.fldScoreTeamSnapshot ?? gameOptions.fldStartingScore)
        : gameOptions.fldStartingScore;
    teamScores.add((team: entry.team, score: score, color: entry.teamColor));
  }

  // Sort descending by score
  teamScores.sort((a, b) => b.score.compareTo(a.score));

  return ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: teamScores.length,
    itemBuilder: (context, index) {
      final item = teamScores[index];
      // Combine player nicknames with " & "
      final teamNamesString = item.team.fldPlayers
          .map((p) => p.fldNickName)
          .join(' & ');

      return Container(
        padding: EdgeInsets.symmetric(
          vertical: responsiveTile * 0.010,
          horizontal: responsiveTile * 0.015,
        ),
        margin: EdgeInsets.only(bottom: responsiveTile * 0.015),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withAlpha(150),
          borderRadius: BorderRadius.circular(responsiveTile * 0.015),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                index == 0
                    ? Text(
                        "${index + 1}.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontSize: responsiveTile * 0.04,
                        ),
                      )
                    : Text(
                        "${index + 1}.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsiveTile * 0.0325,
                        ),
                      ),

                SizedBox(width: responsiveTile * 0.010),

                index == 0
                    ? Text(
                        teamNamesString,
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveTile * 0.04,
                        ),
                      )
                    : Text(
                        teamNamesString,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: responsiveTile * 0.0325,
                        ),
                      ),
              ],
            ),

            index == 0
                ? Text(
                    "${item.score}",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: responsiveTile * 0.04,
                    ),
                  )
                : Text(
                    "${item.score}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: responsiveTile * 0.0325,
                    ),
                  ),
          ],
        ),
      );
    },
  );
}

Widget gBuildGame7DartsRankingWidget({
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required bool isPlayerMode,
  required double responsiveTile,
}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: responsiveTile * 0.012,
      vertical: responsiveTile * 0.010,
    ),
    decoration: BoxDecoration(
      color: Colors.grey.shade800.withAlpha(150),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(responsiveTile * 0.03),
        bottomRight: Radius.circular(responsiveTile * 0.03),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: isPlayerMode
              ? buildGame7DartsPlayersRankingList(
                  gameConfig: gameConfig,
                  gamesScoresBox: gamesScoresBox,
                  gameOptions: gameOptions,
                  gamePlayers: gamePlayers,
                  responsiveTile: responsiveTile,
                )
              : buildGame7DartsTeamsRankingList(
                  gameConfig: gameConfig,
                  gamesScoresBox: gamesScoresBox,
                  gameOptions: gameOptions,
                  gamePlayers: gamePlayers,
                  gameTeams: gameTeams,
                  responsiveTile: responsiveTile,
                ),
        ),
      ],
    ),
  );
}

Widget buildGame7DartsPlayersRankingList({
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required double responsiveTile,
}) {
  // Gather latest score for each player
  final List<({TblPlayer player, int score, Color color, int originalIdx})>
  playerScores = [];

  for (var entry in gamePlayers) {
    final pRecords = gamesScoresBox.values
        .where((s) => s.fldGame == gameConfig && s.fldPlayer == entry.player)
        .toList();

    final score = pRecords.isNotEmpty
        ? pRecords.last.fldScorePlayerSnapshot
        : gameOptions.fldStartingScore;
    playerScores.add((
      player: entry.player,
      score: score,
      color: entry.playerColor,
      originalIdx: entry.originalIndex,
    ));
  }

  // Sort descending by score
  playerScores.sort((a, b) => b.score.compareTo(a.score));

  return ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: playerScores.length,
    itemBuilder: (context, index) {
      final item = playerScores[index];
      return Container(
        padding: EdgeInsets.symmetric(
          vertical: responsiveTile * 0.010,
          horizontal: responsiveTile * 0.015,
        ),
        margin: EdgeInsets.only(bottom: responsiveTile * 0.013),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withAlpha(170),
          borderRadius: BorderRadius.circular(responsiveTile * 0.015),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                index == 0
                    ? Text(
                        "${index + 1}.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontSize: responsiveTile * 0.0425,
                        ),
                      )
                    : Text(
                        "${index + 1}.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsiveTile * 0.04,
                        ),
                      ),

                SizedBox(width: responsiveTile * 0.005),

                index == 0
                    ? Text(
                        item.player.fldNickName,
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveTile * 0.0425,
                        ),
                      )
                    : Text(
                        item.player.fldNickName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: responsiveTile * 0.04,
                        ),
                      ),
              ],
            ),

            index == 0
                ? Text(
                    "${item.score}",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: responsiveTile * 0.0425,
                    ),
                  )
                : Text(
                    "${item.score}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: responsiveTile * 0.04,
                    ),
                  ),
          ],
        ),
      );
    },
  );
}

Widget buildGame7DartsTeamsRankingList({
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required double responsiveTile,
}) {
  if (gameTeams.isEmpty) return const SizedBox.shrink();

  final List<({TblTeam team, int score, Color color})> teamScores = [];

  for (var entry in gameTeams) {
    final teamPlayerNames = entry.team.fldPlayers
        .map((p) => p.fldNickName)
        .toSet();
    final tRecords = gamesScoresBox.values
        .where(
          (s) =>
              s.fldGame == gameConfig &&
              teamPlayerNames.contains(s.fldPlayer.fldNickName),
        )
        .toList();

    final score = tRecords.isNotEmpty
        ? (tRecords.last.fldScoreTeamSnapshot ?? gameOptions.fldStartingScore)
        : gameOptions.fldStartingScore;
    teamScores.add((team: entry.team, score: score, color: entry.teamColor));
  }

  // Sort descending by score
  teamScores.sort((a, b) => b.score.compareTo(a.score));

  return ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: teamScores.length,
    itemBuilder: (context, index) {
      final item = teamScores[index];
      // Combine player nicknames with " & "
      final teamNamesString = item.team.fldPlayers
          .map((p) => p.fldNickName)
          .join(' & ');

      return Container(
        padding: EdgeInsets.symmetric(
          vertical: responsiveTile * 0.010,
          horizontal: responsiveTile * 0.015,
        ),
        margin: EdgeInsets.only(bottom: responsiveTile * 0.015),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withAlpha(150),
          borderRadius: BorderRadius.circular(responsiveTile * 0.015),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                index == 0
                    ? Text(
                        "${index + 1}.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontSize: responsiveTile * 0.04,
                        ),
                      )
                    : Text(
                        "${index + 1}.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsiveTile * 0.0325,
                        ),
                      ),

                SizedBox(width: responsiveTile * 0.010),

                index == 0
                    ? Text(
                        teamNamesString,
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveTile * 0.04,
                        ),
                      )
                    : Text(
                        teamNamesString,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: responsiveTile * 0.0325,
                        ),
                      ),
              ],
            ),

            index == 0
                ? Text(
                    "${item.score}",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: responsiveTile * 0.04,
                    ),
                  )
                : Text(
                    "${item.score}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: responsiveTile * 0.0325,
                    ),
                  ),
          ],
        ),
      );
    },
  );
}

Widget gBuildGameAroundClockRankingWidget({
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required bool isPlayerMode,
  required double responsiveTile,
}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: responsiveTile * 0.012,
      vertical: responsiveTile * 0.010,
    ),
    decoration: BoxDecoration(
      color: Colors.grey.shade800.withAlpha(150),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(responsiveTile * 0.03),
        bottomRight: Radius.circular(responsiveTile * 0.03),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: isPlayerMode
            ? buildGameAroundClockPlayersRankingList(
                gameConfig: gameConfig,
                gamesScoresBox: gamesScoresBox,
                gameOptions: gameOptions,
                gamePlayers: gamePlayers,
                responsiveTile: responsiveTile,
              )
            : buildGameAroundClockTeamsRankingList(
                gameConfig: gameConfig,
                gamesScoresBox: gamesScoresBox,
                gameOptions: gameOptions,
                gamePlayers: gamePlayers,
                gameTeams: gameTeams,
                responsiveTile: responsiveTile,
              ),
        ),
      ],
    ),
  );
}

Widget buildGameAroundClockPlayersRankingList({
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required double responsiveTile,
}) {
  final targets = gGetTargetsForGame(gameConfig);

  // Gather latest target index for each player
  final List<({TblPlayer player, int targetIndex, String targetLabel, Color color, int originalIdx})>
  playerRankings = [];

  for (var entry in gamePlayers) {
    final pRecords = gamesScoresBox.values
        .where((s) => s.fldGame == gameConfig && s.fldPlayer == entry.player)
        .toList();

    final lastRecord = pRecords.isNotEmpty ? pRecords.last : null;
    
    // Get the next target index (fallback to 0 if no records yet)
    final targetIndex = lastRecord != null 
        ? (lastRecord.fldNextTargetIndex ?? lastRecord.fldTargetIndex) 
        : 0;

    // Get the target label safely
    final targetLabel = (targetIndex >= 0 && targetIndex < targets.length)
        ? targets[targetIndex].label
        : '-';

    playerRankings.add((
      player: entry.player,
      targetIndex: targetIndex,
      targetLabel: targetLabel,
      color: entry.playerColor,
      originalIdx: entry.originalIndex,
    ));
  }

  // Sort descending by targetIndex so the player furthest along the clock is #1
  playerRankings.sort((a, b) => b.targetIndex.compareTo(a.targetIndex));

  return ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: playerRankings.length,
    itemBuilder: (context, index) {
      final item = playerRankings[index];
      final isLeader = index == 0;

      return Container(
        padding: EdgeInsets.symmetric(
          vertical: responsiveTile * 0.010,
          horizontal: responsiveTile * 0.015,
        ),
        margin: EdgeInsets.only(bottom: responsiveTile * 0.013),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withAlpha(170),
          borderRadius: BorderRadius.circular(responsiveTile * 0.015),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Rank number & Player nickname
            Row(
              children: [
                Text(
                  "${index + 1}.",
                  style: TextStyle(
                    fontWeight: isLeader ? FontWeight.bold : FontWeight.normal,
                    color: isLeader ? Colors.amber : Colors.white,
                    fontSize: responsiveTile * (isLeader ? 0.0425 : 0.04),
                  ),
                ),
                SizedBox(width: responsiveTile * 0.005),
                Text(
                  item.player.fldNickName,
                  style: TextStyle(
                    color: isLeader ? Colors.amber : Colors.white,
                    fontWeight: isLeader ? FontWeight.bold : FontWeight.w500,
                    fontSize: responsiveTile * (isLeader ? 0.0425 : 0.04),
                  ),
                ),
              ],
            ),
            // Right side: Player's current target label
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (gAcIsGoingDown(gameConfig, item.targetIndex) != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      gAcIsGoingDown(gameConfig, item.targetIndex)!
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: gAcIsGoingDown(gameConfig, item.targetIndex)!
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                      size: responsiveTile * (isLeader ? 0.0425 : 0.04),
                    ),
                  ),
                  SizedBox(width: responsiveTile * 0.01),
                Text(
                  item.targetLabel,
                  style: TextStyle(
                    color: isLeader ? Colors.amber : Colors.white,
                    fontWeight: isLeader ? FontWeight.bold : FontWeight.normal,
                    fontSize: responsiveTile * (isLeader ? 0.0425 : 0.04),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget buildGameAroundClockTeamsRankingList({
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required double responsiveTile,
}) {
  if (gameTeams.isEmpty) return const SizedBox.shrink();

  final targets = gGetTargetsForGame(gameConfig);
  // "score" holds the next target label displayed; "idx" is the progress used for sorting
  final List<({TblTeam team, String score, int idx, Color color})> teamScores = [];

  for (var entry in gameTeams) {
    // Seats are interleaved by team: team = seat % number of teams
    final lastRecord = gamesScoresBox.values
        .where(
          (s) =>
              s.fldGame == gameConfig &&
              s.fldRound >= 0 &&
              s.fldSeatIndex % gameTeams.length == entry.originalIndex,
        )
        .lastOrNull;

    final targetIndex = lastRecord != null
        ? (lastRecord.fldNextTargetIndex ?? lastRecord.fldTargetIndex)
        : 0;
    final label = (targetIndex >= 0 && targetIndex < targets.length)
        ? targets[targetIndex].label
        : '-';
    teamScores.add((
      team: entry.team,
      score: label,
      idx: targetIndex,
      color: entry.teamColor,
    ));
  }

  // Sort descending by progress so the team furthest along the clock is #1
  teamScores.sort((a, b) => b.idx.compareTo(a.idx));

  return ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: teamScores.length,
    itemBuilder: (context, index) {
      final item = teamScores[index];
      // Combine player nicknames with " & "
      final teamNamesString = item.team.fldPlayers
          .map((p) => p.fldNickName)
          .join(' & ');

      return Container(
        padding: EdgeInsets.symmetric(
          vertical: responsiveTile * 0.010,
          horizontal: responsiveTile * 0.015,
        ),
        margin: EdgeInsets.only(bottom: responsiveTile * 0.015),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withAlpha(150),
          borderRadius: BorderRadius.circular(responsiveTile * 0.015),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                index == 0
                    ? Text(
                        "${index + 1}.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontSize: responsiveTile * 0.04,
                        ),
                      )
                    : Text(
                        "${index + 1}.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsiveTile * 0.0325,
                        ),
                      ),

                SizedBox(width: responsiveTile * 0.010),

                index == 0
                    ? Text(
                        teamNamesString,
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveTile * 0.04,
                        ),
                      )
                    : Text(
                        teamNamesString,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: responsiveTile * 0.0325,
                        ),
                      ),
              ],
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (gAcIsGoingDown(gameConfig, item.idx) != null)
                  Icon(
                    gAcIsGoingDown(gameConfig, item.idx)!
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: index == 0 ? Colors.amber : Colors.white,
                    size: responsiveTile * (index == 0 ? 0.04 : 0.0325),
                  ),
                Text(
                  item.score,
                  style: TextStyle(
                    color: index == 0 ? Colors.amber : Colors.white,
                    fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                    fontSize: responsiveTile * (index == 0 ? 0.04 : 0.0325),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}