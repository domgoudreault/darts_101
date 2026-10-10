// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:gif_view/gif_view.dart';

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
import 'package:darts_101/helpers_standings.dart';
import 'package:darts_101/helpers_menus.dart';
import 'package:darts_101/helpers_scoreboards.dart';
import 'package:darts_101/helpers_rankings.dart';
import 'package:darts_101/helpers_stats.dart';

class Game7DartsScreen extends StatefulWidget {
  final TblGame game;
  final bool resumeMode;

  const Game7DartsScreen({
    super.key,
    required this.game,
    required this.resumeMode,
  });

  @override
  State<Game7DartsScreen> createState() => _Game7DartsScreenState();
}

class _Game7DartsScreenState extends State<Game7DartsScreen>
    with TickerProviderStateMixin {
  // Define all responsive height and width of the rosters selection UI
  double get _safeHeight => GlobalAppDisplay.safeHeight;
  double get _toolbarHeight => (_safeHeight * 0.10).clamp(56.0, 142.0);
  double get _headerHeight => (_safeHeight - _toolbarHeight) * (1 / 6);
  double get _heightBoostPlayerPanel => (_safeHeight - _toolbarHeight - (_headerHeight * 0.006 * 2)) * 0.595;
  double get _heightBoostTeamPanel => (_safeHeight - _toolbarHeight - (_headerHeight * 0.006 * 2)) * 0.45;
  double get _avatarHeight => _headerHeight * 2;
  double get _avatarHeightOuterSize => _avatarHeight * 1.12;
  double get _avatarSlicedWidth => _avatarHeight * 0.42;
  double get _avatarSlicedWidthOuterSize => _avatarSlicedWidth * 1.12;
  double get _cardHeight => _headerHeight * 1.9;
  double get _cardWidth => _cardHeight * 1.4628;
  double get _cardWidthOuterSize => _cardWidth * 1.12;
  double get _cardSlicedHeight => _cardWidth * 0.305;
  double get _cardSlicedHeightOuterSize => _cardSlicedHeight * 1.12;

  // flags for animation HitsBadge
  bool _previousHitsBadgeAnime = false;
  bool _activeHitsBadgeAnime = false;

  late Box<TblGameScore> gamesScoresBox;
  late Box<TblPlayer> playersBox;
  late Box<TblTeam> teamsBox;

  GameProgressState7Darts _progress = GameProgressState7Darts();

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
    return (player: _gameConfig.fldPlayers[index],
      originalIndex: index,
      playerColor: playersSlotColors[index],
    );
  });

  List<({TblTeam team, int originalIndex, Color teamColor})> get _gameTeams {
    if (_gameConfig.fldPlayersGM || _gameConfig.fldTeams == null) {
      return [];
    }
    return List.generate(_gameConfig.fldTeams!.length, (index) {
      return (team: _gameConfig.fldTeams![index],
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
    return gamesScoresBox.values
        .lastWhere((gamesScores) =>
              gamesScores.fldGame == _gameConfig &&
              gamesScores.fldPlayer == _activePlayer &&
              gamesScores.fldSeatIndex == _progress.activeSeatIdx
        )
        .fldScorePlayerSnapshot;
  }

  TblPlayer get _previousPlayer => _gamePlayers[_progress.previousSeatIdx].player;
  int get _previousPlayerIndex => _gamePlayers[_progress.previousSeatIdx].originalIndex;
  Color get _previousPlayerColor => _gamePlayers[_progress.previousSeatIdx].playerColor;
  int get _previousPlayerLastScore {
    return gamesScoresBox.values
        .lastWhere((gamesScores) =>
              gamesScores.fldGame == _gameConfig &&
              gamesScores.fldPlayer == _previousPlayer &&
              gamesScores.fldSeatIndex == _progress.previousSeatIdx,
        )
        .fldScorePlayerSnapshot;
  }

  TblPlayer get _nextPlayer => _gamePlayers[_progress.nextSeatIdx].player;
  int get _nextPlayerIndex => _gamePlayers[_progress.nextSeatIdx].originalIndex;
  Color get _nextPlayerColor => _gamePlayers[_progress.nextSeatIdx].playerColor;

  TblTeam get _activeTeam => _gameTeams[_progress.activeSeatIdx % _gameTeams.length].team;
  int get _activeTeamIndex => _gameTeams[_progress.activeSeatIdx % _gameTeams.length].originalIndex;
  Color get _activeTeamColor => _gameTeams[_progress.activeSeatIdx % _gameTeams.length].teamColor;
  int get _activeTeamLastScore {
    final teamScores = gamesScoresBox.values.where((gamesScores) =>
          gamesScores.fldGame == _gameConfig &&
          _gameTeams.any((gameTeams) =>
                gameTeams.team == _activeTeam &&
                gameTeams.team.fldPlayers.contains(gamesScores.fldPlayer),
          ),
    );
    return teamScores.last.fldScoreTeamSnapshot!;
  }

  TblTeam get _previousTeam => _gameTeams[_progress.previousSeatIdx % _gameTeams.length].team;
  int get _previousTeamIndex => _gameTeams[_progress.previousSeatIdx % _gameTeams.length].originalIndex;
  Color get _previousTeamColor => _gameTeams[_progress.previousSeatIdx % _gameTeams.length].teamColor;
  int get _previousTeamLastScore {
    final teamScores = gamesScoresBox.values.where((gamesScores) =>
          gamesScores.fldGame == _gameConfig &&
          _gameTeams.any((gameTeams) =>
                gameTeams.team == _previousTeam &&
                gameTeams.team.fldPlayers.contains(gamesScores.fldPlayer),
          ),
    );
    return teamScores.last.fldScoreTeamSnapshot!;
  }

  TblTeam get _nextTeam => _gameTeams[_progress.nextSeatIdx % _gameTeams.length].team;
  int get _nextTeamIndex => _gameTeams[_progress.nextSeatIdx % _gameTeams.length].originalIndex;
  Color get _nextTeamColor => _gameTeams[_progress.nextSeatIdx % _gameTeams.length].teamColor;

  int get _activeTargetValue => gTargets7Darts[_progress.activeTargetIdx].value;
  int get _nextTargetValue => gTargets7Darts[_progress.nextTargetIdx].value;

  // Get total hits for the active player in their current round and specific seat index so far
  int get _activePlayerCurrentRoundHits {
    final activeDartsThisRound = gamesScoresBox.values.where((s) =>
          s.fldGame == _gameConfig &&
          s.fldPlayer == _activePlayer &&
          s.fldSeatIndex == _progress.activeSeatIdx &&
          s.fldRound == _progress.activeRoundIdx,
    );
    return activeDartsThisRound.fold(0, (sum, record) => sum + record.fldHits);
  }

  // Get total hits for the previous player in their last completed round and specific seat index
  int get _previousPlayerLastRoundHits {
    final allDartsThisRound = gamesScoresBox.values.where((s) =>
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
      _progress = gStepGameState7Darts(
        currentState: GameProgressState7Darts(),
        gameState: GlobalGameState.backwardState,
        gameConfig: _gameConfig,
        gamesScoresBox: gamesScoresBox,
        totalPlayers: _gamePlayers.length,
        totalRounds: _gameOptions.fldNbrRounds,
        targetsList: gTargets7Darts,
      );
    } else {
      _progress = GameProgressState7Darts();
    }
  }

  // --- LOGIC: GAME OVER ---
  void _endGame() {
    gClearAllArcadeOverlays();

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
      (s) => s.fldGame == _gameConfig && s.fldRound >= 0 && s.fldDartIndex >= 6,
    );
  }

  bool get _hasGameNextPlayer {
    final isLastRound = _progress.activeRoundIdx >= _gameOptions.fldNbrRounds - 1;
    final isLastPlayer = _progress.activeSeatIdx >= _gamePlayers.length - 1;

    // There is no next player if we are on the final player of the final round
    return !(isLastRound && isLastPlayer);
  }

  void _processThrow(int hits) {
    setState(() {
      bool isMiss = (hits == 0);

      // 1. Save the record and persist to Hive
      _recordThrow(hits);

      // 2. Set the animation flag if a round was just completed
      if (_progress.activeDartIdx == 6) {
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
      _progress = gStepGameState7Darts(
        currentState: _progress,
        gameState: GlobalGameState.forwardState,
        gameConfig: _gameConfig,
        gamesScoresBox: gamesScoresBox,
        totalPlayers: _gamePlayers.length,
        totalRounds: _gameOptions.fldNbrRounds,
        targetsList: gTargets7Darts,
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

    int lastDartPoints = 0;
    if (!isMiss) {
      lastDartPoints = _getPreviousDartPoints();
    }
    int newPlayerScore;
    int? newTeamScore;

    if (_isPlayerMode) {
      newPlayerScore = _activePlayerLastScore + (_activeTargetValue * hits) + lastDartPoints;
    } else {
      newPlayerScore = _activePlayerLastScore + (_activeTargetValue * hits) + lastDartPoints;
      newTeamScore = _activeTeamLastScore + (_activeTargetValue * hits) + lastDartPoints;
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
      fldScorePlayerSnapshot: newPlayerScore,
      fldScoreTeamSnapshot: newTeamScore,
    );

    gamesScoresBox.add(scoreRecord);
  }

  int _getPreviousDartPoints() {
    final prevDart = gamesScoresBox.values.where((s) =>
      s.fldGame == _gameConfig &&
      s.fldPlayer == _activePlayer &&
      s.fldRound == _progress.activeRoundIdx &&
      s.fldSeatIndex == _progress.activeSeatIdx &&
      s.fldDartIndex == _progress.activeDartIdx - 1
    ).firstOrNull;

    if (prevDart == null) {
      return 0; // First dart of the turn has no preceding dart
    }

    return prevDart.fldTargetValue * prevDart.fldHits;
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
      _progress = gStepGameState7Darts(
        currentState: _progress,
        gameState: GlobalGameState.backwardState,
        gameConfig: _gameConfig,
        gamesScoresBox: gamesScoresBox,
        totalPlayers: _gamePlayers.length,
        totalRounds: _gameOptions.fldNbrRounds,
        targetsList: gTargets7Darts,
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
        gRightPopupMenu: GlobalGame7DartsPopupMenu(enuGameType: _gameConfig.fldGameType),
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
                                        gShowGame7DartsScoreboardDialog(
                                          context: context,
                                          gameConfig: _gameConfig,
                                          gameOptions: _gameOptions,
                                          gamesScoresBox: gamesScoresBox,
                                          gamePlayers: _gamePlayers,
                                          gameTeams: _gameTeams,
                                          isPlayerMode: _isPlayerMode,
                                          responsiveTile: _responsiveTile,
                                          responsiveFontSize: _responsiveFontSize,
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
                                          ? () => gShowPlayerStatsGame7DartsDialog(
                                              context: context,
                                              player: _previousPlayer,
                                              playerColor: _isPlayerMode
                                                  ? _previousPlayerColor
                                                  : _previousTeamColor,
                                              seatIndex: _progress.previousSeatIdx,
                                              responsiveTile: _responsiveTile,
                                              responsiveFontSize: _responsiveFontSize,
                                              gameConfig: _gameConfig,
                                              gamesScoresBox: gamesScoresBox,
                                              gameOptions: _gameOptions,
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
                                      onPressed: () => gShowPlayerStatsGame7DartsDialog(
                                        context: context,
                                        player: _activePlayer,
                                        playerColor: _isPlayerMode
                                            ? _activePlayerColor
                                            : _activeTeamColor,
                                        seatIndex: _progress.activeSeatIdx,
                                        responsiveTile: _responsiveTile,
                                        responsiveFontSize: _responsiveFontSize,
                                        gameConfig: _gameConfig,
                                        gamesScoresBox: gamesScoresBox,
                                        gameOptions: _gameOptions,
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
                                                      gBuildGame7DartsRankingWidget(
                                                        gameConfig: _gameConfig,
                                                        gameOptions: _gameOptions,
                                                        gamesScoresBox: gamesScoresBox,
                                                        gamePlayers: _gamePlayers,
                                                        gameTeams: _gameTeams,
                                                        isPlayerMode: _isPlayerMode,
                                                        responsiveTile: _responsiveTile,
                                                      ),
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
                                                    _progress.activeTargetIdx,
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
                                                          0.005,
                                                    ),

                                                    // --- 7-DARTS INDICATOR ROW PLACED ABOVE THE DARTBOARD ---
                                                    ...List.generate(7, (dIdx) {
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
                                          ? () => gShowPlayerStatsGame7DartsDialog(
                                              context: context,
                                              player: _nextPlayer,
                                              playerColor: _isPlayerMode
                                                  ? _nextPlayerColor
                                                  : _nextTeamColor,
                                              seatIndex: _progress.nextSeatIdx,
                                              responsiveTile: _responsiveTile,
                                              responsiveFontSize: _responsiveFontSize,
                                              gameConfig: _gameConfig,
                                              gamesScoresBox: gamesScoresBox,
                                              gameOptions: _gameOptions,
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
          ],
        ),
      ),
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
}