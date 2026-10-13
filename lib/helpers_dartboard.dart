// Flutter basics
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/enum_game_type.dart';
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_score.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';

final List<({int value, String label})> gTargets = [
  (value: 1, label: '1'),
  (value: 2, label: '2'),
  (value: 3, label: '3'),
  (value: 4, label: '4'),
  (value: 5, label: '5'),
  (value: 6, label: '6'),
  (value: 7, label: '7'),
  (value: 8, label: '8'),
  (value: 9, label: '9'),
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargetsHalf = [
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargets7Darts = [
  (value: 20, label: '20'),
  (value: 19, label: '19'),
  (value: 18, label: '18'),
  (value: 17, label: '17'),
  (value: 16, label: '16'),
  (value: 15, label: '15'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargetsACClassic = [
  (value: 1, label: '1'),
  (value: 2, label: '2'),
  (value: 3, label: '3'),
  (value: 4, label: '4'),
  (value: 5, label: '5'),
  (value: 6, label: '6'),
  (value: 7, label: '7'),
  (value: 8, label: '8'),
  (value: 9, label: '9'),
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargetsACClassicStart = [
  (value: 25, label: 'BULL'),
  (value: 1, label: '1'),
  (value: 2, label: '2'),
  (value: 3, label: '3'),
  (value: 4, label: '4'),
  (value: 5, label: '5'),
  (value: 6, label: '6'),
  (value: 7, label: '7'),
  (value: 8, label: '8'),
  (value: 9, label: '9'),
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargetsACClassicStart2 = [
  (value: 25, label: 'BULL'),
  (value: 25, label: 'BULL'),
  (value: 1, label: '1'),
  (value: 2, label: '2'),
  (value: 3, label: '3'),
  (value: 4, label: '4'),
  (value: 5, label: '5'),
  (value: 6, label: '6'),
  (value: 7, label: '7'),
  (value: 8, label: '8'),
  (value: 9, label: '9'),
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargetsACClassicUpDown = [
  (value: 1, label: '1'),
  (value: 2, label: '2'),
  (value: 3, label: '3'),
  (value: 4, label: '4'),
  (value: 5, label: '5'),
  (value: 6, label: '6'),
  (value: 7, label: '7'),
  (value: 8, label: '8'),
  (value: 9, label: '9'),
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
  (value: 20, label: '20'),
  (value: 19, label: '19'),
  (value: 18, label: '18'),
  (value: 17, label: '17'),
  (value: 16, label: '16'),
  (value: 15, label: '15'),
  (value: 14, label: '14'),
  (value: 13, label: '13'),
  (value: 12, label: '12'),
  (value: 11, label: '11'),
  (value: 10, label: '10'),
  (value: 9, label: '9'),
  (value: 8, label: '8'),
  (value: 7, label: '7'),
  (value: 6, label: '6'),
  (value: 5, label: '5'),
  (value: 4, label: '4'),
  (value: 3, label: '3'),
  (value: 2, label: '2'),
  (value: 1, label: '1'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargetsACClassicUpDown2 = [
  (value: 1, label: '1'),
  (value: 2, label: '2'),
  (value: 3, label: '3'),
  (value: 4, label: '4'),
  (value: 5, label: '5'),
  (value: 6, label: '6'),
  (value: 7, label: '7'),
  (value: 8, label: '8'),
  (value: 9, label: '9'),
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
  (value: 25, label: 'BULL'),
  (value: 20, label: '20'),
  (value: 19, label: '19'),
  (value: 18, label: '18'),
  (value: 17, label: '17'),
  (value: 16, label: '16'),
  (value: 15, label: '15'),
  (value: 14, label: '14'),
  (value: 13, label: '13'),
  (value: 12, label: '12'),
  (value: 11, label: '11'),
  (value: 10, label: '10'),
  (value: 9, label: '9'),
  (value: 8, label: '8'),
  (value: 7, label: '7'),
  (value: 6, label: '6'),
  (value: 5, label: '5'),
  (value: 4, label: '4'),
  (value: 3, label: '3'),
  (value: 2, label: '2'),
  (value: 1, label: '1'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargetsACUpDownStart = [
  (value: 25, label: 'BULL'),
  (value: 1, label: '1'),
  (value: 2, label: '2'),
  (value: 3, label: '3'),
  (value: 4, label: '4'),
  (value: 5, label: '5'),
  (value: 6, label: '6'),
  (value: 7, label: '7'),
  (value: 8, label: '8'),
  (value: 9, label: '9'),
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
  (value: 20, label: '20'),
  (value: 19, label: '19'),
  (value: 18, label: '18'),
  (value: 17, label: '17'),
  (value: 16, label: '16'),
  (value: 15, label: '15'),
  (value: 14, label: '14'),
  (value: 13, label: '13'),
  (value: 12, label: '12'),
  (value: 11, label: '11'),
  (value: 10, label: '10'),
  (value: 9, label: '9'),
  (value: 8, label: '8'),
  (value: 7, label: '7'),
  (value: 6, label: '6'),
  (value: 5, label: '5'),
  (value: 4, label: '4'),
  (value: 3, label: '3'),
  (value: 2, label: '2'),
  (value: 1, label: '1'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargetsACUpDownStart2 = [
  (value: 25, label: 'BULL'),
  (value: 25, label: 'BULL'),
  (value: 1, label: '1'),
  (value: 2, label: '2'),
  (value: 3, label: '3'),
  (value: 4, label: '4'),
  (value: 5, label: '5'),
  (value: 6, label: '6'),
  (value: 7, label: '7'),
  (value: 8, label: '8'),
  (value: 9, label: '9'),
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
  (value: 20, label: '20'),
  (value: 19, label: '19'),
  (value: 18, label: '18'),
  (value: 17, label: '17'),
  (value: 16, label: '16'),
  (value: 15, label: '15'),
  (value: 14, label: '14'),
  (value: 13, label: '13'),
  (value: 12, label: '12'),
  (value: 11, label: '11'),
  (value: 10, label: '10'),
  (value: 9, label: '9'),
  (value: 8, label: '8'),
  (value: 7, label: '7'),
  (value: 6, label: '6'),
  (value: 5, label: '5'),
  (value: 4, label: '4'),
  (value: 3, label: '3'),
  (value: 2, label: '2'),
  (value: 1, label: '1'),
  (value: 25, label: 'BULL'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargetsACUpDown2Start = [
  (value: 25, label: 'BULL'),
  (value: 1, label: '1'),
  (value: 2, label: '2'),
  (value: 3, label: '3'),
  (value: 4, label: '4'),
  (value: 5, label: '5'),
  (value: 6, label: '6'),
  (value: 7, label: '7'),
  (value: 8, label: '8'),
  (value: 9, label: '9'),
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
  (value: 25, label: 'BULL'),
  (value: 20, label: '20'),
  (value: 19, label: '19'),
  (value: 18, label: '18'),
  (value: 17, label: '17'),
  (value: 16, label: '16'),
  (value: 15, label: '15'),
  (value: 14, label: '14'),
  (value: 13, label: '13'),
  (value: 12, label: '12'),
  (value: 11, label: '11'),
  (value: 10, label: '10'),
  (value: 9, label: '9'),
  (value: 8, label: '8'),
  (value: 7, label: '7'),
  (value: 6, label: '6'),
  (value: 5, label: '5'),
  (value: 4, label: '4'),
  (value: 3, label: '3'),
  (value: 2, label: '2'),
  (value: 1, label: '1'),
  (value: 25, label: 'BULL'),
];

final List<({int value, String label})> gTargetsACUpDown2Start2 = [
  (value: 25, label: 'BULL'),
  (value: 25, label: 'BULL'),
  (value: 1, label: '1'),
  (value: 2, label: '2'),
  (value: 3, label: '3'),
  (value: 4, label: '4'),
  (value: 5, label: '5'),
  (value: 6, label: '6'),
  (value: 7, label: '7'),
  (value: 8, label: '8'),
  (value: 9, label: '9'),
  (value: 10, label: '10'),
  (value: 11, label: '11'),
  (value: 12, label: '12'),
  (value: 13, label: '13'),
  (value: 14, label: '14'),
  (value: 15, label: '15'),
  (value: 16, label: '16'),
  (value: 17, label: '17'),
  (value: 18, label: '18'),
  (value: 19, label: '19'),
  (value: 20, label: '20'),
  (value: 25, label: 'BULL'),
  (value: 25, label: 'BULL'),
  (value: 20, label: '20'),
  (value: 19, label: '19'),
  (value: 18, label: '18'),
  (value: 17, label: '17'),
  (value: 16, label: '16'),
  (value: 15, label: '15'),
  (value: 14, label: '14'),
  (value: 13, label: '13'),
  (value: 12, label: '12'),
  (value: 11, label: '11'),
  (value: 10, label: '10'),
  (value: 9, label: '9'),
  (value: 8, label: '8'),
  (value: 7, label: '7'),
  (value: 6, label: '6'),
  (value: 5, label: '5'),
  (value: 4, label: '4'),
  (value: 3, label: '3'),
  (value: 2, label: '2'),
  (value: 1, label: '1'),
  (value: 25, label: 'BULL'),
  (value: 25, label: 'BULL'),
];

List<({int value, String label})> gGetTargetsForGame(TblGame game) {
  switch (game.fldGameType) {
    case GlobalGameType.halfIt:
    case GlobalGameType.buildUp:
      return gTargetsHalf;
    case GlobalGameType.sevenDarts:
      return gTargets7Darts;
    case GlobalGameType.aroundClock:
      if (game.getACModeNbrStartEndBulls == 0 && game.getACModeNbrMiddleBulls == 0) {return gTargetsACClassic;}
      else if (game.getACModeNbrStartEndBulls == 1 && game.getACModeNbrMiddleBulls == 0) {return gTargetsACClassicStart;}
      else if (game.getACModeNbrStartEndBulls == 2 && game.getACModeNbrMiddleBulls == 0) {return gTargetsACClassicStart2;}
      else if (game.getACModeNbrStartEndBulls == 0 && game.getACModeNbrMiddleBulls == 1) {return gTargetsACClassicUpDown;}
      else if (game.getACModeNbrStartEndBulls == 0 && game.getACModeNbrMiddleBulls == 2) {return gTargetsACClassicUpDown2;}
      else if (game.getACModeNbrStartEndBulls == 1 && game.getACModeNbrMiddleBulls == 1) {return gTargetsACUpDownStart;}
      else if (game.getACModeNbrStartEndBulls == 2 && game.getACModeNbrMiddleBulls == 1) {return gTargetsACUpDownStart2;}
      else if (game.getACModeNbrStartEndBulls == 1 && game.getACModeNbrMiddleBulls == 2) {return gTargetsACUpDown2Start;}
      else if (game.getACModeNbrStartEndBulls == 2 && game.getACModeNbrMiddleBulls == 2) {return gTargetsACUpDown2Start2;}
      else {return gTargets;}
    default:
      return gTargets;
  }
}

class GameProgressStateHalf {
  int activeSeatIdx;
  int previousSeatIdx;
  int nextSeatIdx;
  int activeDartIdx;
  int previousDartIdx;
  int activeRoundIdx;
  int previousRoundIdx;
  int activeTargetIdx;
  int previousTargetIdx;
  int nextTargetIdx;
  bool endGame;

  GameProgressStateHalf({
    this.activeSeatIdx = 0,
    this.previousSeatIdx = 0,
    this.nextSeatIdx = 1,
    this.activeDartIdx = 0,
    this.previousDartIdx = 0,
    this.activeRoundIdx = 0,
    this.previousRoundIdx = 0,
    this.activeTargetIdx = 0,
    this.previousTargetIdx = 0,
    this.nextTargetIdx = 1,
    this.endGame = false,
  });
}

GameProgressStateHalf gStepGameStateHalf({
  required GameProgressStateHalf currentState,
  required GlobalGameState gameState,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required int totalPlayers,
  required List<dynamic> targetsList,
}) {
  if (gameState == GlobalGameState.forwardState) {
    // 1. Advance Dart Index
    currentState.activeDartIdx++;

    // 2. Check if turn is complete (3 darts thrown)
    if (currentState.activeDartIdx >= 3) {
      // 3. Shift current active states to previous before moving forward
      currentState.previousDartIdx = currentState.activeDartIdx;
      currentState.previousSeatIdx = currentState.activeSeatIdx;
      currentState.previousRoundIdx = currentState.activeRoundIdx;
      currentState.previousTargetIdx = currentState.activeTargetIdx;

      // Advance Seat Index in rotation
      currentState.activeDartIdx = 0;
      currentState.activeSeatIdx =
          (currentState.activeSeatIdx + 1) % totalPlayers;

      // 4. Check if a full round rotation is complete
      if (currentState.activeSeatIdx == 0) {
        if (currentState.activeRoundIdx < targetsList.length - 1) {
          currentState.activeRoundIdx++;
          currentState.activeTargetIdx++;
          if (currentState.nextTargetIdx != targetsList.length - 1){
            currentState.nextTargetIdx++;
          }          
        } else {
          currentState.endGame = true;
        }
      }
    }
  } else {
    // BACKWARD / RESUME ENGINE
    final updatedRecords = gamesScoresBox.values
        .where((s) => s.fldGame == gameConfig && s.fldRound >= 0)
        .toList();

    if (updatedRecords.isEmpty) {
      // Reset to start state
      return GameProgressStateHalf();
    }

    final activeRec = updatedRecords.last;

    int nextSeat = activeRec.fldSeatIndex;
    int nextDart = activeRec.fldDartIndex + 1;
    int nextRound = activeRec.fldRound;
    int nextTarget = activeRec.fldTargetIndex;
    int nextTargetIdxVal = activeRec.fldNextTargetIndex ?? nextTarget;

    if (nextDart >= 3) {
      nextDart = 0;
      nextSeat = (nextSeat + 1) % totalPlayers;
      if (nextSeat == 0) {
        if (nextRound < targetsList.length - 1) {
          nextRound++;
          nextTarget = nextRound;
          nextTargetIdxVal = nextRound < targetsList.length - 1
              ? nextRound + 1
              : nextRound;
        }
      }
    }

    currentState.endGame = false;

    currentState.activeSeatIdx = nextSeat;
    currentState.activeDartIdx = nextDart;
    currentState.activeRoundIdx = nextRound;
    currentState.activeTargetIdx = nextTarget;
    currentState.nextTargetIdx = nextTargetIdxVal;

    // Find previous player correctly
    final prevRecord = updatedRecords.reversed.firstWhere(
      (s) => s.fldSeatIndex != currentState.activeSeatIdx,
      orElse: () => updatedRecords.first,
    );

    currentState.previousSeatIdx = prevRecord.fldSeatIndex;
    currentState.previousDartIdx = prevRecord.fldDartIndex;
    currentState.previousRoundIdx = prevRecord.fldRound;
    currentState.previousTargetIdx = prevRecord.fldTargetIndex;
  }

  currentState.nextSeatIdx = (currentState.activeSeatIdx + 1) % totalPlayers;

  return currentState;
}

class GameProgressState7Darts {
  int activeSeatIdx;
  int previousSeatIdx;
  int nextSeatIdx;
  int activeDartIdx;
  int previousDartIdx;
  int activeTargetIdx;
  int previousTargetIdx;
  int nextTargetIdx;
  int activeRoundIdx;
  int previousRoundIdx;
  bool endGame;

  GameProgressState7Darts({
    this.activeSeatIdx = 0,
    this.previousSeatIdx = 0,
    this.nextSeatIdx = 1,
    this.activeDartIdx = 0,
    this.previousDartIdx = 0,
    this.activeTargetIdx = 0,
    this.previousTargetIdx = 0,
    this.nextTargetIdx = 1,
    this.activeRoundIdx = 0,
    this.previousRoundIdx = 0,
    this.endGame = false,
  });
}

GameProgressState7Darts gStepGameState7Darts({
  required GameProgressState7Darts currentState,
  required GlobalGameState gameState,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required int totalPlayers,
  required int totalRounds,
  required List<dynamic> targetsList,
}) {
  if (gameState == GlobalGameState.forwardState) {
    // 1. Save current state to previous before moving forward
    currentState.previousDartIdx = currentState.activeDartIdx;
    currentState.previousTargetIdx = currentState.activeTargetIdx;

    // 2. Advance Dart and Target Index
    currentState.activeDartIdx++;
    currentState.activeTargetIdx++;
    if (currentState.nextTargetIdx != targetsList.length - 1){
      currentState.nextTargetIdx++;
    }

    // 3. Check if turn is complete (7 darts thrown)
    if (currentState.activeDartIdx >= targetsList.length) {
      // 4. Shift current active states to previous before moving forward
      currentState.previousSeatIdx = currentState.activeSeatIdx;
      currentState.previousRoundIdx = currentState.activeRoundIdx;

      // 5. Advance Seat Index in rotation
      currentState.activeDartIdx = 0;
      currentState.activeTargetIdx = 0;
      currentState.nextTargetIdx = 1;
      currentState.activeSeatIdx =
          (currentState.activeSeatIdx + 1) % totalPlayers;

      // 6. Check if a full round rotation is complete
      if (currentState.activeSeatIdx == 0) {
        if (currentState.activeRoundIdx < totalRounds - 1) {
          currentState.activeRoundIdx++;
        } else {
          currentState.endGame = true;
        }
      }
    }
  } else {
    // BACKWARD / RESUME ENGINE
    final updatedRecords = gamesScoresBox.values
        .where((s) => s.fldGame == gameConfig && s.fldRound >= 0)
        .toList();

    if (updatedRecords.isEmpty) {
      // Reset to start state
      return GameProgressState7Darts();
    }

    final activeRec = updatedRecords.last;

    int nextSeat = activeRec.fldSeatIndex;
    int nextDart = activeRec.fldDartIndex + 1;
    int nextRound = activeRec.fldRound;
    int nextTarget = nextDart;
    int nextTargetIdxVal = nextTarget < targetsList.length - 1
        ? nextTarget + 1
        : nextTarget;
    currentState.endGame = false;
    
    if (nextDart >= targetsList.length) {
      nextDart = 0;
      nextTarget = 0;
      nextTargetIdxVal = targetsList.length > 1 ? 1 : 0;
      nextSeat = (nextSeat + 1) % totalPlayers;
      if (nextSeat == 0) {
        if (nextRound < totalRounds - 1) {
          nextRound++;
        } else {
          currentState.endGame = true;
        }
      }
    }

    currentState.activeSeatIdx = nextSeat;
    currentState.activeDartIdx = nextDart;
    currentState.activeRoundIdx = nextRound;
    currentState.activeTargetIdx = nextTarget;
    currentState.nextTargetIdx = nextTargetIdxVal;

    // Find previous player correctly
    final prevRecord = updatedRecords.reversed.firstWhere(
      (s) => s.fldSeatIndex != currentState.activeSeatIdx,
      orElse: () => updatedRecords.first,
    );

    currentState.previousSeatIdx = prevRecord.fldSeatIndex;
    currentState.previousDartIdx = prevRecord.fldDartIndex;
    currentState.previousRoundIdx = prevRecord.fldRound;
    currentState.previousTargetIdx = prevRecord.fldTargetIndex;
  }

  currentState.nextSeatIdx = (currentState.activeSeatIdx + 1) % totalPlayers;

  return currentState;
}

class GameProgressStateAC {
  int activeSeatIdx;
  int previousSeatIdx;
  int nextSeatIdx;
  int activeDartIdx;
  int previousDartIdx;
  int activeRoundIdx;
  int previousRoundIdx;
  int activeTargetIdx;
  int previousTargetIdx;
  int nextTargetIdx;
  bool endGame;

  GameProgressStateAC({
    this.activeSeatIdx = 0,
    this.previousSeatIdx = 0,
    this.nextSeatIdx = 1,
    this.activeDartIdx = 0,
    this.previousDartIdx = 0,
    this.activeRoundIdx = 0,
    this.previousRoundIdx = 0,
    this.activeTargetIdx = 0,
    this.previousTargetIdx = 0,
    this.nextTargetIdx = 1,
    this.endGame = false,
  });
}

// Target a seat resumes from. In team mode every player shares the progression
// of his team (seats are interleaved: team = seat % number of teams).
int _gAcResumeTargetIdx(
  TblGame gameConfig,
  Box<TblGameScore> gamesScoresBox,
  int seatIdx,
) {
  final teamCount = gameConfig.fldPlayersGM ? 0 : (gameConfig.fldTeams?.length ?? 0);
  final last = gamesScoresBox.values
      .where(
        (s) =>
            s.fldGame == gameConfig &&
            s.fldRound >= 0 &&
            (teamCount > 0
                ? s.fldSeatIndex % teamCount == seatIdx % teamCount
                : s.fldSeatIndex == seatIdx),
      )
      .lastOrNull;
  if (last == null) return 0;
  return last.fldNextTargetIndex ?? last.fldTargetIndex;
}

GameProgressStateAC gStepGameStateAC({
  required GameProgressStateAC currentState,
  required GlobalGameState gameState,
  required TblGame gameConfig,
  required Box<TblGameScore> gamesScoresBox,
  required int totalPlayers,
  required List<dynamic> targetsList,
  int? hits,
}) {
  if (gameState == GlobalGameState.forwardState) {
    // 1. Advance Dart Index continuously
    currentState.previousDartIdx = currentState.activeDartIdx;
    currentState.activeDartIdx++;

    // 2. Store previous target before updating
    currentState.previousTargetIdx = currentState.activeTargetIdx;
    
    // 3. Determine advance steps based on hit multiplier
    int advanceSteps = hits ?? 1;

    // 4. Check bounds against the final target (BULL)
    if (currentState.activeTargetIdx + advanceSteps > targetsList.length - 1) {
      currentState.activeTargetIdx = targetsList.length - 1;
      currentState.nextTargetIdx = targetsList.length - 1;
      currentState.endGame = true;
      return currentState;
    } else {
      currentState.activeTargetIdx += advanceSteps;
      // Update next target index safely
      if (currentState.activeTargetIdx != targetsList.length - 1){
        currentState.nextTargetIdx = currentState.activeTargetIdx + 1;
      } else {
        currentState.nextTargetIdx = currentState.activeTargetIdx;
      }
    }

    // 5. Check if turn is complete using modulo 3 on the continuous dart index
    if (currentState.activeDartIdx % 3 == 0) {
      // Fetch all records for this game and active seat, then take the last 3 throws
      final playerRecords = gamesScoresBox.values
          .where((s) => s.fldGame == gameConfig && s.fldSeatIndex == currentState.activeSeatIdx)
          .toList();

      final lastThree = playerRecords.sublist(playerRecords.length - 3);

      // Check if any of the 3 throws resulted in a miss (fldHits == 0)
      bool hasMissed = lastThree.any((record) => record.fldHits == 0);

      // A miss occurred -> end of player's turn, rotate to the next seat
      if (hasMissed) {
        // Shift current active states to previous before moving forward
        currentState.previousRoundIdx = currentState.activeRoundIdx;
        currentState.previousSeatIdx = currentState.activeSeatIdx;

        // Advance Seat Index in rotation
        currentState.activeSeatIdx = (currentState.activeSeatIdx + 1) % totalPlayers;

        // 6. Check if a full round rotation is complete
        if (currentState.activeSeatIdx == 0) {
          currentState.activeRoundIdx++;
        }

        currentState.activeTargetIdx = _gAcResumeTargetIdx(
          gameConfig,
          gamesScoresBox,
          currentState.activeSeatIdx,
        );
        
        if (currentState.activeTargetIdx < targetsList.length - 1) {
          currentState.nextTargetIdx = currentState.activeTargetIdx + 1;
        } else {
          currentState.nextTargetIdx = targetsList.length - 1;
        }
      } else {
        // All 3 darts hit successfully -> player takes back darts and continues throwing in the same seat
      }
    }

  } else {
    // BACKWARD / RESUME ENGINE
    final updatedRecords = gamesScoresBox.values
        .where((s) => s.fldGame == gameConfig && s.fldRound >= 0)
        .toList();

    if (updatedRecords.isEmpty) {
      // Reset to start state if no records remain
      return GameProgressStateAC();
    }

    currentState.endGame = false;

    // Grab the absolute last record in the database after deletion (for undo) or load (for resume)
    final lastRec = updatedRecords.last;

    // 1. Determine the active dart index for the next throw
    currentState.activeDartIdx = lastRec.fldDartIndex + 1;

    // 2. Check if the turn finished on the last throw (every 3 darts)
    final playerRecords = updatedRecords
        .where((s) => s.fldSeatIndex == lastRec.fldSeatIndex && s.fldRound == lastRec.fldRound)
        .toList();

    final lastThree = playerRecords.length >= 3
        ? playerRecords.sublist(playerRecords.length - 3)
        : playerRecords;

    bool hasMissed = lastThree.any((r) => r.fldHits == 0);
    bool turnCompleted = (currentState.activeDartIdx % 3 == 0);

    if (turnCompleted && hasMissed) {
      // Turn ended due to a miss -> advance seat rotation
      currentState.previousSeatIdx = lastRec.fldSeatIndex;
      currentState.activeSeatIdx = (lastRec.fldSeatIndex + 1) % totalPlayers;
      currentState.previousRoundIdx = lastRec.fldRound;
      
      if (currentState.activeSeatIdx == 0) {
        currentState.activeRoundIdx = lastRec.fldRound + 1;
      } else {
        currentState.activeRoundIdx = lastRec.fldRound;
      }
    } else if (turnCompleted && !hasMissed) {
      // Hit all 3 successfully -> player takes back darts and continues in the same seat
      currentState.previousSeatIdx = lastRec.fldSeatIndex;
      currentState.activeSeatIdx = lastRec.fldSeatIndex;
      currentState.previousRoundIdx = lastRec.fldRound;
      currentState.activeRoundIdx = lastRec.fldRound;
    } else {
      // Mid-turn (e.g. dart index 1 or 2 of 3)
      currentState.previousSeatIdx = lastRec.fldSeatIndex;
      currentState.activeSeatIdx = lastRec.fldSeatIndex;
      currentState.previousRoundIdx = lastRec.fldRound;
      currentState.activeRoundIdx = lastRec.fldRound;
    }

    // 3. Restore the correct target index for the active player/seat from their latest snapshot
    currentState.activeTargetIdx = _gAcResumeTargetIdx(
      gameConfig,
      gamesScoresBox,
      currentState.activeSeatIdx,
    );

    if (currentState.activeTargetIdx < targetsList.length - 1) {
      currentState.nextTargetIdx = currentState.activeTargetIdx + 1;
    } else {
      currentState.nextTargetIdx = targetsList.length - 1;
    }

    // 4. Previous pointers: the last throw is lastRec (same as forward), and the
    // previous player's round must match the previous seat (the seat just before the active one)
    currentState.previousDartIdx = lastRec.fldDartIndex;
    currentState.previousTargetIdx = lastRec.fldTargetIndex;
    // Like the forward path, the previous player is the last one who played before the active seat
    final otherSeatRecords =
        updatedRecords.where((s) => s.fldSeatIndex != currentState.activeSeatIdx);
    if (otherSeatRecords.isNotEmpty) {
      currentState.previousSeatIdx = otherSeatRecords.last.fldSeatIndex;
      currentState.previousRoundIdx = otherSeatRecords.last.fldRound;
    } else {
      currentState.previousSeatIdx = currentState.activeSeatIdx;
      currentState.previousRoundIdx = lastRec.fldRound;
    }
  }

  currentState.nextSeatIdx = (currentState.activeSeatIdx + 1) % totalPlayers;

  return currentState;
}

class GlobalTargetZonePainter extends CustomPainter {
  final int targetValue;

  GlobalTargetZonePainter(this.targetValue);

  // Standard dartboard angles mapping...
  static double getAngleForValue(int val) {
    Map<int, double> angles = {
      20: 270,
      1: 288,
      18: 306,
      4: 324,
      13: 342,
      6: 0,
      10: 18,
      15: 36,
      2: 54,
      17: 72,
      3: 90,
      19: 108,
      7: 126,
      16: 144,
      8: 162,
      11: 180,
      14: 198,
      9: 216,
      12: 234,
      5: 252,
    };
    return angles[val] ?? 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (targetValue == 25) {
      _paintBullseye(canvas, size);
      return;
    }

    double angle = getAngleForValue(targetValue);

    // RECALIBRATED RATIOS (to pull highlights away from the number ring)
    // Double Zone (Outer Ring)
    _drawArcSegment(
      canvas,
      size,
      angle,
      0.69,
      0.77,
      Colors.purpleAccent.withValues(alpha: 0.9),
    );
    // Triple Zone (Inner Ring)
    _drawArcSegment(
      canvas,
      size,
      angle,
      0.405,
      0.485,
      Colors.purpleAccent.withValues(alpha: 0.9),
    );
    // Single Zone 1 (Main Area)
    _drawArcSegment(
      canvas,
      size,
      angle,
      0.095,
      0.403,
      Colors.yellow.withValues(alpha: 0.9),
    );
    // Single Zone 2 (Main Area)
    _drawArcSegment(
      canvas,
      size,
      angle,
      0.487,
      0.687,
      Colors.yellow.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant GlobalTargetZonePainter oldDelegate) =>
      oldDelegate.targetValue != targetValue;

  void _paintBullseye(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintOuterBull = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final paintInnerBull = Paint()
      ..color = Colors.purpleAccent.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.09, paintOuterBull);
    canvas.drawCircle(center, radius * 0.04, paintInnerBull);
  }

  void _drawArcSegment(
    Canvas canvas,
    Size size,
    double centerAngle,
    double innerRadiusRatio,
    double outerRadiusRatio,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    double startAngle = (centerAngle - 9) * (pi / 180);
    double sweepAngle = 18 * (pi / 180);
    double radius = size.width / 2;
    Offset center = Offset(radius, radius);

    Path path = Path();
    // Start at outer arc
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius * outerRadiusRatio),
      startAngle,
      sweepAngle,
      true,
    );
    // Line to inner arc and sweep back
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius * innerRadiusRatio),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    );
    path.close();
    canvas.drawPath(path, paint);
  }
}

int processZoneTap(Offset localPosition, Size size, int targetVal) {
  double radius = size.width / 2;
  Offset center = Offset(radius, radius);
  double dist = (localPosition - center).distance / radius;

  // Identify who is throwing based on the lane tapped
  int leap = 0;

  if (targetVal == 25) {
    if (dist <= 0.04) {
      leap = 2;
    } else if (dist <= 0.09) {
      leap = 1;
    }
  } else {
    double tapAngle = getTapAngle(localPosition, size);
    double targetAngle = GlobalTargetZonePainter.getAngleForValue(targetVal);
    double angleDiff = (tapAngle - targetAngle).abs();
    if (angleDiff > 180) angleDiff = 360 - angleDiff;
    if (angleDiff > 9) return 0; // Ignore taps outside the slice

    if (dist >= 0.405 && dist <= 0.485) {
      leap = 3;
    } else if (dist >= 0.69 && dist <= 0.77) {
      leap = 2;
    } else if ((dist >= 0.095 && dist <= 0.403) ||
        (dist >= 0.487 && dist <= 0.687)) {
      leap = 1;
    }
  }

  return leap;
}

double getTapAngle(Offset pos, Size size) {
  final rad = size.width / 2;
  final deg = atan2(pos.dy - rad, pos.dx - rad) * (180 / pi);
  return deg < 0 ? deg + 360 : deg;
}

Widget gBuildDartboardInputZone({
  required int gActiveTargetIdx,
  required TblGame gGame,
  required Function(int leap) gOnTap,
  bool gIsFrozen = false,
}) {
  final List<({String label, int value})> targetsList = gGetTargetsForGame(gGame);

  return Column(
    children: [
      Expanded(
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: gIsFrozen, // Locks the GestureDetector
              child: Center(
                child: LayoutBuilder(
                  builder: (context, c) {
                    double size = min(c.maxWidth, c.maxHeight);
                    int currentTargetValue =
                        targetsList[gActiveTargetIdx].value;

                    // --- REFINED VIEWPORT LOGIC ---
                    double zoomScale = 1.6;
                    Alignment zoomAlignment;

                    switch (currentTargetValue) {
                      case 12 || 5 || 20 || 1 || 18:
                        // Push Top down slightly more to see the "20" label
                        zoomAlignment = const Alignment(0.0, -0.9);
                        break;
                      case 4 || 13 || 6 || 10 || 15:
                        // Push Right further left to see the numbers 10, 13, 15
                        zoomAlignment = const Alignment(0.95, 0.0);
                        break;
                      case 2 || 17 || 3 || 19 || 7:
                        // Push Bottom up to see 17 and 19 labels
                        zoomAlignment = const Alignment(0.0, 0.9);
                        break;
                      case 9 || 14 || 11 || 8 || 16:
                        // Push Left further right to see 11, 14, 16
                        zoomAlignment = const Alignment(-0.95, 0.0);
                        break;
                      case 25:
                        zoomAlignment = Alignment.center;
                        zoomScale = 2.5;
                        break;
                      default:
                        zoomAlignment = Alignment.center;
                        zoomScale = 1.0;
                        break;
                    }

                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTapUp: (d) {
                          double centerX = size / 2;
                          double centerY = size / 2;

                          // 1. Calculate how much the alignment shifted the board
                          double shiftX =
                              zoomAlignment.x * centerX * (zoomScale - 1);
                          double shiftY =
                              zoomAlignment.y * centerY * (zoomScale - 1);

                          // 2. Reverse the shift and the scale
                          // We subtract the shift first, then scale back to 1:1, then move back to center
                          double touchX =
                              (d.localPosition.dx - centerX + shiftX) /
                                  zoomScale +
                              centerX;
                          double touchY =
                              (d.localPosition.dy - centerY + shiftY) /
                                  zoomScale +
                              centerY;

                          gOnTap(
                            processZoneTap(
                              Offset(touchX, touchY),
                              Size(size, size),
                              currentTargetValue,
                            ),
                          );
                        },
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: ClipRect(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              child: Transform.scale(
                                scale: zoomScale,
                                alignment: zoomAlignment,
                                child: Stack(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/svg/games/dartboard.svg',
                                      width: size,
                                      height: size,
                                    ),
                                    CustomPaint(
                                      size: Size(size, size),
                                      painter: GlobalTargetZonePainter(
                                        currentTargetValue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (gIsFrozen) Positioned.fill(child: _buildFrostedOverlay()),
          ],
        ),
      ),
    ],
  );
}

Widget _buildFrostedOverlay() {
  return ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(Icons.lock_outline, color: Colors.white54, size: 64),
        ),
      ),
    ),
  );
}