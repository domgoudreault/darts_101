// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_score.dart';
import 'package:darts_101/database/tbl_game_options.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

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

Widget buildGameAroundClockTeamsRankingList({
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