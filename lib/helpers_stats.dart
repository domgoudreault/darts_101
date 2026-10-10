// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_score.dart';
import 'package:darts_101/database/tbl_game_options.dart';
import 'package:darts_101/database/tbl_player.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_dartboard.dart';

void gShowPlayerStatsGameHalfItDialog({
  required BuildContext context,
  required TblPlayer player,
  required bool isActivePlayer,
  required Color playerColor,
  required int seatIndex,
  required double responsiveTile,
  required double responsiveFontSize,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
}) {
  gClearAllArcadeOverlays();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade500,
        title: Text(
          "${player.fldNickName}'s Stats",
          style: gBuildArcadeTextStyle(
            responsiveFontSize,
            gFontWeight: FontWeight.bold,
            gTextColor: playerColor,
          ),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: responsiveTile * 0.8,
          height: responsiveTile * 1.1,
          child: buildPlayerStatsGameHalfItTable(
            player: player,
            isActivePlayer: isActivePlayer,
            playerColor: playerColor,
            seatIdx: seatIndex,
            gameConfig: gameConfig,
            gamesScoresBox: gamesScoresBox,
            gameOptions: gameOptions,
            responsiveTile: responsiveTile,
            responsiveFontSize: responsiveFontSize,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade800, // Works directly here
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Close",
              style: gBuildArcadeTextStyle(
                responsiveFontSize * 0.8,
                gFontWeight: FontWeight.bold,
                gTextColor: Colors.amber,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget buildPlayerStatsGameHalfItTable({
  required TblPlayer player,
  required bool isActivePlayer,
  required Color playerColor,
  required int seatIdx,
  required double responsiveTile,
  required double responsiveFontSize,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
}) {
  return Column(
    children: [
      // Table Header Row
      Container(
        padding: EdgeInsets.only(
          top: responsiveTile * 0.011,
          bottom: responsiveTile * 0.011,
          left: responsiveTile * 0.007,
          right: responsiveTile * 0.014,
        ),
        decoration: BoxDecoration(
          color: playerColor,
          border: Border(
            bottom: BorderSide(
              color: playerColor,
              width: responsiveTile * 0.003,
            ),
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(responsiveTile * 0.02),
            topRight: Radius.circular(responsiveTile * 0.02),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                'Target',
                textAlign: TextAlign.center,
                style: gBuildArcadeTextStyle(
                  responsiveFontSize * 0.53,
                  gFontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                'Round',
                textAlign: TextAlign.center,
                style: gBuildArcadeTextStyle(
                  responsiveFontSize * 0.53,
                  gFontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                gameConfig.fldPlayersGM ? 'Total' : 'Player/Team',
                textAlign: TextAlign.end,
                style: gBuildArcadeTextStyle(
                  responsiveFontSize * 0.53,
                  gFontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      // Scrollable Rows
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: gTargetsHalf.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              final startPlayerScore = gameOptions.fldStartingScore;
              final startTeamScore = gameOptions.fldStartingScore * 2;

              return Container(
                padding: EdgeInsets.symmetric(
                  vertical: responsiveTile * 0.005,
                  horizontal: responsiveTile * 0.014,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade800.withAlpha(120),
                  border: Border.all(
                    color: playerColor.withAlpha(200),
                    width: responsiveTile * 0.002,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Start",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveFontSize,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "-",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveFontSize,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        gameConfig.fldPlayersGM
                            ? '$startPlayerScore'
                            : '$startPlayerScore / $startTeamScore',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveFontSize,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final rIdx = index - 1;
            final target = gTargetsHalf[rIdx];

            final roundRecords = gamesScoresBox.values
                .where(
                  (s) =>
                      s.fldGame == gameConfig &&
                      s.fldPlayer == player &&
                      s.fldSeatIndex == seatIdx &&
                      s.fldRound == rIdx &&
                      (isActivePlayer ? true : s.fldDartIndex >= 2),
                )
                .toList();

            final record = roundRecords.isNotEmpty ? roundRecords.last : null;
            final playerScore = record?.fldScorePlayerSnapshot;
            final isPenalized = record?.fldIsHalfIt ?? false;

            final allPlayerRecords = gamesScoresBox.values
                .where(
                  (s) =>
                      s.fldGame == gameConfig &&
                      s.fldPlayer == player &&
                      s.fldSeatIndex == seatIdx &&
                      s.fldRound >= 0,
                )
                .toList();

            final int? lastThrownRound = allPlayerRecords.isNotEmpty
                ? allPlayerRecords
                      .map((s) => s.fldRound)
                      .reduce((a, b) => a > b ? a : b)
                : null;

            final bool isLastThrownRound =
                (lastThrownRound != null && rIdx == lastThrownRound);

            int? teamScore;
            if (!gameConfig.fldPlayersGM && gameConfig.fldTeams != null) {
              final int totalTeams = gameConfig.fldTeams!.length;
              final int teamIdx = seatIdx % totalTeams;

              final roundAllRecords = gamesScoresBox.values
                  .where(
                    (s) =>
                        s.fldGame == gameConfig &&
                        s.fldRound == rIdx &&
                        (isActivePlayer ? true : s.fldDartIndex >= 2),
                  )
                  .toList();

              final teamRoundRecords = roundAllRecords
                  .where((s) => (s.fldSeatIndex % totalTeams) == teamIdx)
                  .toList();

              if (teamRoundRecords.isNotEmpty) {
                teamScore = teamRoundRecords.last.fldScoreTeamSnapshot;
              }
            }

            String roundScoreStr = "-";
            if (record != null) {
              if (isPenalized) {
                roundScoreStr = "(Half-It)";
              } else {
                int previousRunningScore;
                if (rIdx == 0) {
                  final baselineRecords = gamesScoresBox.values
                      .where(
                        (s) =>
                            s.fldGame == gameConfig &&
                            s.fldPlayer == player &&
                            s.fldRound == -1,
                      )
                      .toList();
                  previousRunningScore = baselineRecords.isNotEmpty
                      ? baselineRecords.last.fldScorePlayerSnapshot
                      : (gameConfig.fldPlayersGM
                            ? gameOptions.fldStartingScore
                            : (gameOptions.fldStartingScore / 2).round());
                } else {
                  final prevRoundRecords = gamesScoresBox.values
                      .where(
                        (s) =>
                            s.fldGame == gameConfig &&
                            s.fldPlayer == player &&
                            s.fldRound == rIdx - 1,
                      )
                      .toList();
                  previousRunningScore = prevRoundRecords.isNotEmpty
                      ? prevRoundRecords.last.fldScorePlayerSnapshot
                      : 0;
                }

                final int diff = playerScore! - previousRunningScore;
                roundScoreStr = diff >= 0 ? "+ $diff" : "$diff";
              }
            }

            return Container(
              padding: EdgeInsets.symmetric(
                vertical: responsiveTile * 0.010,
                horizontal: responsiveTile * 0.014,
              ),
              decoration: BoxDecoration(
                color: isPenalized
                    ? Colors.red.shade100
                    : (isLastThrownRound
                          ? Colors.grey.shade800.withAlpha(120)
                          : null),
                border: Border.all(
                  color: playerColor.withAlpha(200),
                  width: responsiveTile * 0.002,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      target.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize,
                        color: isPenalized
                            ? Colors.red.shade900
                            : (isLastThrownRound
                                  ? Colors.amber
                                  : Colors.black),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      roundScoreStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize,
                        color: isPenalized
                            ? Colors.red.shade900
                            : (isLastThrownRound
                                  ? Colors.amber
                                  : Colors.black),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      gameConfig.fldPlayersGM
                          ? '${playerScore ?? '-'}'
                          : '${playerScore ?? '-'} / ${teamScore ?? '-'}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize,
                        color: isPenalized
                            ? Colors.red.shade900
                            : (isLastThrownRound
                                  ? Colors.amber
                                  : Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

void gShowPlayerStatsGame7DartsDialog({
  required BuildContext context,
  required TblPlayer player,
  required Color playerColor,
  required int seatIndex,
  required double responsiveTile,
  required double responsiveFontSize,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
}) {
  final double safeHeight = GlobalAppDisplay.safeHeight;
  final double safeWidth = GlobalAppDisplay.safeWidth;
  
  gClearAllArcadeOverlays();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade500,
        title: Text(
          "${player.fldNickName}'s Stats",
          style: gBuildArcadeTextStyle(
            responsiveFontSize,
            gFontWeight: FontWeight.bold,
            gTextColor: playerColor,
          ),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: safeWidth * 0.9,
          height: safeHeight * 0.9,
          child: buildPlayerStatsGame7DartsTable(
            player: player,
            playerColor: playerColor,
            seatIdx: seatIndex,
            responsiveTile: responsiveTile,
            responsiveFontSize: responsiveFontSize,
            gameConfig: gameConfig,
            gameOptions: gameOptions,
            gamesScoresBox: gamesScoresBox,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade800, // Works directly here
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Close",
              style: gBuildArcadeTextStyle(
                responsiveFontSize * 0.8,
                gFontWeight: FontWeight.bold,
                gTextColor: Colors.amber,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget buildPlayerStatsGame7DartsTable({
  required TblPlayer player,
  required Color playerColor,
  required int seatIdx,
  required double responsiveTile,
  required double responsiveFontSize,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
}) {
  return Column(
    children: [
      // Table Header Row
      Container(
        padding: EdgeInsets.only(
          top: responsiveTile * 0.011,
          bottom: responsiveTile * 0.011,
          left: responsiveTile * 0.007,
          right: responsiveTile * 0.014,
        ),
        decoration: BoxDecoration(
          color: playerColor,
          border: Border(
            bottom: BorderSide(
              color: playerColor,
              width: responsiveTile * 0.003,
            ),
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(responsiveTile * 0.02),
            topRight: Radius.circular(responsiveTile * 0.02),
          ),
        ),
        child: Column (
          children: [
            Row (
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    ' ',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 21,
                  child: Column(
                    children: [
                      Text(
                        'Targets',
                        textAlign: TextAlign.center,
                        style: gBuildArcadeTextStyle(
                          responsiveFontSize * 0.53,
                          gFontWeight: FontWeight.bold,
                        ),
                      ),

                      const Divider(color: Colors.white),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    ' ',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Round',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '20',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '19',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '18',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '17',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '16',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '15',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'BULL',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    gameConfig.fldPlayersGM ? 'Total' : 'Player/Team',
                    textAlign: TextAlign.end,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 0.53,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // Scrollable Rows
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: gameOptions.fldNbrRounds,
          itemBuilder: (context, roundIdx) {
            final roundRecords = gamesScoresBox.values
              .where(
                (s) =>
                    s.fldGame == gameConfig &&
                    s.fldPlayer == player &&
                    s.fldSeatIndex == seatIdx &&
                    s.fldRound == roundIdx,
              )
              .toList();

            final allPlayerRecords = gamesScoresBox.values
                .where(
                  (s) =>
                      s.fldGame == gameConfig &&
                      s.fldPlayer == player &&
                      s.fldSeatIndex == seatIdx &&
                      s.fldRound >= 0,
                )
                .toList();

            final int? lastThrownRound = allPlayerRecords.isNotEmpty
                ? allPlayerRecords
                      .map((s) => s.fldRound)
                      .reduce((a, b) => a > b ? a : b)
                : null;

            final bool isLastThrownRound =
                (lastThrownRound != null && roundIdx == lastThrownRound);

            final bool isPlayed = roundRecords.isNotEmpty;

            // Map dart index (0 to 6) to points earned on that throw
            Map<int, int> dartPoints = {};
            int? roundFinalScore;
            int? teamRoundFinalScore;

            for (var record in roundRecords) {
              int points = record.fldTargetValue * record.fldHits;
              dartPoints[record.fldDartIndex] = points;
              roundFinalScore = record.fldScorePlayerSnapshot;
              teamRoundFinalScore = record.fldScoreTeamSnapshot;
            }

            // Team score calculation if applicable
            if (!gameConfig.fldPlayersGM && gameConfig.fldTeams != null) {
              final int totalTeams = gameConfig.fldTeams!.length;
              final int teamIdx = seatIdx % totalTeams;
              final teamRoundRecords = gamesScoresBox.values
                  .where(
                    (s) =>
                        s.fldGame == gameConfig &&
                        s.fldRound == roundIdx &&
                        (s.fldSeatIndex % totalTeams) == teamIdx,
                  )
                  .toList();

              if (teamRoundRecords.isNotEmpty) {
                teamRoundFinalScore = teamRoundRecords.last.fldScoreTeamSnapshot;
              }
            }

            return Container(
              padding: EdgeInsets.symmetric(
                vertical: responsiveTile * 0.010,
                horizontal: responsiveTile * 0.014,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: playerColor.withAlpha(200),
                  width: responsiveTile * 0.002,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Round Number Column
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${roundIdx + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize,
                        color: isLastThrownRound ? Colors.amber : Colors.black,
                      ),
                    ),
                  ),
                  // 7 Target Columns (Dart Index 0 to 6)
                  ...List.generate(7, (dartIdx) {
                    final record = roundRecords.where((s) => s.fldDartIndex == dartIdx).firstOrNull;
                    final prevRecord = dartIdx > 0 
                        ? roundRecords.where((s) => s.fldDartIndex == dartIdx - 1).firstOrNull 
                        : null;

                    return Expanded(
                      flex: 3,
                      child: buildGame7DartsDartScoreCell(
                        record, 
                        prevRecord, 
                        isLastThrownRound,
                        responsiveTile,
                        responsiveFontSize,
                      ),
                    );
                  }),
                  // Total Column
                  Expanded(
                    flex: 4,
                    child: Text(
                      isPlayed
                          ? (gameConfig.fldPlayersGM
                              ? '${roundFinalScore ?? '-'}'
                              : '${roundFinalScore ?? '-'} / ${teamRoundFinalScore ?? '-'}')
                          : '-',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize,
                        color: isLastThrownRound ? Colors.amber : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

Widget buildGame7DartsDartScoreCell(
  TblGameScore? record, 
  TblGameScore? prevRecord, 
  bool isLastThrownRound,
  double responsiveTile,
  double responsiveFontSize,
  ) {
  final Color textColor = isLastThrownRound ? Colors.amber : Colors.black;
  
  if (record == null) {
    return Text(
      '-',
      textAlign: TextAlign.center,
      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
    );
  }

  int currentHits = record.fldHits;
  int currentPoints = record.fldTargetValue * currentHits;

  // If there is a previous record in the sequence, show the sequence (+ previous)
  if (prevRecord != null && prevRecord.fldHits > 0 && record.fldHits > 0) {
    int prevHits = prevRecord.fldHits;
    int prevPoints = prevRecord.fldTargetValue * prevHits;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildGame7DartsHitPillWithScore(currentHits, currentPoints, textColor, responsiveTile, responsiveFontSize),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text(' + ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
        ),
        buildGame7DartsHitPillWithScore(prevHits, prevPoints, textColor, responsiveTile, responsiveFontSize),
      ],
    );
  }

  // Otherwise, just show the single target throw pill and score
  return Center(
    child: buildGame7DartsHitPillWithScore(currentHits, currentPoints, textColor, responsiveTile, responsiveFontSize),
  );
}

Widget buildGame7DartsHitPillWithScore(
  int hits, 
  int points, 
  Color textColor,
  double responsiveTile,
  double responsiveFontSize,
  ) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Pill container only around the hits number
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsiveTile * 0.003,
          vertical: responsiveTile * 0.002,
        ),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(
            responsiveTile * 0.012,
          ),
          border: Border.all(
            color: Colors.black,
            width: responsiveTile * 0.002,
          ),
        ),
        child: Text(
          '$hits',
          style: TextStyle(
            color: const Color.fromARGB(255, 207, 20, 17),
            fontWeight: FontWeight.bold,
            fontSize: responsiveFontSize * 0.75,
          ),
        ),
      ),
      Icon(
        Icons.arrow_right_alt,
        color: Colors.black, // Adjusted for clear visibility against the row background
        size: responsiveFontSize * 0.9,
      ),
      Text(
        '$points',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: responsiveFontSize * 0.8,
        ),
      ),
    ],
  );
}

void gShowPlayerStatsGameAroundClockDialog({
  required BuildContext context,
  required TblPlayer player,
  required bool isActivePlayer,
  required Color playerColor,
  required int seatIndex,
  required double responsiveTile,
  required double responsiveFontSize,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
}) {
  gClearAllArcadeOverlays();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade500,
        title: Text(
          "${player.fldNickName}'s Stats",
          style: gBuildArcadeTextStyle(
            responsiveFontSize,
            gFontWeight: FontWeight.bold,
            gTextColor: playerColor,
          ),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: responsiveTile * 0.8,
          height: responsiveTile * 1.1,
          child: buildPlayerStatsGameAroundClockTable(
            player: player,
            isActivePlayer: isActivePlayer,
            playerColor: playerColor,
            seatIdx: seatIndex,
            responsiveTile: responsiveTile,
            responsiveFontSize: responsiveFontSize,
            gameConfig: gameConfig,
            gamesScoresBox: gamesScoresBox,
            gameOptions: gameOptions,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade800, // Works directly here
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Close",
              style: gBuildArcadeTextStyle(
                responsiveFontSize * 0.8,
                gFontWeight: FontWeight.bold,
                gTextColor: Colors.amber,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget buildPlayerStatsGameAroundClockTable({
  required TblPlayer player,
  required bool isActivePlayer,
  required Color playerColor,
  required int seatIdx,
  required double responsiveTile,
  required double responsiveFontSize,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
}) {
  return Column(
    children: [
      // Table Header Row
      Container(
        padding: EdgeInsets.only(
          top: responsiveTile * 0.011,
          bottom: responsiveTile * 0.011,
          left: responsiveTile * 0.007,
          right: responsiveTile * 0.014,
        ),
        decoration: BoxDecoration(
          color: playerColor,
          border: Border(
            bottom: BorderSide(
              color: playerColor,
              width: responsiveTile * 0.003,
            ),
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(responsiveTile * 0.02),
            topRight: Radius.circular(responsiveTile * 0.02),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                'Target',
                textAlign: TextAlign.center,
                style: gBuildArcadeTextStyle(
                  responsiveFontSize * 0.53,
                  gFontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                'Round',
                textAlign: TextAlign.center,
                style: gBuildArcadeTextStyle(
                  responsiveFontSize * 0.53,
                  gFontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                gameConfig.fldPlayersGM ? 'Total' : 'Player/Team',
                textAlign: TextAlign.end,
                style: gBuildArcadeTextStyle(
                  responsiveFontSize * 0.53,
                  gFontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      // Scrollable Rows
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: gTargetsHalf.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              final startPlayerScore = gameOptions.fldStartingScore;
              final startTeamScore = gameOptions.fldStartingScore * 2;

              return Container(
                padding: EdgeInsets.symmetric(
                  vertical: responsiveTile * 0.005,
                  horizontal: responsiveTile * 0.014,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade800.withAlpha(120),
                  border: Border.all(
                    color: playerColor.withAlpha(200),
                    width: responsiveTile * 0.002,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Start",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveFontSize,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "-",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveFontSize,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        gameConfig.fldPlayersGM
                            ? '$startPlayerScore'
                            : '$startPlayerScore / $startTeamScore',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveFontSize,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final rIdx = index - 1;
            final target = gTargetsHalf[rIdx];

            final roundRecords = gamesScoresBox.values
                .where(
                  (s) =>
                      s.fldGame == gameConfig &&
                      s.fldPlayer == player &&
                      s.fldSeatIndex == seatIdx &&
                      s.fldRound == rIdx &&
                      (isActivePlayer ? true : s.fldDartIndex >= 2),
                )
                .toList();

            final record = roundRecords.isNotEmpty ? roundRecords.last : null;
            final playerScore = record?.fldScorePlayerSnapshot;
            final isPenalized = record?.fldIsHalfIt ?? false;

            final allPlayerRecords = gamesScoresBox.values
                .where(
                  (s) =>
                      s.fldGame == gameConfig &&
                      s.fldPlayer == player &&
                      s.fldSeatIndex == seatIdx &&
                      s.fldRound >= 0,
                )
                .toList();

            final int? lastThrownRound = allPlayerRecords.isNotEmpty
                ? allPlayerRecords
                      .map((s) => s.fldRound)
                      .reduce((a, b) => a > b ? a : b)
                : null;

            final bool isLastThrownRound =
                (lastThrownRound != null && rIdx == lastThrownRound);

            int? teamScore;
            if (!gameConfig.fldPlayersGM && gameConfig.fldTeams != null) {
              final int totalTeams = gameConfig.fldTeams!.length;
              final int teamIdx = seatIdx % totalTeams;

              final roundAllRecords = gamesScoresBox.values
                  .where(
                    (s) =>
                        s.fldGame == gameConfig &&
                        s.fldRound == rIdx &&
                        (isActivePlayer ? true : s.fldDartIndex >= 2),
                  )
                  .toList();

              final teamRoundRecords = roundAllRecords
                  .where((s) => (s.fldSeatIndex % totalTeams) == teamIdx)
                  .toList();

              if (teamRoundRecords.isNotEmpty) {
                teamScore = teamRoundRecords.last.fldScoreTeamSnapshot;
              }
            }

            String roundScoreStr = "-";
            if (record != null) {
              if (isPenalized) {
                roundScoreStr = "(Half-It)";
              } else {
                int previousRunningScore;
                if (rIdx == 0) {
                  final baselineRecords = gamesScoresBox.values
                      .where(
                        (s) =>
                            s.fldGame == gameConfig &&
                            s.fldPlayer == player &&
                            s.fldRound == -1,
                      )
                      .toList();
                  previousRunningScore = baselineRecords.isNotEmpty
                      ? baselineRecords.last.fldScorePlayerSnapshot
                      : (gameConfig.fldPlayersGM
                            ? gameOptions.fldStartingScore
                            : (gameOptions.fldStartingScore / 2).round());
                } else {
                  final prevRoundRecords = gamesScoresBox.values
                      .where(
                        (s) =>
                            s.fldGame == gameConfig &&
                            s.fldPlayer == player &&
                            s.fldRound == rIdx - 1,
                      )
                      .toList();
                  previousRunningScore = prevRoundRecords.isNotEmpty
                      ? prevRoundRecords.last.fldScorePlayerSnapshot
                      : 0;
                }

                final int diff = playerScore! - previousRunningScore;
                roundScoreStr = diff >= 0 ? "+ $diff" : "$diff";
              }
            }

            return Container(
              padding: EdgeInsets.symmetric(
                vertical: responsiveTile * 0.010,
                horizontal: responsiveTile * 0.014,
              ),
              decoration: BoxDecoration(
                color: isPenalized
                    ? Colors.red.shade100
                    : (isLastThrownRound
                          ? Colors.grey.shade800.withAlpha(120)
                          : null),
                border: Border.all(
                  color: playerColor.withAlpha(200),
                  width: responsiveTile * 0.002,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      target.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize,
                        color: isPenalized
                            ? Colors.red.shade900
                            : (isLastThrownRound
                                  ? Colors.amber
                                  : Colors.black),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      roundScoreStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize,
                        color: isPenalized
                            ? Colors.red.shade900
                            : (isLastThrownRound
                                  ? Colors.amber
                                  : Colors.black),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      gameConfig.fldPlayersGM
                          ? '${playerScore ?? '-'}'
                          : '${playerScore ?? '-'} / ${teamScore ?? '-'}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize,
                        color: isPenalized
                            ? Colors.red.shade900
                            : (isLastThrownRound
                                  ? Colors.amber
                                  : Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}