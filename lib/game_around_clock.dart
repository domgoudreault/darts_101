// Flutter basics
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:gif_view/gif_view.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_options.dart';
import 'package:darts_101/database/tbl_game_score.dart';
import 'package:darts_101/database/enum_game_type.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_database.dart';
import 'package:darts_101/helpers_dartboard.dart';
import 'package:darts_101/helpers_standings.dart';
import 'package:darts_101/helpers_menus.dart';

class GameAroundClockScreen extends StatefulWidget {
  final TblGame game;
  final bool resumeMode;

  const GameAroundClockScreen({
    super.key,
    required this.game,
    required this.resumeMode,
  });

  @override
  State<GameAroundClockScreen> createState() => _GameAroundClockScreenState();
}

class _GameAroundClockScreenState extends State<GameAroundClockScreen>
    with TickerProviderStateMixin {
  // Define all responsive height and width of the rosters selection UI
  double get _safeHeight => GlobalAppDisplay.safeHeight;
  double get _toolbarHeight => (_safeHeight * 0.10).clamp(56.0, 142.0);
  double get _headerHeight => (_safeHeight - _toolbarHeight) * (1 / 6);
  double get _heightBoostPlayerPanel =>
      (_safeHeight - _toolbarHeight - (_headerHeight * 0.006 * 2)) * 0.595;
  double get _heightBoostTeamPanel =>
      (_safeHeight - _toolbarHeight - (_headerHeight * 0.006 * 2)) * 0.45;
  double get _avatarHeight => _headerHeight * 2;
  double get _avatarHeightOuterSize => _avatarHeight * 1.12;
  double get _avatarSlicedWidth => _avatarHeight * 0.42;
  double get _avatarSlicedWidthOuterSize => _avatarSlicedWidth * 1.12;
  double get _cardHeight => _headerHeight * 1.9;
  double get _cardWidth => _cardHeight * 1.4628;
  double get _cardWidthOuterSize => _cardWidth * 1.12;
  double get _cardSlicedHeight => _cardWidth * 0.305;
  double get _cardSlicedHeightOuterSize => _cardSlicedHeight * 1.12;

  late AnimationController _slashController;
  bool _showSlash = false;
  // flags for animation HitsBadge
  bool _previousHitsBadgeAnime = false;
  bool _activeHitsBadgeAnime = false;

  late Box<TblGameScore> gamesScoresBox;
  late Box<TblPlayer> playersBox;
  late Box<TblTeam> teamsBox;

  GameProgressStateHalf _progress = GameProgressStateHalf();

  double get _responsiveTile => _safeHeight * 0.67;
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
  List<({TblPlayer player, int originalIndex, Color playerColor})>
  get _gamePlayers => List.generate(_gameConfig.fldPlayers.length, (index) {
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
  int get _activePlayerIndex =>
      _gamePlayers[_progress.activeSeatIdx].originalIndex;
  Color get _activePlayerColor =>
      _gamePlayers[_progress.activeSeatIdx].playerColor;
  int get _activePlayerLastScore {
    return gamesScoresBox.values
        .lastWhere(
          (gamesScores) =>
              gamesScores.fldGame == _gameConfig &&
              gamesScores.fldPlayer == _activePlayer &&
              gamesScores.fldSeatIndex == _progress.activeSeatIdx,
        )
        .fldScorePlayerSnapshot;
  }

  TblPlayer get _previousPlayer =>
      _gamePlayers[_progress.previousSeatIdx].player;
  int get _previousPlayerIndex =>
      _gamePlayers[_progress.previousSeatIdx].originalIndex;
  Color get _previousPlayerColor =>
      _gamePlayers[_progress.previousSeatIdx].playerColor;
  int get _previousPlayerLastScore {
    return gamesScoresBox.values
        .lastWhere(
          (gamesScores) =>
              gamesScores.fldGame == _gameConfig &&
              gamesScores.fldPlayer == _previousPlayer &&
              gamesScores.fldSeatIndex == _progress.previousSeatIdx,
        )
        .fldScorePlayerSnapshot;
  }

  TblPlayer get _nextPlayer => _gamePlayers[_progress.nextSeatIdx].player;
  int get _nextPlayerIndex => _gamePlayers[_progress.nextSeatIdx].originalIndex;
  Color get _nextPlayerColor => _gamePlayers[_progress.nextSeatIdx].playerColor;

  TblTeam get _activeTeam =>
      _gameTeams[_progress.activeSeatIdx % _gameTeams.length].team;
  int get _activeTeamIndex =>
      _gameTeams[_progress.activeSeatIdx % _gameTeams.length].originalIndex;
  Color get _activeTeamColor =>
      _gameTeams[_progress.activeSeatIdx % _gameTeams.length].teamColor;
  int get _activeTeamLastScore {
    final teamScores = gamesScoresBox.values.where(
      (gamesScores) =>
          gamesScores.fldGame == _gameConfig &&
          _gameTeams.any(
            (gameTeams) =>
                gameTeams.team == _activeTeam &&
                gameTeams.team.fldPlayers.contains(gamesScores.fldPlayer),
          ),
    );
    return teamScores.last.fldScoreTeamSnapshot!;
  }

  TblTeam get _previousTeam =>
      _gameTeams[_progress.previousSeatIdx % _gameTeams.length].team;
  int get _previousTeamIndex =>
      _gameTeams[_progress.previousSeatIdx % _gameTeams.length].originalIndex;
  Color get _previousTeamColor =>
      _gameTeams[_progress.previousSeatIdx % _gameTeams.length].teamColor;
  int get _previousTeamLastScore {
    final teamScores = gamesScoresBox.values.where(
      (gamesScores) =>
          gamesScores.fldGame == _gameConfig &&
          _gameTeams.any(
            (gameTeams) =>
                gameTeams.team == _previousTeam &&
                gameTeams.team.fldPlayers.contains(gamesScores.fldPlayer),
          ),
    );
    return teamScores.last.fldScoreTeamSnapshot!;
  }

  TblTeam get _nextTeam =>
      _gameTeams[_progress.nextSeatIdx % _gameTeams.length].team;
  int get _nextTeamIndex =>
      _gameTeams[_progress.nextSeatIdx % _gameTeams.length].originalIndex;
  Color get _nextTeamColor =>
      _gameTeams[_progress.nextSeatIdx % _gameTeams.length].teamColor;

  int get _activeTargetValue => gTargetsHalf[_progress.activeTargetIdx].value;
  int get _nextTargetValue => gTargetsHalf[_progress.nextTargetIdx].value;

  // Get total hits for the active player in their current round and specific seat index so far
  int get _activePlayerCurrentRoundHits {
    final activeDartsThisRound = gamesScoresBox.values.where(
      (s) =>
          s.fldGame == _gameConfig &&
          s.fldPlayer == _activePlayer &&
          s.fldSeatIndex == _progress.activeSeatIdx &&
          s.fldRound == _progress.activeRoundIdx,
    );
    return activeDartsThisRound.fold(0, (sum, record) => sum + record.fldHits);
  }

  // Get total hits for the previous player in their last completed round and specific seat index
  int get _previousPlayerLastRoundHits {
    final allDartsThisRound = gamesScoresBox.values.where(
      (s) =>
          s.fldGame == _gameConfig &&
          s.fldPlayer == _previousPlayer &&
          s.fldSeatIndex == _progress.previousSeatIdx &&
          s.fldRound == _progress.previousRoundIdx,
    );
    return allDartsThisRound.fold(0, (sum, record) => sum + record.fldHits);
  }

  @override
  void initState() {
    super.initState();
    gamesScoresBox = Hive.box<TblGameScore>('gamesScoresBox');
    
    _initGameStartingScores();

    // Handle resume mode vs fresh game initialization using the helper
    if (widget.resumeMode) {
      _progress = gStepGameStateHalf(
        currentState: GameProgressStateHalf(),
        gameState: GlobalGameState.backwardState,
        gameConfig: _gameConfig,
        gamesScoresBox: gamesScoresBox,
        totalPlayers: _gamePlayers.length,
        targetsList: gTargetsHalf,
      );
    } else {
      _progress = GameProgressStateHalf();
    }

    _slashController = AnimationController(
      vsync: this,
      duration: kIsWeb
          ? Duration(seconds: 30)
          : Duration(seconds: 2), // Fast like a sword
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

  // --- LOGIC: GAME OVER ---
  void _endGame() {
    gClearAllArcadeOverlays();

    // 1. We'll store the results in a list of Map for easy sorting
    List<GameResultRecord> finalResults = gComputeGameResults(
      gameConfig: _gameConfig,
      gamePlayers: _gamePlayers,
      gameTeams: _gameTeams
    );

    gshowStandingsDialog(
      context: context,
      gameConfig: _gameConfig,
      finalResults: finalResults,
      onUndoLastThrow: () {_undoLastThrow();},
      responsiveTile: _responsiveTile,
      responsiveFontSize: _responsiveFontSize,
      avatarHeight: _avatarHeight,
      avatarHeightOuterSize: _avatarHeightOuterSize,
      avatarSlicedWidth: _avatarSlicedWidth,
      avatarSlicedWidthOuterSize: _avatarSlicedWidthOuterSize,
      cardHeight: _cardHeight,
      cardWidth: _cardWidth,
      cardWidthOuterSize: _cardWidthOuterSize,
      cardSlicedHeight: _cardSlicedHeight,
      cardSlicedHeightOuterSize: _cardSlicedHeightOuterSize
    );
  }

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
          fldScorePlayerSnapshot: _startingScore,
          fldScoreTeamSnapshot: _startingScore * 2,
        ),
      );
    }
  }

  bool get _hasGameStarted {
    return gamesScoresBox.values.any(
      (s) => s.fldGame == _gameConfig && s.fldRound >= 0 && s.fldDartIndex >= 0,
    );
  }

  bool get _hasGamePreviousPlayer {
    return gamesScoresBox.values.any(
      (s) => s.fldGame == _gameConfig && s.fldRound >= 0 && s.fldDartIndex >= 2,
    );
  }

  bool get _hasGameNextPlayer {
    final isLastRound = _progress.activeRoundIdx >= gTargetsHalf.length - 1;
    final isLastPlayer = _progress.activeSeatIdx >= _gamePlayers.length - 1;

    // There is no next player if we are on the final player of the final round
    return !(isLastRound && isLastPlayer);
  }

  bool _checkIfHalfIt() {
    final previousDartsThisRound = gamesScoresBox.values
        .where(
          (s) =>
              s.fldGame == _gameConfig &&
              s.fldPlayer == _activePlayer &&
              s.fldRound == _progress.activeRoundIdx &&
              s.fldDartIndex < 2,
        )
        .toList();

    return previousDartsThisRound.length == 2 &&
        previousDartsThisRound.every((d) => d.fldIsMiss);
  }

  void _processThrow(int hits) {
    setState(() {
      bool isMiss = (hits == 0);

      // 1. Save the record and persist to Hive
      _recordThrow(hits);

      // 2. Set the animation flag if a round was just completed
      if (_progress.activeDartIdx == 2) {
        _previousHitsBadgeAnime = true;
        _activeHitsBadgeAnime = false;
      } else {
        _previousHitsBadgeAnime = false;
        if (!isMiss) {
          _activeHitsBadgeAnime = true;
        } else {
          _activeHitsBadgeAnime = false;
        }
      }

      // 3. Advance the state machine pointers for the next turn
      // Step state forward using the global helper function
      _progress = gStepGameStateHalf(
        currentState: _progress,
        gameState: GlobalGameState.forwardState,
        gameConfig: _gameConfig,
        gamesScoresBox: gamesScoresBox,
        totalPlayers: _gamePlayers.length,
        targetsList: gTargetsHalf,
      );

      if (_progress.endGame == true) {
        _previousHitsBadgeAnime = false;
        _activeHitsBadgeAnime = false;
        _endGame();
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
      fldNextTargetIndex: _progress.activeTargetIdx == _progress.nextTargetIdx 
        ? null
        : _progress.nextTargetIdx,
      fldNextTargetValue: _activeTargetValue == _nextTargetValue
        ? null
        : _nextTargetValue,
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
      // turn off the animation flag so it never pops up on rollback
      _previousHitsBadgeAnime = false;
      _activeHitsBadgeAnime = false;

      // 2. Delete the absolute latest record from Hive
      gamesScoresBox.delete(gameRecords.last.key);

      // 3. Step the state machine backward
      _progress = gStepGameStateHalf(
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
    final isBullTarget = _activeTargetValue == 25;

    return Scaffold(
      backgroundColor: _gameConfig.fldGameType.tileBackgroundColor,
      appBar: gBuildAppBar(
        gToolbarHeight: _toolbarHeight,
        gAppBarTitle: _gameConfig.fldGameType.tileDisplayName,
        gAppBarColorBg: _gameConfig.fldGameType.tileColor,
        gCallFromMainScreen: false,
        gOnPressed: null,
        gRightPopupMenu: GameAroundClockPopupMenu(enuGameType: _gameConfig.fldGameType),
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
                    bottom: _safeHeight * 0.006,
                  ),
                  height: (_safeHeight - _toolbarHeight),
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
                                      avatarHeight: _avatarHeight,
                                      avatarHeightOuterSize:
                                          _avatarHeightOuterSize,
                                      avatarSlicedWidth: _avatarSlicedWidth,
                                      avatarSlicedWidthOuterSize:
                                          _avatarSlicedWidthOuterSize,
                                      slotBgColor: _previousPlayerColor,
                                      playerPosition: _previousPlayerIndex,
                                      responsiveTile: _responsiveTile,
                                      heightBoost: _heightBoostPlayerPanel,
                                      isEmptyPanel: !_hasGamePreviousPlayer,
                                      isPreviousPlayer: true,
                                    )
                                  : gBuildSlicedTeamCardVPanel(
                                      team: _previousTeam,
                                      cardHeight: _cardHeight,
                                      cardWidth: _cardWidth,
                                      cardWidthOuterSize: _cardWidthOuterSize,
                                      cardSlicedHeight: _cardSlicedHeight,
                                      cardSlicedHeightOuterSize:
                                          _cardSlicedHeightOuterSize,
                                      slotBgColor: _previousTeamColor,
                                      teamPosition: _previousTeamIndex,
                                      responsiveTile: _responsiveTile,
                                      heightBoost: _heightBoostTeamPanel,
                                      focusPlayer: _hasGamePreviousPlayer
                                          ? _previousPlayer
                                          : null,
                                      focusPlayerFirst:
                                          _progress.previousSeatIdx <
                                          (_gamePlayers.length / 2),
                                      isEmptyPanel: !_hasGamePreviousPlayer,
                                      isPreviousPlayer: true,
                                    ),

                              // Floating Score Table for all players button
                              Positioned(
                                bottom: _responsiveTile * 0.01,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.16,
                                    height: _responsiveTile * 0.16,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () =>
                                          _showFullDebugSpreadsheet(context),
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      blurRadius:
                                                          _responsiveTile *
                                                          0.015,
                                                      offset: Offset(
                                                        _responsiveTile * 0.003,
                                                        _responsiveTile * 0.003,
                                                      ), // Casts shadow upward onto the screen content
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            Image.asset(
                                              'assets/png/mechanics/database.png',
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ],
                                        ),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row TOP BANNER
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    (_isPlayerMode
                                            ? _activePlayerColor
                                            : _activeTeamColor)
                                        .withAlpha(
                                          150,
                                        ), // Choose your background color here!
                                borderRadius: BorderRadius.circular(
                                  _avatarSlicedWidthOuterSize * 0.15,
                                ), // Optional: rounds the corners nicely
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Previous player
                                      if (_isPlayerMode) ...[
                                        gBuildSlicedPlayerAvatarH(
                                          player: _previousPlayer,
                                          avatarHeight: _avatarHeight,
                                          avatarHeightOuterSize:
                                              _avatarHeightOuterSize,
                                          avatarSlicedWidth: _avatarSlicedWidth,
                                          avatarSlicedWidthOuterSize:
                                              _avatarSlicedWidthOuterSize,
                                          slotBgColor: _previousPlayerColor,
                                          playerPosition: _previousPlayerIndex,
                                          responsiveTile: _responsiveTile,
                                          isTagNickNameLeft: true,
                                          isEmptyPanel: !_hasGamePreviousPlayer,
                                        ),
                                      ] else ...[
                                        gBuildSlicedPlayerAvatarH(
                                          player: _previousPlayer,
                                          avatarHeight: _avatarHeight,
                                          avatarHeightOuterSize:
                                              _avatarHeightOuterSize,
                                          avatarSlicedWidth: _avatarSlicedWidth,
                                          avatarSlicedWidthOuterSize:
                                              _avatarSlicedWidthOuterSize,
                                          slotBgColor: _previousTeamColor,
                                          playerPosition: _previousPlayerIndex,
                                          responsiveTile: _responsiveTile,
                                          isTagNickNameLeft: true,
                                          isEmptyPanel: !_hasGamePreviousPlayer,
                                        ),
                                      ],
                                    ],
                                  ),

                                  SizedBox(width: _responsiveTile * 0.004),

                                  // Previous player
                                  SizedBox(
                                    width: _responsiveTile * 0.18,
                                    height: _responsiveTile * 0.18,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () =>
                                          _showFullScoreboardDialog(context),
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      blurRadius:
                                                          _responsiveTile *
                                                          0.015,
                                                      offset: Offset(
                                                        _responsiveTile * 0.003,
                                                        _responsiveTile * 0.003,
                                                      ), // Casts shadow upward onto the screen content
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            Image.asset(
                                              'assets/png/mechanics/scoreboard.png',
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              color: Colors.transparent,
                                              width: double.infinity,
                                              height:
                                                  _avatarSlicedWidthOuterSize,
                                            ),

                                            // Centered Undo button
                                            SizedBox(
                                              width: _responsiveTile * 0.2,
                                              height: _responsiveTile * 0.2,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  padding: EdgeInsets.zero,
                                                  elevation: 4,
                                                ),
                                                onPressed: _hasGameStarted
                                                    ? () => _undoLastThrow()
                                                    : null,
                                                child: AnimatedOpacity(
                                                  opacity: _hasGameStarted
                                                      ? 1.0
                                                      : 0.3,
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  child: Image.asset(
                                                    'assets/png/mechanics/undo.png',
                                                    fit: BoxFit.contain,
                                                    filterQuality:
                                                        FilterQuality.high,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(
                                    width: _responsiveTile * 0.16,
                                    height: _responsiveTile * 0.16,
                                    child: GifView.asset(
                                      'assets/png/mechanics/arrow_right.png',
                                      height: _responsiveTile * 0.08,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),

                                  SizedBox(width: _responsiveTile * 0.012),

                                  // Active player
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (_isPlayerMode) ...[
                                        gBuildSlicedPlayerAvatarH(
                                          player: _activePlayer,
                                          avatarHeight: _avatarHeight,
                                          avatarHeightOuterSize:
                                              _avatarHeightOuterSize,
                                          avatarSlicedWidth: _avatarSlicedWidth,
                                          avatarSlicedWidthOuterSize:
                                              _avatarSlicedWidthOuterSize,
                                          slotBgColor: _activePlayerColor,
                                          playerPosition: _activePlayerIndex,
                                          responsiveTile: _responsiveTile,
                                          isTagNickNameLeft: false,
                                        ),
                                      ] else ...[
                                        gBuildSlicedPlayerAvatarH(
                                          player: _activePlayer,
                                          avatarHeight: _avatarHeight,
                                          avatarHeightOuterSize:
                                              _avatarHeightOuterSize,
                                          avatarSlicedWidth: _avatarSlicedWidth,
                                          avatarSlicedWidthOuterSize:
                                              _avatarSlicedWidthOuterSize,
                                          slotBgColor: _activeTeamColor,
                                          playerPosition: _activePlayerIndex,
                                          responsiveTile: _responsiveTile,
                                          isTagNickNameLeft: false,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Row HITS && SCORES
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: _responsiveTile * 0.015,
                                horizontal: _responsiveTile * 0.004,
                              ),
                              decoration: BoxDecoration(
                                color: Colors
                                    .transparent, // Choose your background color here!
                                borderRadius: BorderRadius.circular(
                                  _avatarSlicedWidthOuterSize * 0.15,
                                ), // Optional: rounds the corners nicely
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Previous player Score
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          gBuildArcadeOverlayHitsBadge(
                                            gHitsText: _hasGamePreviousPlayer
                                                ? '$_previousPlayerLastRoundHits'
                                                : '-',
                                            gTextColor: Color.fromARGB(
                                              255,
                                              207,
                                              20,
                                              17,
                                            ),
                                            gResponsiveTile: _responsiveTile,
                                            gResponsiveFontSize:
                                                _responsiveFontSize,
                                            gForceAnimate:
                                                _previousHitsBadgeAnime,
                                          ),

                                          SizedBox(
                                            width: _responsiveTile * 0.008,
                                          ),

                                          _buildScoreContainer(
                                            avatarHeightOuterSize:
                                                _avatarHeightOuterSize,
                                            containerColor: _isPlayerMode
                                                ? _previousPlayerColor
                                                : _previousTeamColor,
                                            isPreviousPlayer: true,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  SizedBox(width: _responsiveTile * 0.004),

                                  // Previous player Stats
                                  SizedBox(
                                    width: _responsiveTile * 0.18,
                                    height: _responsiveTile * 0.18,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: _hasGamePreviousPlayer
                                          ? () => _showPlayerStatsDialog(
                                              context,
                                              _previousPlayer,
                                              _isPlayerMode
                                                  ? _previousPlayerColor
                                                  : _previousTeamColor,
                                              _progress.previousSeatIdx,
                                            )
                                          : null,
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: AnimatedOpacity(
                                                opacity: _hasGamePreviousPlayer
                                                    ? 1.0
                                                    : 0.3,
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        blurRadius:
                                                            _responsiveTile *
                                                            0.015,
                                                        offset: Offset(
                                                          _responsiveTile *
                                                              0.003,
                                                          _responsiveTile *
                                                              0.003,
                                                        ), // Casts shadow upward onto the screen content
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            AnimatedOpacity(
                                              opacity: _hasGamePreviousPlayer
                                                  ? 1.0
                                                  : 0.3,
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: Image.asset(
                                                'assets/png/mechanics/stats.png',
                                                fit: BoxFit.contain,
                                                filterQuality:
                                                    FilterQuality.high,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        gBuildArcadeActiveTarget(
                                          currentTarget:
                                              _activeTargetValue, // or your active target variable
                                          responsiveTile: _responsiveTile,
                                          targetBgColor:
                                              _gameConfig.fldGameType.tileColor,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Active player Stats
                                  SizedBox(
                                    width: _responsiveTile * 0.18,
                                    height: _responsiveTile * 0.18,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () => _showPlayerStatsDialog(
                                        context,
                                        _activePlayer,
                                        _isPlayerMode
                                            ? _activePlayerColor
                                            : _activeTeamColor,
                                        _progress.activeSeatIdx,
                                      ),
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      blurRadius:
                                                          _responsiveTile *
                                                          0.015,
                                                      offset: Offset(
                                                        _responsiveTile * 0.003,
                                                        _responsiveTile * 0.003,
                                                      ), // Casts shadow upward onto the screen content
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            Image.asset(
                                              'assets/png/mechanics/stats.png',
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: _responsiveTile * 0.004),

                                  // Active player Score
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          _buildScoreContainer(
                                            avatarHeightOuterSize:
                                                _avatarHeightOuterSize,
                                            containerColor: _isPlayerMode
                                                ? _activePlayerColor
                                                : _activeTeamColor,
                                            isPreviousPlayer: false,
                                          ),

                                          SizedBox(
                                            width: _responsiveTile * 0.008,
                                          ),

                                          gBuildArcadeOverlayHitsBadge(
                                            gHitsText:
                                                _activePlayerCurrentRoundHits
                                                    .toString(),
                                            gTextColor: Color.fromARGB(
                                              255,
                                              207,
                                              20,
                                              17,
                                            ),
                                            gResponsiveTile: _responsiveTile,
                                            gResponsiveFontSize:
                                                _responsiveFontSize,
                                            gForceAnimate:
                                                _activeHitsBadgeAnime,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Row Rankings and Interactive Dartboard)
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: _responsiveTile * 0.004,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // Rankings
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header label right above the players ranking table
                                          Container(
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.only(
                                              top: _responsiveTile * 0.010,
                                              bottom: _responsiveTile * 0.004,
                                              left: _responsiveTile * 0.008,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade800
                                                  .withAlpha(200),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(
                                                  _responsiveTile * 0.03,
                                                ),
                                                topRight: Radius.circular(
                                                  _responsiveTile * 0.03,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              _isPlayerMode
                                                  ? "PLAYERS RANKING"
                                                  : "TEAMS RANKING",
                                              style: gBuildArcadeTextStyle(
                                                _responsiveFontSize * 1.1,
                                                gFontWeight: FontWeight.bold,
                                                gTextColor: Colors.amber,
                                              ),
                                            ),
                                          ),

                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child:
                                                        _buildRankingWidget(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(
                                            height: _responsiveTile * 0.017,
                                          ),
                                        ],
                                      ),
                                    ),

                                    Expanded(
                                      flex: 6,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: _responsiveTile * 0.010,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: gBuildDartboardInputZone(
                                                gActiveTargetIdx:
                                                    _progress.activeRoundIdx,
                                                gGametype:
                                                    _gameConfig.fldGameType,
                                                gOnTap: (leap) {
                                                  _processThrow(leap);
                                                },
                                              ),
                                            ),

                                            Container(
                                              alignment: Alignment.center,
                                              padding: EdgeInsets.symmetric(
                                                vertical:
                                                    _responsiveTile * 0.004,
                                                horizontal:
                                                    _responsiveTile * 0.008,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade800
                                                    .withAlpha(200),
                                                border: BoxBorder.all(
                                                  color: Colors.yellowAccent,
                                                  width:
                                                      _responsiveTile * 0.006,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      _responsiveTile * 0.03,
                                                    ),
                                              ),
                                              child: FittedBox(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    ..."DARTS"
                                                        .split('')
                                                        .map(
                                                          (letter) => Text(
                                                            letter,
                                                            style: gBuildArcadeTextStyle(
                                                              _responsiveFontSize *
                                                                  1.2,
                                                              gFontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              gTextColor:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),

                                                    SizedBox(
                                                      height:
                                                          _responsiveTile *
                                                          0.03,
                                                    ),

                                                    // --- 3-DART INDICATOR ROW PLACED ABOVE THE DARTBOARD ---
                                                    ...List.generate(3, (dIdx) {
                                                      bool isThrown =
                                                          dIdx <
                                                          _progress
                                                              .activeDartIdx;
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  _responsiveTile *
                                                                  0.004,
                                                            ),
                                                        child: Icon(
                                                          Icons.circle,
                                                          size:
                                                              _responsiveFontSize *
                                                              2.5,
                                                          color: isThrown
                                                              ? Colors
                                                                    .yellowAccent
                                                              : Colors
                                                                    .grey
                                                                    .shade900,
                                                        ),
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
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: _responsiveTile * 0.017),
                          ],
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
                                      avatarHeight: _avatarHeight,
                                      avatarHeightOuterSize:
                                          _avatarHeightOuterSize,
                                      avatarSlicedWidth: _avatarSlicedWidth,
                                      avatarSlicedWidthOuterSize:
                                          _avatarSlicedWidthOuterSize,
                                      slotBgColor: _activePlayerColor,
                                      playerPosition: _activePlayerIndex,
                                      responsiveTile: _responsiveTile,
                                      heightBoost: _heightBoostPlayerPanel,
                                    )
                                  : gBuildSlicedTeamCardVPanel(
                                      team: _activeTeam,
                                      cardHeight: _cardHeight,
                                      cardWidth: _cardWidth,
                                      cardWidthOuterSize: _cardWidthOuterSize,
                                      cardSlicedHeight: _cardSlicedHeight,
                                      cardSlicedHeightOuterSize:
                                          _cardSlicedHeightOuterSize,
                                      slotBgColor: _activeTeamColor,
                                      teamPosition: _activeTeamIndex,
                                      responsiveTile: _responsiveTile,
                                      heightBoost: _heightBoostTeamPanel,
                                      focusPlayer: _activePlayer,
                                      focusPlayerFirst:
                                          _progress.activeSeatIdx <
                                          (_gamePlayers.length / 2),
                                    ),

                              // Floating MISS button
                              Positioned(
                                bottom: _responsiveTile * 0.505,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.16,
                                    height: _responsiveTile * 0.16,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () => _processThrow(0),
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      blurRadius:
                                                          _responsiveTile *
                                                          0.015,
                                                      offset: Offset(
                                                        _responsiveTile * 0.003,
                                                        _responsiveTile * 0.003,
                                                      ), // Casts shadow upward onto the screen content
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            Image.asset(
                                              'assets/png/mechanics/target_miss.png',
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Floating Single button
                              Positioned(
                                bottom: _responsiveTile * 0.34,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.16,
                                    height: _responsiveTile * 0.16,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () => _processThrow(1),
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      blurRadius:
                                                          _responsiveTile *
                                                          0.015,
                                                      offset: Offset(
                                                        _responsiveTile * 0.003,
                                                        _responsiveTile * 0.003,
                                                      ), // Casts shadow upward onto the screen content
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            Image.asset(
                                              'assets/png/mechanics/target_single.png',
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Floating Double button
                              Positioned(
                                bottom: _responsiveTile * 0.175,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.16,
                                    height: _responsiveTile * 0.16,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: () => _processThrow(2),
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      blurRadius:
                                                          _responsiveTile *
                                                          0.015,
                                                      offset: Offset(
                                                        _responsiveTile * 0.003,
                                                        _responsiveTile * 0.003,
                                                      ), // Casts shadow upward onto the screen content
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            Image.asset(
                                              'assets/png/mechanics/target_double.png',
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Floating Triple button
                              Positioned(
                                bottom: _responsiveTile * 0.01,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.16,
                                    height: _responsiveTile * 0.16,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                        onPressed: isBullTarget
                                          ? null
                                          : () => _processThrow(3),
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: AnimatedOpacity(
                                                opacity: isBullTarget
                                                    ? 0.3
                                                    : 1.0,
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        blurRadius:
                                                            _responsiveTile *
                                                            0.015,
                                                        offset: Offset(
                                                          _responsiveTile *
                                                              0.003,
                                                          _responsiveTile *
                                                              0.003,
                                                        ), // Casts shadow upward onto the screen content
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            AnimatedOpacity(
                                              opacity: isBullTarget ? 0.3 : 1.0,
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: Image.asset(
                                                'assets/png/mechanics/target_triple.png',
                                                fit: BoxFit.contain,
                                                filterQuality: FilterQuality.high,
                                              ),
                                            ),
                                          ],
                                        ),
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

                      // COLUMN 4: Next Player Sidebar (Next Team or player)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Stack(
                            children: [
                              _isPlayerMode
                                  ? gBuildSlicedPlayerAvatarVPanel(
                                      player: _nextPlayer,
                                      avatarHeight: _avatarHeight,
                                      avatarHeightOuterSize:
                                          _avatarHeightOuterSize,
                                      avatarSlicedWidth: _avatarSlicedWidth,
                                      avatarSlicedWidthOuterSize:
                                          _avatarSlicedWidthOuterSize,
                                      slotBgColor: _nextPlayerColor,
                                      playerPosition: _nextPlayerIndex,
                                      responsiveTile: _responsiveTile,
                                      heightBoost: _heightBoostPlayerPanel,
                                      isEmptyPanel: !_hasGameNextPlayer,
                                      isNextPlayer: true,
                                    )
                                  : gBuildSlicedTeamCardVPanel(
                                      team: _nextTeam,
                                      cardHeight: _cardHeight,
                                      cardWidth: _cardWidth,
                                      cardWidthOuterSize: _cardWidthOuterSize,
                                      cardSlicedHeight: _cardSlicedHeight,
                                      cardSlicedHeightOuterSize:
                                          _cardSlicedHeightOuterSize,
                                      slotBgColor: _nextTeamColor,
                                      teamPosition: _nextTeamIndex,
                                      responsiveTile: _responsiveTile,
                                      heightBoost: _heightBoostTeamPanel,
                                      focusPlayer: _hasGameNextPlayer
                                          ? _nextPlayer
                                          : null,
                                      focusPlayerFirst:
                                          _progress.nextSeatIdx <
                                          (_gamePlayers.length / 2),
                                      isEmptyPanel: !_hasGameNextPlayer,
                                      isNextPlayer: true,
                                    ),

                              // Floating Stats button
                              Positioned(
                                bottom: _responsiveTile * 0.005,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: _responsiveTile * 0.18,
                                    height: _responsiveTile * 0.18,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        elevation: 4,
                                      ),
                                      onPressed: _hasGameNextPlayer
                                          ? () => _showPlayerStatsDialog(
                                              context,
                                              _nextPlayer,
                                              _isPlayerMode
                                                  ? _nextPlayerColor
                                                  : _nextTeamColor,
                                              _progress.nextSeatIdx,
                                            )
                                          : null,
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: AnimatedOpacity(
                                                opacity: _hasGameNextPlayer
                                                    ? 1.0
                                                    : 0.3,
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        blurRadius:
                                                            _responsiveTile *
                                                            0.015,
                                                        offset: Offset(
                                                          _responsiveTile *
                                                              0.003,
                                                          _responsiveTile *
                                                              0.003,
                                                        ), // Casts shadow upward onto the screen content
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            AnimatedOpacity(
                                              opacity: _hasGameNextPlayer
                                                  ? 1.0
                                                  : 0.3,
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: Image.asset(
                                                'assets/png/mechanics/stats.png',
                                                fit: BoxFit.contain,
                                                filterQuality:
                                                    FilterQuality.high,
                                              ),
                                            ),
                                          ],
                                        ),
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
                    width: GlobalAppDisplay.safeWidth,
                    height: _safeHeight,
                    onLoaded: kIsWeb
                        ? (composition) {
                            _slashController.duration =
                                composition.duration * 20;
                          }
                        : (composition) {
                            _slashController.duration = composition.duration;
                          },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlayerStatsDialog(
    BuildContext context,
    TblPlayer player,
    Color playerColor,
    int seatIndex,
  ) {
    gClearAllArcadeOverlays();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade500,
          title: Text(
            "${player.fldNickName}'s Stats",
            style: gBuildArcadeTextStyle(
              _responsiveFontSize,
              gFontWeight: FontWeight.bold,
              gTextColor: playerColor,
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: _responsiveTile * 0.8,
            height: _responsiveTile * 1.1,
            child: _buildPlayerStatsTable(
              player: player,
              playerColor: playerColor,
              seatIdx: seatIndex,
              includeCurrentRound: player == _activePlayer ? true : false,
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
                  _responsiveFontSize * 0.8,
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

  void _showFullDebugSpreadsheet(BuildContext context) {
    gClearAllArcadeOverlays();

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
                        headingRowColor: WidgetStateProperty.all(
                          Colors.blueGrey.shade100,
                        ),
                        columns: const [
                          DataColumn(label: Text('Index')),
                          DataColumn(label: Text('Seat')),
                          DataColumn(label: Text('Player')),
                          DataColumn(label: Text('Round')),
                          DataColumn(label: Text('Dart')),
                          DataColumn(label: Text('Target')),
                          DataColumn(label: Text('NextTarget')),
                          DataColumn(label: Text('Hits')),
                          DataColumn(label: Text('Half-It?')),
                          DataColumn(label: Text('Player Score')),
                          DataColumn(label: Text('Team Score')),
                        ],
                        rows: allRecords.asMap().entries.map((entry) {
                          final i = entry.key;
                          final s = entry.value;
                          return DataRow(
                            cells: [
                              DataCell(Text('$i')),
                              DataCell(Text('${s.fldSeatIndex}')),
                              DataCell(Text(s.fldPlayer.fldNickName)),
                              DataCell(Text('${s.fldRound}')),
                              DataCell(Text('${s.fldDartIndex}')),
                              DataCell(Text('${s.fldTargetValue}')),
                              DataCell(Text('${s.fldNextTargetValue}')),
                              DataCell(Text('${s.fldHits}')),
                              DataCell(Text(s.fldIsHalfIt ? 'YES' : '')),
                              DataCell(
                                Text(
                                  '${s.fldScorePlayerSnapshot}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${s.fldScoreTeamSnapshot ?? "-"}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ],
                          );
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

  Widget _buildScoreContainer({
    required double avatarHeightOuterSize,
    required Color containerColor,
    required bool isPreviousPlayer,
  }) {
    return Container(
      constraints: BoxConstraints(
        minWidth:
            avatarHeightOuterSize -
            (_responsiveTile *
                0.172), // Minimum floor so it never crushes down to zero/overflows
        maxWidth: double.infinity,
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        vertical: _responsiveTile * 0.004,
        horizontal: _responsiveTile * 0.008,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        border: BoxBorder.all(
          color: Colors.yellowAccent,
          width: _responsiveTile * 0.006,
        ),
        borderRadius: BorderRadius.circular(_responsiveTile * 0.03),
        boxShadow: [
          BoxShadow(
            blurRadius: _responsiveFontSize * 0.35,
            offset: Offset(_responsiveTile * 0.006, _responsiveTile * 0.006),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "SCORE",
            style: gBuildArcadeTextStyle(
              _responsiveFontSize,
              gFontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          if (_isPlayerMode) ...[
            Text(
              isPreviousPlayer
                  ? _hasGamePreviousPlayer
                        ? _previousPlayerLastScore.toString()
                        : '-'
                  : _activePlayerLastScore.toString(),
              style: TextStyle(
                fontSize: _responsiveFontSize * 2.6,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(
                      -(_responsiveFontSize * 0.12),
                      _responsiveFontSize * 0.12,
                    ),
                    color: Colors.black,
                    blurRadius: 0.5,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isPreviousPlayer
                      ? _hasGamePreviousPlayer
                            ? _previousPlayerLastScore.toString()
                            : '-'
                      : _activePlayerLastScore.toString(),
                  style: TextStyle(
                    fontSize: _responsiveFontSize * 2.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(
                          -(_responsiveFontSize * 0.12),
                          _responsiveFontSize * 0.12,
                        ),
                        color: Colors.black,
                        blurRadius: 0.5,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                Text(
                  '/',
                  style: TextStyle(
                    fontSize: _responsiveFontSize * 2.4,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                    shadows: [
                      Shadow(
                        offset: Offset(
                          -(_responsiveFontSize * 0.12),
                          _responsiveFontSize * 0.12,
                        ),
                        color: Colors.black,
                        blurRadius: 0.5,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                Text(
                  isPreviousPlayer
                      ? _hasGamePreviousPlayer
                            ? _previousTeamLastScore.toString()
                            : '-'
                      : _activeTeamLastScore.toString(),
                  style: TextStyle(
                    fontSize: _responsiveFontSize * 2.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(
                          -(_responsiveFontSize * 0.12),
                          _responsiveFontSize * 0.12,
                        ),
                        color: Colors.black,
                        blurRadius: 0.5,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerStatsTable({
    required TblPlayer player,
    required Color playerColor,
    required int seatIdx,
    required bool includeCurrentRound,
  }) {
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
            color: playerColor,
            border: Border(
              bottom: BorderSide(
                color: playerColor,
                width: _responsiveTile * 0.003,
              ),
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_responsiveTile * 0.02),
              topRight: Radius.circular(_responsiveTile * 0.02),
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
                    _responsiveFontSize * 0.53,
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
                    _responsiveFontSize * 0.53,
                    gFontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  _isPlayerMode ? 'Total' : 'Player/Team',
                  textAlign: TextAlign.end,
                  style: gBuildArcadeTextStyle(
                    _responsiveFontSize * 0.53,
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
                final startPlayerScore = _startingScore;
                final startTeamScore = _startingScore * 2;

                return Container(
                  padding: EdgeInsets.symmetric(
                    vertical: _responsiveTile * 0.005,
                    horizontal: _responsiveTile * 0.014,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800.withAlpha(120),
                    border: Border.all(
                      color: playerColor.withAlpha(200),
                      width: _responsiveTile * 0.002,
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
                            fontSize: _responsiveFontSize,
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
                            fontSize: _responsiveFontSize,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          _isPlayerMode
                              ? '$startPlayerScore'
                              : '$startPlayerScore / $startTeamScore',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: _responsiveFontSize,
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
                        s.fldGame == _gameConfig &&
                        s.fldPlayer == player &&
                        s.fldSeatIndex == seatIdx &&
                        s.fldRound == rIdx &&
                        (includeCurrentRound ? true : s.fldDartIndex >= 2),
                  )
                  .toList();

              final record = roundRecords.isNotEmpty ? roundRecords.last : null;
              final playerScore = record?.fldScorePlayerSnapshot;
              final isPenalized = record?.fldIsHalfIt ?? false;

              final allPlayerRecords = gamesScoresBox.values
                  .where(
                    (s) =>
                        s.fldGame == _gameConfig &&
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
              if (!_isPlayerMode && _gameConfig.fldTeams != null) {
                final int totalTeams = _gameConfig.fldTeams!.length;
                final int teamIdx = seatIdx % totalTeams;

                final roundAllRecords = gamesScoresBox.values
                    .where(
                      (s) =>
                          s.fldGame == _gameConfig &&
                          s.fldRound == rIdx &&
                          (includeCurrentRound ? true : s.fldDartIndex >= 2),
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
                              s.fldGame == _gameConfig &&
                              s.fldPlayer == player &&
                              s.fldRound == -1,
                        )
                        .toList();
                    previousRunningScore = baselineRecords.isNotEmpty
                        ? baselineRecords.last.fldScorePlayerSnapshot
                        : (_isPlayerMode
                              ? _startingScore
                              : (_startingScore / 2).round());
                  } else {
                    final prevRoundRecords = gamesScoresBox.values
                        .where(
                          (s) =>
                              s.fldGame == _gameConfig &&
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
                  vertical: _responsiveTile * 0.010,
                  horizontal: _responsiveTile * 0.014,
                ),
                decoration: BoxDecoration(
                  color: isPenalized
                      ? Colors.red.shade100
                      : (isLastThrownRound
                            ? Colors.grey.shade800.withAlpha(120)
                            : null),
                  border: Border.all(
                    color: playerColor.withAlpha(200),
                    width: _responsiveTile * 0.002,
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
                          fontSize: _responsiveFontSize,
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
                          fontSize: _responsiveFontSize,
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
                        _isPlayerMode
                            ? '${playerScore ?? '-'}'
                            : '${playerScore ?? '-'} / ${teamScore ?? '-'}',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _responsiveFontSize,
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

  Widget _buildRankingWidget() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _responsiveTile * 0.012,
        vertical: _responsiveTile * 0.010,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withAlpha(150),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_responsiveTile * 0.03),
          bottomRight: Radius.circular(_responsiveTile * 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _isPlayerMode
                ? _buildPlayersRankingList()
                : _buildTeamsRankingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersRankingList() {
    // Gather latest score for each player
    final List<({TblPlayer player, int score, Color color, int originalIdx})>
    playerScores = [];

    for (var entry in _gamePlayers) {
      final pRecords = gamesScoresBox.values
          .where((s) => s.fldGame == _gameConfig && s.fldPlayer == entry.player)
          .toList();

      final score = pRecords.isNotEmpty
          ? pRecords.last.fldScorePlayerSnapshot
          : _startingScore;
      playerScores.add((
        player: entry.player,
        score: score,
        color: entry.playerColor,
        originalIdx: entry.originalIndex,
      ));
    }

    // Sort descending by score
    playerScores.sort((a, b) => b.score.compareTo(a.score));

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: playerScores.length,
      itemBuilder: (context, index) {
        final item = playerScores[index];
        return Container(
          padding: EdgeInsets.symmetric(
            vertical: _responsiveTile * 0.010,
            horizontal: _responsiveTile * 0.015,
          ),
          margin: EdgeInsets.only(bottom: _responsiveTile * 0.013),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withAlpha(170),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            fontSize: _responsiveTile * 0.0425,
                          ),
                        )
                      : Text(
                          "${index + 1}.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _responsiveTile * 0.04,
                          ),
                        ),

                  SizedBox(width: _responsiveTile * 0.005),

                  index == 0
                      ? Text(
                          item.player.fldNickName,
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: _responsiveTile * 0.0425,
                          ),
                        )
                      : Text(
                          item.player.fldNickName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: _responsiveTile * 0.04,
                          ),
                        ),
                ],
              ),

              index == 0
                  ? Text(
                      "${item.score}",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: _responsiveTile * 0.0425,
                      ),
                    )
                  : Text(
                      "${item.score}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _responsiveTile * 0.04,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamsRankingList() {
    if (_gameTeams.isEmpty) return const SizedBox.shrink();

    final List<({TblTeam team, int score, Color color})> teamScores = [];

    for (var entry in _gameTeams) {
      final teamPlayerNames = entry.team.fldPlayers
          .map((p) => p.fldNickName)
          .toSet();
      final tRecords = gamesScoresBox.values
          .where(
            (s) =>
                s.fldGame == _gameConfig &&
                teamPlayerNames.contains(s.fldPlayer.fldNickName),
          )
          .toList();

      final score = tRecords.isNotEmpty
          ? (tRecords.last.fldScoreTeamSnapshot ?? _startingScore)
          : _startingScore;
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
        final teamNamesString = item.team.fldPlayers
            .map((p) => p.fldNickName)
            .join(' & ');

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: _responsiveTile * 0.010,
            horizontal: _responsiveTile * 0.015,
          ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            fontSize: _responsiveTile * 0.04,
                          ),
                        )
                      : Text(
                          "${index + 1}.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _responsiveTile * 0.0325,
                          ),
                        ),

                  SizedBox(width: _responsiveTile * 0.010),

                  index == 0
                      ? Text(
                          teamNamesString,
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: _responsiveTile * 0.04,
                          ),
                        )
                      : Text(
                          teamNamesString,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: _responsiveTile * 0.0325,
                          ),
                        ),
                ],
              ),

              index == 0
                  ? Text(
                      "${item.score}",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: _responsiveTile * 0.04,
                      ),
                    )
                  : Text(
                      "${item.score}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _responsiveTile * 0.0325,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _showFullScoreboardDialog(BuildContext context) {
    gClearAllArcadeOverlays();

    showDialog(
      context: context,
      builder: (context) {
        MediaQuery.sizeOf(context);

        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          title: Text(
            _isPlayerMode ? "Players Full Scoreboard" : "Teams Full Scoreboard",
            style: gBuildArcadeTextStyle(
              _responsiveFontSize,
              gFontWeight: FontWeight.bold,
              gTextColor: Colors.amber,
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: GlobalAppDisplay.safeWidth * 0.9,
            height: _safeHeight * 0.8,
            child: _buildFullScoreboardTable(),
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
                  _responsiveFontSize * 0.8,
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

  Widget _buildFullScoreboardTable() {
    final totalColumns = _gamePlayers.length + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double calculatedPlayerColWidth =
            (_isPlayerMode && _gamePlayers.length > 5)
            ? (constraints.maxWidth / (_gamePlayers.length + 1)).clamp(
                85.0,
                115.0,
              )
            : 115.0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(_responsiveTile * 0.02),
            border: Border.all(
              color: Colors.amber,
              width: _responsiveTile * 0.003,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_responsiveTile * 0.02),
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
                            height: _responsiveTile * 0.1,
                            child: Center(
                              child: Text(
                                'Targets',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: _responsiveFontSize * 0.75,
                                ),
                              ),
                            ),
                          ),
                          // Player Headers
                          if (_isPlayerMode)
                            ..._gamePlayers.map(
                              (gp) => SizedBox(
                                height: _responsiveTile * 0.1,
                                child: Center(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 2),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: _responsiveTile * 0.008,
                                      vertical: _responsiveTile * 0.004,
                                    ),
                                    decoration: BoxDecoration(
                                      color: gp.playerColor,
                                      borderRadius: BorderRadius.circular(
                                        _responsiveTile * 0.01,
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
                                        fontSize: _responsiveFontSize * 0.7,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._gamePlayers.map((gp) {
                              final teamEntry = _gameTeams.firstWhere(
                                (gt) => gt.team.fldPlayers.contains(gp.player),
                              );
                              return SizedBox(
                                height: _responsiveTile * 0.1,
                                child: Center(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 2),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: _responsiveTile * 0.008,
                                      vertical: _responsiveTile * 0.004,
                                    ),
                                    decoration: BoxDecoration(
                                      color: teamEntry.teamColor,
                                      borderRadius: BorderRadius.circular(
                                        _responsiveTile * 0.01,
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
                                        fontSize: _responsiveFontSize * 0.7,
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
                            height: _responsiveTile * 0.09,
                            child: Center(
                              child: Text(
                                'Start',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: _responsiveFontSize * 0.7,
                                ),
                              ),
                            ),
                          ),
                          if (_isPlayerMode)
                            ..._gamePlayers.map(
                              (_) => SizedBox(
                                height: _responsiveTile * 0.09,
                                child: Center(
                                  child: Text(
                                    '$_startingScore',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _responsiveFontSize * 0.7,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._gamePlayers.map((_) {
                              final startTeamScore = _startingScore * 2;
                              return SizedBox(
                                height: _responsiveTile * 0.09,
                                child: Center(
                                  child: Text(
                                    '$_startingScore / $startTeamScore',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _responsiveFontSize * 0.65,
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
                              height: _responsiveTile * 0.09,
                              child: Center(
                                child: Text(
                                  target.label,
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: _responsiveFontSize * 0.7,
                                  ),
                                ),
                              ),
                            ),
                            if (_isPlayerMode)
                              ..._gamePlayers.map((gp) {
                                final records = gamesScoresBox.values
                                    .where(
                                      (s) =>
                                          s.fldGame == _gameConfig &&
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
                                  height: _responsiveTile * 0.09,
                                  child: Center(
                                    child: hasCompletedRound
                                        ? (isHalfIt
                                              ? Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        _responsiveTile * 0.01,
                                                    vertical:
                                                        _responsiveTile * 0.003,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade700,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          _responsiveTile *
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
                                                          _responsiveFontSize *
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
                                                                _responsiveTile *
                                                                0.006,
                                                            vertical: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              _responsiveTile *
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
                                                              _responsiveFontSize *
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
                                                            _responsiveFontSize *
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
                                                            _responsiveFontSize *
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
                                                  _responsiveFontSize * 0.7,
                                            ),
                                          ),
                                  ),
                                );
                              })
                            else
                              ..._gamePlayers.map((gp) {
                                final records = gamesScoresBox.values
                                    .where(
                                      (s) =>
                                          s.fldGame == _gameConfig &&
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
                                    height: _responsiveTile * 0.09,
                                    child: Center(
                                      child: isHalfIt
                                          ? Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    _responsiveTile * 0.01,
                                                vertical:
                                                    _responsiveTile * 0.003,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade700,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      _responsiveTile * 0.02,
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
                                                      _responsiveFontSize *
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
                                                        _responsiveTile * 0.006,
                                                    vertical: 1,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          _responsiveTile *
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
                                                          _responsiveFontSize *
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
                                                        _responsiveFontSize *
                                                        0.75,
                                                  ),
                                                ),
                                                Text(
                                                  scoreDisplay,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        _responsiveFontSize *
                                                        0.65,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  );
                                }

                                return SizedBox(
                                  height: _responsiveTile * 0.09,
                                  child: Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: _responsiveFontSize * 0.7,
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
}

class GameAroundClockPopupMenu extends StatelessWidget {
  final GlobalGameType enuGameType;

  const GameAroundClockPopupMenu({super.key, required this.enuGameType});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.grey.shade700,
      iconColor: Colors.white,
      onSelected: (String value) {
        switch (value) {
          case 'gac_pop_menu_rules':
            gShowGameRulesDialog(context, enuGameType);
            break;
          case 'gac_pop_menu_info':
            gShowInformationDialog(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildMenuItem('gac_pop_menu_info', 'Information'),
        _buildMenuItem('gac_pop_menu_rules', 'Game Rules'),        
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        text,
        style: gBuildArcadeTextStyle(
          (GlobalAppDisplay.safeWidth * 0.012).clamp(11.0, 18.0),
        ),
      ),
    );
  }
}