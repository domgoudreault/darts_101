// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
//import 'package:lottie/lottie.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_score.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_dartboard.dart';

class GameHalfItScreen extends StatefulWidget {
  final TblGame game;
  final bool resumeMode;
  
  const GameHalfItScreen({
    super.key, 
    required this.game,
    required this.resumeMode
  });

  @override
  State<GameHalfItScreen> createState() => _GameHalfItScreenState();
}

class _GameHalfItScreenState extends State<GameHalfItScreen> with TickerProviderStateMixin {
  late AnimationController _slashController;
  // ignore: prefer_final_fields
  //bool _showSlash = false;

  late Box<TblGameScore> gamesScoresBox;
  late Box<TblPlayer> playersBox;
  late Box<TblTeam> teamsBox;

  double get _responsiveTile => GlobalAppDisplay.safeHeight * 0.67;
  //double get _responsiveFontSize => (_responsiveTile * 0.035).clamp(8.0, 60.0);

  // Every declaration reusable needed for this game
  TblGame get _gameConfig => widget.game;

  // Sort slot colors to match player positions
  List<Color> get playersSlotColors {
    final sorted = GlobalPlayersGridConfig.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return sorted.map((config) => config.bgColor).toList();
  }
  
  // Sort slot colors to match team positions
  List<Color> get teamsSlotColors {
    final sorted = GlobalTeamsGridConfig.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return sorted.map((config) => config.bgColor).toList();
  }

  // Pair each player with their original index and player color for the game
  List<({TblPlayer player, int originalIndex, Color playerColor})> get _gamePlayers => List.generate(_gameConfig.fldPlayers.length, (index) {
    return (
      player: _gameConfig.fldPlayers[index],
      originalIndex: index,
      playerColor: playersSlotColors[index],
    );
  });

  List<({TblTeam team, int originalIndex, Color teamColor})> get _gameTeams {
    if (_gameConfig.fldPlayersGM || _gameConfig.fldTeams == null) {
      return [];
    }
    return List.generate(_gameConfig.fldTeams!.length, (index) {
      return (
        team: _gameConfig.fldTeams![index],
        originalIndex: index,
        teamColor: teamsSlotColors[index],
      );
    });
  }

  // Game progression state and getters for the UI
  int _activeSeatIdx = 0;  // Tracks whose turn it is in the rotation
  int _previousSeatIdx = 0;  // Tracks whose turn it was in the rotation
  int _activeDartIdx = 0;  // 0, 1, or 2 (3 darts per turn)
  int _previousDartIdx = 0;  // 0, 1, or 2 (3 darts per turn)
  int _activeRoundIdx = 0; // 0 to 11 (matching the 12 targets)
  int _previousRoundIdx = 0;  // 0 to 11 (matching the 12 targets)
  int _activeTargetIdx = 0;
  int _previousTargetIdx = 0;
  int _nextTargetIdx = 0;
  
  TblPlayer get _activePlayer => _gamePlayers[_activeSeatIdx].player;
  TblPlayer get _previousPlayer => _gamePlayers[_previousSeatIdx].player;
  TblTeam get _activeTeam => _gameTeams[_activeSeatIdx].team;
  TblTeam get _previousTeam => _gameTeams[_previousSeatIdx].team;
  int get _activeTargetValue => gTargetsHalf[_activeTargetIdx].value;
  int get _previousTargetValue => gTargetsHalf[_previousTargetIdx].value;
  int get _nextTargetValue => gTargetsHalf[_nextTargetIdx].value;
  String get _activeTargetLabel => gTargetsHalf[_activeTargetIdx].label;
  String get _previousTargetLabel => gTargetsHalf[_previousTargetIdx].label;
  String get _nextTargetLabel => gTargetsHalf[_nextTargetIdx].label;

