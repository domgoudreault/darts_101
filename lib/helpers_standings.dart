// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_score.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
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
    this.ranking = 999,
  });
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

      final lastScore = playerScores.last.fldScorePlayerSnapshot;

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
        ),
      );
    }
  } else {
    for (var gameTeam in gameTeams) {
      final teamPlayers = gameTeam.team.fldPlayers;

      final teamScores = gamesScoresBox.values.where(
        (s) => s.fldGame == gameConfig && teamPlayers.contains(s.fldPlayer),
      );

      final lastScore = teamScores.last.fldScoreTeamSnapshot!;

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
        ),
      );
    }
  }

  // 2. Sort results (Highest score first)
  finalResults.sort((a, b) {
    if (b.lastScore != a.lastScore) {
      return b.lastScore.compareTo(a.lastScore);
    }
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
          curr.triplesCount == prev.triplesCount &&
          curr.doublesCount == prev.doublesCount &&
          curr.hitsBull == prev.hitsBull);
      if (!isIdentical) {
        currentRank = i + 1;
      }
    }
    finalResults[i].ranking = currentRank; // Direct write!
  }

  return finalResults;
}

void gshowStandingsDialog({
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
  final topScore = finalResults.first;

  final List<GameResultRecord> winners = finalResults
    .where(
      (result) =>
          result.lastScore == topScore.lastScore &&
          result.triplesCount == topScore.triplesCount &&
          result.doublesCount == topScore.doublesCount &&
          result.hitsBull == topScore.hitsBull,
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
                    borderRadius: BorderRadius.circular(
                      responsiveTile * 0.015,
                    ),
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

  Widget buildStandingsHeader(int headerFlex, String headerText, TextAlign headerAlign, bool isTie) {
    return Expanded(
      flex: headerFlex,
      child: Text(
        headerText,
        textAlign: headerAlign,
        style: gBuildArcadeTextStyle(
          (responsiveFontSize * 0.6).clamp(
            responsiveFontSize * 0.5,
            60,
          ),
          gFontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildStandingsData(int dataFlex, String dataText, TextAlign dataAlign, bool isWinner, bool isTie, bool isOverflow) {
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

  Widget buildCreateListResults(GameResultRecord<dynamic> res, bool isWinner, bool isTie) {
    final int headerFlex = isPlayerMode ? 2 : isTie ? 2 : 1;

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
          buildStandingsData(headerFlex, "${res.ranking}.", TextAlign.center, isWinner, isTie, false),
          buildStandingsData(5, res.displayName, TextAlign.left, isWinner, isTie, true),
          buildStandingsData(headerFlex, "${res.triplesCount}", TextAlign.center, isWinner, isTie, false),
          buildStandingsData(headerFlex, "${res.doublesCount}", TextAlign.center, isWinner, isTie, false),
          buildStandingsData(headerFlex, "${res.hitsBull}", TextAlign.center, isWinner, isTie, false),
          buildStandingsData(headerFlex, "${res.lastScore}", TextAlign.right, isWinner, isTie, false),
        ],
      ),
    );
  }
  
  final int headerFlex = isPlayerMode ? 2 : isTie ? 2 : 1;

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
                              avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
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
                            SingleChildScrollView(
                              padding: EdgeInsets.all(
                                responsiveTile * 0.005,
                              ),
                              child: Column(
                                children: [
                                  // 3. STANDINGS LIST
                                  Container(
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(vertical: responsiveTile * 0.01),
                                    decoration: BoxDecoration(
                                      color: (winners[0].color).withAlpha(220),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(responsiveTile * 0.025),
                                        bottom: Radius.zero,
                                      ),
                                    ),
                                    child: Text(
                                      "FINAL STANDINGS",
                                      style: gBuildArcadeTextStyle(responsiveFontSize, gFontWeight: FontWeight.bold),
                                    ),
                                  ),

                                  SizedBox(height: responsiveTile * 0.015),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      buildStandingsHeader(headerFlex,"RANK", TextAlign.center, isTie),
                                      buildStandingsHeader(5, !isPlayerMode ? "TEAMS" : "PLAYERS", TextAlign.left, isTie),
                                      buildStandingsHeader(headerFlex, isPlayerMode ? "TRIPLES" : isTie ? "TRIPLES" : "TRP", TextAlign.center, isTie),
                                      buildStandingsHeader(headerFlex, isPlayerMode ? "DOUBLES" : isTie ? "DOUBLES" : "DBL", TextAlign.center, isTie),
                                      buildStandingsHeader(headerFlex, "BULLS", TextAlign.center, isTie),
                                      buildStandingsHeader(headerFlex, isPlayerMode ? "POINTS" : isTie ? "POINTS" : "PTS", TextAlign.right, isTie),
                                    ],
                                  ),

                                  const Divider(color: Colors.white),

                                  // Map the results directly into the column
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