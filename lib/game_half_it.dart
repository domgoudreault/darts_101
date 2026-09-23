// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lottie/lottie.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_options.dart';
import 'package:darts_101/database/tbl_game_score.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_database.dart';
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
  bool _showSlash = false;

  late Box<TblGameScore> gamesScoresBox;
  late Box<TblPlayer> playersBox;
  late Box<TblTeam> teamsBox;

  GameProgressState _progress = GameProgressState();

  double get _responsiveTile => GlobalAppDisplay.safeHeight * 0.67;
  double get _responsiveFontSize => (_responsiveTile * 0.035).clamp(8.0, 60.0);

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
  TblGameOptions get _gameOptions => gGetGameOptions(_gameConfig.fldGameType);
  int get _startingScore => _gameOptions.fldStartingScore;
  bool get _isPlayerMode => _gameConfig.fldPlayersGM;

  TblPlayer get _activePlayer => _gamePlayers[_progress.activeSeatIdx].player;
  int get _activePlayerIndex => _gamePlayers[_progress.activeSeatIdx].originalIndex;
  Color get _activePlayerColor => _gamePlayers[_progress.activeSeatIdx].playerColor;
  int get _activePlayerLastScore {
    return gamesScoresBox.values.lastWhere(
      (gamesScores) => gamesScores.fldGame == _gameConfig && gamesScores.fldPlayer == _activePlayer,
    ).fldScorePlayerSnapshot;
  }
  TblPlayer get _previousPlayer => _gamePlayers[_progress.previousSeatIdx].player;
  int get _previousPlayerIndex => _gamePlayers[_progress.previousSeatIdx].originalIndex;
  Color get _previousPlayerColor => _gamePlayers[_progress.previousSeatIdx].playerColor;
  int get _previousPlayerLastScore {
    return gamesScoresBox.values.lastWhere(
      (gamesScores) => gamesScores.fldGame == _gameConfig && gamesScores.fldPlayer == _previousPlayer,
    ).fldScorePlayerSnapshot;
  }
  TblTeam get _activeTeam => _gameTeams[_progress.activeSeatIdx % _gameTeams.length].team;
  int get _activeTeamIndex => _gameTeams[_progress.activeSeatIdx % _gameTeams.length].originalIndex;
  Color get _activeTeamColor => _gameTeams[_progress.activeSeatIdx % _gameTeams.length].teamColor;
  int get _activeTeamLastScore {
    final teamScores = gamesScoresBox.values.where((gamesScores) =>
      gamesScores.fldGame == _gameConfig &&
      _gameTeams.any((gameTeams) => gameTeams.team == _activeTeam && gameTeams.team.fldPlayers.contains(gamesScores.fldPlayer))
    );
    return teamScores.last.fldScoreTeamSnapshot!;
  }
  TblTeam get _previousTeam => _gameTeams[_progress.previousSeatIdx % _gameTeams.length].team;
  int get _previousTeamIndex => _gameTeams[_progress.previousSeatIdx % _gameTeams.length].originalIndex;
  Color get _previousTeamColor => _gameTeams[_progress.previousSeatIdx % _gameTeams.length].teamColor;
  int get _previousTeamLastScore {
    final teamScores = gamesScoresBox.values.where((gamesScores) =>
      gamesScores.fldGame == _gameConfig &&
      _gameTeams.any((gameTeams) => gameTeams.team == _previousTeam && gameTeams.team.fldPlayers.contains(gamesScores.fldPlayer))
    );
    return teamScores.last.fldScoreTeamSnapshot!;
  }
  int get _activeTargetValue => gTargetsHalf[_progress.activeTargetIdx].value;
  int get _previousTargetValue => gTargetsHalf[_progress.previousTargetIdx].value;
  int get _nextTargetValue => gTargetsHalf[_progress.nextTargetIdx].value;
  String get _activeTargetLabel => gTargetsHalf[_progress.activeTargetIdx].label;
  String get _previousTargetLabel => gTargetsHalf[_progress.previousTargetIdx].label;
  String get _nextTargetLabel => gTargetsHalf[_progress.nextTargetIdx].label;

  // Get total hits for the previous player in their last completed round
  int get _previousPlayerLastRoundHits {
    final allDartsThisRound = gamesScoresBox.values.where(
      (s) => s.fldGame == _gameConfig && 
            s.fldPlayer == _previousPlayer && 
            s.fldRound == _progress.previousRoundIdx
    );
    return allDartsThisRound.fold(0, (sum, record) => sum + record.fldHits);
  }

  // Get total hits for the active player in their current round so far
  int get _activePlayerCurrentRoundHits {
    final activeDartsThisRound = gamesScoresBox.values.where(
      (s) => s.fldGame == _gameConfig && 
            s.fldPlayer == _activePlayer && 
            s.fldRound == _progress.activeRoundIdx
    );
    return activeDartsThisRound.fold(0, (sum, record) => sum + record.fldHits);
  }

  @override
  void initState() {
    super.initState();
    gamesScoresBox = Hive.box<TblGameScore>('gamesScoresBox');
    playersBox = Hive.box<TblPlayer>('playersBox');
    teamsBox = Hive.box<TblTeam>('teamsBox');

    _initGameStartingScores();

    // Handle resume mode vs fresh game initialization using the helper
    if (widget.resumeMode) {
      _progress = gStepGameState(
        currentState: GameProgressState(),
        gameState: GlobalGameState.backwardState,
        gameConfig: _gameConfig,
        gamesScoresBox: gamesScoresBox,
        totalPlayers: _gamePlayers.length,
        targetsList: gTargetsHalf,
      );
    } else {
      _progress = GameProgressState();
    }

    _slashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50), // Fast like a sword
    );

    // Hide the animation overlay when it finishes playing
    _slashController.addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _showSlash = false;
      });
    }
  });
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

  void _initGameStartingScores() {
    // Check if scores for this game already exist in the box
    if (gamesScoresBox.values.any((s) => s.fldGame == _gameConfig)) return;

    for (int seatIdx = 0; seatIdx < _gamePlayers.length; seatIdx++) {
      gamesScoresBox.add(
        TblGameScore(
          fldGame: _gameConfig,
          fldPlayer: _gamePlayers[seatIdx].player,
          fldSeatIndex: seatIdx,
          fldDartIndex: -1,
          fldRound: -1,
          fldTargetIndex: -1,
          fldTargetValue: 0,
          fldHits: 0,
          fldIsSingle: false,
          fldIsDouble: false,
          fldIsTriple: false,
          fldIsMiss: false,
          fldIsHalfIt: false,
          fldScorePlayerSnapshot: _isPlayerMode ? _startingScore : (_startingScore / 2).round(),
          fldScoreTeamSnapshot: !_isPlayerMode ? _startingScore : null,
        ),
      );
    }
  }

  bool get _hasGameStarted {
    return gamesScoresBox.values.any(
      (s) => s.fldGame == _gameConfig && s.fldRound >= 0 && s.fldDartIndex >= 0
    );
  }

  bool get _hasGamePreviousPlayer {
    return gamesScoresBox.values.any(
      (s) => s.fldGame == _gameConfig && s.fldRound >= 0 && s.fldDartIndex >= 2
    );
  }

  bool _checkIfHalfIt() {
    final previousDartsThisRound = gamesScoresBox.values.where((s) =>
        s.fldGame == _gameConfig &&
        s.fldPlayer == _activePlayer &&
        s.fldRound == _progress.activeRoundIdx &&
        s.fldDartIndex < 2
    ).toList();

    return previousDartsThisRound.length == 2 && previousDartsThisRound.every((d) => d.fldIsMiss);
  }

  void _processThrow(int hits) {
    setState(() {
      // 1. Save the record and persist to Hive
      _recordThrow(hits);
      
      // 2. Advance the state machine pointers for the next turn
      // Step state forward using the global helper function
      _progress = gStepGameState(
        currentState: _progress,
        gameState: GlobalGameState.forwardState,
        gameConfig: _gameConfig,
        gamesScoresBox: gamesScoresBox,
        totalPlayers: _gamePlayers.length,
        targetsList: gTargetsHalf,
      );

      if (_progress.endGame == true) {
        // TODO: Handle game over completion
      }
    });
  }

  void _recordThrow(int hits) {
    bool isMiss = (hits == 0);
    bool isSingle = (hits == 1);
    bool isDouble = (hits == 2);
    bool isTriple = (hits == 3);
    
    bool isHalfIt = false;
    if (_progress.activeDartIdx == 2 && isMiss) {
      isHalfIt = _checkIfHalfIt();
    }

    // Trigger slash effect if Half-It penalty occurs
    if (isHalfIt) {
      setState(() {
        _showSlash = true;
      });
      _slashController.reset();
      _slashController.forward();
    }
    
    int newPlayerScore;
    int? newTeamScore;

    if (_isPlayerMode) {
      if (isHalfIt) {
        newPlayerScore = (_activePlayerLastScore / 2).round();
      } else {
        newPlayerScore = _activePlayerLastScore + (_activeTargetValue * hits);
      }
    } else {
      if (isHalfIt) {
        newPlayerScore = (_activePlayerLastScore / 2).round();
        newTeamScore = (_activeTeamLastScore / 2).round();
      } else {
        newPlayerScore = _activePlayerLastScore + (_activeTargetValue * hits);
        newTeamScore = _activeTeamLastScore + (_activeTargetValue * hits);
      }
    }

    final scoreRecord = TblGameScore(
      fldGame: _gameConfig,
      fldPlayer: _activePlayer,
      fldSeatIndex: _progress.activeSeatIdx,
      fldDartIndex: _progress.activeDartIdx,
      fldRound: _progress.activeRoundIdx,
      fldTargetIndex: _progress.activeTargetIdx,
      fldTargetValue: _activeTargetValue,
      fldNextTargetIndex: _progress.nextTargetIdx,
      fldNextTargetValue: _nextTargetValue,
      fldIsSingle: isSingle,
      fldIsDouble: isDouble,
      fldIsTriple: isTriple,
      fldIsMiss: isMiss,
      fldHits: hits,
      fldIsHalfIt: isHalfIt,
      fldScorePlayerSnapshot: newPlayerScore,
      fldScoreTeamSnapshot: newTeamScore,
    );

    gamesScoresBox.add(scoreRecord);
  }

  void _undoLastThrow() {
    // 1. Find all score records for this game, excluding initial baseline records (round == -1)
    final gameRecords = gamesScoresBox.values
        .where((s) => s.fldGame == _gameConfig && s.fldRound >= 0)
        .toList();

    setState(() {
      // 2. Delete the absolute latest record from Hive
      gamesScoresBox.delete(gameRecords.last.key);
      
      // 3. Step the state machine backward
      _progress = gStepGameState(
        currentState: _progress,
        gameState: GlobalGameState.backwardState,
        gameConfig: _gameConfig,
        gamesScoresBox: gamesScoresBox,
        totalPlayers: _gamePlayers.length,
        targetsList: gTargetsHalf,
      );
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
                          Stack(
                            children: [
                              _isPlayerMode
                                ? gBuildSlicedPlayerAvatarVPanel(
                                    player: _previousPlayer,
                                    avatarHeight: avatarHeight,
                                    avatarHeightOuterSize: avatarHeightOuterSize,
                                    avatarSlicedWidth: avatarSlicedWidth,
                                    avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                    slotBgColor: _previousPlayerColor,
                                    playerPosition: _previousPlayerIndex,
                                    responsiveTile: _responsiveTile,
                                    heightBoost: heightBoostPlayerPanel,
                                    isEmptyPanel: !_hasGamePreviousPlayer,
                                  )
                                : gBuildSlicedTeamCardVPanel(
                                    team: _previousTeam,
                                    cardHeight: cardHeight,
                                    cardWidth: cardWidth,
                                    cardWidthOuterSize: cardWidthOuterSize,
                                    cardSlicedHeight: cardSlicedHeight,
                                    cardSlicedHeightOuterSize: cardSlicedHeightOuterSize,
                                    slotBgColor: _previousTeamColor,
                                    teamPosition: _previousTeamIndex,
                                    responsiveTile: _responsiveTile,
                                    heightBoost: heightBoostTeamPanel,
                                    isEmptyPanel: !_hasGamePreviousPlayer,
                                  ),
                              
                              // Floating Score Table for all players button
                              Positioned(
                                bottom: _responsiveTile * 0.02,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.14,
                                    height: _responsiveTile * 0.12,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () => _showFullDebugSpreadsheet(context),
                                      child: Image.asset(
                                        'assets/png/mechanics/score.png',
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                            Container(
                              decoration: BoxDecoration(
                                color: (_isPlayerMode ? _activePlayerColor : _activeTeamColor).withAlpha(150), // Choose your background color here!
                                borderRadius: BorderRadius.circular(avatarSlicedWidthOuterSize * 0.15), // Optional: rounds the corners nicely
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_isPlayerMode) ...[
                                        gBuildSlicedPlayerAvatarH(
                                          player: _previousPlayer,
                                          avatarHeight: avatarHeight,
                                          avatarHeightOuterSize: avatarHeightOuterSize,
                                          avatarSlicedWidth: avatarSlicedWidth,
                                          avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                          slotBgColor: _previousPlayerColor,
                                          playerPosition: _previousPlayerIndex,
                                          responsiveTile: _responsiveTile,
                                          isTagNickNameLeft: true,
                                          isEmptyPanel: !_hasGamePreviousPlayer,
                                        ),
                                      ] else ...[
                                        gBuildSlicedPlayerAvatarH(
                                          player: _previousPlayer,
                                          avatarHeight: avatarHeight,
                                          avatarHeightOuterSize: avatarHeightOuterSize,
                                          avatarSlicedWidth: avatarSlicedWidth,
                                          avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                          slotBgColor: _previousTeamColor,
                                          playerPosition: _previousPlayerIndex,
                                          responsiveTile: _responsiveTile,
                                          isTagNickNameLeft: true,
                                          isEmptyPanel: !_hasGamePreviousPlayer,
                                        ),
                                      ]
                                    ],
                                  ),

                                  // Previous player Hits
                                  SizedBox(
                                    width: _responsiveTile * 0.15,
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/png/mechanics/hits.png',
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.high,
                                          ),

                                          Container(
                                            width: _responsiveTile * 0.09,
                                            height: _responsiveTile * 0.09,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha(180), // White with transparency
                                              shape: BoxShape.circle,
                                            ),
                                          ),

                                          Text(
                                            _hasGamePreviousPlayer ? '$_previousPlayerLastRoundHits' : '-',
                                            style: TextStyle(
                                              fontSize: _responsiveFontSize * 2.5,
                                              fontWeight: FontWeight.bold,
                                              color: _isPlayerMode ? _previousPlayerColor : _previousTeamColor,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(-(_responsiveFontSize * 0.15), _responsiveFontSize * 0.15),
                                                  color: Colors.black, // Or your custom gShadowColor
                                                  blurRadius: 0.0,
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              color: Colors.transparent,
                                              width: double.infinity,
                                              height: avatarSlicedWidthOuterSize,         
                                            ),
                                            
                                            // Centered Undo button
                                            SizedBox(
                                              width: _responsiveTile * 0.15,
                                              height: _responsiveTile * 0.15,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  padding: EdgeInsets.zero,
                                                  elevation: 4,
                                                ),
                                                onPressed: _hasGameStarted ? () => _undoLastThrow() : null,
                                                child: AnimatedOpacity(
                                                  opacity: _hasGameStarted ? 1.0 : 0.3,
                                                  duration: const Duration(milliseconds: 200),
                                                  child: Image.asset(
                                                    'assets/png/mechanics/undo.png',
                                                    fit: BoxFit.contain,
                                                    filterQuality: FilterQuality.high,
                                                    ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),

                                  // Active player Hits
                                  SizedBox(
                                    width: _responsiveTile * 0.15,
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/png/mechanics/hits.png',
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.high,
                                          ),

                                          Container(
                                            width: _responsiveTile * 0.09,
                                            height: _responsiveTile * 0.09,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha(180), // White with transparency
                                              shape: BoxShape.circle,
                                            ),
                                          ),

                                          Text(
                                            '$_activePlayerCurrentRoundHits',
                                            style: TextStyle(
                                              fontSize: _responsiveFontSize * 2.5,
                                              fontWeight: FontWeight.bold,
                                              color: _isPlayerMode ? _activePlayerColor : _activeTeamColor,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(-(_responsiveFontSize * 0.15), _responsiveFontSize * 0.15),
                                                  color: Colors.black, // Or your custom gShadowColor
                                                  blurRadius: 0.0,
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (_isPlayerMode) ...[
                                        gBuildSlicedPlayerAvatarH(
                                          player: _activePlayer,
                                          avatarHeight: avatarHeight,
                                          avatarHeightOuterSize: avatarHeightOuterSize,
                                          avatarSlicedWidth: avatarSlicedWidth,
                                          avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                          slotBgColor: _activePlayerColor,
                                          playerPosition: _activePlayerIndex,
                                          responsiveTile: _responsiveTile,
                                          isTagNickNameLeft: false,
                                        ),
                                      ] else ...[
                                        gBuildSlicedPlayerAvatarH(
                                          player: _activePlayer,
                                          avatarHeight: avatarHeight,
                                          avatarHeightOuterSize: avatarHeightOuterSize,
                                          avatarSlicedWidth: avatarSlicedWidth,
                                          avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                          slotBgColor: _activeTeamColor,
                                          playerPosition: _activePlayerIndex,
                                          responsiveTile: _responsiveTile,
                                          isTagNickNameLeft: false,
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Row for Previous Player score, Rankings, Active Player (Interactive Dartboard)
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header label right above the previous player table
                                        Container(
                                          alignment: Alignment.center,
                                          //color: Colors.white,
                                          padding: EdgeInsets.only(
                                            top: _responsiveTile * 0.017,
                                            bottom: _responsiveTile * 0.004,
                                            left: _responsiveTile * 0.008,
                                          ),
                                          child: Text(
                                            _isPlayerMode ? "PREVIOUS PLAYER" : "PREVIOUS TEAM",
                                            style: gBuildArcadeTextStyle(_responsiveFontSize, 
                                              gFontWeight: FontWeight.bold, 
                                              gTextColor: _isPlayerMode ? _previousPlayerColor : _previousTeamColor,
                                            ),
                                          ),
                                        ),
                                        
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.only(
                                              bottom: _responsiveTile * 0.010,
                                              left: _responsiveTile * 0.008,
                                              right: _responsiveTile * 0.008,
                                            ),
                                            //color: Colors.orange.shade900.withAlpha(40), // Soft background tint
                                            width: double.infinity,
                                            child: _buildPreviousPlayerTable(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: _responsiveTile * 0.007),
                                        
                                        // Header label right above the player rankings table
                                        Container(
                                          alignment: Alignment.center,
                                          padding: EdgeInsets.only(
                                            top: _responsiveTile * 0.010,
                                            bottom: _responsiveTile * 0.004,
                                            left: _responsiveTile * 0.008,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade800.withAlpha(200),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(_responsiveTile * 0.03),
                                              topRight: Radius.circular(_responsiveTile * 0.03),
                                            )
                                          ),
                                          child: Text(
                                            _isPlayerMode ? "PLAYER RANKINGS" : "TEAM RANKINGS",
                                            style: gBuildArcadeTextStyle(_responsiveFontSize, 
                                              gFontWeight: FontWeight.bold, 
                                              gTextColor: Colors.amber,
                                            ),
                                          ),
                                        ),
                                        
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: _buildRankingWidget(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: _responsiveTile * 0.017),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    flex: 6,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: _responsiveTile * 0.010
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header label right above the active player table
                                          Container(
                                            alignment: Alignment.center,
                                            //color: Colors.white,
                                            padding: EdgeInsets.only(
                                              top: _responsiveTile * 0.017,
                                              bottom: _responsiveTile * 0.004,
                                              left: _responsiveTile * 0.008,
                                            ),
                                            child: Text(
                                              _isPlayerMode ? "ACTIVE PLAYER" : "ACTIVE TEAM",
                                              style: gBuildArcadeTextStyle(_responsiveFontSize, 
                                                gFontWeight: FontWeight.bold, 
                                                gTextColor: _isPlayerMode ? _activePlayerColor : _activeTeamColor,
                                              ),
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
                                                      gActiveTargetIdx: _progress.activeRoundIdx, 
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

                                          SizedBox(height: _responsiveTile * 0.017),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ),
                      ),

                      SizedBox(width: _responsiveTile * 0.008),

                      // COLUMN 3: Right Sidebar (Active Team or player)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Stack(
                            children: [
                              _isPlayerMode
                                ? gBuildSlicedPlayerAvatarVPanel(
                                    player: _activePlayer,
                                    avatarHeight: avatarHeight,
                                    avatarHeightOuterSize: avatarHeightOuterSize,
                                    avatarSlicedWidth: avatarSlicedWidth,
                                    avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                    slotBgColor: _activePlayerColor,
                                    playerPosition: _activePlayerIndex,
                                    responsiveTile: _responsiveTile,
                                    heightBoost: heightBoostPlayerPanel,
                                  )
                                : gBuildSlicedTeamCardVPanel(
                                    team: _activeTeam,
                                    cardHeight: cardHeight,
                                    cardWidth: cardWidth,
                                    cardWidthOuterSize: cardWidthOuterSize,
                                    cardSlicedHeight: cardSlicedHeight,
                                    cardSlicedHeightOuterSize: cardSlicedHeightOuterSize,
                                    slotBgColor: _activeTeamColor,
                                    teamPosition: _activeTeamIndex,
                                    responsiveTile: _responsiveTile,
                                    heightBoost: heightBoostTeamPanel,
                                  ),
                              
                              // Floating MISS button
                              Positioned(
                                bottom: _responsiveTile * 0.54,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.14,
                                    height: _responsiveTile * 0.12,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () => _processThrow(0),
                                      child: Image.asset(
                                        'assets/png/mechanics/target_miss.png',
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Floating Single button
                              Positioned(
                                bottom: _responsiveTile * 0.41,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.14,
                                    height: _responsiveTile * 0.12,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () => _processThrow(1),
                                      child: Image.asset(
                                        'assets/png/mechanics/target_single.png',
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Floating Doublle button
                              Positioned(
                                bottom: _responsiveTile * 0.28,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.14,
                                    height: _responsiveTile * 0.12,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () => _processThrow(2),
                                      child: Image.asset(
                                        'assets/png/mechanics/target_double.png',
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Floating Triple button
                              Positioned(
                                bottom: _responsiveTile * 0.15,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.14,
                                    height: _responsiveTile * 0.12,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () => _processThrow(3),
                                      child: Image.asset(
                                        'assets/png/mechanics/target_triple.png',
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Pop-up Active Player current game stats
                              Positioned(
                                bottom: _responsiveTile * 0.02,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.14,
                                    height: _responsiveTile * 0.12,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () => _showFullDebugSpreadsheet(context),
                                      child: Image.asset(
                                        'assets/png/mechanics/stats.png',
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Samurai Slash Overlay Animation Layer
            if (_showSlash)
              IgnorePointer(
                child: Center(
                  child: Lottie.asset(
                    'assets/lottie/magic-sword.json',
                    controller: _slashController,
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.8,
                    /* onLoaded: (composition) {
                      _slashController.duration = composition.duration;
                    }, */
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullDebugSpreadsheet(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // Grab all records for this specific game
        final allRecords = gamesScoresBox.values
            .where((s) => s.fldGame == _gameConfig)
            .toList();

        return AlertDialog(
          title: Text("Hive Database Inspector (${allRecords.length} records)"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.7,
            child: allRecords.isEmpty
                ? const Center(child: Text("No score records found yet."))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade100),
                        columns: const [
                          DataColumn(label: Text('Index')),
                          DataColumn(label: Text('Seat')),
                          DataColumn(label: Text('Player')),
                          DataColumn(label: Text('Round')),
                          DataColumn(label: Text('Dart')),
                          DataColumn(label: Text('Target')),
                          DataColumn(label: Text('Hits')),
                          DataColumn(label: Text('Half-It?')),
                          DataColumn(label: Text('Player Score')),
                          DataColumn(label: Text('Team Score')),
                        ],
                        rows: allRecords.asMap().entries.map((entry) {
                          final i = entry.key;
                          final s = entry.value;
                          return DataRow(cells: [
                            DataCell(Text('$i')),
                            DataCell(Text('${s.fldSeatIndex}')),
                            DataCell(Text(s.fldPlayer.fldNickName)),
                            DataCell(Text('${s.fldRound}')),
                            DataCell(Text('${s.fldDartIndex}')),
                            DataCell(Text('${s.fldTargetValue}')),
                            DataCell(Text('${s.fldHits}')),
                            DataCell(Text(s.fldIsHalfIt ? 'YES' : '')),
                            DataCell(Text('${s.fldScorePlayerSnapshot}', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text('${s.fldScoreTeamSnapshot ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviousPlayerTable() {
    return Column(
      children: [
        // Table Header Row
        Container(
          padding: EdgeInsets.only(
            top: _responsiveTile * 0.011,
            bottom: _responsiveTile * 0.011,
            left: _responsiveTile * 0.007,
            right: _responsiveTile * 0.014,
          ),
          decoration: BoxDecoration(
            color: _isPlayerMode ? _previousPlayerColor : _previousTeamColor,
            border: Border(
              bottom: BorderSide(color: _isPlayerMode ? _previousPlayerColor : _previousTeamColor, width: _responsiveTile * 0.003),
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_responsiveTile * 0.02),
              topRight: Radius.circular(_responsiveTile * 0.02),
            )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Target',
                  textAlign: TextAlign.center,
                  style: gBuildArcadeTextStyle(_responsiveFontSize * 0.53, gFontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Round',
                  textAlign: TextAlign.center,
                  style: gBuildArcadeTextStyle(_responsiveFontSize * 0.53, gFontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  _isPlayerMode ? 'Total' : 'Player/Team',
                  textAlign: TextAlign.end,
                  style: gBuildArcadeTextStyle(_responsiveFontSize * 0.53, gFontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // Scrollable Rows (Start + Targets 10 through Bull)
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: gTargetsHalf.length + 1,
            itemBuilder: (context, index) {
              // Row 0: Starting Baseline Row
              if (index == 0) {
                final baselineRecords = gamesScoresBox.values.where(
                  (s) => s.fldGame == _gameConfig && 
                         s.fldPlayer == _previousPlayer && 
                         s.fldRound == -1,
                ).toList();

                final baseline = baselineRecords.isNotEmpty ? baselineRecords.last : null;
                final startPlayerScore = baseline?.fldScorePlayerSnapshot ?? (_isPlayerMode ? _startingScore : (_startingScore / 2).round());
                
                int startTeamScore = _startingScore;
                if (!_isPlayerMode && _gameConfig.fldTeams != null) {
                  final int totalTeams = _gameConfig.fldTeams!.length;
                  final int prevTeamIdx = _progress.previousSeatIdx % totalTeams;
                  
                  final baselineTeamRecords = gamesScoresBox.values.where(
                    (s) => s.fldGame == _gameConfig && 
                           s.fldRound == -1 && 
                           (s.fldSeatIndex % totalTeams) == prevTeamIdx,
                  ).toList();
                  
                  startTeamScore = baselineTeamRecords.isNotEmpty 
                      ? (baselineTeamRecords.last.fldScoreTeamSnapshot ?? _startingScore)
                      : _startingScore;
                }

                return Container(
                  padding: EdgeInsets.only(
                    top: _responsiveTile * 0.005,
                    bottom: _responsiveTile * 0.005,
                    left: _responsiveTile * 0.001,
                    right: _responsiveTile * 0.014,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800.withAlpha(120),
                    border: Border(
                      bottom: BorderSide(color: (_isPlayerMode ? _previousPlayerColor : _previousTeamColor).withAlpha(200), width: _responsiveTile * 0.002),
                      left: BorderSide(color: (_isPlayerMode ? _previousPlayerColor : _previousTeamColor).withAlpha(200), width: _responsiveTile * 0.002),
                      right: BorderSide(color: (_isPlayerMode ? _previousPlayerColor : _previousTeamColor).withAlpha(200), width: _responsiveTile * 0.002),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize, color: Colors.black),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          "-",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize, color: Colors.black),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          _isPlayerMode ? '$startPlayerScore' : '$startPlayerScore / $startTeamScore',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Rounds 1 through 12 (Targets 10 through Bull)
              final rIdx = index - 1;
              final target = gTargetsHalf[rIdx];
              
              final roundRecords = gamesScoresBox.values.where(
                (s) => s.fldGame == _gameConfig && 
                       s.fldPlayer == _previousPlayer && 
                       s.fldRound == rIdx &&
                       s.fldDartIndex >=2,
              ).toList();

              final record = roundRecords.isNotEmpty ? roundRecords.last : null;
              final playerScore = record?.fldScorePlayerSnapshot;
              final isPenalized = record?.fldIsHalfIt ?? false;

              // Check if this is the last round the previous player threw
              final allPreviousPlayerRecords = gamesScoresBox.values.where(
                (s) => s.fldGame == _gameConfig && s.fldPlayer == _previousPlayer && s.fldRound >= 0,
              ).toList();
              
              final int? lastThrownRound = allPreviousPlayerRecords.isNotEmpty 
                  ? allPreviousPlayerRecords.map((s) => s.fldRound).reduce((a, b) => a > b ? a : b) 
                  : null;
              
              final bool isLastThrownRound = (lastThrownRound != null && rIdx == lastThrownRound);

              // If team mode, find the absolute latest team score recorded for this round across the entire team
              int? teamScore;
              if (!_isPlayerMode && _gameConfig.fldTeams != null) {
                final int totalTeams = _gameConfig.fldTeams!.length;
                final int prevTeamIdx = _progress.previousSeatIdx % totalTeams;
                
                final roundAllRecords = gamesScoresBox.values.where(
                  (s) => s.fldGame == _gameConfig && s.fldRound == rIdx && s.fldDartIndex >= 2,
                ).toList();

                final teamRoundRecords = roundAllRecords.where(
                  (s) => (s.fldSeatIndex % totalTeams) == prevTeamIdx,
                ).toList();

                if (teamRoundRecords.isNotEmpty) {
                  teamScore = teamRoundRecords.last.fldScoreTeamSnapshot;
                }
              }

              // Calculate what was scored in this round specifically
              String roundScoreStr = "-";
              if (record != null) {
                if (isPenalized) {
                  roundScoreStr = "(Half-It)";
                } else {
                  int previousRunningScore;
                  if (rIdx == 0) {
                    final baselineRecords = gamesScoresBox.values.where(
                      (s) => s.fldGame == _gameConfig && s.fldPlayer == _previousPlayer && s.fldRound == -1,
                    ).toList();
                    previousRunningScore = baselineRecords.isNotEmpty ? baselineRecords.last.fldScorePlayerSnapshot : (_isPlayerMode ? _startingScore : (_startingScore / 2).round());
                  } else {
                    final prevRoundRecords = gamesScoresBox.values.where(
                      (s) => s.fldGame == _gameConfig && s.fldPlayer == _previousPlayer && s.fldRound == rIdx - 1,
                    ).toList();
                    previousRunningScore = prevRoundRecords.isNotEmpty ? prevRoundRecords.last.fldScorePlayerSnapshot : 0;
                  }
                  
                  final int diff = playerScore! - previousRunningScore;
                  roundScoreStr = diff >= 0 ? "+ $diff" : "$diff";
                }
              }

              return Container(
                padding: EdgeInsets.only(
                  top: _responsiveTile * 0.010,
                  bottom: _responsiveTile * 0.010,
                  left: _responsiveTile * 0.001,
                  right: _responsiveTile * 0.014,
                ),
                decoration: BoxDecoration(
                  color: isPenalized 
                      ? Colors.red.shade100 
                      : (isLastThrownRound ? Colors.grey.shade800.withAlpha(120) : null),
                  border: Border(
                    bottom: BorderSide(color: (_isPlayerMode ? _previousPlayerColor : _previousTeamColor).withAlpha(200), width: _responsiveTile * 0.002),
                    left: BorderSide(color: (_isPlayerMode ? _previousPlayerColor : _previousTeamColor).withAlpha(200), width: _responsiveTile * 0.002),
                    right: BorderSide(color: (_isPlayerMode ? _previousPlayerColor : _previousTeamColor).withAlpha(200), width: _responsiveTile * 0.002),
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize, 
                          color: isPenalized 
                            ? Colors.red.shade900 
                            : (isLastThrownRound ? Colors.amber : Colors.black)
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
                          fontSize: _responsiveFontSize,
                          color: isPenalized 
                            ? Colors.red.shade900 
                            : (isLastThrownRound ? Colors.amber : Colors.black)
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        _isPlayerMode 
                            ? '${playerScore ?? '-'}' 
                            : '${playerScore ?? '-'} / ${teamScore ?? '-'}',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: _responsiveFontSize, 
                          color: isPenalized 
                            ? Colors.red.shade900 
                            : (isLastThrownRound ? Colors.amber : Colors.black),
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

  Widget _buildRankingWidget() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _responsiveTile * 0.012,
        vertical: _responsiveTile * 0.010,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withAlpha(120),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_responsiveTile * 0.03),
          bottomRight: Radius.circular(_responsiveTile * 0.03),
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _isPlayerMode ? _buildPlayerRankingsList() : _buildTeamRankingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRankingsList() {
    // Gather latest score for each player
    final List<({TblPlayer player, int score, Color color, int originalIdx})> playerScores = [];

    for (var entry in _gamePlayers) {
      final pRecords = gamesScoresBox.values.where(
        (s) => s.fldGame == _gameConfig && s.fldPlayer == entry.player,
      ).toList();

      final score = pRecords.isNotEmpty ? pRecords.last.fldScorePlayerSnapshot : _startingScore;
      playerScores.add((player: entry.player, score: score, color: entry.playerColor, originalIdx: entry.originalIndex));
    }

    // Sort descending by score
    playerScores.sort((a, b) => b.score.compareTo(a.score));

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: playerScores.length,
      itemBuilder: (context, index) {
        final item = playerScores[index];
        return Container(
          padding: EdgeInsets.symmetric(vertical: _responsiveTile * 0.010, horizontal: _responsiveTile * 0.015),
          margin: EdgeInsets.only(bottom: _responsiveTile * 0.015),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withAlpha(150),
            borderRadius: BorderRadius.circular(_responsiveTile * 0.015),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  index == 0 
                    ? Text(
                        "${index + 1}.",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: _responsiveTile * 0.04),
                      )
                    : Text(
                        "${index + 1}.",
                        style: TextStyle(color: Colors.white, fontSize: _responsiveTile * 0.0325),
                      ),

                  SizedBox(width: _responsiveTile * 0.010),
                  
                  index == 0
                    ? Text(
                        item.player.fldNickName,
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: _responsiveTile * 0.04),
                      )
                    : Text(
                        item.player.fldNickName,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: _responsiveTile * 0.0325),
                      ),
                ],
              ),

              index == 0
                ? Text(
                    "${item.score}",
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: _responsiveTile * 0.04),
                  )
                : Text(
                    "${item.score}",
                    style: TextStyle(color: Colors.white, fontSize: _responsiveTile * 0.0325),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamRankingsList() {
    if (_gameTeams.isEmpty) return const SizedBox.shrink();

    final List<({TblTeam team, int score, Color color})> teamScores = [];

    for (var entry in _gameTeams) {
      final teamPlayerNames = entry.team.fldPlayers.map((p) => p.fldNickName).toSet();
      final tRecords = gamesScoresBox.values.where(
        (s) => s.fldGame == _gameConfig && teamPlayerNames.contains(s.fldPlayer.fldNickName),
      ).toList();

      final score = tRecords.isNotEmpty ? (tRecords.last.fldScoreTeamSnapshot ?? _startingScore) : _startingScore;
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
        final teamNamesString = item.team.fldPlayers.map((p) => p.fldNickName).join(' & ');

        return Container(
          padding: EdgeInsets.symmetric(vertical: _responsiveTile * 0.010, horizontal: _responsiveTile * 0.015),
          margin: EdgeInsets.only(bottom: _responsiveTile * 0.015),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withAlpha(150),
            borderRadius: BorderRadius.circular(_responsiveTile * 0.015),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  index == 0 
                    ? Text(
                        "${index + 1}.",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: _responsiveTile * 0.04),
                      )
                    : Text(
                        "${index + 1}.",
                        style: TextStyle(color: Colors.white, fontSize: _responsiveTile * 0.0325),
                      ),
                  
                  SizedBox(width: _responsiveTile * 0.010),
                  
                  index == 0
                    ? Text(
                        teamNamesString,
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: _responsiveTile * 0.04),
                      )
                    : Text(
                        teamNamesString,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: _responsiveTile * 0.0325),
                      ),
                ],
              ),
              
              index == 0
                ? Text(
                    "${item.score}",
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: _responsiveTile * 0.04),
                  )
                : Text(
                    "${item.score}",
                    style: TextStyle(color: Colors.white, fontSize: _responsiveTile * 0.0325),
                  ),
            ],
          ),
        );
      },
    );
  }
}