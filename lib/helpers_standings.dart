// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_score.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/database/enum_game_type.dart';
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_dartboard.dart';
import 'package:darts_101/helpers_ui.dart';

class GameResultRecord<objRef> {
  final objRef objReference;
  final int originalIndex;
  final String displayName;
  final int lastScore;
  final Color color;
  final int playerPosition1;
  final int playerPosition2;
  final int triplesCount;
  final int doublesCount;
  final int hitsBull;
  final String? nextTargetLabel;
  int ranking;

  GameResultRecord({
    required this.objReference,
    required this.originalIndex,
    required this.displayName,
    required this.lastScore,
    required this.color,
    required this.playerPosition1,
    this.playerPosition2 = 0,
    this.triplesCount = 0,
    this.doublesCount = 0,
    this.hitsBull = 0,
    this.nextTargetLabel,
    this.ranking = 999,
  });
}

// Around the Clock progress: (rank value, label). The winner has no next target left.
({int progress, String label}) _acProgress(
  TblGame gameConfig,
  Iterable<TblGameScore> scores,
) {
  final targets = gGetTargetsForGame(gameConfig);
  final played = scores.where((s) => s.fldRound >= 0).toList();
  if (played.isEmpty) return (progress: 0, label: targets.first.label);

  final last = played.last;
  if (last.fldNextTargetIndex == null) {
    return (progress: targets.length, label: 'WIN');
  }
  final idx = last.fldNextTargetIndex!;
  return (progress: idx, label: targets[idx].label);
}

List<GameResultRecord> gComputeGameResults({
  required TblGame gameConfig,
  required List<dynamic> gamePlayers,
  required List<dynamic> gameTeams,
}) {
  final gamesScoresBox = Hive.box<TblGameScore>('gamesScoresBox');

  // 1. We'll store the results in a list of Map for easy sorting
  List<GameResultRecord> finalResults = [];

  if (gameConfig.fldPlayersGM) {
    for (var gamePlayer in gamePlayers) {
      final playerScores = gamesScoresBox.values.where(
        (s) => s.fldGame == gameConfig && s.fldPlayer == gamePlayer.player,
      );

      final isAC = gameConfig.fldGameType == GlobalGameType.aroundClock ||
          gameConfig.fldGameType == GlobalGameType.buildUp;
      final ac = isAC ? _acProgress(gameConfig, playerScores) : null;
      final lastScore =
          ac?.progress ?? playerScores.last.fldScorePlayerSnapshot;

      int triples = 0;
      int doubles = 0;
      int hitsBull = 0;

      for (var score in playerScores) {
        if (score.fldIsTriple) triples++;
        if (score.fldIsDouble) doubles++;
        if (score.fldTargetValue == 25) hitsBull += score.fldHits;
      }

      finalResults.add(
        GameResultRecord(
          objReference: gamePlayer.player,
          originalIndex: gamePlayer.originalIndex,
          playerPosition1: gamePlayer.originalIndex,
          displayName: gamePlayer.player.fldNickName,
          lastScore: lastScore,
          color: gamePlayer.playerColor,
          triplesCount: triples,
          doublesCount: doubles,
          hitsBull: hitsBull,
          nextTargetLabel: ac?.label,
        ),
      );
    }
  } else {
    for (var gameTeam in gameTeams) {
      final teamPlayers = gameTeam.team.fldPlayers;

      final teamScores = gamesScoresBox.values.where(
        (s) => s.fldGame == gameConfig && teamPlayers.contains(s.fldPlayer),
      );

      final isAC = gameConfig.fldGameType == GlobalGameType.aroundClock;
      final ac = isAC ? _acProgress(gameConfig, teamScores) : null;
      final lastScore = ac?.progress ?? teamScores.last.fldScoreTeamSnapshot!;

      int triples = 0;
      int doubles = 0;
      int hitsBull = 0;

      for (var score in teamScores) {
        if (score.fldIsTriple) triples++;
        if (score.fldIsDouble) doubles++;
        if (score.fldTargetValue == 25) hitsBull += score.fldHits;
      }

      int playerPosition1 = 0;
      int playerPosition2 = 0;

      // verify if dummy
      if (teamPlayers[0] == teamPlayers[1]) {
        playerPosition1 = gamePlayers.indexWhere(
          (gp) => gp.player == teamPlayers[0],
        );
        playerPosition2 = playerPosition1 + (gamePlayers.length ~/ 2);
      } else {
        playerPosition1 = gamePlayers.indexWhere(
          (gp) => gp.player == teamPlayers[0],
        );
        playerPosition2 = gamePlayers.indexWhere(
          (gp) => gp.player == teamPlayers[1],
        );
      }

      finalResults.add(
        GameResultRecord(
          objReference: gameTeam.team,
          originalIndex: gameTeam.originalIndex,
          playerPosition1: playerPosition1,
          playerPosition2: playerPosition2,
          displayName:
              '${teamPlayers[0].fldNickName} & ${teamPlayers[1].fldNickName}',
          lastScore: lastScore,
          color: gameTeam.teamColor,
          triplesCount: triples,
          doublesCount: doubles,
          hitsBull: hitsBull,
          nextTargetLabel: ac?.label,
        ),
      );
    }
  }

  // 2. Sort results (Highest score first; Around the Clock ranks on progress only)
  final bool progressOnly =
      gameConfig.fldGameType == GlobalGameType.aroundClock;
  finalResults.sort((a, b) {
    if (b.lastScore != a.lastScore) {
      return b.lastScore.compareTo(a.lastScore);
    }
    if (progressOnly) return 0;
    if (b.triplesCount != a.triplesCount) {
      return b.triplesCount.compareTo(a.triplesCount);
    }
    if (b.doublesCount != a.doublesCount) {
      return b.doublesCount.compareTo(a.doublesCount);
    }
    return b.hitsBull.compareTo(a.hitsBull);
  });

  // 3. Compute proper rankings handling ties
  int currentRank = 1;
  for (int i = 0; i < finalResults.length; i++) {
    if (i > 0) {
      final prev = finalResults[i - 1];
      final curr = finalResults[i];
      bool isIdentical =
          (curr.lastScore == prev.lastScore &&
          (progressOnly ||
              (curr.triplesCount == prev.triplesCount &&
                  curr.doublesCount == prev.doublesCount &&
                  curr.hitsBull == prev.hitsBull)));
      if (!isIdentical) {
        currentRank = i + 1;
      }
    }
    finalResults[i].ranking = currentRank; // Direct write!
  }

  return finalResults;
}