  @override
  void initState() {
    super.initState();
    gamesScoresBox = Hive.box<TblGameScore>('gamesScoresBox');
    playersBox = Hive.box<TblPlayer>('playersBox');
    teamsBox = Hive.box<TblTeam>('teamsBox');

    _slashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Fast like a sword
    );
  }

  @override
  void dispose() {
    _slashController.dispose(); // Always clean up
    super.dispose();
  }  

  /* void _gameClosed(bool isTie, List<Map<String, dynamic>> finalResults) {    
    // if it's a tie, for me.. their is no winner
    if (!isTie) {
      if (widget.game.fldPlayersGM) {        
        //TO DO add multiple players winner if it'S the case
        //widget.game.fldPlayersWinner = players;         
      } else {
        //TO DO add multiple teams winner if it'S the case
        //widget.game.fldTeamsWinner = teams;         
      }
    }

    // Save and end the game :)
    widget.game.fldIsEnded = true;
    widget.game.save();
    
    // 2. Clear the Navigation stack back to the very first screen
    // This will dismiss the Dialog AND the GameScoreScreen in one go.
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  } */

 bool _checkIfHalfIt() {
    final previousDartsThisRound = gamesScoresBox.values.where((s) =>
        s.fldGame == _gameConfig &&
        s.fldPlayer == _gamePlayers[_activeSeatIdx].player &&
        s.fldRound == _activeRoundIdx &&
        s.fldDartIndex < 2
    ).toList();

    return previousDartsThisRound.length == 2 && previousDartsThisRound.every((d) => d.fldIsMiss);
  }

  void _processThrow(int hits) {
    setState(() {
      // 1. Save current states as previous before advancing
      _previousRoundIdx = _activeRoundIdx;
      _previousSeatIdx = _activeSeatIdx;
      _previousDartIdx = _activeDartIdx;

      bool isMiss = (hits == 0);
      bool isSingle = (hits == 1);
      bool isDouble = (hits == 2);
      bool isTriple = (hits == 3);
      
      bool isHalfIt = false;
      // Only evaluate Half-It if we are strictly on the 3rd dart (index 2) and it's a miss
      if (_activeDartIdx == 2 && isMiss) {
        isHalfIt = _checkIfHalfIt();
      }
      
      // 2. Save the throw directly into Hive using TblGameScore
      final scoreRecord = TblGameScore(
        fldGame: _gameConfig,
        fldPlayer: _activePlayer,
        fldSeatIndex: _activeSeatIdx,
        fldDartIndex: _activeDartIdx,
        fldRound: _activeRoundIdx,
        fldTargetIndex: _activeTargetIdx,
        fldTargetValue: _activeTargetValue,
        fldNextTargetIndex: _nextTargetIdx,
        fldNextTargetValue: _nextTargetValue,
        fldIsSingle: isSingle,
        fldIsDouble: isDouble,
        fldIsTriple: isTriple,
        fldIsMiss: isMiss,
        fldHits: hits,
        fldIsHalfIt: isHalfIt,
        fldScorePlayerSnapshot: isMiss ? 0 : gTargetsHalf[_activeRoundIdx].value * hits,
      );

      gamesScoresBox.add(scoreRecord);
      
      // 3. Increment the dart throw index for the current turn (0, 1, 2)
      _activeDartIdx++;

      // 4. Check if the player has completed their 3 darts for this turn
      if (_activeDartIdx >= 3) {
        _activeDartIdx = 0; // Reset dart counter for the next player

        // Advance to the next player in the rotation
        _activeSeatIdx = (_activeSeatIdx + 1) % _gamePlayers.length;

        // If we've cycled through all players, advance to the next round target
        if (_activeSeatIdx == 0) {
          if (_activeRoundIdx < gTargetsHalf.length - 1) {
            _activeRoundIdx++;
          } else {
            // Game finished or reached the final target level
            // _endGame();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {    
    MediaQuery.sizeOf(context);
    
    // Define all responsive height and width of the rosters selection UI
    final toolbarHeight = (GlobalAppDisplay.safeHeight * 0.10).clamp(56.0, 142.0);
    final headerHeight = (GlobalAppDisplay.safeHeight - toolbarHeight) * (1/7);
    final heightBoostPlayerPanel = (GlobalAppDisplay.safeHeight - toolbarHeight - (GlobalAppDisplay.safeWidth * 0.006 * 2)) * 0.662;
    final heightBoostTeamPanel = (GlobalAppDisplay.safeHeight - toolbarHeight - (GlobalAppDisplay.safeWidth * 0.006 * 2)) * 0.535;
    final avatarHeight = headerHeight * 2;
    final avatarHeightOuterSize = avatarHeight * 1.12;
    final avatarSlicedWidth = avatarHeight * 0.42;
    final avatarSlicedWidthOuterSize = avatarSlicedWidth * 1.12;
    final cardHeight = headerHeight * 1.9;
    final cardWidth = cardHeight * 1.4628;
    final cardWidthOuterSize = cardWidth * 1.12;
    final cardSlicedHeight = cardWidth * 0.305;
    final cardSlicedHeightOuterSize = cardSlicedHeight * 1.12;
    
    // --- CACHED STATE VARIABLES FOR THIS GAME ---
    final bool isPlayerMode = _gameConfig.fldPlayersGM;
    
    final activePlayer = _gamePlayers[_activeSeatIdx];
    final previousPlayer = _gamePlayers[_activeSeatIdx];
    final activeTeam = isPlayerMode ? null : _gameTeams[_activeSeatIdx % _gameTeams.length];
    final previousTeam = isPlayerMode ? null : _gameTeams[_activeSeatIdx % _gameTeams.length];

    return Scaffold(
      backgroundColor: _gameConfig.fldGameType.tileBackgroundColor,
      appBar: 
        gBuildAppBar(
          gToolbarHeight: toolbarHeight,
          gAppBarTitle: _gameConfig.fldGameType.tileDisplayName, 
          gAppBarColorBg: _gameConfig.fldGameType.tileColor,
          gCallFromMainScreen: false,
          gOnPressed: null,
          gRightPopupMenu: null,
      ),

      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              top: 0,
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/png/tiles/${_gameConfig.fldGameType.tileType}_${_gameConfig.fldGameType.tileCode}.png',
                  //gameTileImageConfig.assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),

            // Main Area for Game (Takes (GlobalAppDisplay.safeHeight - toolbarHeight) of screen free space)
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.only(
                    left: GlobalAppDisplay.safeWidth * 0.004,
                    right: GlobalAppDisplay.safeWidth * 0.006,
                    top: GlobalAppDisplay.safeWidth * 0.006,
                    bottom: GlobalAppDisplay.safeHeight * 0.006,
                  ),
                  height: (GlobalAppDisplay.safeHeight - toolbarHeight),
                  //color: Colors.grey.shade900,
                  
                  // Main Row containing 3 main Columns (Left SideBar, Center Screen (2 Rows, 3 Columns each), Right Sidebar)
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // COLUMN 1: Left Sidebar (Previous Team or player)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          isPlayerMode
                            ? gBuildSlicedPlayerAvatarVPanel(
                                player: previousPlayer.player,
                                avatarHeight: avatarHeight,
                                avatarHeightOuterSize: avatarHeightOuterSize,
                                avatarSlicedWidth: avatarSlicedWidth,
                                avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                slotBgColor: previousPlayer.playerColor,
                                playerPosition: previousPlayer.originalIndex,
                                responsiveTile: _responsiveTile,
                                heightBoost: heightBoostPlayerPanel,
                              )
                            : gBuildSlicedTeamCardVPanel(
                                team: previousTeam!.team,
                                cardHeight: cardHeight,
                                cardWidth: cardWidth,
                                cardWidthOuterSize: cardWidthOuterSize,
                                cardSlicedHeight: cardSlicedHeight,
                                cardSlicedHeightOuterSize: cardSlicedHeightOuterSize,
                                slotBgColor: previousTeam.teamColor,
                                teamPosition: previousTeam.originalIndex,
                                responsiveTile: _responsiveTile,
                                heightBoost: heightBoostTeamPanel,
                              ),
                        ],
                      ),

                      SizedBox(width: _responsiveTile * 0.008),

                      // COLUMN 2: Center-Top / Header Area
                      Expanded(
                        child:Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row TOP BANNER
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isPlayerMode) ...[
                                      gBuildSlicedPlayerAvatarH(
                                        player: previousPlayer.player,
                                        avatarHeight: avatarHeight,
                                        avatarHeightOuterSize: avatarHeightOuterSize,
                                        avatarSlicedWidth: avatarSlicedWidth,
                                        avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                        slotBgColor: previousPlayer.playerColor,
                                        playerPosition: previousPlayer.originalIndex,
                                        responsiveTile: _responsiveTile,
                                        isTagNickNameLeft: true,
                                      ),
                                    ] else ...[
                                      gBuildSlicedPlayerAvatarH(
                                        player: previousPlayer.player,
                                        avatarHeight: avatarHeight,
                                        avatarHeightOuterSize: avatarHeightOuterSize,
                                        avatarSlicedWidth: avatarSlicedWidth,
                                        avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                        slotBgColor: previousTeam!.teamColor,
                                        playerPosition: previousPlayer.originalIndex,
                                        responsiveTile: _responsiveTile,
                                        isTagNickNameLeft: true,
                                      ),
                                    ]
                                  ],
                                ),

                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      /* Expanded(
                                        child: */ Container(
                                          alignment: Alignment.center,
                                          color: Colors.red.shade900.withAlpha(100),
                                          width: double.infinity,
                                          height: avatarSlicedWidthOuterSize,
                                        ),
                                      /* ), */
                                    ],
                                  ),
                                ),

                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (isPlayerMode) ...[
                                      gBuildSlicedPlayerAvatarH(
                                        player: activePlayer.player,
                                        avatarHeight: avatarHeight,
                                        avatarHeightOuterSize: avatarHeightOuterSize,
                                        avatarSlicedWidth: avatarSlicedWidth,
                                        avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                        slotBgColor: activePlayer.playerColor,
                                        playerPosition: activePlayer.originalIndex,
                                        responsiveTile: _responsiveTile,
                                        isTagNickNameLeft: false,
                                      ),
                                    ] else ...[
                                      gBuildSlicedPlayerAvatarH(
                                        player: activePlayer.player,
                                        avatarHeight: avatarHeight,
                                        avatarHeightOuterSize: avatarHeightOuterSize,
                                        avatarSlicedWidth: avatarSlicedWidth,
                                        avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                        slotBgColor: activeTeam!.teamColor,
                                        playerPosition: activePlayer.originalIndex,
                                        responsiveTile: _responsiveTile,
                                        isTagNickNameLeft: false,
                                      ),
                                    ]
                                  ],
                                ),
                              ],
                            ),

                            // Row for Previous Player score, Rankings, Interactive Dartboard
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            color: Colors.orange.shade900.withAlpha(100),
                                            width: double.infinity,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            color: Colors.green.shade900.withAlpha(100),
                                            width: double.infinity,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            color: Colors.yellow.shade300.withAlpha(100),
                                            child: gBuildDartboardInputZone(
                                              gActiveTargetIdx: _activeRoundIdx, 
                                              gGametype: _gameConfig.fldGameType, 
                                              gOnTap: (leap) {
                                                _processThrow(leap);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ),
                      ),

                      SizedBox(width: _responsiveTile * 0.008),

                      // COLUMN 3: Left Sidebar (Active Team or player)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          isPlayerMode
                            ? gBuildSlicedPlayerAvatarVPanel(
                                player: activePlayer.player,
                                avatarHeight: avatarHeight,
                                avatarHeightOuterSize: avatarHeightOuterSize,
                                avatarSlicedWidth: avatarSlicedWidth,
                                avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                slotBgColor: activePlayer.playerColor,
                                playerPosition: activePlayer.originalIndex,
                                responsiveTile: _responsiveTile,
                                heightBoost: heightBoostPlayerPanel,
                              )
                            : gBuildSlicedTeamCardVPanel(
                                team: activeTeam!.team,
                                cardHeight: cardHeight,
                                cardWidth: cardWidth,
                                cardWidthOuterSize: cardWidthOuterSize,
                                cardSlicedHeight: cardSlicedHeight,
                                cardSlicedHeightOuterSize: cardSlicedHeightOuterSize,
                                slotBgColor: activeTeam.teamColor,
                                teamPosition: activeTeam.originalIndex,
                                responsiveTile: _responsiveTile,
                                heightBoost: heightBoostTeamPanel,
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Samurai Slash Overlay Animation Layer
            /* if (_showSlash)
              IgnorePointer(
                child: Center(
                  child: Lottie.asset(
                    'assets/lottie/magic-sword.json',
                    controller: _slashController,
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.8,
                    onLoaded: (composition) {
                      _slashController.duration = composition.duration;
                    },
                  ),
                ),
              ), */
          ],
        ),
      ),
    );
  }

  /* Widget _buildTable() {    
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
            ...widget.game.fldPlayers!.map((player) {
              int teamIndex;
              String teamName = "";
              final int currentSeat = seatCounter++;

              if (!widget.game.fldPlayersGM) {
                final int totalTeams = widget.game.fldTeams!.length;
      
                // The seat dictates the team rotation
                teamIndex = currentSeat % totalTeams;
                //teamID = widget.game.teamsIDs![teamIndex];
                
                //final team = teamsBox.get(teamID);
                //teamName = team?.fldSurName ?? "";
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (teamName.isNotEmpty)                      
                      // THE DECORATION BOX (The Background)
                      Container(                        
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber,  //TO DO getTeamColor and getPlayerColor to design
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
                      player.fldNickName,
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
            decoration: BoxDecoration(color: rIdx == 0 ? Colors.orange.shade50 : Colors.white),
            children: [
              Padding(                
                padding: const EdgeInsets.all(2), 
                child: Text(
                  targetLabels[rIdx], 
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // White text if penalized, otherwise black
                    fontWeight: FontWeight.normal,
                    fontSize: 18,
                  ),
                )
              ),
              // rest of the scoreboard
              ...widget.game.fldPlayers!.asMap().entries.map((player) {
                final int columnSeatIndex = 0; // This is the seat index for THIS column
                
                return _buildCell(
                  0, 
                  rIdx, 
                  columnSeatIndex, // Use the column index, NOT the global currentPlayerIndex
                  (rIdx == 0 && columnSeatIndex == 0),
                );
              }),
            ],
          );
        }),
      ],
    );
  } */

  /* Widget _buildCell(int pId, int rIdx, int sIdx, bool isActive) {
    final entry = gamesScoresBox.values.cast<TblGameScore>().firstWhere(
      (gs) => gs.fldGame == widget.game && gs.fldPlayer == widget.game.fldPlayers![0] && gs.fldRound == rIdx && gs.fldSeatIndex == sIdx,
    );

    // If halfIt is true, we show the oval
    final bool isPenalized = entry.fldIsHalfIt;

    return Container(
      padding: const EdgeInsets.all(2),
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
            widget.game.fldPlayersGM ? "${entry.fldScorePlayerSnapshot}" : "${entry.fldScorePlayerSnapshot} / ${entry.fldsScoreTeamSnapshot}",
            textAlign: TextAlign.center,
            style: TextStyle(
              // White text if penalized, otherwise black
              color: isPenalized ? Colors.white : Colors.black,
              fontWeight: FontWeight.normal,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  } */
}