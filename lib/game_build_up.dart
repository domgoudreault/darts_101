import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:darts_101/database/player.dart';
import 'package:darts_101/database/game.dart';
import 'package:darts_101/database/gamebuildup.dart';

enum TargetZone { single, double, triple }
enum BuildUpMode { forward, backward }

class GameBuildUpScreen extends StatefulWidget {
  final Game game;
  final String gameText;
  
  const GameBuildUpScreen({super.key, required this.game, required this.gameText});

  @override
  State<GameBuildUpScreen> createState() => _GameBuildUpScreenState();
}

class _GameBuildUpScreenState extends State<GameBuildUpScreen> {
  // 1. Game Configuration
  final List<int> targets = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25];
  final List<String> targetLabels = ["10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "BULL"];

  bool _isProcessing = false;
  int currentPlayerIndex = 0; // Index in widget.game.playersIDs
  int currentTargetIndex = 0; // Index in targets list (0-11)
  int currentDartIndex = 0;   // 0, 1, 2
  int hitsInCurrentTurn = 0;  // 0, 1, 2, 3

  late Box<GameBuildUp> gameTeamBuildUpBox;
  late Box<Player> playersBox;    

  @override
  void initState() {
    super.initState();
    gameTeamBuildUpBox = Hive.box<GameBuildUp>('gameTeamBuildUpBox');
    playersBox = Hive.box<Player>('playersBox'); 
  }
  
  List<Map<String, dynamic>> _getCurrentRankings({int? winnerId}) {
    List<Map<String, dynamic>> rankings = [];
    
    for (int i = 0; i < widget.game.playersIDs.length; i++) {
      int pId = widget.game.playersIDs[i];
      final hitCount = gameTeamBuildUpBox.values.where((s) => 
        s.idGame == widget.game.idGame && s.idPlayer == pId
      ).length;

      int targetIdx = _getPlayerCurrentTargetIndex(pId, i);
      
      rankings.add({
        'target': targetIdx,
        'hits': hitCount,
        'name': playersBox.get(pId)?.nickName ?? "Player",
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

  List<Map<String, dynamic>> _getRankingsWithTrends() {
    final currentRanks = _getCurrentRankings();
    final allHistory = gameTeamBuildUpBox.values
        .where((s) => s.idGame == widget.game.idGame)
        .toList();

    if (allHistory.isEmpty) return currentRanks;

    // 1. Calculate scores as they were BEFORE the last throw
    List<Map<String, dynamic>> previousRanks = [];
    for (int i = 0; i < widget.game.playersIDs.length; i++) {
      int pId = widget.game.playersIDs[i];
      
      // Find history for this player excluding the very last global entry
      final pHistory = allHistory.sublist(0, allHistory.length - 1)
          .where((s) => s.idPlayer == pId && s.seatIndex == i)
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

  void _processZoneTap(Offset localPosition, Size size) {
    double radius = size.width / 2;
    Offset center = Offset(radius, radius);
    double dist = (localPosition - center).distance / radius;

    int pId = widget.game.playersIDs[currentPlayerIndex];
    int activeTargetIdx = _getPlayerCurrentTargetIndex(pId, currentPlayerIndex);
    
    if (activeTargetIdx < 0 || activeTargetIdx >= targets.length) return;

    int targetVal = targets[activeTargetIdx];

    // 1. Angle Check (Only for non-bull targets)
    if (targetVal != 25) {
      double tapAngle = _getTapAngle(localPosition, size);
      double targetAngle = TargetZonePainter.getAngleForValue(targetVal);
      double angleDiff = (tapAngle - targetAngle).abs();
      if (angleDiff > 180) angleDiff = 360 - angleDiff;
      
      // If they tapped outside the 18-degree wedge of the target number, ignore
      if (angleDiff > 9) return; 
    }

    // 2. Leap Check - EXACTLY MATCHING YOUR PAINTER RATIOS
    int leap = 0;
    
    if (targetVal == 25) {
      // Bullseye Logic (0.04 and 0.09)
      if (dist <= 0.04) {
        leap = 2; // Double Bull
      } else if (dist <= 0.09) {
        leap = 1; // Single Bull
      } 
    } else {
      // TRIPLE RING: (0.405 to 0.485)
      if (dist >= 0.405 && dist <= 0.485) {
        leap = 3;
      } 
      // DOUBLE RING: (0.69 to 0.77)
      else if (dist >= 0.69 && dist <= 0.77) {
        leap = 2;
      } 
      // SINGLE ZONE 1: (0.095 to 0.403)
      // SINGLE ZONE 2: (0.487 to 0.687)
      else if ((dist >= 0.095 && dist <= 0.403) || (dist >= 0.487 && dist <= 0.687)) {
        leap = 1;
      }
    }

    // 3. Final Execution
    if (leap > 0) {
      _recordBuildUp(leap);
    } else {
      // Tapped the board but didn't hit the target wedge or the right ring
      _handleMiss();
    }
  }

  void _undoLastScore(bool isUndoFromDialog) {
    final gameHistory = gameTeamBuildUpBox.values
        .where((s) => s.idGame == widget.game.idGame)
        .toList();

    if (gameHistory.isEmpty) return;

    final lastEntry = gameHistory.last;
    gameTeamBuildUpBox.delete(lastEntry.key);

    setState(() {
      // Sync pointers to exactly where the deleted throw happened
      currentPlayerIndex = lastEntry.seatIndex;
      
      // Calculate what the global round was for that specific throw
      // This handles wrapping back from Round 5 to Round 4 correctly
      int pId = widget.game.playersIDs[currentPlayerIndex];
      currentTargetIndex = _getPlayerCurrentTargetIndex(pId, currentPlayerIndex);
    });

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Last score removed"), duration: Duration(seconds: 1)),
    );
  }

  // Change this helper to find where a specific player is currently standing
  int _getPlayerCurrentTargetIndex(int playerId, int seatIndex) {
    final history = gameTeamBuildUpBox.values.where((s) => 
      s.idGame == widget.game.idGame && 
      s.idPlayer == playerId && 
      s.seatIndex == seatIndex
    ).toList();

    if (history.isEmpty) return 0; // Starts at '10' (index 0)
    
    // Their current target is the 'nextTargetValue' from their last saved entry
    int lastVal = history.last.nextTargetValue;
    int idx = targets.indexOf(lastVal);
    return idx == -1 ? 0 : idx;
  }

  // This is called when they tap the "MISS" button or tap the wrong area of the board
  void _handleMiss() {
    setState(() {
      currentDartIndex++;
      _checkTurnEnd();
    });
  }

  void _recordBuildUp(int leap) async {
    if (_isProcessing) return;
    _isProcessing = true;
    
    try {
      int pId = widget.game.playersIDs[currentPlayerIndex];
      int currentIdx = _getPlayerCurrentTargetIndex(pId, currentPlayerIndex);
      
      // 1. Calculate and Save Hit (Since leap > 0)
      hitsInCurrentTurn++; 
      int nextIdx = (currentIdx + leap).clamp(0, targets.length - 1);

      final gameBuildUp = GameBuildUp(
        idGame: widget.game.idGame!,
        idPlayer: pId,
        seatIndex: currentPlayerIndex,
        targetValue: targets[currentIdx],
        hitDouble: leap == 2,
        hitTriple: leap == 3,
        nextTargetValue: targets[nextIdx],
      );

      await gameTeamBuildUpBox.add(gameBuildUp);
      gameBuildUp.idGameBuildUp = gameBuildUp.key as int;
      await gameBuildUp.save();

      // 2. Winning Check
      if (targets[currentIdx] == 25) {
        _endGame(pId);
        _isProcessing = false;
        return;
      }

      // 3. Advance Dart Counter
      setState(() {
        currentDartIndex++;
        _checkTurnEnd();
      });
    }finally{
      await Future.delayed(const Duration(milliseconds: 300));
      _isProcessing = false;
    }
  }

  void _checkTurnEnd() {
    if (currentDartIndex < 3) return;
    
    bool isBonus = hitsInCurrentTurn == 3;
    currentDartIndex = 0;
    hitsInCurrentTurn = 0;

    if (isBonus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("3/3! RE-THROW"), backgroundColor: Colors.green));
    } else {
      currentPlayerIndex = (currentPlayerIndex + 1) % widget.game.playersIDs.length;
    }

    // Refresh the target index for the new player/turn
    int nextPlayerId = widget.game.playersIDs[currentPlayerIndex];
    currentTargetIndex = _getPlayerCurrentTargetIndex(nextPlayerId, currentPlayerIndex);
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
    widget.game.ended = true;
    widget.game.save();
    
    // 2. Clear the Navigation stack back to the very first screen
    // This will dismiss the Dialog AND the GameScoreScreen in one go.
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }  

  @override
  Widget build(BuildContext context) {
    final activePlayerId = widget.game.playersIDs[currentPlayerIndex];
    final activePlayer = playersBox.get(activePlayerId);

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      // --- KEEPING YOUR APPBAR AS IS ---
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 48.0,
                height: 48.0,
                child: Image.asset(
                  'assets/png/darts_101_logo_48x48.png',
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
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: "Undo last turn",
            onPressed: (currentTargetIndex == 0 && currentPlayerIndex == 0)
                ? null
                : () => _undoLastScore(false),
          ),
        ],
      ),

      // --- NEW THREE-COLUMN BODY ---
      body: Row(
        children: [
          // 1. LEFT PANEL: Player & Target
          Container(
            width: 160,
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TARGET", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(
                  targetLabels[_getPlayerCurrentTargetIndex(activePlayerId, currentPlayerIndex)],
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.deepOrange.shade400),
                ),
                const SizedBox(height: 30),
                const Text("PLAYER", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(
                  activePlayer?.nickName ?? "",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Is Throwing...",
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.deepOrange.shade400),
                ),
              ],
            ),
          ),

          // 2. CENTER: Dartboard & Floating Button
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double boardSize = min(constraints.maxWidth, constraints.maxHeight) * 0.95;
                      return _buildDartboard(boardSize);
                    },
                  ),
                ),
                // FLOATING MISS BUTTON (Bottom Right of the center zone)
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: FloatingActionButton.extended(
                    onPressed: () => _handleMiss(),
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.not_interested),
                    label: const Text("MISS", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // 3. RIGHT PANEL: Permanent Ranking
          SizedBox(
            width: 260,            
            child: _buildLiveRankings(), // Note: Remove the AnimatedPositioned from this function!
          ),
        ],
      ),
    );
  }

  Widget _buildDartboard(double size) {
    int activePId = widget.game.playersIDs[currentPlayerIndex];
    int activeTargetIdx = _getPlayerCurrentTargetIndex(activePId, currentPlayerIndex);

    return GestureDetector(
      onTapUp: (details) => _processZoneTap(details.localPosition, Size(size, size)),
      child: FittedBox(
        child: Stack(
          children: [
            SvgPicture.asset(
              'assets/svg/dartboard.svg',
              width: size,
              height: size,
              fit: BoxFit.contain,
              // placeholderBuilder: (context) => const CircularProgressIndicator(), // Optional loader
            ),
            CustomPaint(
              size: Size(size, size),
              painter: TargetZonePainter(targets[activeTargetIdx], Size(size, size)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveRankings() {
    final ranks = _getRankingsWithTrends();
    
    return ClipRRect( // Clips the blur effect to the container bounds
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomLeft: Radius.circular(24),
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
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset('assets/png/trophy_24x24.png'),
                        Text("Players Ranking", 
                          style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                        Image.asset('assets/png/trophy_24x24.png'),                        
                      ]
                    ),
                    const SizedBox(height: 2),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [                        
                          Text("TARGETS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text("HITS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text("PLAYERS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text("TREND", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                    final String trend = (item['trend'] ?? 'stable').toString();

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isFirst ? Colors.orange.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: const VisualDensity(vertical: -4),
                        leading: SizedBox(
                          width: 100, // Widened to fit both columns
                          child: Row(
                            children: [
                              // TARGET column
                              SizedBox(
                                width: 60,
                                child: Text(
                                  targetLabels[item['target']], 
                                  style: TextStyle(
                                    color: isFirst ? Colors.orangeAccent : Colors.white70, 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              // HITS column
                              SizedBox(
                                width: 40,
                                child: Center(
                                  child: Text(
                                    "${item['hits']}", 
                                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: Container(                        
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            item['name'], 
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 13, 
                              fontWeight: 
                              FontWeight.w500
                            )
                          ),
                        ),
                        
                        trailing: _buildTrendIcon(trend),
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

  Widget _buildTrendIcon(String trend) {
    final data = {
      'up': [Icons.arrow_upward, Colors.greenAccent],
      'down': [Icons.arrow_downward, Colors.redAccent],
    }[trend] ?? [Icons.remove, Colors.white60];

    final icon = data[0] as IconData, color = data[1] as Color;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class TargetZonePainter extends CustomPainter {
  final int targetValue;
  final Size boardSize;

  TargetZonePainter(this.targetValue, this.boardSize);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}