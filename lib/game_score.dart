import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:darts_101/database/player.dart';
import 'package:darts_101/database/team.dart';
import 'package:darts_101/database/game.dart';
import 'package:darts_101/database/gamescore.dart';

enum ScoringMode{
  forward,
  backward
}

class GameScoreScreen extends StatefulWidget {
  final Game game;
  final String gameText;
  
  const GameScoreScreen({
    super.key, 
    required this.game,
    required this.gameText
  });

  @override
  State<GameScoreScreen> createState() => _GameScoreScreenState();
}

class _GameScoreScreenState extends State<GameScoreScreen> {
  // 1. Game Configuration
  final List<int> targets = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25];
  final List<String> targetLabels = ["10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "BULL"];

  bool _showRankings = false;
  Timer? _rankTimer;
  int currentPlayerIndex = 0; // Index in widget.game.playersIDs
  int currentTeamIndex = 0; // Index in widget.game.teamsIDs
  int currentTargetIndex = 0; // Index in targets list (0-11)

  late Box<GameScore> scoreBox;
  late Box<Player> playersBox;
  late Box<Team> teamsBox;

  @override
  void initState() {
    super.initState();
    scoreBox = Hive.box<GameScore>('gamescoresBox');
    playersBox = Hive.box<Player>('playersBox');
    teamsBox = Hive.box<Team>('teamsBox');
  }

  Color _getTeamColor(int? idTeam) {
  if (idTeam == null || idTeam == -1) return Colors.transparent;
  
    // A curated list of distinct colors for darts teams
    final List<Color> materialColors = [
      Colors.blue.shade600,
      Colors.green.shade700,
      Colors.purple.shade600,
      Colors.orange.shade800,
      Colors.pinkAccent.shade400,
      Colors.cyan.shade700,
      Colors.grey.shade800,
      Colors.lime.shade800,
    ];

    return materialColors[idTeam % materialColors.length];
  }
  
  List<Map<String, dynamic>> _getCurrentRankings() {
    List<Map<String, dynamic>> rankings = [];
    bool isTeamMode = widget.game.gameMode == 2;

    if (isTeamMode) {
      for (int tId in widget.game.teamsIDs!) {
        final player1 = playersBox.get(teamsBox.get(tId)?.idPlayer1)?.nickName ?? "Player 1";
        final player2 = playersBox.get(teamsBox.get(tId)?.idPlayer2)?.nickName ?? "Player 2";
        rankings.add({
          'name': "$player1, $player2",
          'team_name': teamsBox.get(tId)?.surName ?? "Team",
          'score': _getLatestTeamScore(tId),
          'color': _getTeamColor(tId),
          'id': tId,
        });
      }
    } else {
      for (int i = 0; i < widget.game.playersIDs.length; i++) {
        int pId = widget.game.playersIDs[i];
        rankings.add({          
          'name': playersBox.get(pId)?.nickName ?? "Player",
          'team_name': playersBox.get(pId)?.nickName ?? "Player", // property won't be used in TeamMode, needs to be identical for purpose
          'score': _getLatestPlayerScore(pId, i),
          'color': Colors.blueGrey.shade700,
          'id': pId,
        });
      }
    }

    // Sort: High score first
    rankings.sort((a, b) => b['score'].compareTo(a['score']));
    return rankings;
  }

  List<Map<String, dynamic>> _getRankingsWithTrends() {
    final currentRanks = _getCurrentRankings();
    final bool isTeamMode = widget.game.gameMode == 2;

    // 1. Get the last entry for this game
    final gameHistory = scoreBox.values.where((s) => s.idGame == widget.game.idGame).toList();
    if (gameHistory.isEmpty) return currentRanks;

    final lastScoreEntry = gameHistory.last;

    // 2. Create the "Previous" rankings list
    List<Map<String, dynamic>> previousRanks = [];
    
    if (isTeamMode) {
      for (int tId in widget.game.teamsIDs!) {
        // Find the score snapshot just BEFORE the last entry for this team
        final teamHistory = gameHistory.where((s) => s.idTeam == tId).toList();
        int prevScore = 0;
        if (teamHistory.length > 1 && lastScoreEntry.idTeam == tId) {
          // If the last throw was this team's, their previous score is the second-to-last entry
          prevScore = teamHistory[teamHistory.length - 2].scoreTeamSnapshot;
        } else {
          prevScore = teamHistory.isEmpty ? 0 : teamHistory.last.scoreTeamSnapshot;
        }
        previousRanks.add({'id': tId, 'score': prevScore});
      }
    } else {
      for (int i = 0; i < widget.game.playersIDs.length; i++) {
        int pId = widget.game.playersIDs[i];
        final playerHistory = gameHistory.where((s) => s.idPlayer == pId && s.seatIndex == i).toList();
        int prevScore = 0;
        if (playerHistory.length > 1 && lastScoreEntry.idPlayer == pId && lastScoreEntry.seatIndex == i) {
          prevScore = playerHistory[playerHistory.length - 2].scoreSnapshot;
        } else {
          prevScore = playerHistory.isEmpty ? 0 : playerHistory.last.scoreSnapshot;
        }
        previousRanks.add({'id': pId, 'score': prevScore});
      }
    }

    // Sort previous ranks to find old positions
    previousRanks.sort((a, b) => b['score'].compareTo(a['score']));

    // 3. Map trends to current ranks
    return currentRanks.map((item) {
      int currentPos = currentRanks.indexOf(item);
      int prevPos = previousRanks.indexWhere((p) => p['id'] == item['id']);

      String trend = 'stable';
      if (prevPos > currentPos) trend = 'up';
      if (prevPos < currentPos) trend = 'down';

      return {...item, 'trend': trend};
    }).toList();
  }

  void _undoLastScore(bool isUndoFromDialog) {
    // 1. Find the last entry for this specific game
    final gameScores = scoreBox.values
        .where((s) => s.idGame == widget.game.idGame)
        .toList();

    if (gameScores.isEmpty) return; // Nothing to undo

    // 2. Delete the last entry from Hive
    final lastEntry = gameScores.last;
    // Use the internal Hive key to delete exactly that object
    scoreBox.delete(lastEntry.key);

    if (!isUndoFromDialog) {
      _manageFwdBwdIncremental(ScoringMode.backward);
    } else {
      // 2. Sync the state
      setState(() {
        // We don't just call backward once, because after the last hit, 
        // the pointers might have wrapped around. 
        // The safest way is to set the pointers to the record we are deleting:
        currentTargetIndex = lastEntry.round;
        currentPlayerIndex = lastEntry.seatIndex;
        
        // Now recalculate the team index so the UI highlights the right team
        final int totalTeams = widget.game.teamsIDs?.length ?? 0;
        if (totalTeams > 0) {
          currentTeamIndex = currentPlayerIndex % totalTeams;
        }
      });
    } 
    
    // ADD THIS: Clears the old snackbar so the new one shows immediately
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Last score removed"), duration: Duration(seconds: 1)),
    );
  }

  // Returns the last scoreSnapshot for a specific player in a specific seat
  int _getLatestPlayerScore(int playerId, int seatIndex) {
    final history = scoreBox.values.where((s) => 
      s.idGame == widget.game.idGame && 
      s.idPlayer == playerId && 
      s.seatIndex == seatIndex
    ).toList();

    return history.isEmpty ? 0 : history.last.scoreSnapshot;
  }

  // Returns the last scoreTeamSnapshot for any player belonging to this Team ID
  int _getLatestTeamScore(int teamId) {
    final history = scoreBox.values.where((s) => 
      s.idGame == widget.game.idGame && 
      s.idTeam == teamId
    ).toList();

    return history.isEmpty ? 0 : history.last.scoreTeamSnapshot;
  }

  void _recordScore(int hits) {
    // Safety check: Don't allow more than 6 for Bull
    if (targetLabels[currentTargetIndex] == "BULL" && hits > 6) return;
    
    int playerId = widget.game.playersIDs[currentPlayerIndex];
    int targetValue = targets[currentTargetIndex];
    bool isTeamMode = widget.game.gameMode == 2;
    
    int teamId = 0;
    if (isTeamMode && widget.game.teamsIDs != null) {
      teamId = widget.game.teamsIDs![currentTeamIndex];
    }     
    
    int prevPlayerTotal = _getLatestPlayerScore(playerId, currentPlayerIndex);
    int prevTeamTotal = _getLatestTeamScore(teamId);    
    
    int newPlayerTotal = 0;
    int newTeamTotal = 0;
    bool wasHalved = false;

    if (hits > 0) {
      newPlayerTotal = prevPlayerTotal + (targetValue * hits);
      newTeamTotal = prevTeamTotal + (targetValue *hits);
    } else {
      wasHalved = true;
      
      // if in playerMode
      if (!isTeamMode) {
        if (prevPlayerTotal > 0) {
          newPlayerTotal = (prevPlayerTotal / 2).round();          
        } else {
          newPlayerTotal = 0;
        }
      }
      if (prevTeamTotal > 0) {
        newPlayerTotal = prevPlayerTotal + (targetValue * hits);
        newTeamTotal = (prevTeamTotal / 2).round();        
      } else {
        newTeamTotal = 0;
      }
    }

    // Save to Hive
    final gameScore = GameScore(
      idGame: widget.game.idGame!,
      idTeam: widget.game.gameMode == 2 ? teamId : null,
      idPlayer: playerId,
      seatIndex: currentPlayerIndex,
      round: currentTargetIndex,
      targetValue: targetValue,
      hits: hits,
      scoreSnapshot: newPlayerTotal,
      scoreTeamSnapshot: newTeamTotal,
      halfIt: wasHalved,
    );
    scoreBox.add(gameScore);

    // Get the auto-increment key that was generated
    gameScore.idGameScore = gameScore.key as int;

    // Save the player with the auto-increment id that was generated By Hive
    gameScore.save();

    setState(() {
      _showRankings = true;
    });

    // Cancel any existing timer so it doesn't disappear too early 
    // if you click buttons rapidly
    _rankTimer?.cancel();
    _rankTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showRankings = false;
        });
      }
    });

    _manageFwdBwdIncremental(ScoringMode.forward);
  }

  void _manageFwdBwdIncremental(ScoringMode enuScoringMode) {
    final int totalPlayers = widget.game.playersIDs.length;
    // Use .length of teamsIDs to determine how many teams are in the rotation
    final int totalTeams = widget.game.teamsIDs?.length ?? 0;

    // Advance turn
    setState(() {
      if (enuScoringMode == ScoringMode.forward) {
        if (currentPlayerIndex < totalPlayers - 1) {
          currentPlayerIndex++;
        } else {
          currentPlayerIndex = 0;
          if (currentTargetIndex < targets.length - 1) {
            currentTargetIndex++;
          } else {
            _endGame();
          }
        }
      } else {
        if (currentPlayerIndex > 0) {
          // Just go back one player in the same round
          currentPlayerIndex--;
        } else {
          // We were at the start of a round, go back to the end of the PREVIOUS round
          if (currentTargetIndex > 0) {
            currentTargetIndex--;
            currentPlayerIndex = widget.game.playersIDs.length - 1;
          }
        }
      }

      // This maps Player Index back to Team Index based on your rotation:
      // T1P1(0), T2P1(1), T3P1(2) -> Next Round -> T1P2(3), T2P2(4), T3P2(5)
      if (totalTeams > 0) {
        currentTeamIndex = currentPlayerIndex % totalTeams;
      }
    });
  }

  // --- LOGIC: GAME OVER ---
  void _endGame() {
    // We'll store the results in a list of Map for easy sorting
    List<Map<String, dynamic>> finalResults = [];
    final bool isTeamMode = (widget.game.gameMode == 2);

    if (isTeamMode) {
      // TEAM MODE
      for (int tId in widget.game.teamsIDs!) {
        final team = teamsBox.get(tId);
        final score = _getLatestTeamScore(tId);
        finalResults.add({
          'name': team?.surName,
          'id': tId,
          'score': score,
          'color': _getTeamColor(tId),
        });
      }
    } else {
      // PLAYER MODE
      for (int pId in widget.game.playersIDs) {
        final player = playersBox.get(pId);
        // We search for the player's specific seat to ensure accuracy
        final seatIdx = widget.game.playersIDs.indexOf(pId);
        final score = _getLatestPlayerScore(pId, seatIdx);
        finalResults.add({
          'name': player?.nickName,
          'id': pId,
          'score': score,
          'color': Colors.blueGrey.shade700,
        });
      }
    }

    // 2. Sort results (Highest score first)
    finalResults.sort((a, b) => b['score'].compareTo(a['score']));
    
    final winner = finalResults.first;
    final isTie = finalResults.length > 1 && finalResults[0]['score'] == finalResults[1]['score'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
                isTeamMode 
                    ? Image.asset('assets/png/trophy_2_players_48x120.png', height: 80) 
                    : Image.asset('assets/png/trophy_1_player_48x80.png', height: 80),
                const SizedBox(height: 4),
                Text(isTie ? "IT'S A TIE!" : isTeamMode ? "WINNERS" : "WINNER", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                
                const SizedBox(height: 4),

                // 2. WINNER HIGHLIGHT
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: winner['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: winner['color'], width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(isTeamMode ? "Team: ${winner['name']}" : "${winner['name']}", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: winner['color'])
                      ),
                      Text("${winner['score']} pts", 
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. STANDINGS LIST
                const Text("FINAL STANDINGS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row( 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isTeamMode ? "TEAMS" : "PLAYERS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("POINTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ]
                ),
                const Divider(),
                
                // Map the results directly into the column
                ...finalResults.map((res) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(res['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("${res['score']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),

                const SizedBox(height: 24),

                // 4. BOTTOM BUTTONS (Moved from Actions)
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
                  onPressed: () => _gameClosed(isTeamMode, isTie, finalResults),
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
      ),
    );    
  }

  void _gameClosed(bool isTeamMode, bool isTie, List<Map<String, dynamic>> finalResults) {    
    // if it's a tie, for me.. their is no winner
    if (!isTie) {
      if (isTeamMode) {        
        widget.game.idTeamWinner = finalResults[0]['id']; // keep the winner team id
      } else {
        widget.game.idPlayerWinner = finalResults[0]['id']; // keep the winner player id
      }
    }

    // Save and end the game :)
    widget.game.ended = true;
    widget.game.save();
    
    // 2. Clear the Navigation stack back to the very first screen
    // This will dismiss the Dialog AND the GameScoreScreen in one go.
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }

  // --- UI: BUILDING THE SCREEN ---
  @override
  Widget build(BuildContext context) {
    final activePlayerId = widget.game.playersIDs[currentPlayerIndex];
    final activePlayer = playersBox.get(activePlayerId);

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Row (
          children: [
            // pour l'icone de l'Application
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 48.0,
                height: 48.0,
                child: Image.asset(
                  'assets/png/darts_101_logo_48x48.png', // Replace with your image path (PNG, JPG, or SVG)
                  fit: BoxFit.contain, // Ensures the image fits within the box
                ),
              ),
            ),
            // pour le titre de la tuile
            Text(
              widget.gameText,              
              style: const TextStyle(color: Colors.white),
            ),
          ]          
        ),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: "Undo last turn",
            onPressed: (currentTargetIndex == 0 && currentPlayerIndex == 0) 
                ? null // Disable if at the very start
                : () => _undoLastScore(false),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header: Current Target & Player Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CURRENT TARGET", style: TextStyle(fontSize: 12, color: Colors.black)),
                    Text(targetLabels[currentTargetIndex], style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade400)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(activePlayer?.nickName ?? "", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("Is Throwing...", style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.deepOrange.shade400)),
                  ],
                )
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                // LEFT SIDE: The Scoreboard Table
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(4),
                    child: _buildTable(),
                  ),
                ),
                
                // LAYER 2: The Floating Ranking (Slides over the table)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  bottom: 0,
                  right: _showRankings ? 0 : -310, // Slides from off-screen (-10 diff with width) to on-screen (0)
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(-5, 0),
                        ),
                      ],
                    ),
                    child: _buildLiveRankings(),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Input Pad
          Container(
            color: Colors.blueGrey.shade900,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Number of Hits:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,                    
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,    // Horizontal space
                        runSpacing: 8, // Vertical space if they wrap
                        children: List.generate(10, (i) {
                          return SizedBox(
                            // On a tablet, make buttons wider; on a phone, make them smaller
                            width: constraints.maxWidth > 600 ? 70 : 55, 
                            height: 60,
                            child: _buildInputButton(i),
                          );
                        }),
                      ),
                    );
                  }),
                ]
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRankings() {
    final ranks = _getRankingsWithTrends();
    final bool isTeamMode = widget.game.gameMode == 2;

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
                        Text(isTeamMode ? "Teams Ranking" : "Players Ranking", 
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
                          Text("POINTS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(isTeamMode ? "TEAMS" : "PLAYERS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isFirst ? Colors.orange.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        leading: SizedBox(
                          width: 50,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("${item['score']}", 
                              style: TextStyle(color: isFirst ? Colors.orangeAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                        title: Container(                        
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item['color'],
                            borderRadius: BorderRadius.circular(4),                              
                          ),
                          child: Text(
                            isTeamMode ? item['team_name'] : item['name'], 
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
                        subtitle: Text(isTeamMode ? "${item['name']}" : "", 
                          style: TextStyle(color: isFirst ? Colors.orangeAccent : Colors.white54, fontSize: 11)),
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
    IconData icon;
    Color color;
    
    if (trend == 'up') {
      icon = Icons.arrow_upward;
      color = Colors.greenAccent;
    } else if (trend == 'down') {
      icon = Icons.arrow_downward;
      color = Colors.redAccent;
    } else {
      icon = Icons.remove;
      color = Colors.white60;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildInputButton(int value) {
    // Check if we are currently on the BULL target
    bool isBullRound = targetLabels[currentTargetIndex] == "BULL";

    // Disable button if it's the Bull round and value is 7, 8, or 9
    bool isDisabled = isBullRound && value > 6;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled 
          ? Colors.grey.shade400 
          : (value == 0 ? Colors.red.shade700 : Colors.deepOrange.shade400),
        foregroundColor: Colors.white,
        minimumSize: const Size(80, 70),        
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: isDisabled ? null : () => _recordScore(value),
      child: Text(
        "$value", 
        style: TextStyle(
          fontSize: 28,
          color: isDisabled ? Colors.white38 : Colors.white,
        )
      ),
    );
  }

  Widget _buildTable() {    
    int seatCounter = 0;

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: Colors.grey.shade400),
      columnWidths: const {0: FixedColumnWidth(60)},
      children: [
        // Table Header
        TableRow(          
          decoration: BoxDecoration(color: Colors.blueGrey.shade100),
          children: [
            Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                "Target",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.deepOrange.shade400)
              )
            ),
            ...widget.game.playersIDs.map((pId) {
              final player = playersBox.get(pId);
              String teamName = "";
              int teamID = -1; // Store the ID for the color function
              final int currentSeat = seatCounter++;

              if (widget.game.gameMode == 2 && widget.game.teamsIDs != null) {
                final int totalTeams = widget.game.teamsIDs!.length;
      
                // The seat dictates the team rotation
                int teamIndex = currentSeat % totalTeams;
                teamID = widget.game.teamsIDs![teamIndex];
                
                final team = teamsBox.get(teamID);
                teamName = team?.surName ?? "";
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (teamName.isNotEmpty)                      
                      // THE DECORATION BOX (The Background)
                      Container(                        
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTeamColor(teamID),
                          borderRadius: BorderRadius.circular(4),                              
                        ),
                        child: Text(
                          teamName,
                          style: TextStyle(
                            fontSize: 9, 
                            color: Colors.white, // High contrast text                            
                          ),
                        ),
                      ),
                      const SizedBox(height: 2), // Small gap between team box and player name                                          
                    Text(
                      player?.nickName ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              );
            }),            
          ],
        ),
        // Table Rows (10 to Bull)
        ...List.generate(targets.length, (rIdx) {
          return TableRow(
            decoration: BoxDecoration(color: rIdx == currentTargetIndex ? Colors.orange.shade50 : Colors.white),
            children: [
              Padding(                
                padding: const EdgeInsets.all(4), 
                child: Text(
                  targetLabels[rIdx], 
                  textAlign: TextAlign.center
                )
              ),
              // rest of the scoreboard
              ...widget.game.playersIDs.asMap().entries.map((entry) {
                final int columnSeatIndex = entry.key; // This is the seat index for THIS column
                final int playerId = entry.value;

                return _buildCell(
                  playerId, 
                  rIdx, 
                  columnSeatIndex, // Use the column index, NOT the global currentPlayerIndex
                  (rIdx == currentTargetIndex && columnSeatIndex == currentPlayerIndex),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCell(int pId, int rIdx, int sIdx, bool isActive) {
    final entry = scoreBox.values.cast<GameScore?>().firstWhere(
      (s) => s?.idGame == widget.game.idGame && s?.idPlayer == pId && s?.round == rIdx && s?.seatIndex == sIdx,
      orElse: () => null,
    );

    // If halfIt is true, we show the oval
    final bool isPenalized = entry?.halfIt ?? false;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(border: isActive ? Border.all(color: Colors.deepOrange.shade400, width: 2) : null),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 110, // Ensures it stays circular for small numbers
          ),
          decoration: isPenalized 
            ? BoxDecoration(
                color: Colors.red.shade700, // Full colored background
                borderRadius: BorderRadius.circular(20), // Oval/Circle shape                
              ) 
            : null,
          child: Text(          
            entry == null ? "" : widget.game.gameMode == 1 ? "${entry.scoreSnapshot}" : "${entry.scoreSnapshot} / ${entry.scoreTeamSnapshot}",
            textAlign: TextAlign.center,
            style: TextStyle(
              // White text if penalized, otherwise black
              color: isPenalized ? Colors.white : Colors.black,
              fontWeight: FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}