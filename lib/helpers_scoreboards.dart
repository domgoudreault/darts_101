// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_score.dart';
import 'package:darts_101/database/tbl_game_options.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_dartboard.dart';


void gShowGame7DartsScoreboardDialog({
  required BuildContext context,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required bool isPlayerMode,
  required double responsiveTile,
  required double responsiveFontSize,
}) {
  gClearAllArcadeOverlays();

  showDialog(
    context: context,
    builder: (context) {
      MediaQuery.sizeOf(context);

      return AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: Text(
          isPlayerMode ? "Players Full Scoreboard" : "Teams Full Scoreboard",
          style: gBuildArcadeTextStyle(
            responsiveFontSize,
            gFontWeight: FontWeight.bold,
            gTextColor: Colors.amber,
          ),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: GlobalAppDisplay.safeWidth * 0.9,
          height: GlobalAppDisplay.safeHeight * 0.8,
          child: buildGame7DartsScoreboardTable(
            gameConfig: gameConfig,
            gameOptions: gameOptions,
            gamesScoresBox: gamesScoresBox,
            gamePlayers: gamePlayers,
            gameTeams: gameTeams,
            isPlayerMode: isPlayerMode,
            responsiveTile: responsiveTile,
            responsiveFontSize: responsiveFontSize,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade900,
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

Widget buildGame7DartsScoreboardTable({
  required TblGame gameConfig,
  required TblGameOptions gameOptions,
  required Box<TblGameScore> gamesScoresBox,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required bool isPlayerMode,
  required double responsiveTile,
  required double responsiveFontSize,
}) {
  final totalColumns = gamePlayers.length + 1;

  return LayoutBuilder(
    builder: (context, constraints) {
      final double calculatedPlayerColWidth =
          (isPlayerMode && gamePlayers.length > 5)
          ? (constraints.maxWidth / (gamePlayers.length + 1)).clamp(
              85.0,
              115.0,
            )
          : 115.0;

      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(responsiveTile * 0.02),
          border: Border.all(
            color: Colors.amber,
            width: responsiveTile * 0.003,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(responsiveTile * 0.02),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.grey.shade700,
                      width: 1,
                    ),
                    verticalInside: BorderSide(
                      color: Colors.grey.shade700,
                      width: 1,
                    ),
                    bottom: BorderSide(color: Colors.grey.shade700, width: 1),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: const FixedColumnWidth(
                      90.0,
                    ), // Compact Targets column width
                    for (int i = 1; i < totalColumns; i++)
                      i: FixedColumnWidth(
                        calculatedPlayerColWidth,
                      ), // Responsive player column width
                  },
                  children: [
                    // --- HEADER ROW ---
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade800),
                      children: [
                        // Targets Header
                        SizedBox(
                          height: responsiveTile * 0.1,
                          child: Center(
                            child: Text(
                              'Rounds',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: responsiveFontSize * 0.75,
                              ),
                            ),
                          ),
                        ),
                        // Player Headers
                        if (isPlayerMode)
                          ...gamePlayers.map(
                            (gp) => SizedBox(
                              height: responsiveTile * 0.1,
                              child: Center(
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsiveTile * 0.008,
                                    vertical: responsiveTile * 0.004,
                                  ),
                                  decoration: BoxDecoration(
                                    color: gp.playerColor,
                                    borderRadius: BorderRadius.circular(
                                      responsiveTile * 0.01,
                                    ),
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    gp.player.fldNickName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: responsiveFontSize * 0.7,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          ...gamePlayers.map((gp) {
                            final teamEntry = gameTeams.firstWhere(
                              (gt) => gt.team.fldPlayers.contains(gp.player),
                            );
                            return SizedBox(
                              height: responsiveTile * 0.1,
                              child: Center(
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsiveTile * 0.008,
                                    vertical: responsiveTile * 0.004,
                                  ),
                                  decoration: BoxDecoration(
                                    color: teamEntry.teamColor,
                                    borderRadius: BorderRadius.circular(
                                      responsiveTile * 0.01,
                                    ),
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    gp.player.fldNickName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: responsiveFontSize * 0.7,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),

                    // --- ROUND ROWS ---
                    ...List.generate(gameOptions.fldNbrRounds, (roundIdx) {
                      return TableRow(
                        children: [
                          SizedBox(
                            height: responsiveTile * 0.09,
                            child: Center(
                              child: Text(
                                '${roundIdx + 1}',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFontSize * 0.7,
                                ),
                              ),
                            ),
                          ),
                          if (isPlayerMode)
                            ...gamePlayers.map((gp) {
                              final records = gamesScoresBox.values
                                  .where(
                                    (s) =>
                                        s.fldGame == gameConfig &&
                                        s.fldPlayer == gp.player &&
                                        s.fldRound == roundIdx &&
                                        s.fldDartIndex >= 0,
                                  )
                                  .toList();

                              final hasCompletedRound = records.any(
                                (s) => s.fldDartIndex == 6,
                              );
                              final latestRecord = records.isNotEmpty
                                  ? records.last
                                  : null;
                              
                              final scoreStr = latestRecord != null
                                  ? '${latestRecord.fldScorePlayerSnapshot}'
                                  : '-';

                              return SizedBox(
                                height: responsiveTile * 0.09,
                                child: Center(
                                  child: hasCompletedRound
                                    ? Text(
                                        scoreStr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize:
                                              responsiveFontSize *
                                              0.7,
                                        ),
                                      )
                                    : Text(
                                        '-',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize:
                                              responsiveFontSize * 0.7,
                                        ),
                                      ),
                                ),
                              );
                            })
                          else
                            ...gamePlayers.map((gp) {
                              final records = gamesScoresBox.values
                                  .where(
                                    (s) =>
                                        s.fldGame == gameConfig &&
                                        s.fldPlayer == gp.player &&
                                        s.fldRound == roundIdx &&
                                        s.fldDartIndex >= 0,
                                  )
                                  .toList();

                              final hasCompletedRound = records.any(
                                (s) => s.fldDartIndex == 6,
                              );
                              final latestRecord = records.isNotEmpty
                                  ? records.last
                                  : null;

                              if (latestRecord != null && hasCompletedRound) {
                                final pScore =
                                    latestRecord.fldScorePlayerSnapshot;
                                final tScore =
                                    latestRecord.fldScoreTeamSnapshot ?? '-';
                                final scoreDisplay =
                                    '$pScore / $tScore'; // Added proper spacing around the slash

                                return SizedBox(
                                  height: responsiveTile * 0.09,
                                  child: Center(
                                    child: Text(
                                        scoreDisplay,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              responsiveFontSize *
                                              0.65,
                                        ),
                                      ),
                                  ),
                                );
                              }

                              return SizedBox(
                                height: responsiveTile * 0.09,
                                child: Center(
                                  child: Text(
                                    '-',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: responsiveFontSize * 0.7,
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void gShowGameHalfItScoreboardDialog({
  required BuildContext context,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required bool isPlayerMode,
  required double responsiveTile,
  required double responsiveFontSize,
}) {
  gClearAllArcadeOverlays();

  showDialog(
    context: context,
    builder: (context) {
      MediaQuery.sizeOf(context);

      return AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: Text(
          isPlayerMode ? "Players Full Scoreboard" : "Teams Full Scoreboard",
          style: gBuildArcadeTextStyle(
            responsiveFontSize,
            gFontWeight: FontWeight.bold,
            gTextColor: Colors.amber,
          ),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: GlobalAppDisplay.safeWidth * 0.9,
          height: GlobalAppDisplay.safeHeight * 0.8,
          child: buildGameHalfItScoreboardTable(
            gameConfig: gameConfig,
            gameOptions: gameOptions,
            gamesScoresBox: gamesScoresBox,
            gamePlayers: gamePlayers,
            gameTeams: gameTeams,
            isPlayerMode: isPlayerMode,
            responsiveTile: responsiveTile,
            responsiveFontSize: responsiveFontSize,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade900,
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

Widget buildGameHalfItScoreboardTable({
  required TblGame gameConfig,
  required TblGameOptions gameOptions,
  required Box<TblGameScore> gamesScoresBox,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required bool isPlayerMode,
  required double responsiveTile,
  required double responsiveFontSize,
}) {
    final totalColumns = gamePlayers.length + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double calculatedPlayerColWidth =
            (isPlayerMode && gamePlayers.length > 5)
            ? (constraints.maxWidth / (gamePlayers.length + 1)).clamp(
                85.0,
                115.0,
              )
            : 115.0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(responsiveTile * 0.02),
            border: Border.all(
              color: Colors.amber,
              width: responsiveTile * 0.003,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(responsiveTile * 0.02),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: Colors.grey.shade700,
                        width: 1,
                      ),
                      verticalInside: BorderSide(
                        color: Colors.grey.shade700,
                        width: 1,
                      ),
                      bottom: BorderSide(color: Colors.grey.shade700, width: 1),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: {
                      0: const FixedColumnWidth(
                        90.0,
                      ), // Compact Targets column width
                      for (int i = 1; i < totalColumns; i++)
                        i: FixedColumnWidth(
                          calculatedPlayerColWidth,
                        ), // Responsive player column width
                    },
                    children: [
                      // --- HEADER ROW ---
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade800),
                        children: [
                          // Targets Header
                          SizedBox(
                            height: responsiveTile * 0.1,
                            child: Center(
                              child: Text(
                                'Targets',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFontSize * 0.75,
                                ),
                              ),
                            ),
                          ),
                          // Player Headers
                          if (isPlayerMode)
                            ...gamePlayers.map(
                              (gp) => SizedBox(
                                height: responsiveTile * 0.1,
                                child: Center(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 2),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsiveTile * 0.008,
                                      vertical: responsiveTile * 0.004,
                                    ),
                                    decoration: BoxDecoration(
                                      color: gp.playerColor,
                                      borderRadius: BorderRadius.circular(
                                        responsiveTile * 0.01,
                                      ),
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      gp.player.fldNickName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: responsiveFontSize * 0.7,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...gamePlayers.map((gp) {
                              final teamEntry = gameTeams.firstWhere(
                                (gt) => gt.team.fldPlayers.contains(gp.player),
                              );
                              return SizedBox(
                                height: responsiveTile * 0.1,
                                child: Center(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 2),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsiveTile * 0.008,
                                      vertical: responsiveTile * 0.004,
                                    ),
                                    decoration: BoxDecoration(
                                      color: teamEntry.teamColor,
                                      borderRadius: BorderRadius.circular(
                                        responsiveTile * 0.01,
                                      ),
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      gp.player.fldNickName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: responsiveFontSize * 0.7,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),

                      // --- START ROW ---
                      TableRow(
                        children: [
                          SizedBox(
                            height: responsiveTile * 0.09,
                            child: Center(
                              child: Text(
                                'Start',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFontSize * 0.7,
                                ),
                              ),
                            ),
                          ),
                          if (isPlayerMode)
                            ...gamePlayers.map(
                              (_) => SizedBox(
                                height: responsiveTile * 0.09,
                                child: Center(
                                  child: Text(
                                    gameOptions.fldStartingScore.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: responsiveFontSize * 0.7,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...gamePlayers.map((_) {
                              final startTeamScore = gameOptions.fldStartingScore * 2;
                              return SizedBox(
                                height: responsiveTile * 0.09,
                                child: Center(
                                  child: Text(
                                    '${gameOptions.fldStartingScore} / $startTeamScore',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: responsiveFontSize * 0.65,
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),

                      // --- TARGET ROWS ---
                      ...List.generate(gTargetsHalf.length, (rowIndex) {
                        final target = gTargetsHalf[rowIndex];
                        final rIdx = rowIndex;

                        return TableRow(
                          children: [
                            SizedBox(
                              height: responsiveTile * 0.09,
                              child: Center(
                                child: Text(
                                  target.label,
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: responsiveFontSize * 0.7,
                                  ),
                                ),
                              ),
                            ),
                            if (isPlayerMode)
                              ...gamePlayers.map((gp) {
                                final records = gamesScoresBox.values
                                    .where(
                                      (s) =>
                                          s.fldGame == gameConfig &&
                                          s.fldPlayer == gp.player &&
                                          s.fldRound == rIdx &&
                                          s.fldDartIndex >= 0,
                                    )
                                    .toList();

                                final hasCompletedRound = records.any(
                                  (s) => s.fldDartIndex == 2,
                                );
                                final latestRecord = records.isNotEmpty
                                    ? records.last
                                    : null;
                                final isHalfIt =
                                    latestRecord?.fldIsHalfIt ?? false;

                                final totalHits = records.fold(
                                  0,
                                  (sum, r) => sum + r.fldHits,
                                );
                                final scoreStr = latestRecord != null
                                    ? '${latestRecord.fldScorePlayerSnapshot}'
                                    : '-';

                                return SizedBox(
                                  height: responsiveTile * 0.09,
                                  child: Center(
                                    child: hasCompletedRound
                                        ? (isHalfIt
                                              ? Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        responsiveTile * 0.01,
                                                    vertical:
                                                        responsiveTile * 0.003,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade700,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          responsiveTile *
                                                              0.02,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    scoreStr,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          responsiveFontSize *
                                                          0.7,
                                                    ),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                responsiveTile *
                                                                0.006,
                                                            vertical: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              responsiveTile *
                                                                  0.012,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white24,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        '$totalHits',
                                                        style: TextStyle(
                                                          color:
                                                              const Color.fromARGB(
                                                                255,
                                                                207,
                                                                20,
                                                                17,
                                                              ),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize:
                                                              responsiveFontSize *
                                                              0.65,
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 2,
                                                          ),
                                                      child: Icon(
                                                        Icons.arrow_right_alt,
                                                        color: Colors.white70,
                                                        size:
                                                            responsiveFontSize *
                                                            0.8,
                                                      ),
                                                    ),
                                                    Text(
                                                      scoreStr,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            responsiveFontSize *
                                                            0.7,
                                                      ),
                                                    ),
                                                  ],
                                                ))
                                        : Text(
                                            '-',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize:
                                                  responsiveFontSize * 0.7,
                                            ),
                                          ),
                                  ),
                                );
                              })
                            else
                              ...gamePlayers.map((gp) {
                                final records = gamesScoresBox.values
                                    .where(
                                      (s) =>
                                          s.fldGame == gameConfig &&
                                          s.fldPlayer == gp.player &&
                                          s.fldRound == rIdx &&
                                          s.fldDartIndex >= 0,
                                    )
                                    .toList();

                                final hasCompletedRound = records.any(
                                  (s) => s.fldDartIndex == 2,
                                );
                                final latestRecord = records.isNotEmpty
                                    ? records.last
                                    : null;

                                if (latestRecord != null && hasCompletedRound) {
                                  final pScore =
                                      latestRecord.fldScorePlayerSnapshot;
                                  final tScore =
                                      latestRecord.fldScoreTeamSnapshot ?? '-';
                                  final isHalfIt = latestRecord.fldIsHalfIt;
                                  final totalHits = records.fold(
                                    0,
                                    (sum, r) => sum + r.fldHits,
                                  );
                                  final scoreDisplay =
                                      '$pScore / $tScore'; // Added proper spacing around the slash

                                  return SizedBox(
                                    height: responsiveTile * 0.09,
                                    child: Center(
                                      child: isHalfIt
                                          ? Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    responsiveTile * 0.01,
                                                vertical:
                                                    responsiveTile * 0.003,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade700,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      responsiveTile * 0.02,
                                                    ),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                scoreDisplay,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      responsiveFontSize *
                                                      0.65,
                                                ),
                                              ),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        responsiveTile * 0.006,
                                                    vertical: 1,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          responsiveTile *
                                                              0.012,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white24,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '$totalHits',
                                                    style: TextStyle(
                                                      color:
                                                          const Color.fromARGB(
                                                            255,
                                                            207,
                                                            20,
                                                            17,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          responsiveFontSize *
                                                          0.6,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 1,
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_right_alt,
                                                    color: Colors.white70,
                                                    size:
                                                        responsiveFontSize *
                                                        0.75,
                                                  ),
                                                ),
                                                Text(
                                                  scoreDisplay,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        responsiveFontSize *
                                                        0.65,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  );
                                }

                                return SizedBox(
                                  height: responsiveTile * 0.09,
                                  child: Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: responsiveFontSize * 0.7,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

void gShowGameAroundClockScoreboardDialog({
  required BuildContext context,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required TblGameOptions gameOptions,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required bool isPlayerMode,
  required double responsiveTile,
  required double responsiveFontSize,
}) {
  gClearAllArcadeOverlays();

  showDialog(
    context: context,
    builder: (context) {
      MediaQuery.sizeOf(context);

      return AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: Text(
          isPlayerMode ? "Players Full Scoreboard" : "Teams Full Scoreboard",
          style: gBuildArcadeTextStyle(
            responsiveFontSize,
            gFontWeight: FontWeight.bold,
            gTextColor: Colors.amber,
          ),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: GlobalAppDisplay.safeWidth * 0.9,
          height: GlobalAppDisplay.safeHeight * 0.8,
          child: buildGameAroundClockScoreboardTable(
            gameConfig: gameConfig,
            gameOptions: gameOptions,
            gamesScoresBox: gamesScoresBox,
            gamePlayers: gamePlayers,
            gameTeams: gameTeams,
            isPlayerMode: isPlayerMode,
            responsiveTile: responsiveTile,
            responsiveFontSize: responsiveFontSize,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade900,
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

Widget buildGameAroundClockScoreboardTable({
  required TblGame gameConfig,
  required TblGameOptions gameOptions,
  required Box<TblGameScore> gamesScoresBox,
  required List<({int originalIndex, TblPlayer player, Color playerColor})> gamePlayers,
  required List<({int originalIndex, TblTeam team, Color teamColor})> gameTeams,
  required bool isPlayerMode,
  required double responsiveTile,
  required double responsiveFontSize,
}) {
  final totalColumns = gamePlayers.length + 1;

  return LayoutBuilder(
    builder: (context, constraints) {
      final double calculatedPlayerColWidth =
          (isPlayerMode && gamePlayers.length > 5)
          ? (constraints.maxWidth / (gamePlayers.length + 1)).clamp(
              85.0,
              115.0,
            )
          : 115.0;

      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(responsiveTile * 0.02),
          border: Border.all(
            color: Colors.amber,
            width: responsiveTile * 0.003,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(responsiveTile * 0.02),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.grey.shade700,
                      width: 1,
                    ),
                    verticalInside: BorderSide(
                      color: Colors.grey.shade700,
                      width: 1,
                    ),
                    bottom: BorderSide(color: Colors.grey.shade700, width: 1),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: const FixedColumnWidth(
                      90.0,
                    ), // Compact Targets column width
                    for (int i = 1; i < totalColumns; i++)
                      i: FixedColumnWidth(
                        calculatedPlayerColWidth,
                      ), // Responsive player column width
                  },
                  children: [
                    // --- HEADER ROW ---
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade800),
                      children: [
                        // Targets Header
                        SizedBox(
                          height: responsiveTile * 0.1,
                          child: Center(
                            child: Text(
                              'Targets',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: responsiveFontSize * 0.75,
                              ),
                            ),
                          ),
                        ),
                        // Player Headers
                        if (isPlayerMode)
                          ...gamePlayers.map(
                            (gp) => SizedBox(
                              height: responsiveTile * 0.1,
                              child: Center(
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsiveTile * 0.008,
                                    vertical: responsiveTile * 0.004,
                                  ),
                                  decoration: BoxDecoration(
                                    color: gp.playerColor,
                                    borderRadius: BorderRadius.circular(
                                      responsiveTile * 0.01,
                                    ),
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    gp.player.fldNickName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: responsiveFontSize * 0.7,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          ...gamePlayers.map((gp) {
                            final teamEntry = gameTeams.firstWhere(
                              (gt) => gt.team.fldPlayers.contains(gp.player),
                            );
                            return SizedBox(
                              height: responsiveTile * 0.1,
                              child: Center(
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsiveTile * 0.008,
                                    vertical: responsiveTile * 0.004,
                                  ),
                                  decoration: BoxDecoration(
                                    color: teamEntry.teamColor,
                                    borderRadius: BorderRadius.circular(
                                      responsiveTile * 0.01,
                                    ),
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    gp.player.fldNickName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: responsiveFontSize * 0.7,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),

                    // --- START ROW ---
                    TableRow(
                      children: [
                        SizedBox(
                          height: responsiveTile * 0.09,
                          child: Center(
                            child: Text(
                              'Start',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: responsiveFontSize * 0.7,
                              ),
                            ),
                          ),
                        ),
                        if (isPlayerMode)
                          ...gamePlayers.map(
                            (_) => SizedBox(
                              height: responsiveTile * 0.09,
                              child: Center(
                                child: Text(
                                  gameOptions.fldStartingScore.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: responsiveFontSize * 0.7,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          ...gamePlayers.map((_) {
                            final startTeamScore = gameOptions.fldStartingScore * 2;
                            return SizedBox(
                              height: responsiveTile * 0.09,
                              child: Center(
                                child: Text(
                                  '${gameOptions.fldStartingScore} / $startTeamScore',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: responsiveFontSize * 0.65,
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),

                    // --- TARGET ROWS ---
                    ...List.generate(gTargetsHalf.length, (rowIndex) {
                      final target = gTargetsHalf[rowIndex];
                      final rIdx = rowIndex;

                      return TableRow(
                        children: [
                          SizedBox(
                            height: responsiveTile * 0.09,
                            child: Center(
                              child: Text(
                                target.label,
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFontSize * 0.7,
                                ),
                              ),
                            ),
                          ),
                          if (isPlayerMode)
                            ...gamePlayers.map((gp) {
                              final records = gamesScoresBox.values
                                  .where(
                                    (s) =>
                                        s.fldGame == gameConfig &&
                                        s.fldPlayer == gp.player &&
                                        s.fldRound == rIdx &&
                                        s.fldDartIndex >= 0,
                                  )
                                  .toList();

                              final hasCompletedRound = records.any(
                                (s) => s.fldDartIndex == 2,
                              );
                              final latestRecord = records.isNotEmpty
                                  ? records.last
                                  : null;
                              final isHalfIt =
                                  latestRecord?.fldIsHalfIt ?? false;

                              final totalHits = records.fold(
                                0,
                                (sum, r) => sum + r.fldHits,
                              );
                              final scoreStr = latestRecord != null
                                  ? '${latestRecord.fldScorePlayerSnapshot}'
                                  : '-';

                              return SizedBox(
                                height: responsiveTile * 0.09,
                                child: Center(
                                  child: hasCompletedRound
                                      ? (isHalfIt
                                            ? Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      responsiveTile * 0.01,
                                                  vertical:
                                                      responsiveTile * 0.003,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade700,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        responsiveTile *
                                                            0.02,
                                                      ),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  scoreStr,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize:
                                                        responsiveFontSize *
                                                        0.7,
                                                  ),
                                                ),
                                              )
                                            : Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal:
                                                              responsiveTile *
                                                              0.006,
                                                          vertical: 1,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            responsiveTile *
                                                                0.012,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.white24,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '$totalHits',
                                                      style: TextStyle(
                                                        color:
                                                            const Color.fromARGB(
                                                              255,
                                                              207,
                                                              20,
                                                              17,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            responsiveFontSize *
                                                            0.65,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 2,
                                                        ),
                                                    child: Icon(
                                                      Icons.arrow_right_alt,
                                                      color: Colors.white70,
                                                      size:
                                                          responsiveFontSize *
                                                          0.8,
                                                    ),
                                                  ),
                                                  Text(
                                                    scoreStr,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          responsiveFontSize *
                                                          0.7,
                                                    ),
                                                  ),
                                                ],
                                              ))
                                      : Text(
                                          '-',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize:
                                                responsiveFontSize * 0.7,
                                          ),
                                        ),
                                ),
                              );
                            })
                          else
                            ...gamePlayers.map((gp) {
                              final records = gamesScoresBox.values
                                  .where(
                                    (s) =>
                                        s.fldGame == gameConfig &&
                                        s.fldPlayer == gp.player &&
                                        s.fldRound == rIdx &&
                                        s.fldDartIndex >= 0,
                                  )
                                  .toList();

                              final hasCompletedRound = records.any(
                                (s) => s.fldDartIndex == 2,
                              );
                              final latestRecord = records.isNotEmpty
                                  ? records.last
                                  : null;

                              if (latestRecord != null && hasCompletedRound) {
                                final pScore =
                                    latestRecord.fldScorePlayerSnapshot;
                                final tScore =
                                    latestRecord.fldScoreTeamSnapshot ?? '-';
                                final isHalfIt = latestRecord.fldIsHalfIt;
                                final totalHits = records.fold(
                                  0,
                                  (sum, r) => sum + r.fldHits,
                                );
                                final scoreDisplay =
                                    '$pScore / $tScore'; // Added proper spacing around the slash

                                return SizedBox(
                                  height: responsiveTile * 0.09,
                                  child: Center(
                                    child: isHalfIt
                                        ? Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  responsiveTile * 0.01,
                                              vertical:
                                                  responsiveTile * 0.003,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade700,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    responsiveTile * 0.02,
                                                  ),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              scoreDisplay,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    responsiveFontSize *
                                                    0.65,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      responsiveTile * 0.006,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        responsiveTile *
                                                            0.012,
                                                      ),
                                                  border: Border.all(
                                                    color: Colors.white24,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  '$totalHits',
                                                  style: TextStyle(
                                                    color:
                                                        const Color.fromARGB(
                                                          255,
                                                          207,
                                                          20,
                                                          17,
                                                        ),
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize:
                                                        responsiveFontSize *
                                                        0.6,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 1,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_right_alt,
                                                  color: Colors.white70,
                                                  size:
                                                      responsiveFontSize *
                                                      0.75,
                                                ),
                                              ),
                                              Text(
                                                scoreDisplay,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      responsiveFontSize *
                                                      0.65,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              }

                              return SizedBox(
                                height: responsiveTile * 0.09,
                                child: Center(
                                  child: Text(
                                    '-',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: responsiveFontSize * 0.7,
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}