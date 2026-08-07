import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_build_up.dart';

enum TargetZone { single, double, triple }
enum BuildUpMode { forward, backward }

class GameBuildUpScreen extends StatefulWidget {
  final TblGame game;
  final String gameText;
  final Color tileBackgroundColor;
  final bool resumeMode;
  
  const GameBuildUpScreen({
    super.key, 
    required this.game,
    required this.gameText,
    required this.tileBackgroundColor,
    required this.resumeMode
  });

  @override
  State<GameBuildUpScreen> createState() => _GameBuildUpScreenState();
}

class _GameBuildUpScreenState extends State<GameBuildUpScreen> {
  // 1. Game Configuration
  List<int> leftPile = [];
  List<int> rightPile = [];  
  final List<int> targets = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25];
  final List<String> targetLabels = ["10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "BULL"];
  int leftCurrentPlayerIdx = 0; // Index within the leftPile
  int currentLeftDartIdx = 0;
  int leftCurrentTargetIndex = 0;
  int leftHitsInCurrentTurn = 0;
  int leftCurrentRound = 1;
  
  int rightCurrentPlayerIdx = 0; // Index within the rightPile
  int currentRightDartIdx = 0;
  int rightCurrentTargetIndex = 0;
  int rightHitsInCurrentTurn = 0;  
  int rightCurrentRound = 1;

  bool isLeftWinnerFreezeUI = false;
  bool isRightWinnerFreezeUI = false;
    
  late Box<TblGameBuildUp> gameTeamBuildUpBox;
  late Box<TblPlayer> playersBox;    

  @override
  void initState() {
    super.initState();
    gameTeamBuildUpBox = Hive.box<TblGameBuildUp>('gameTeamBuildUpBox');
    playersBox = Hive.box<TblPlayer>('playersBox');
    _splitPlayers(widget.resumeMode);

    if (widget.resumeMode) {
      _calculateResumeIndexes();
    }
  }

  void _calculateResumeIndexes() {        
    // 1. Filter history for this specific game
    final history = gameTeamBuildUpBox.values
        .where((s) => s.idGame == widget.game.idGame && s.isSeatedRecord == false)
        .toList();

    if (history.isEmpty) {return;}

    setState(() {
      // --- LEFT LANE RESUME ---
      // Efficiently find the MAX round from gameplay records
      leftCurrentRound = gameTeamBuildUpBox.values
          .where((s) => s.idGame == widget.game.idGame && s.isSeatedRecord == false && s.isLeftLane == true)
          .fold<int>(1, (max, e) => e.round > max ? e.round : max);
      
      final leftHistory = history.where((s) => s.isLeftLane == true).toList();
      if (leftHistory.isNotEmpty) {
        final lastLeft = leftHistory.last;
        leftCurrentTargetIndex = targets.indexOf(lastLeft.nextTargetValue);
        leftCurrentPlayerIdx = leftPile.indexOf(lastLeft.idPlayer);
        
        // Count only the darts thrown by THIS player in THIS round
        int playerDartsThisRound = leftHistory.where((s) => 
          s.idPlayer == lastLeft.idPlayer && 
          s.round == lastLeft.round
        ).length;

        currentLeftDartIdx = playerDartsThisRound % 3;
      }

      // --- RIGHT LANE RESUME ---
      // Efficiently find the MAX round from gameplay records
      rightCurrentRound = gameTeamBuildUpBox.values
          .where((s) => s.idGame == widget.game.idGame && s.isSeatedRecord == false && s.isLeftLane == false)
          .fold<int>(1, (max, e) => e.round > max ? e.round : max);
      
      final rightHistory = history.where((s) => s.isLeftLane == false).toList();
      if (rightHistory.isNotEmpty) {
        final lastRight = rightHistory.last;
        rightCurrentTargetIndex = targets.indexOf(lastRight.nextTargetValue);
        rightCurrentPlayerIdx = rightPile.indexOf(lastRight.idPlayer);

        // Count only the darts thrown by THIS player in THIS round
        int playerDartsThisRound = rightHistory.where((s) => 
          s.idPlayer == lastRight.idPlayer && 
          s.round == lastRight.round
        ).length;

        currentRightDartIdx = playerDartsThisRound % 3;        
      }
    });
  }

  void _splitPlayers(bool resumeMode) {    
    if (resumeMode) {
      // 1. Reconstruct piles from seating records (round 0)
      final history = gameTeamBuildUpBox.values
          .where((s) => s.idGame == widget.game.idGame && s.isSeatedRecord == true && s.round == 0)
          .toList()          
          ..sort((a, b) => a.seatIndex.compareTo(b.seatIndex));

      // 2. Reconstruct the piles based on those specific seating records
      for (var record in history) {
        if (record.isLeftLane) {
          leftPile.add(record.idPlayer);
        } else {
          rightPile.add(record.idPlayer);
        }
      }
    } else {      
      final Random random = Random();

      List<int> shuffledIds = List<int>.from(widget.game.playersIDs);
      shuffledIds.shuffle(random);

      for (int i = 0; i < shuffledIds.length; i++) {
        int pId = shuffledIds[i];
        bool isLeft;

        if (i == shuffledIds.length - 1 && shuffledIds.length % 2 != 0) {
          isLeft = random.nextBool();
        } else {
          isLeft = (i % 2 == 0);
        }

        // Assign to piles and save the "Seated Record"
        if (isLeft) {
          leftPile.add(pId);
        } else {
          rightPile.add(pId);
        }        

        // This ensures the player is "locked" into this lane for future resumes
        final seatRecord = TblGameBuildUp(
          idGame: widget.game.idGame!,
          idPlayer: pId,
          isLeftLane: isLeft,
          seatIndex: i,
          isSeatedRecord: true, // This is the magic flag
          round: 0,
          targetValue: targets[0],
          isSingle: false,
          isDouble: false,
          isTriple: false,
          isMiss: false,
          nextTargetValue: targets[0],
        );

        gameTeamBuildUpBox.add(seatRecord);
      }
    }
  }

  void _undoSpecificLane(bool isLeft) {
    // 1. Get all entries for this specific game
    final gameHistory = gameTeamBuildUpBox.values
        .where((s) => s.idGame == widget.game.idGame && s.isSeatedRecord == false)
        .toList();

    if (gameHistory.isEmpty) return;

    // 2. Identify the correct pile to search in
    final targetPile = isLeft ? leftPile : rightPile;

    try {
      // 3. Find the last entry made by anyone in this specific lane
      final lastEntry = gameHistory.lastWhere(
        (entry) => targetPile.contains(entry.idPlayer),
      );

      // 4. Delete from Hive immediately
      gameTeamBuildUpBox.delete(lastEntry.key);

      setState(() {
        if (isLeft) {
          // Check freeze first, unfreeze if it's necessary
          if (isLeftWinnerFreezeUI) {
            isLeftWinnerFreezeUI = false;
            currentLeftDartIdx--;
          }else{
            // If we are undoing the first dart of the first player, go back one round
            if (leftCurrentPlayerIdx == 0 && currentLeftDartIdx == 0) {
              leftCurrentRound--;
            }
            
            // If we were at the start of a turn (0), we jump back to 2 dots of the previous state
            if (currentLeftDartIdx == 0) {
              currentLeftDartIdx = 2; 
            } else {
              currentLeftDartIdx--; // Otherwise just go back one dot
            }
          }

          // Re-verify hits for the current turn from Hive
          final playerHistory = gameTeamBuildUpBox.values
              .where((s) => s.idGame == widget.game.idGame && s.isSeatedRecord == false && s.idPlayer == lastEntry.idPlayer)
              .toList();
          
          int currentSetStart = (playerHistory.length ~/ 3) * 3;
          leftHitsInCurrentTurn = playerHistory
              .skip(currentSetStart)
              .where((s) => !s.isMiss)
              .length;

          leftCurrentTargetIndex = targets.indexOf(lastEntry.targetValue);
          leftCurrentPlayerIdx = targetPile.indexOf(lastEntry.idPlayer);
        } else {
          // Check freeze first, unfreeze if it's necessary
          if (isRightWinnerFreezeUI) {
            isRightWinnerFreezeUI = false;
            currentRightDartIdx--;
          }else{
            // If we are undoing the first dart of the first player, go back one round
            if (rightCurrentPlayerIdx == 0 && currentRightDartIdx == 0) {
              rightCurrentRound--;
            }
            
            // If we were at the start of a turn (0), we jump back to 2 dots of the previous state
            if (currentRightDartIdx == 0) {
              currentRightDartIdx = 2; 
            } else {
              currentRightDartIdx--; // Otherwise just go back one dot
            }
          }                    

          final playerHistory = gameTeamBuildUpBox.values
              .where((s) => s.idGame == widget.game.idGame && s.isSeatedRecord == false && s.idPlayer == lastEntry.idPlayer)
              .toList();

          int currentSetStart = (playerHistory.length ~/ 3) * 3;
          rightHitsInCurrentTurn = playerHistory
              .skip(currentSetStart)
              .where((s) => !s.isMiss)
              .length;

          rightCurrentTargetIndex = targets.indexOf(lastEntry.targetValue);
          rightCurrentPlayerIdx = targetPile.indexOf(lastEntry.idPlayer);
        }
      });      
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No scores to undo in this lane"))
      );
    }
  }
  
  List<Map<String, dynamic>> _getCurrentRankings({int? winnerId}) {
    List<Map<String, dynamic>> rankings = [];
    
    for (int i = 0; i < widget.game.playersIDs.length; i++) {
      int pId = widget.game.playersIDs[i];
      final hitCount = gameTeamBuildUpBox.values.where((s) => 
        s.idGame == widget.game.idGame && s.isSeatedRecord == false && s.idPlayer == pId && s.isMiss == false
      ).length;

      int targetIdx = _getPlayerActiveTargetIndex(pId);
      
      rankings.add({
        'target': targetIdx,
        'hits': hitCount,
        'name': playersBox.get(pId)?.fldNickName ?? "Player",
        'id': pId,
        'color': Colors.blueGrey.shade700,
      });
    }

    rankings.sort((a, b) {
      // 1. If we have an explicit winner, they ALWAYS go to the top
      if (winnerId != null) {
        if (a['id'] == winnerId) return -1;
        if (b['id'] == winnerId) return 1;
      }

      // 2. Standard Sorting for everyone else:
      // Compare Target Index (Higher is better)
      int targetComp = b['target'].compareTo(a['target']);
      if (targetComp != 0) return targetComp;

      // 3. Tie-breaker: Fewer hits (Lower is better)
      return a['hits'].compareTo(b['hits']);
    });

    return rankings;
  }

  List<Map<String, dynamic>> _getRankings() {
    final currentRanks = _getCurrentRankings();
    final allHistory = gameTeamBuildUpBox.values
        .where((s) => s.idGame == widget.game.idGame && s.isSeatedRecord == false)
        .toList();

    if (allHistory.isEmpty) return currentRanks;

    // 1. Calculate scores as they were BEFORE the last throw
    List<Map<String, dynamic>> previousRanks = [];
    for (int i = 0; i < widget.game.playersIDs.length; i++) {
      int pId = widget.game.playersIDs[i];
      
      // Find history for this player excluding the very last global entry
      final pHistory = allHistory.sublist(0, allHistory.length - 1)
          .where((s) => s.idPlayer == pId)
          .toList();

      // Use the actual value to find the index in the targets list
      int prevTargetValue = pHistory.isEmpty ? targets[0] : pHistory.last.nextTargetValue;
      int prevTargetIndex = targets.indexOf(prevTargetValue);
      
      previousRanks.add({'id': pId, 'targetIndex': prevTargetIndex});
    }

    // 2. Sort previous ranks to find old positions (Higher index = closer to Bull)
    previousRanks.sort((a, b) => b['targetIndex'].compareTo(a['targetIndex']));

    // 3. Compare positions
    return currentRanks.map((item) {
      int currPos = currentRanks.indexOf(item);
      int prevPos = previousRanks.indexWhere((p) => p['id'] == item['id']);
      
      return {
        ...item, // Copies all existing fields (name, id, color, etc.)
        'trend': prevPos > currPos ? 'up' : (prevPos < currPos ? 'down' : 'stable'),
      };
    }).toList();
  }

  double _getTapAngle(Offset pos, Size size) {
    final rad = size.width / 2;
    final deg = atan2(pos.dy - rad, pos.dx - rad) * (180 / pi);
    return deg < 0 ? deg + 360 : deg;
  }
  
  void _processZoneTap(Offset localPosition, Size size, bool isLeft) {
    double radius = size.width / 2;
    Offset center = Offset(radius, radius);
    double dist = (localPosition - center).distance / radius;

    // Identify who is throwing based on the lane tapped
    int pId = isLeft ? leftPile[leftCurrentPlayerIdx] : rightPile[rightCurrentPlayerIdx];
    int activeTargetIdx = _getPlayerActiveTargetIndex(pId);
    
    int targetVal = targets[activeTargetIdx];
    int leap = 0;

    if (targetVal == 25) {
      if (dist <= 0.04) {
        leap = 2;
      } else if (dist <= 0.09) {
        leap = 1;
      }
    } else {
      double tapAngle = _getTapAngle(localPosition, size);
      double targetAngle = TargetZonePainter.getAngleForValue(targetVal);
      double angleDiff = (tapAngle - targetAngle).abs();
      if (angleDiff > 180) angleDiff = 360 - angleDiff;
      if (angleDiff > 9) return; // Ignore taps outside the slice

      if (dist >= 0.405 && dist <= 0.485) {
        leap = 3;
      }
      else if (dist >= 0.69 && dist <= 0.77) {
        leap = 2;
      }
      else if ((dist >= 0.095 && dist <= 0.403) || (dist >= 0.487 && dist <= 0.687)) {
        leap = 1;
      }
    }

    _recordBuildUp(leap, isLeft);     
  }

  void _undoLastScore(bool isUndoFromDialog) {
    final gameHistory = gameTeamBuildUpBox.values
        .where((s) => s.idGame == widget.game.idGame && s.isSeatedRecord == false)
        .toList();

    if (gameHistory.isEmpty) return;

    final lastEntry = gameHistory.last;
    
    // Identify which player this entry belonged to
    int pId = lastEntry.idPlayer;
    bool isLeft = leftPile.contains(pId);

    // Delete from Hive
    gameTeamBuildUpBox.delete(lastEntry.key);

    setState(() {
      if (isLeft) {
        // Revert the dart dot and the hit counter for the left lane
        if (currentLeftDartIdx > 0) currentLeftDartIdx--;
        if (!lastEntry.isMiss && leftHitsInCurrentTurn > 0) {
           leftHitsInCurrentTurn--;
        }
        // Ensure the correct player in the pile is active
        leftCurrentPlayerIdx = leftPile.indexOf(pId);
      } else {
        // Revert the dart dot and the hit counter for the right lane
        if (currentRightDartIdx > 0) currentRightDartIdx--;
        if (!lastEntry.isMiss && rightHitsInCurrentTurn > 0) {
           rightHitsInCurrentTurn--;
        }
        // Ensure the correct player in the pile is active
        rightCurrentPlayerIdx = rightPile.indexOf(pId);
      }
    });    
  }

  int _getPlayerActiveTargetIndex(int playerId) {
    final history = gameTeamBuildUpBox.values.where((s) => 
      s.idGame == widget.game.idGame && s.isSeatedRecord == false && 
      s.idPlayer == playerId
    ).toList();

    if (history.isEmpty) return 0; 
    int lastVal = history.last.nextTargetValue;
    int idx = targets.indexOf(lastVal);
    return idx == -1 ? 0 : idx;
  }

  // 2. Update Record Logic
  void _recordBuildUp(int leap, bool isLeft) {
    int pId = isLeft ? leftPile[leftCurrentPlayerIdx] : rightPile[rightCurrentPlayerIdx];
    int currentIdx = _getPlayerActiveTargetIndex(pId);
    
    // Increment the specific lane counters
    if (isLeft) {      
      currentLeftDartIdx++;
      if (leap > 0) {
        leftHitsInCurrentTurn++;
      }
    } else {      
      currentRightDartIdx++;
      if (leap > 0) {
        rightHitsInCurrentTurn++;
      }
    }

    int nextIdx = (currentIdx + leap).clamp(0, targets.length - 1);

    final gameBuildUp = TblGameBuildUp(
      idGame: widget.game.idGame!, 
      idPlayer: pId,
      isLeftLane: isLeft,
      seatIndex: isLeft ? (leftCurrentPlayerIdx * 2) : (rightCurrentPlayerIdx * 2 + 1),
      isSeatedRecord: false,
      round: isLeft ? leftCurrentRound : rightCurrentRound,
      targetValue: targets[currentIdx], 
      isSingle: leap == 1,
      isDouble: leap == 2, 
      isTriple: leap == 3,
      isMiss: leap == 0,
      nextTargetValue: targets[nextIdx],
    );

    gameTeamBuildUpBox.add(gameBuildUp);
    
    setState(() {
      // 1. THE WINNER DETECTED
      if (targets[currentIdx] == 25 && leap > 0) {         
        if (isLeft) {
          isLeftWinnerFreezeUI = true;
        } else {
          isRightWinnerFreezeUI = true;
        }
      }else{
        if (isLeft) {
          leftCurrentTargetIndex = nextIdx;
        } else {
          rightCurrentTargetIndex = nextIdx;
        }
      }

      // ignore: unused_local_variable
      bool isOneLaneFrozen = isLeft ? isLeftWinnerFreezeUI : isRightWinnerFreezeUI;
    
      // if (isOneLaneFrozen) {
      // return false; 
      // }

      // _checkTurnEnd returns true if the player hit a streak and is re-throwing
      // ignore: unused_local_variable
      bool playerHasBonusRound = _checkTurnEnd(isLeft);
      
      bool someoneIsFrozen = isLeftWinnerFreezeUI || isRightWinnerFreezeUI;

      // If someone is frozen and this specific turn is officially finished
      if (someoneIsFrozen ) { // && !isStillThrowing) {
        bool timeMatched = false;

        // 1. Get the latest record for the Left Lane from Hive
        final lastLeftRecord = gameTeamBuildUpBox.values.lastWhere(
          (r) => r.isLeftLane == true,
          orElse: () => TblGameBuildUp(idGame: -1, idPlayer: -1, isLeftLane: true, seatIndex: -1, isSeatedRecord: false, round: -1, targetValue: -1, isSingle: false, isDouble: false, isTriple: false, isMiss: false, nextTargetValue: -1),
        );

        // 2. Get the latest record for the Right Lane from Hive
        final lastRightRecord = gameTeamBuildUpBox.values.lastWhere(
          (r) => r.isLeftLane == false,
          orElse: () => TblGameBuildUp(idGame: -1, idPlayer: -1, isLeftLane: false, seatIndex: -1, isSeatedRecord: false, round: -1, targetValue: -1, isSingle: false, isDouble: false, isTriple: false, isMiss: false, nextTargetValue: -1),
        );

        if (lastLeftRecord.idGame != -1 && lastRightRecord.idGame != -1) {
          int leftPileIdx = (lastLeftRecord.seatIndex / 2).floor();
          int rightPileIdx = (lastRightRecord.seatIndex / 2).floor();

          if (isLeftWinnerFreezeUI) {
            // Left won: Time is matched if Right is in the same round and same/later pile index
            // OR if Right has already progressed to a later round.
            timeMatched = (lastRightRecord.round > lastLeftRecord.round) || 
                          (lastRightRecord.round == lastLeftRecord.round && rightPileIdx >= leftPileIdx);
          } else if (isRightWinnerFreezeUI) {
            // Right won: Time is matched if Left is in the same round and same/later pile index
            // OR if Left has already progressed to a later round.
            timeMatched = (lastLeftRecord.round > lastRightRecord.round) || 
                          (lastLeftRecord.round == lastRightRecord.round && leftPileIdx >= rightPileIdx);
          }
        }

        if (timeMatched) {
          // Use the winner's ID from the lane that is actually frozen
          int winnerPid = isLeftWinnerFreezeUI 
              ? lastLeftRecord.idPlayer 
              : lastRightRecord.idPlayer;
              
          _handleWinnerLogic(winnerPid, isLeftWinnerFreezeUI);
        }
      }
    });
  }

  void _handleWinnerLogic(int winnerId, bool isLeft) {    
    // Identify what needs to be deleted
    final keysToDelete = _getKeysToPrune(winnerId, isLeft);

    // If we found entries that outran the win, prune them
    if (keysToDelete.isNotEmpty) {
      _pruneOutrunEntries(keysToDelete, isLeft);
    }
    
    _endGame(winnerId);
  }

  List<dynamic> _getKeysToPrune(int winnerId, bool isLeft) {
    // 1. Find the winning entry to get the exact seatIndex and round
    final winningEntry = gameTeamBuildUpBox.values.lastWhere(
      (s) => s.idGame == widget.game.idGame && 
            s.idPlayer == winnerId && 
            s.isSeatedRecord == false
    );
    
    final int winningSeatIndex = winningEntry.seatIndex;
    final int winningRound = isLeft ? leftCurrentRound : rightCurrentRound;

    return gameTeamBuildUpBox.values
        .where((s) => s.idGame == widget.game.idGame && s.isSeatedRecord == false)
        .where((entry) {
          // Condition 1: Any entry in a future round
          if (entry.round > winningRound) return true;

          // Condition 2: Current round pruning based on your seatIndex sequence
          if (entry.round == winningRound) {
            // If the winner is Left (even index), we prune everyone after their partner (index + 1)
            // If the winner is Right (odd index), we prune everyone after them (index)
            if (isLeft) {
              return entry.seatIndex > (winningSeatIndex + 1);
            } else {
              return entry.seatIndex > winningSeatIndex;
            }
          }
          return false;
        })
        .map((e) => e.key)
        .toList();
  }

  void _pruneOutrunEntries(List<dynamic> keysToDelete, bool winnerIsLeft) {
    // 1. Execute the deletion from Hive
    for (var key in keysToDelete) {
      gameTeamBuildUpBox.delete(key);
    }

    // 2. Sync the opponent's state directly
    setState(() {
      if (winnerIsLeft) {
        rightCurrentRound = leftCurrentRound;
        if (rightCurrentPlayerIdx > leftCurrentPlayerIdx) {
          rightCurrentPlayerIdx = leftCurrentPlayerIdx;
          currentRightDartIdx = 0; 
          rightHitsInCurrentTurn = 0;
        }
      } else {
        leftCurrentRound = rightCurrentRound;
        if (leftCurrentPlayerIdx > rightCurrentPlayerIdx) {
          leftCurrentPlayerIdx = rightCurrentPlayerIdx;
          currentLeftDartIdx = 0;
          leftHitsInCurrentTurn = 0;
        }
      }
    });
  }

  // 3. Independent Turn End
  bool _checkTurnEnd(bool isLeft) {        
    int dartIdx = isLeft ? currentLeftDartIdx : currentRightDartIdx;
    
    // Use the history to be 100% sure of the hits in this set
    int pId = isLeft ? leftPile[leftCurrentPlayerIdx] : rightPile[rightCurrentPlayerIdx];
    int currentRound = isLeft ? leftCurrentRound : rightCurrentRound;    
    int hits = gameTeamBuildUpBox.values
      .where((r) => r.idPlayer == pId && r.round == currentRound && !r.isMiss).length;
    bool isBonus = (hits % 3 == 0);

    if (dartIdx >= 3) {            
      setState(() {
        if (isLeft) {
          currentLeftDartIdx = 0;
          leftHitsInCurrentTurn = 0;
          if (!isBonus) {
            if (leftCurrentPlayerIdx == leftPile.length - 1) {
              leftCurrentRound++;
            }
            leftCurrentPlayerIdx = (leftCurrentPlayerIdx + 1) % leftPile.length;
          }
        } else {
          currentRightDartIdx = 0;
          rightHitsInCurrentTurn = 0;
          if (!isBonus) {
            if (rightCurrentPlayerIdx == rightPile.length - 1) {
              rightCurrentRound++;
            }
            rightCurrentPlayerIdx = (rightCurrentPlayerIdx + 1) % rightPile.length;
          }
        }
      });
    }

    if (isBonus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("3/3! RE-THROW"), 
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        )
      );
      
      return true;
    }else{
      return false;
    }
  }

  // --- LOGIC: GAME OVER ---
  void _endGame(int winnerId) {
    // 1. Get the exact same rankings used in the right panel
    final finalResults = _getCurrentRankings(winnerId: winnerId); 
    final winner = finalResults[0]; // This will now definitely be the winnerId player
    final int count = finalResults.length;
    bool isOdd = count % 2 != 0;
    bool winnerPlaysAlone = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder( // Allows the UI to refresh when toggle changes
          builder: (context, setDialogState) {
            // Calculate Teams based on current toggle state
            List<Map<String, dynamic>> teams = [];
            if (!isOdd) {
              // EVEN: Standard 1st+Last, 2nd+5th...
              for (int i = 0; i < count / 2; i++) {
                teams.add({'p1': finalResults[i], 'p2': finalResults[count - 1 - i]});
              }
            } else {
              // ODD: Interactive logic
              if (winnerPlaysAlone) {
                // Option A: Winner alone, then 2nd+7th, 3rd+6th...
                teams.add({'p1': finalResults[0], 'p2': {'name': 'DUMMY (Self)', 'isDummy': true}});
                int left = 1, right = count - 1;
                while (left < right) {
                  teams.add({'p1': finalResults[left++], 'p2': finalResults[right--]});
                }
              } else {
                // Option B: Winner+7th, 2nd+6th, 3rd+5th... 4th is alone
                int left = 0, right = count - 1;
                while (left < right) {
                  teams.add({'p1': finalResults[left++], 'p2': finalResults[right--]});
                }
                teams.add({'p1': finalResults[left], 'p2': {'name': 'DUMMY (Self)', 'isDummy': true}});
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              // We leave 'title' and 'actions' null to give all space to 'content'
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. TOP SECTION (Moved from Title)
                      Align(
                        alignment: Alignment.topRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.undo, size: 18, color: Colors.white),
                          label: const Text("Undo last entry", style: TextStyle(fontSize: 10)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () {                  
                            Navigator.of(context).pop();
                            _undoLastScore(true);
                          },
                        ),
                      ),
                      Image.asset('assets/png/trophy_1_player_48x80.png'),
                      const SizedBox(height: 2),
                      Text("WINNER", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      
                      const SizedBox(height: 2),

                      // 2. WINNER HIGHLIGHT
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: winner['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: winner['color'], width: 2),
                        ),
                        child: Text(
                          "${winner['name']}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: winner['color'])
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 3. STANDINGS LIST
                      const Text("FINAL STANDINGS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Row( 
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("PLAYERS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text("TARGETS (HITS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ]
                      ),
                      const Divider(),
                      
                      // Map the results directly into the column
                      ...finalResults.map((res) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(res['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${targetLabels[res['target']]} (${res['hits']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )),

                      const SizedBox(height: 24),

                      // 4. TEAMS LIST
                      if (isOdd) ...[
                        const Text("WINNER'S CHOICE", style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ToggleButtons(
                          isSelected: [winnerPlaysAlone, !winnerPlaysAlone],
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: Colors.deepOrange,
                          constraints: const BoxConstraints(minHeight: 36, minWidth: 140),
                          onPressed: (index) {
                            setDialogState(() => winnerPlaysAlone = (index == 0));
                          },
                          children: const [
                            Text("Play Alone"),
                            Text("Team with Last"),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 5. TEAM BUILD UP LIST
                      const Text("TEAM BUILD UP", style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                      const Divider(),
                      
                      ...teams.map((team) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueGrey.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(team['p1']['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.link, size: 16, color: Colors.grey),
                            ),
                            Text(team['p2']['name'], 
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: team['p2']['isDummy'] == true ? Colors.blue : Colors.black
                              )
                            ),
                          ],
                        ),
                      )),

                      // 5. BOTTOM BUTTONS (Moved from Actions)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text(
                          "CLOSE AND SAVE THE GAME",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange.shade400,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: () => _gameClosed(finalResults),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "** If you want to keep your statistics, you must press 'CLOSE AND SAVE'. Otherwise, this game's data will be lost.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _gameClosed(List<Map<String, dynamic>> finalResults) {    
    // if it's a tie, for me.. their is no winner
    widget.game.idPlayerWinner = finalResults[0]['id']; // keep the winner player id          

    // Save and end the game :)
    widget.game.isEnded = true;
    widget.game.save();
    
    // 2. Clear the Navigation stack back to the very first screen
    // This will dismiss the Dialog AND the GameScoreScreen in one go.
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }  

  @override
  Widget build(BuildContext context) {
    //final double safeBottom = min(MediaQuery.of(context).padding.bottom, 10.0); // Capture the safe area inset

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 48.0,
                height: 48.0,
                child: Image.asset(
                  'assets/png/logos/darts_101_logo_48x48.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Text(
              widget.gameText,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: widget.tileBackgroundColor,
        foregroundColor: Colors.white,        
      ),
      
      body: SafeArea(
        top: false,
        child : Stack(
          children: [
            // 1. The Dartboards (This stays as the background layer)
            Column(
              children: [
                Expanded(
                  child: Row(
                    children: [                      
                      Expanded(child: _buildInputZone(true)),
                      SizedBox(width: 2),
                      SizedBox(
                        width: 180, // Same width as your old ranking board
                        child: Column(
                          children: [
                            // 1. Fake Divider TOP (Optical continuation)
                            Container(
                              width: 2, 
                              height: 245, // Adjust height to match your top margin
                              color: Colors.blueGrey.withValues(alpha: 0.3),
                            ),
                                                        
                            // 2. THE RANKINGS (Literal old version)
                            Expanded(
                              child: _buildLiveRankings(),
                            ),
                            
                            // 3. Fake Divider BOTTOM (Optical continuation)
                            Container(
                              width: 2, 
                              height: 40, // Adjust height to clear the bottom MISS buttons
                              color: Colors.blueGrey.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 2),
                      Expanded(child: _buildInputZone(false)),
                    ],
                  ),
                ),
              ],
            ),
            
            // Left Player List
            Positioned(
              top: 0,
              right: (MediaQuery.of(context).size.width / 2) + 10,
              child: _buildLanePlayerList(true),
            ),
            // Right Player List
            Positioned(
              top: 0,
              left: (MediaQuery.of(context).size.width / 2) + 10,
              child: _buildLanePlayerList(false),
            ),
          ],
        ),
      ),
    );
  }  

  Widget _buildInputZone(bool isLeftSide) {
    // Determine if this specific lane is currently frozen
    bool isFrozen = isLeftSide ? isLeftWinnerFreezeUI : isRightWinnerFreezeUI;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          height: 40,
          child: Stack(
            children: [
              // 1. THE LANE LABEL: Always perfectly centered in the lane
              Center(
                child: _buildLaneLabel(isLeftSide), 
              ),

              // 2. THE ROUND BADGE: Pinned to the "inner" side
              Positioned(
                // If Left lane, pin to the right (inner). If Right lane, pin to the left (inner).
                right: isLeftSide ? 5 : null,
                left: isLeftSide ? null : 5,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildRoundBadge(isLeftSide),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              IgnorePointer(
                ignoring: isFrozen, // Locks the GestureDetector
                child: Center(
                  child: LayoutBuilder(builder: (context, c) {
                    double size = min(c.maxWidth, c.maxHeight);
                    int lanePId = isLeftSide ? leftPile[leftCurrentPlayerIdx] : rightPile[rightCurrentPlayerIdx];            
                    int activeTargetIdx = _getPlayerActiveTargetIndex(lanePId);
                    int currentTargetValue = targets[activeTargetIdx];

                    // --- REFINED VIEWPORT LOGIC ---
                    double zoomScale = 1.6; 
                    Alignment zoomAlignment;

                    if (currentTargetValue == 12 || currentTargetValue == 20 || currentTargetValue == 18) {
                      // Push Top down slightly more to see the "20" label
                      zoomAlignment = const Alignment(0.0, -0.9); 
                    } else if (currentTargetValue == 13 || currentTargetValue == 10 || currentTargetValue == 15) {
                      // Push Right further left to see the numbers 10, 13, 15
                      zoomAlignment = const Alignment(0.95, 0.0);  
                    } else if (currentTargetValue == 17 || currentTargetValue == 19) {
                      // Push Bottom up to see 17 and 19 labels
                      zoomAlignment = const Alignment(0.0, 0.9);  
                    } else if (currentTargetValue == 16 || currentTargetValue == 11 || currentTargetValue == 14) {
                      // Push Left further right to see 11, 14, 16
                      zoomAlignment = const Alignment(-0.95, 0.0); 
                    } else if (currentTargetValue == 25) {
                      zoomAlignment = Alignment.center;
                      zoomScale = 2.5; 
                    } else {
                      zoomAlignment = Alignment.center;
                      zoomScale = 1.0;
                    }

                    return GestureDetector(
                      onTapUp: (d) {
                        double centerX = size / 2;
                        double centerY = size / 2;
                        
                        // 1. Calculate how much the alignment shifted the board
                        double shiftX = zoomAlignment.x * centerX * (zoomScale - 1);
                        double shiftY = zoomAlignment.y * centerY * (zoomScale - 1);
                        
                        // 2. Reverse the shift and the scale
                        // We subtract the shift first, then scale back to 1:1, then move back to center
                        double touchX = (d.localPosition.dx - centerX + shiftX) / zoomScale + centerX;
                        double touchY = (d.localPosition.dy - centerY + shiftY) / zoomScale + centerY;
                        
                        _processZoneTap(Offset(touchX, touchY), Size(size, size), isLeftSide);
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
                                  SvgPicture.asset('assets/svg/dartboard.svg', width: size, height: size),
                                  CustomPaint(
                                    size: Size(size, size), 
                                    painter: TargetZonePainter(currentTargetValue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),  
              ),
              if (isFrozen)
                Positioned.fill(
                  child: _buildFrostedOverlay(),
                ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: isLeftSide 
              ? [
                  // LANE 1 (Left): Miss on left, Undo on right
                  IgnorePointer(
                    ignoring: isFrozen,
                    child: Opacity(
                      opacity: isFrozen ? 0.4 : 1.0, 
                      child: _buildSideMissButton(true),
                    ),
                  ),
                  _buildUndoButton(true),
                ]
              : [
                  // LANE 2 (Right): Undo on left, Miss on right
                  _buildUndoButton(false),
                  IgnorePointer(
                    ignoring: isFrozen,
                    child: Opacity(
                      opacity: isFrozen ? 0.4 : 1.0, 
                      child: _buildSideMissButton(false),
                    ),
                  ),
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

  Widget _buildUndoButton(bool isLeft) {
    return SizedBox(
      width: 160,
      height: 105,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLeft ? Colors.deepOrange.shade400 : Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
        onPressed: () {
          final hasHistory = gameTeamBuildUpBox.values.any((s) => 
            s.idGame == widget.game.idGame && s.isSeatedRecord == false && 
            (isLeft ? leftPile.contains(s.idPlayer) : rightPile.contains(s.idPlayer))
          );
          if (!hasHistory) return null;
          return isLeft ? () => _undoSpecificLane(true) : () => _undoSpecificLane(false);
        }(),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.undo, size: 42),
            Text("UNDO", style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLaneLabel(bool isLeft) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isLeft ? Colors.deepOrange.shade400 : Colors.blueAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isLeft ? "LANE 1" : "LANE 2",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildRoundBadge(bool isLeft) {
    final int currentSideRound = isLeft ? leftCurrentRound : rightCurrentRound;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLeft ? Colors.deepOrange.shade400 : Colors.blueAccent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        "ROUND $currentSideRound",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildSideMissButton(bool isLeft) {
    return SizedBox(
      width: 160, 
      height: 105,
      child: ElevatedButton(
        // The heroTag is removed because ElevatedButton doesn't use it
        onPressed: () => _recordBuildUp(0, isLeft),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6, // Matches the "floating" feel of the original
          padding: EdgeInsets.zero, // Ensures content isn't pushed around
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.not_interested, size: 42),
            Text("MISS", style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }  

  Widget _buildLiveRankings() {
    final ranks = _getRankings();
    
    return ClipRRect( // Clips the blur effect to the container bounds
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // The "Frosted Glass" effect
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7), // Deep semi-transparent dark
            border: Border(left: BorderSide(color: Colors.white24, width: 0.5)),
          ),
          child: Column(
            children: [
              // Header with Trophies Icons
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset('assets/png/trophy_36x36.png'),
                        Column(
                          children: [
                            Text("Players", 
                            style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)
                            ),
                            Text("Ranking", 
                            style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)
                            ),
                          ],
                        ),
                        Image.asset('assets/png/trophy_36x36.png'),                        
                      ]
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Row(                        
                        children: [                        
                          SizedBox(
                            width: 55,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("TARG", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("HIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),                                
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 2.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("PLAYER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: ranks.length,
                  itemBuilder: (context, index) {
                    final item = ranks[index];
                    final bool isFirst = index == 0;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isFirst ? Colors.orange.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                        visualDensity: const VisualDensity(vertical: -4),
                        title: Row(
                          children: [                            
                            SizedBox(
                              width: 55,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    targetLabels[item['target']], 
                                    style: TextStyle(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold, 
                                      color: isFirst ? Colors.orangeAccent : Colors.white,
                                    )
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "${item['hits']}",
                                    style: TextStyle(
                                      fontSize: 14, 
                                      fontWeight: FontWeight.bold, 
                                      color: isFirst ? Colors.orangeAccent : Colors.white,
                                    )
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 14, 
                                        fontWeight: FontWeight.bold, 
                                        color: isFirst ? Colors.orangeAccent : Colors.white,
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanePlayerList(bool isLeft) {
    List<int> pile = isLeft ? leftPile : rightPile;
    int currentIdx = isLeft ? leftCurrentPlayerIdx : rightCurrentPlayerIdx;

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: List.generate(pile.length, (index) {
          int pId = pile[index];
          String name = playersBox.get(pId)?.fldNickName ?? "P";
          bool isDone = index < currentIdx;
          bool isActive = index == currentIdx;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Align(
              alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // crossAxisAlignment: isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name.toUpperCase(),
                    style: TextStyle(
                      fontSize: isActive ? 20 : 16,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isDone 
                        ? Colors.grey.withValues(alpha: 0.5) 
                        : (isActive ? isLeft ? Colors.deepOrange.shade400 : Colors.blueAccent : Colors.black),
                    ),
                  ),
                  if (isActive)
                    Row(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (dIdx) {
                        int laneDartIdx = isLeft ? currentLeftDartIdx : currentRightDartIdx;
                        return Icon(
                          Icons.circle,
                          size: 16,
                          color: dIdx < laneDartIdx ? Colors.orange : Colors.grey.shade300,
                        );
                      }),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class TargetZonePainter extends CustomPainter {
  final int targetValue;  

  TargetZonePainter(this.targetValue);

  // Standard dartboard angles mapping...
  static double getAngleForValue(int val) {
    Map<int, double> angles = {
      20: 270, 1: 288, 18: 306, 4: 324, 13: 342, 
      6: 0, 10: 18, 15: 36, 2: 54, 17: 72, 
      3: 90, 19: 108, 7: 126, 16: 144, 8: 162, 
      11: 180, 14: 198, 9: 216, 12: 234, 5: 252
    };
    return angles[val] ?? 0;
  }

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

  @override
  void paint(Canvas canvas, Size size) {
    if (targetValue == 25) {
      _paintBullseye(canvas, size);
      return;
    }

    double angle = getAngleForValue(targetValue);
    
    // RECALIBRATED RATIOS (to pull highlights away from the number ring)
    // Double Zone (Outer Ring)
    _drawArcSegment(canvas, size, angle, 0.69, 0.77, Colors.purpleAccent.withValues(alpha: 0.9));
    // Triple Zone (Inner Ring)
    _drawArcSegment(canvas, size, angle, 0.405, 0.485, Colors.purpleAccent.withValues(alpha: 0.9));
    // Single Zone 1 (Main Area)
    _drawArcSegment(canvas, size, angle, 0.095, 0.403, Colors.yellow.withValues(alpha: 0.9));
    // Single Zone 2 (Main Area)
    _drawArcSegment(canvas, size, angle, 0.487, 0.687, Colors.yellow.withValues(alpha: 0.9));
  }

  void _drawArcSegment(Canvas canvas, Size size, double centerAngle, double innerRadiusRatio, double outerRadiusRatio, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    double startAngle = (centerAngle - 9) * (pi / 180);
    double sweepAngle = 18 * (pi / 180);
    double radius = size.width / 2;
    Offset center = Offset(radius, radius);

    Path path = Path();
    // Start at outer arc
    path.arcTo(Rect.fromCircle(center: center, radius: radius * outerRadiusRatio), startAngle, sweepAngle, true);
    // Line to inner arc and sweep back
    path.arcTo(Rect.fromCircle(center: center, radius: radius * innerRadiusRatio), startAngle + sweepAngle, -sweepAngle, false);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TargetZonePainter oldDelegate) => oldDelegate.targetValue != targetValue;
}