void gShowStandingsDialog({
  required BuildContext context,
  required TblGame gameConfig,
  required List<GameResultRecord> finalResults,
  required VoidCallback onUndoLastThrow,
  required double responsiveTile,
  required double responsiveFontSize,
  required double avatarHeight,
  required double avatarHeightOuterSize,
  required double avatarSlicedWidth,
  required double avatarSlicedWidthOuterSize,
  required double cardHeight,
  required double cardWidth,
  required double cardWidthOuterSize,
  required double cardSlicedHeight,
  required double cardSlicedHeightOuterSize,
}) {
  final isPlayerMode = gameConfig.fldPlayersGM;

  // 1. Extract top record & collect all winners (handles ties)
  final bool isAC = gameConfig.fldGameType == GlobalGameType.aroundClock;
  final topScore = finalResults.first;

  final List<GameResultRecord> winners = finalResults
      .where(
        (result) =>
            result.lastScore == topScore.lastScore &&
            (isAC ||
                (result.triplesCount == topScore.triplesCount &&
                    result.doublesCount == topScore.doublesCount &&
                    result.hitsBull == topScore.hitsBull)),
      )
      .toList();

  final bool isTie = winners.length > 1;

  // 2. Prepare winning players and winning teams locally for the dialog
  List<TblPlayer> winningPlayers = [];
  List<TblTeam> winningTeams = [];

  if (gameConfig.fldPlayersGM) {
    winningPlayers = winners.map((r) => r.objReference as TblPlayer).toList();
  } else {
    winningTeams = winners.map((r) => r.objReference as TblTeam).toList();

    for (var record in winners) {
      final team = record.objReference as TblTeam;

      // If it's a dummy team dummy
      if (team.fldPlayers[0] == team.fldPlayers[1]) {
        winningPlayers.add(team.fldPlayers[0]);
      } else {
        winningPlayers.add(team.fldPlayers[0]);
        winningPlayers.add(team.fldPlayers[1]);
      }
    }
  }

  void gameClosed() {
    // Save the winning teams if in team mode
    if (!gameConfig.fldPlayersGM) {
      gameConfig.fldTeamsWinner = winningTeams;
    }

    // Save and end the game :)
    gameConfig.fldPlayersWinner = winningPlayers;
    gameConfig.fldIsEnded = true;
    gameConfig.save();

    // 2. Clear the Navigation stack back to the very first screen
    // This will dismiss the Dialog AND the GameScoreScreen in one go.
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
  }

  Widget buildWinnerTopBanner({
    required List<GameResultRecord<dynamic>> winners,
    required List<TblPlayer> winningPlayers,
    required List<TblTeam> winningTeams,
  }) {
    final bool isTie = winners.length > 1;

    return Container(
      decoration: BoxDecoration(
        color: (winners[0].color).withAlpha(100),
        borderRadius: BorderRadius.circular(responsiveTile * 0.03),
      ),
      child: Row(
        children: [
          SizedBox(width: responsiveTile * 0.01),

          // Save button
          SizedBox(
            width: responsiveTile * 0.18,
            height: responsiveTile * 0.18,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                elevation: 4,
              ),
              onPressed: () {
                gameClosed();
              },
              child: Center(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: responsiveTile * 0.015,
                              offset: Offset(
                                responsiveTile * 0.003,
                                responsiveTile * 0.003,
                              ), // Casts shadow upward onto the screen content
                            ),
                          ],
                        ),
                      ),
                    ),

                    Image.asset(
                      'assets/png/mechanics/save_game.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: responsiveTile * 0.01,
                    horizontal: responsiveTile * 0.03,
                  ),
                  decoration: BoxDecoration(
                    color: (winners[0].color).withAlpha(220),
                    borderRadius: BorderRadius.circular(responsiveTile * 0.015),
                  ),
                  child: Text(
                    isTie
                        ? "IT'S A TIE!"
                        : isPlayerMode
                        ? "WINNER"
                        : "WINNERS",
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize * 1.1,
                      gFontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          if (!isTie) ...[
            Expanded(
              child: Column(
                children: [
                  if (isPlayerMode) ...[
                    gBuildSlicedPlayerAvatarH(
                      player: winners[0].objReference,
                      avatarHeight: avatarHeight,
                      avatarHeightOuterSize: avatarHeightOuterSize,
                      avatarSlicedWidth: avatarSlicedWidth,
                      avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                      slotBgColor: winners[0].color,
                      playerPosition: winners[0].playerPosition1,
                      responsiveTile: responsiveTile,
                      isTagNickNameLeft: true,
                      isEmptyPanel: false,
                    ),
                  ] else ...[
                    gBuildSlicedTeamCardH(
                      team: winners[0].objReference,
                      cardHeight: cardHeight,
                      cardWidth: cardWidth,
                      cardWidthOuterSize: cardWidthOuterSize,
                      cardSlicedHeight: cardSlicedHeight,
                      cardSlicedHeightOuterSize: cardSlicedHeightOuterSize,
                      slotBgColor: winners[0].color,
                      teamPosition: winners[0].originalIndex,
                      responsiveTile: responsiveTile,
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (!isTie) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: responsiveTile * 0.01,
                      horizontal: responsiveTile * 0.03,
                    ),
                    decoration: BoxDecoration(
                      color: (winners[0].color).withAlpha(220),
                      borderRadius: BorderRadius.circular(
                        responsiveTile * 0.015,
                      ),
                    ),
                    child: Text(
                      isPlayerMode ? "WINNER" : "WINNERS",
                      style: gBuildArcadeTextStyle(
                        responsiveFontSize * 1.1,
                        gFontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Undo Button
          SizedBox(
            width: responsiveTile * 0.18,
            height: responsiveTile * 0.18,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                elevation: 4,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onUndoLastThrow();
              },
              child: Center(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: responsiveTile * 0.015,
                              offset: Offset(
                                responsiveTile * 0.003,
                                responsiveTile * 0.003,
                              ), // Casts shadow upward onto the screen content
                            ),
                          ],
                        ),
                      ),
                    ),

                    Image.asset(
                      'assets/png/mechanics/undo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: responsiveTile * 0.01),
        ],
      ),
    );
  }

  Widget buildStandingsHeader(
    int headerFlex,
    String headerText,
    TextAlign headerAlign,
    bool isTie,
  ) {
    return Expanded(
      flex: headerFlex,
      child: Text(
        headerText,
        textAlign: headerAlign,
        style: gBuildArcadeTextStyle(
          (responsiveFontSize * 0.6).clamp(responsiveFontSize * 0.5, 60),
          gFontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildStandingsData(
    int dataFlex,
    String dataText,
    TextAlign dataAlign,
    bool isWinner,
    bool isTie,
    bool isOverflow,
  ) {
    return Expanded(
      flex: dataFlex,
      child: Text(
        dataText,
        textAlign: dataAlign,
        style: TextStyle(
          fontSize: responsiveFontSize * 0.8,
          fontWeight: FontWeight.bold,
          color: isWinner ? Colors.white : Colors.black,
        ),
        overflow: isOverflow ? TextOverflow.ellipsis : TextOverflow.visible,
      ),
    );
  }

  Widget buildCreateListResults(
    GameResultRecord<dynamic> res,
    bool isWinner,
    bool isTie,
  ) {
    final int headerFlex = isPlayerMode
        ? 2
        : isTie
        ? 2
        : 1;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: responsiveTile * 0.01,
        horizontal: responsiveTile * 0.015,
      ),
      margin: EdgeInsets.symmetric(vertical: responsiveTile * 0.001),
      decoration: BoxDecoration(
        color: isWinner ? res.color : Colors.transparent,
        borderRadius: BorderRadius.circular(responsiveTile * 0.01),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildStandingsData(
            headerFlex,
            "${res.ranking}.",
            TextAlign.center,
            isWinner,
            isTie,
            false,
          ),
          buildStandingsData(
            isPlayerMode
                ? 5
                : isTie
                ? 5
                : 4,
            res.displayName,
            TextAlign.left,
            isWinner,
            isTie,
            true,
          ),
          buildStandingsData(
            headerFlex,
            "${res.triplesCount}",
            TextAlign.center,
            isWinner,
            isTie,
            false,
          ),
          buildStandingsData(
            headerFlex,
            "${res.doublesCount}",
            TextAlign.center,
            isWinner,
            isTie,
            false,
          ),
          buildStandingsData(
            headerFlex,
            "${res.hitsBull}",
            TextAlign.center,
            isWinner,
            isTie,
            false,
          ),
          buildStandingsData(
            headerFlex,
            res.nextTargetLabel ?? "${res.lastScore}",
            TextAlign.right,
            isWinner,
            isTie,
            false,
          ),
        ],
      ),
    );
  }

  final int headerFlex = isPlayerMode
      ? 2
      : isTie
      ? 2
      : 1;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsiveTile * 0.03),
      ),
      // We leave 'title' and 'actions' null to give all space to 'content'
      content: SizedBox(
        width: GlobalAppDisplay.safeWidth * 0.9,
        height: GlobalAppDisplay.safeHeight * 0.9,
        child: Padding(
          padding: EdgeInsets.all(responsiveTile * 0.03),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildWinnerTopBanner(
                winners: winners,
                winningPlayers: winningPlayers,
                winningTeams: winningTeams,
              ),

              SizedBox(height: responsiveTile * 0.03),

              Expanded(
                child: Row(
                  children: [
                    // Left Trophy
                    Column(
                      children: [
                        if (!isPlayerMode) ...[
                          if (!isTie) ...[
                            gBuildSlicedPlayerAvatarH(
                              player: winners[0].objReference.fldPlayers[0],
                              avatarHeight: avatarHeight,
                              avatarHeightOuterSize: avatarHeightOuterSize,
                              avatarSlicedWidth: avatarSlicedWidth,
                              avatarSlicedWidthOuterSize:
                                  avatarSlicedWidthOuterSize,
                              slotBgColor: winners[0].color,
                              playerPosition: winners[0].playerPosition1,
                              responsiveTile: responsiveTile,
                              isTagNickNameLeft: true,
                              isEmptyPanel: false,
                            ),

                            SizedBox(height: responsiveTile * 0.02),
                          ],
                        ],

                        Center(
                          child: SizedBox(
                            height: responsiveTile * 0.3,
                            width: responsiveTile * 0.3,
                            child: Image.asset(
                              'assets/png/mechanics/trophy.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(width: responsiveTile * 0.02),

                    // Final Standings
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: (winners[0].color).withAlpha(100),
                          borderRadius: BorderRadius.circular(
                            responsiveTile * 0.03,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Fixed part: title + header
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                responsiveTile * 0.005,
                                responsiveTile * 0.005,
                                responsiveTile * 0.005,
                                0,
                              ),
                              child: Column(
                                children: [
                                  // 3. STANDINGS LIST
                                  Container(
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(
                                      vertical: responsiveTile * 0.01,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (winners[0].color).withAlpha(220),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(
                                          responsiveTile * 0.025,
                                        ),
                                        bottom: Radius.zero,
                                      ),
                                    ),
                                    child: Text(
                                      "FINAL STANDINGS",
                                      style: gBuildArcadeTextStyle(
                                        responsiveFontSize,
                                        gFontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: responsiveTile * 0.015),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      buildStandingsHeader(
                                        headerFlex,
                                        "RANK",
                                        TextAlign.center,
                                        isTie,
                                      ),
                                      buildStandingsHeader(
                                        isPlayerMode
                                            ? 5
                                            : isTie
                                            ? 5
                                            : 4,
                                        !isPlayerMode ? "TEAMS" : "PLAYERS",
                                        TextAlign.left,
                                        isTie,
                                      ),
                                      buildStandingsHeader(
                                        headerFlex,
                                        isPlayerMode
                                            ? "TRIPLES"
                                            : isTie
                                            ? "TRIPLES"
                                            : "TRP",
                                        TextAlign.center,
                                        isTie,
                                      ),
                                      buildStandingsHeader(
                                        headerFlex,
                                        isPlayerMode
                                            ? "DOUBLES"
                                            : isTie
                                            ? "DOUBLES"
                                            : "DBL",
                                        TextAlign.center,
                                        isTie,
                                      ),
                                      buildStandingsHeader(
                                        headerFlex,
                                        "BULLS",
                                        TextAlign.center,
                                        isTie,
                                      ),
                                      buildStandingsHeader(
                                        headerFlex,
                                        isAC
                                            ? "TARGET"
                                            : isPlayerMode
                                            ? "POINTS"
                                            : isTie
                                            ? "POINTS"
                                            : "PTS",
                                        TextAlign.right,
                                        isTie,
                                      ),
                                    ],
                                  ),

                                  const Divider(color: Colors.white),
                                ],
                              ),
                            ),

                            // Scrollable part: takes the remaining height
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsiveTile * 0.005,
                                ),
                                child: Column(
                                  children: [
                                    ...finalResults.map((res) {
                                      final bool isWinner = res.ranking == 1;

                                      return buildCreateListResults(
                                        res,
                                        isWinner,
                                        isTie,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: responsiveTile * 0.02),

                    // Right Trophy
                    Column(
                      children: [
                        if (!isPlayerMode) ...[
                          if (!isTie) ...[
                            gBuildSlicedPlayerAvatarH(
                              player: winners[0].objReference.fldPlayers[1],
                              avatarHeight: avatarHeight,
                              avatarHeightOuterSize: avatarHeightOuterSize,
                              avatarSlicedWidth: avatarSlicedWidth,
                              avatarSlicedWidthOuterSize:
                                  avatarSlicedWidthOuterSize,
                              slotBgColor: winners[0].color,
                              playerPosition: winners[0].playerPosition2,
                              responsiveTile: responsiveTile,
                              isTagNickNameLeft: true,
                              isEmptyPanel: false,
                            ),

                            SizedBox(height: responsiveTile * 0.02),
                          ],
                        ],

                        Center(
                          child: SizedBox(
                            height: responsiveTile * 0.3,
                            width: responsiveTile * 0.3,
                            child: Image.asset(
                              'assets/png/mechanics/trophy.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Standings of the Build Up game (league opener): same look as
// gshowStandingsDialog, plus a closest-to-the-bull pick for tied players and
// the proposed teams of the night, saved in gSelectedTeams.
void gShowBuildUpStandingsDialog({
  required BuildContext context,
  required TblGame gameConfig,
  required List<GameResultRecord> results,
  required TblPlayer winner,
  required VoidCallback onUndoLastThrow,
  required double responsiveTile,
  required double responsiveFontSize,
  required double avatarHeight,
  required double avatarHeightOuterSize,
  required double avatarSlicedWidth,
  required double avatarSlicedWidthOuterSize,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BuildUpStandingsDialog(
      gameConfig: gameConfig,
      results: results,
      winner: winner,
      onUndoLastThrow: onUndoLastThrow,
      responsiveTile: responsiveTile,
      responsiveFontSize: responsiveFontSize,
      avatarHeight: avatarHeight,
      avatarHeightOuterSize: avatarHeightOuterSize,
      avatarSlicedWidth: avatarSlicedWidth,
      avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
    ),
  );
}

class _BuildUpStandingsDialog extends StatefulWidget {
  final TblGame gameConfig;
  final List<GameResultRecord> results;
  final TblPlayer winner;
  final VoidCallback onUndoLastThrow;
  final double responsiveTile;
  final double responsiveFontSize;
  final double avatarHeight;
  final double avatarHeightOuterSize;
  final double avatarSlicedWidth;
  final double avatarSlicedWidthOuterSize;

  const _BuildUpStandingsDialog({
    required this.gameConfig,
    required this.results,
    required this.winner,
    required this.onUndoLastThrow,
    required this.responsiveTile,
    required this.responsiveFontSize,
    required this.avatarHeight,
    required this.avatarHeightOuterSize,
    required this.avatarSlicedWidth,
    required this.avatarSlicedWidthOuterSize,
  });

  @override
  State<_BuildUpStandingsDialog> createState() =>
      _BuildUpStandingsDialogState();
}

class _BuildUpStandingsDialogState extends State<_BuildUpStandingsDialog> {
  // Groups of players with identical stats, in rank order. _picked holds the
  // players already placed by a tiebreaker, _remaining the ones still tied.
  final List<List<GameResultRecord>> _picked = [];
  final List<List<GameResultRecord>> _remaining = [];

  // Odd player count: false = winner alone, true = middle player alone
  // Odd player count: on = winner alone (default), off = middle player alone
  bool _winnerAlone = true;

  double get _tile => widget.responsiveTile;
  double get _font => widget.responsiveFontSize;

  List<GameResultRecord> get _ordered => [
    for (int g = 0; g < _picked.length; g++) ...[
      ..._picked[g],
      ..._remaining[g],
    ],
  ];

  // Players still tied share the same rank until the tiebreaker decides
  List<int> get _ranks {
    final ranks = <int>[];
    int start = 1;
    for (int g = 0; g < _picked.length; g++) {
      for (int i = 0; i < _picked[g].length; i++) {
        ranks.add(start + i);
      }
      for (int i = 0; i < _remaining[g].length; i++) {
        ranks.add(start + _picked[g].length);
      }
      start += _picked[g].length + _remaining[g].length;
    }
    return ranks;
  }

  // Index of the first group still needing a tiebreaker (-1 when all done)
  int get _currentIdx => _remaining.indexWhere((g) => g.length > 1);
  bool get _isResolved => _currentIdx == -1;

  @override
  void initState() {
    super.initState();

    final winnerRecord = widget.results.firstWhere(
      (r) => r.objReference == widget.winner,
    );
    _addGroup([winnerRecord]);

    final others = widget.results.where((r) => r != winnerRecord).toList()
      ..sort(_compareStats);

    int i = 0;
    while (i < others.length) {
      int j = i + 1;
      while (j < others.length && _compareStats(others[i], others[j]) == 0) {
        j++;
      }
      _addGroup(others.sublist(i, j));
      i = j;
    }
  }

  void _addGroup(List<GameResultRecord> group) {
    _picked.add(group.length == 1 ? group : []);
    _remaining.add(group.length == 1 ? [] : group);
  }

  int _compareStats(GameResultRecord a, GameResultRecord b) {
    if (b.lastScore != a.lastScore) return b.lastScore.compareTo(a.lastScore);
    if (b.triplesCount != a.triplesCount) {
      return b.triplesCount.compareTo(a.triplesCount);
    }
    if (b.doublesCount != a.doublesCount) {
      return b.doublesCount.compareTo(a.doublesCount);
    }
    if (b.hitsBull != a.hitsBull) return b.hitsBull.compareTo(a.hitsBull);
    // Same progress: the player who needed fewer darts ranks higher
    return _playerRoundsDarts(a).darts.compareTo(_playerRoundsDarts(b).darts);
  }

  // Rank being decided in the group currently resolved
  int get _currentGroupRank {
    final idx = _currentIdx;
    int rank = 1;
    for (int g = 0; g < idx; g++) {
      rank += _picked[g].length + _remaining[g].length;
    }
    return rank + _picked[idx].length;
  }

  void _pickClosest(GameResultRecord picked) {
    setState(() {
      final idx = _currentIdx;
      _picked[idx].add(picked);
      _remaining[idx].remove(picked);
      // The last player of a group needs no throw
      if (_remaining[idx].length == 1) {
        _picked[idx].add(_remaining[idx].removeLast());
      }
    });
  }

  // Pairs the ranking from the outside in: best with worst, and so on
  List<List<GameResultRecord>> _buildTeams() {
    final players = List.of(_ordered);
    final List<List<GameResultRecord>> teams = [];

    List<GameResultRecord>? soloTeam;
    if (players.length.isOdd) {
      final soloIdx = _winnerAlone ? 0 : players.length ~/ 2;
      soloTeam = [players.removeAt(soloIdx)];
    }
    for (int i = 0; i < players.length ~/ 2; i++) {
      teams.add([players[i], players[players.length - 1 - i]]);
    }
    // The winner alone stays on top, the middle player goes at the bottom
    if (soloTeam != null) {
      _winnerAlone ? teams.insert(0, soloTeam) : teams.add(soloTeam);
    }
    return teams;
  }

  // Existing active team of these players, or a new one (solo = dummy team)
  Future<TblTeam> _findOrCreateTeam(List<GameResultRecord> members) async {
    final teamsBox = Hive.box<TblTeam>('teamsBox');
    final p1 = members.first.objReference as TblPlayer;
    final p2 = members.length > 1
        ? members[1].objReference as TblPlayer
        : p1;

    final existing = teamsBox.values
        .where(
          (t) =>
              !t.fldIsDeleted &&
              ((t.fldPlayers[0] == p1 && t.fldPlayers[1] == p2) ||
                  (t.fldPlayers[0] == p2 && t.fldPlayers[1] == p1)),
        )
        .firstOrNull;
    if (existing != null) return existing;

    final team = TblTeam(fldPlayers: [p1, p2]);
    await teamsBox.add(team);
    return team;
  }

  Future<void> _saveGame() async {
    final teams = <TblTeam>[];
    for (final members in _buildTeams()) {
      teams.add(await _findOrCreateTeam(members));
    }
    GlobalLeagueSession.setTeams(teams);

    widget.gameConfig.fldPlayersWinner = [widget.winner];
    widget.gameConfig.fldIsEnded = true;
    await widget.gameConfig.save();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  }

  Widget _avatar(GameResultRecord r) => gBuildSlicedPlayerAvatarH(
    player: r.objReference,
    avatarHeight: widget.avatarHeight,
    avatarHeightOuterSize: widget.avatarHeightOuterSize,
    avatarSlicedWidth: widget.avatarSlicedWidth,
    avatarSlicedWidthOuterSize: widget.avatarSlicedWidthOuterSize,
    slotBgColor: r.color,
    playerPosition: r.playerPosition1,
    responsiveTile: _tile,
    isTagNickNameLeft: true,
    isEmptyPanel: false,
  );

  Widget _imageButton(String asset, VoidCallback? onPressed) {
    return SizedBox(
      width: _tile * 0.18,
      height: _tile * 0.18,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Opacity(
          opacity: onPressed == null ? 0.4 : 1,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color, {double scale = 1.1}) => Container(
    padding: EdgeInsets.symmetric(
      vertical: _tile * 0.01,
      horizontal: _tile * 0.03,
    ),
    decoration: BoxDecoration(
      color: color.withAlpha(220),
      borderRadius: BorderRadius.circular(_tile * 0.015),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: gBuildArcadeTextStyle(_font * scale, gFontWeight: FontWeight.bold),
    ),
  );

  Widget _buildTopBanner(GameResultRecord winnerRecord) {
    return Container(
      decoration: BoxDecoration(
        color: winnerRecord.color.withAlpha(100),
        borderRadius: BorderRadius.circular(_tile * 0.03),
      ),
      child: Row(
        children: [
          SizedBox(width: _tile * 0.01),
          _imageButton(
            'assets/png/mechanics/save_game.png',
            _isResolved ? _saveGame : null,
          ),
          Expanded(
            child: Center(child: _label('WINNER', winnerRecord.color)),
          ),
          Expanded(child: Column(children: [_avatar(winnerRecord)])),
          Expanded(
            child: Center(child: _label('WINNER', winnerRecord.color)),
          ),
          _imageButton('assets/png/mechanics/undo.png', () {
            Navigator.of(context).pop();
            widget.onUndoLastThrow();
          }),
          SizedBox(width: _tile * 0.01),
        ],
      ),
    );
  }

  Widget _header(int flex, String text, TextAlign align) => Expanded(
    flex: flex,
    child: Text(
      text,
      textAlign: align,
      style: gBuildArcadeTextStyle(
        (_font * 0.6).clamp(_font * 0.5, 60),
        gFontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _data(int flex, String text, TextAlign align, bool isWinner,
      {bool overflow = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: _font * 0.8,
          fontWeight: FontWeight.bold,
          color: isWinner ? Colors.white : Colors.black,
        ),
        overflow: overflow ? TextOverflow.ellipsis : TextOverflow.visible,
      ),
    );
  }

  // Rounds reached and darts thrown by a player (after any rollback)
  ({int rounds, int darts}) _playerRoundsDarts(GameResultRecord res) {
    final scores = Hive.box<TblGameScore>('gamesScoresBox').values.where(
      (s) =>
          s.fldGame == widget.gameConfig &&
          s.fldPlayer == res.objReference &&
          s.fldRound >= 0,
    );
    if (scores.isEmpty) return (rounds: 0, darts: 0);
    final maxRound = scores.map((s) => s.fldRound).reduce((a, b) => a > b ? a : b);
    return (rounds: maxRound + 1, darts: scores.length);
  }

  Widget _buildRow(int rank, GameResultRecord res) {
    final isWinner = rank == 1;
    final stats = _playerRoundsDarts(res);
    // Only the winner shows WIN; a player who hit BULL later just shows BULL
    final label = res.nextTargetLabel == 'WIN' && !isWinner
        ? 'BULL ✓'
        : (res.nextTargetLabel ?? '${res.lastScore}');
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: _tile * 0.01,
        horizontal: _tile * 0.015,
      ),
      margin: EdgeInsets.symmetric(vertical: _tile * 0.001),
      decoration: BoxDecoration(
        color: isWinner ? res.color : Colors.transparent,
        borderRadius: BorderRadius.circular(_tile * 0.01),
      ),
      child: Row(
        children: [
          _data(2, '$rank.', TextAlign.center, isWinner),
          _data(5, res.displayName, TextAlign.left, isWinner, overflow: true),
          _data(2, '${res.triplesCount}', TextAlign.center, isWinner),
          _data(2, '${res.doublesCount}', TextAlign.center, isWinner),
          _data(2, '${res.hitsBull}', TextAlign.center, isWinner),
          _data(2, '${stats.rounds}', TextAlign.center, isWinner),
          _data(2, '${stats.darts}', TextAlign.center, isWinner),
          _data(3, label, TextAlign.right, isWinner),
        ],
      ),
    );
  }

  Widget _buildStandingsPanel(GameResultRecord winnerRecord) {
    final ordered = _ordered;
    final ranks = _ranks;
    return Container(
      decoration: BoxDecoration(
        color: winnerRecord.color.withAlpha(100),
        borderRadius: BorderRadius.circular(_tile * 0.03),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              _tile * 0.005,
              _tile * 0.005,
              _tile * 0.005,
              0,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: _tile * 0.01),
                  decoration: BoxDecoration(
                    color: winnerRecord.color.withAlpha(220),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_tile * 0.025),
                    ),
                  ),
                  child: Text(
                    'FINAL STANDINGS',
                    style: gBuildArcadeTextStyle(
                      _font,
                      gFontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: _tile * 0.015),
                Row(
                  children: [
                    _header(2, 'RANK', TextAlign.center),
                    _header(5, 'PLAYERS', TextAlign.left),
                    _header(2, 'TRP', TextAlign.center),
                    _header(2, 'DBL', TextAlign.center),
                    _header(2, 'BULLS', TextAlign.center),
                    _header(2, 'RND', TextAlign.center),
                    _header(2, 'DARTS', TextAlign.center),
                    _header(3, 'TARGET', TextAlign.right),
                  ],
                ),
                const Divider(color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: _tile * 0.005),
              child: Column(
                children: [
                  for (int i = 0; i < ordered.length; i++)
                    _buildRow(ranks[i], ordered[i]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTiebreaker(Color color) {
    return Column(
      children: [
        _label('TIE FOR RANK $_currentGroupRank', color, scale: 0.9),
        SizedBox(height: _tile * 0.01),
        Text(
          'Each tied player throws a dart.\nWho was the closest to the bull?',
          textAlign: TextAlign.center,
          style: gBuildArcadeTextStyle(_font * 0.6),
        ),
        SizedBox(height: _tile * 0.015),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final r in _remaining[_currentIdx])
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: _tile * 0.01),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _pickClosest(r),
                        child: _avatar(r),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsPanel(Color color) {
    final teams = _buildTeams();
    return Container(
      padding: EdgeInsets.all(_tile * 0.01),
      decoration: BoxDecoration(
        color: Colors.grey.shade500,
        borderRadius: BorderRadius.circular(_tile * 0.03),
      ),
      child: Column(
      children: [
        _label('TEAMS', color, scale: 0.9),
        if (widget.results.length.isOdd)
          SwitchListTile(
            activeThumbColor: Colors.grey.shade700,
            activeTrackColor: color,
            trackOutlineColor: WidgetStatePropertyAll(Colors.grey.shade700),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              _winnerAlone ? 'WINNER ALONE' : 'MIDDLE PLAYER ALONE',
              style: gBuildArcadeTextStyle(_font * 0.6),
            ),
            value: _winnerAlone,
            onChanged: (v) => setState(() => _winnerAlone = v),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final team in teams)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(vertical: _tile * 0.004),
                    padding: EdgeInsets.symmetric(
                      vertical: _tile * 0.012,
                      horizontal: _tile * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: team.first.color.withAlpha(200),
                      borderRadius: BorderRadius.circular(_tile * 0.01),
                    ),
                    child: Text(
                      '${team.first.displayName} & '
                      '${(team.length > 1 ? team[1] : team.first).displayName}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _font * 0.8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winnerRecord = widget.results.firstWhere(
      (r) => r.objReference == widget.winner,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_tile * 0.03),
      ),
      content: SizedBox(
        width: GlobalAppDisplay.safeWidth * 0.9,
        height: GlobalAppDisplay.safeHeight * 0.9,
        child: Padding(
          padding: EdgeInsets.all(_tile * 0.03),
          child: Column(
            children: [
              _buildTopBanner(winnerRecord),
              SizedBox(height: _tile * 0.03),
              Expanded(
                child: Row(
                  children: [
                    Center(
                      child: SizedBox(
                        height: _tile * 0.3,
                        width: _tile * 0.3,
                        child: Image.asset(
                          'assets/png/mechanics/trophy.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    SizedBox(width: _tile * 0.02),
                    Expanded(flex: 7, child: _buildStandingsPanel(winnerRecord)),
                    SizedBox(width: _tile * 0.02),
                    Expanded(
                      flex: 3,
                      child: _isResolved
                          ? _buildTeamsPanel(winnerRecord.color)
                          : _buildTiebreaker(winnerRecord.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
