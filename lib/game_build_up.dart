// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
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
import 'package:darts_101/helpers_rankings.dart';
import 'package:darts_101/helpers_stats.dart';
import 'package:darts_101/helpers_scoreboards.dart';

typedef _BuildUpSeat = ({
  TblPlayer player,
  int originalIndex,
  Color playerColor,
});

// Creates the baseline records (round -1) of a Build Up game. They also store,
// for the whole game, the lane (fldLaneIndex) and the position in that lane
// (fldSeatIndex) of every player. game.fldPlayers is ordered
// [lane 0 players..., lane 1 players...] and the first lane0Count players
// play in lane 0.
Future<void> gInitBuildUpStartingScores({
  required TblGame game,
  required int lane0Count,
}) async {
  final gamesScoresBox = Hive.box<TblGameScore>('gamesScoresBox');
  if (gamesScoresBox.values.any((s) => s.fldGame == game)) return;

  final startingScore = gGetGameOptions(game.fldGameType).fldStartingScore;

  for (int i = 0; i < game.fldPlayers.length; i++) {
    final isLane0 = i < lane0Count;
    await gamesScoresBox.add(
      TblGameScore(
        fldGame: game,
        fldPlayer: game.fldPlayers[i],
        fldLaneIndex: isLane0 ? 0 : 1,
        fldSeatIndex: isLane0 ? i : i - lane0Count,
        fldDartIndex: -1,
        fldRound: -1,
        fldTargetIndex: -1,
        fldTargetValue: 0,
        fldHits: 0,
        fldScorePlayerSnapshot: startingScore,
      ),
    );
  }
}

// Lane (0 = left, 1 = right) of every player of a Build Up game
Map<TblPlayer, int> gBuildUpPlayerLanes(TblGame game) {
  final gamesScoresBox = Hive.box<TblGameScore>('gamesScoresBox');
  return {
    for (final s in gamesScoresBox.values)
      if (s.fldGame == game && s.fldRound == -1 && s.fldLaneIndex != null)
        s.fldPlayer: s.fldLaneIndex!,
  };
}

class GameBuildUpScreen extends StatefulWidget {
  final TblGame game;
  final bool resumeMode;

  const GameBuildUpScreen({
    super.key,
    required this.game,
    required this.resumeMode,
  });

  @override
  State<GameBuildUpScreen> createState() => _GameBuildUpScreenState();
}

class _GameBuildUpScreenState extends State<GameBuildUpScreen> {
  // Define all responsive height and width of the game UI
  // Real height of the body area, measured by the layout; falls back to the computed value.
  double? _bodyHeight;
  double get _toolbarHeight =>
      (GlobalAppDisplay.safeHeight * 0.10).clamp(56.0, 142.0);
  double get _safeHeight => _bodyHeight == null
      ? GlobalAppDisplay.safeHeight
      : _bodyHeight! + _toolbarHeight;
  double get _headerHeight => (_safeHeight - _toolbarHeight) * (1 / 7);
  double get _heightBoostPlayerPanel =>
      (_safeHeight - _toolbarHeight - (_headerHeight * 0.006 * 2)) * 0.645;
  double get _avatarHeight => _headerHeight * 2;
  double get _avatarHeightOuterSize => _avatarHeight * 1.12;
  double get _avatarSlicedWidth => _avatarHeight * 0.42;
  double get _avatarSlicedWidthOuterSize => _avatarSlicedWidth * 1.12;

  double get _responsiveTile => _safeHeight * 0.67;
  double get _responsiveFontSize => (_responsiveTile * 0.035).clamp(8.0, 60.0);

  late Box<TblGameScore> gamesScoresBox;

  TblGame get _gameConfig => widget.game;
  TblGameOptions get _gameOptions => gGetGameOptions(_gameConfig.fldGameType);
  List<({int value, String label})> get _targets =>
      gGetTargetsForGame(_gameConfig);

  // Players of each lane, ordered by seat. Read from the baseline records.
  late final List<List<_BuildUpSeat>> _lanes;

  // One independent progress state per lane
  final List<GameProgressStateBU> _progress = [
    GameProgressStateBU(),
    GameProgressStateBU(),
  ];

  List<Color> get _playersSlotColors {
    final sorted = GlobalPlayersGridConfig.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return sorted.map((config) => config.bgColor).toList();
  }

  List<({TblPlayer player, int originalIndex, Color playerColor})>
  get _gamePlayers => List.generate(_gameConfig.fldPlayers.length, (index) {
    return (
      player: _gameConfig.fldPlayers[index],
      originalIndex: index,
      playerColor: _playersSlotColors[index],
    );
  });

  @override
  void initState() {
    super.initState();
    gamesScoresBox = Hive.box<TblGameScore>('gamesScoresBox');
    _lanes = _loadLanes();

    if (widget.resumeMode) {
      for (int lane = 0; lane < 2; lane++) {
        _progress[lane] = _stepLane(
          lane: lane,
          gameState: GlobalGameState.backwardState,
        );
      }

      // A game closed after a BULL hit may already be decided
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkGameOver());
    }
  }

  List<List<_BuildUpSeat>> _loadLanes() {
    final colors = _playersSlotColors;
    final lanes = <List<_BuildUpSeat>>[[], []];

    final baselines =
        gamesScoresBox.values
            .where(
              (s) =>
                  s.fldGame == _gameConfig &&
                  s.fldRound == -1 &&
                  s.fldLaneIndex != null,
            )
            .toList()
          ..sort((a, b) => a.fldSeatIndex.compareTo(b.fldSeatIndex));

    for (final s in baselines) {
      final index = _gameConfig.fldPlayers.indexOf(s.fldPlayer);
      lanes[s.fldLaneIndex!].add((
        player: s.fldPlayer,
        originalIndex: index,
        playerColor: colors[index],
      ));
    }
    return lanes;
  }

  GameProgressStateBU _stepLane({
    required int lane,
    required GlobalGameState gameState,
    int? hits,
  }) {
    return gStepGameStateBU(
      currentState: _progress[lane],
      gameState: gameState,
      gameConfig: _gameConfig,
      gamesScoresBox: gamesScoresBox,
      laneIndex: lane,
      lanePlayers: _lanes[lane].length,
      targetsList: _targets,
      hits: hits,
    );
  }

  _BuildUpSeat _activeSeat(int lane) =>
      _lanes[lane][_progress[lane].activeSeatIdx];

  _BuildUpSeat _nextSeat(int lane) => _lanes[lane][_progress[lane].nextSeatIdx];

  bool _hasLaneStarted(int lane) =>
      gBuLaneRecords(_gameConfig, gamesScoresBox, lane).isNotEmpty;

  int _playerLastScore(TblPlayer player) {
    return gamesScoresBox.values
        .lastWhere((s) => s.fldGame == _gameConfig && s.fldPlayer == player)
        .fldScorePlayerSnapshot;
  }

  // --- LOGIC: LANE FINISH / GAME OVER ---
  // Lane that won the game once the rules have been resolved
  int? _winnerLane;
  bool _isResolving = false;
  // Throws removed from the losing lane, kept so the final undo restores them
  final List<TblGameScore> _rolledBack = [];
  final List<dynamic> _keptMisses = [];

  // Throw that hit BULL in a lane (the lane is frozen from then on)
  TblGameScore? _laneFinish(int lane) {
    final lastIdx = _targets.length - 1;
    return gBuLaneRecords(
      _gameConfig,
      gamesScoresBox,
      lane,
    ).where((s) => s.fldTargetIndex == lastIdx && s.fldHits > 0).firstOrNull;
  }

  bool _isLaneFrozen(int lane) =>
      _winnerLane != null || _isResolving || _laneFinish(lane) != null;

  // Lower is better: round, then seat, then dart of the turn (modulo 3)
  int _comparePosition(TblGameScore a, TblGameScore b) {
    final byRound = a.fldRound.compareTo(b.fldRound);
    if (byRound != 0) return byRound;
    final bySeat = a.fldSeatIndex.compareTo(b.fldSeatIndex);
    if (bySeat != 0) return bySeat;
    return (a.fldDartIndex % 3).compareTo(b.fldDartIndex % 3);
  }

  // True when a lane has completed the turn (round + seat) of a BULL hit
  bool _hasPassedTurn(int lane, TblGameScore finish) {
    final state = _progress[lane];
    return state.activeRoundIdx > finish.fldRound ||
        (state.activeRoundIdx == finish.fldRound &&
            state.activeSeatIdx > finish.fldSeatIndex);
  }

  TblGameScore _copyScore(TblGameScore s) => TblGameScore(
    fldGame: s.fldGame,
    fldPlayer: s.fldPlayer,
    fldLaneIndex: s.fldLaneIndex,
    fldSeatIndex: s.fldSeatIndex,
    fldDartIndex: s.fldDartIndex,
    fldRound: s.fldRound,
    fldTargetIndex: s.fldTargetIndex,
    fldTargetValue: s.fldTargetValue,
    fldNextTargetIndex: s.fldNextTargetIndex,
    fldNextTargetValue: s.fldNextTargetValue,
    fldIsSingle: s.fldIsSingle,
    fldIsDouble: s.fldIsDouble,
    fldIsTriple: s.fldIsTriple,
    fldIsMiss: s.fldIsMiss,
    fldHits: s.fldHits,
    fldIsHalfIt: s.fldIsHalfIt,
    fldScorePlayerSnapshot: s.fldScorePlayerSnapshot,
    fldScoreTeamSnapshot: s.fldScoreTeamSnapshot,
  );

  // Called after every throw. A BULL hit only freezes its lane: the game ends
  // when the other lane hits BULL too, or completes the turn of the first hit.
  Future<void> _checkGameOver() async {
    if (_winnerLane != null || _isResolving) return;

    final f0 = _laneFinish(0);
    final f1 = _laneFinish(1);
    if (f0 == null && f1 == null) return;

    int? winner;
    if (f0 != null && f1 != null) {
      final c = _comparePosition(f0, f1);
      if (c < 0) {
        winner = 0;
      } else if (c > 0) {
        winner = 1;
      }
    } else {
      final finishedLane = f0 != null ? 0 : 1;
      final finish = f0 ?? f1!;
      if (!_hasPassedTurn(1 - finishedLane, finish)) return;
      winner = finishedLane;
    }

    if (winner == null) {
      // Same round, seat and dart: closest to the bull decides
      setState(() => _isResolving = true);
      final picked = await _askClosestToBull(f0!.fldPlayer, f1!.fldPlayer);
      if (!mounted) return;
      winner = picked == f0.fldPlayer ? 0 : 1;
      setState(() => _isResolving = false);
    }

    _resolveGame(winner);
  }

  Future<TblPlayer?> _askClosestToBull(TblPlayer p0, TblPlayer p1) {
    return showDialog<TblPlayer>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.game.fldGameType.tileBackgroundColor,
        title: Text(
          'Who was the closest to the bull?',
          textAlign: TextAlign.center,
          style: gBuildArcadeTextStyle(
            _responsiveFontSize,
            gFontWeight: FontWeight.bold,
          ),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final p in [p0, p1])
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _responsiveTile * 0.01,
                ),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(p),
                    child: () {
                      final gp = _gamePlayers.firstWhere((g) => g.player == p);
                      return gBuildSlicedPlayerAvatarH(
                        player: p,
                        avatarHeight: _avatarHeight,
                        avatarHeightOuterSize: _avatarHeightOuterSize,
                        avatarSlicedWidth: _avatarSlicedWidth,
                        avatarSlicedWidthOuterSize: _avatarSlicedWidthOuterSize,
                        slotBgColor: gp.playerColor,
                        playerPosition: gp.originalIndex,
                        responsiveTile: _responsiveTile,
                        isTagNickNameLeft: true,
                      );
                    }(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _resolveGame(int winnerLane) {
    final winnerFinish = _laneFinish(winnerLane)!;
    final loserLane = 1 - winnerLane;

    // The losing lane is rolled back to the turn of the winning BULL hit
    final toRemove = gBuLaneRecords(_gameConfig, gamesScoresBox, loserLane)
        .where(
          (s) =>
              s.fldRound > winnerFinish.fldRound ||
              (s.fldRound == winnerFinish.fldRound &&
                  s.fldSeatIndex > winnerFinish.fldSeatIndex),
        )
        .toList();

    // Only the progress is rolled back: missed darts stay recorded (pinned to
    // the player's target at the cut) so rounds and darts remain truthful.
    final cutTargets = <TblPlayer, TblGameScore>{};
    for (final s in toRemove) {
      cutTargets.putIfAbsent(s.fldPlayer, () => _copyScore(s));
    }
    final keptKeys = <dynamic>[];
    final removed = <TblGameScore>[];

    setState(() {
      _rolledBack
        ..clear()
        ..addAll(toRemove.map(_copyScore));
      _keptMisses.clear();
      for (final s in toRemove) {
        if (s.fldHits == 0) {
          final cut = cutTargets[s.fldPlayer]!;
          s.fldTargetIndex = cut.fldTargetIndex;
          s.fldTargetValue = cut.fldTargetValue;
          s.fldNextTargetIndex = cut.fldTargetIndex;
          s.fldNextTargetValue = cut.fldTargetValue;
          s.save();
          keptKeys.add(s.key);
        } else {
          removed.add(s);
        }
      }
      _keptMisses.addAll(keptKeys);
      for (final s in removed) {
        gamesScoresBox.delete(s.key);
      }
      if (toRemove.isNotEmpty) {
        _progress[loserLane] = _stepLane(
          lane: loserLane,
          gameState: GlobalGameState.backwardState,
        );
      }
      _winnerLane = winnerLane;
    });

    _showFinalStandings(winnerFinish);
  }

  void _showFinalStandings(TblGameScore winnerFinish) {
    gClearAllArcadeOverlays();

    final results = gComputeGameResults(
      gameConfig: _gameConfig,
      gamePlayers: _gamePlayers,
      gameTeams: [],
    );

    gShowBuildUpStandingsDialog(
      context: context,
      gameConfig: _gameConfig,
      results: results,
      winner: winnerFinish.fldPlayer,
      onUndoLastThrow: _undoFinalThrow,
      responsiveTile: _responsiveTile,
      responsiveFontSize: _responsiveFontSize,
      avatarHeight: _avatarHeight,
      avatarHeightOuterSize: _avatarHeightOuterSize,
      avatarSlicedWidth: _avatarSlicedWidth,
      avatarSlicedWidthOuterSize: _avatarSlicedWidthOuterSize,
    );
  }

  // Reopens the game: restores the rolled back throws and removes the
  // winning BULL hit
  void _undoFinalThrow() {
    final winnerLane = _winnerLane;
    if (winnerLane == null) return;

    setState(() {
      for (final k in _keptMisses) {
        gamesScoresBox.delete(k);
      }
      _keptMisses.clear();
      for (final s in _rolledBack) {
        gamesScoresBox.add(s);
      }
      _rolledBack.clear();
      _winnerLane = null;
      final loserLane = 1 - winnerLane;
      _progress[loserLane] = _stepLane(
        lane: loserLane,
        gameState: GlobalGameState.backwardState,
      );
    });
    _undoLastThrow(winnerLane);
  }

  void _processThrow(int lane, int tappedHits) {
    if (_isLaneFrozen(lane)) return;

    // BULL can't be skipped: hits that would go past it are reduced so the
    // throw lands on BULL (a triple on 19 is recorded as a double)
    final lastIdx = _targets.length - 1;
    final activeIdx = _progress[lane].activeTargetIdx;
    final hits = activeIdx < lastIdx
        ? tappedHits.clamp(0, lastIdx - activeIdx)
        : tappedHits;

    setState(() {
      _recordThrow(lane, hits);

      _progress[lane] = _stepLane(
        lane: lane,
        gameState: GlobalGameState.forwardState,
        hits: hits,
      );
    });

    _checkGameOver();
  }

  void _recordThrow(int lane, int hits) {
    final state = _progress[lane];
    final seat = _activeSeat(lane);
    final targetValue = _targets[state.activeTargetIdx].value;
    final lastIdx = _targets.length - 1;
    // BULL can't be skipped: only a real hit on it ends the game
    final isPastLastTarget = state.activeTargetIdx == lastIdx && hits > 0;
    final nextTargetIdx = isPastLastTarget
        ? lastIdx
        : (state.activeTargetIdx + hits).clamp(0, lastIdx);

    gamesScoresBox.add(
      TblGameScore(
        fldGame: _gameConfig,
        fldPlayer: seat.player,
        fldLaneIndex: lane,
        fldSeatIndex: state.activeSeatIdx,
        fldDartIndex: state.activeDartIdx,
        fldRound: state.activeRoundIdx,
        fldTargetIndex: state.activeTargetIdx,
        fldTargetValue: targetValue,
        fldNextTargetIndex: isPastLastTarget ? null : nextTargetIdx,
        fldNextTargetValue: isPastLastTarget
            ? null
            : _targets[nextTargetIdx].value,
        fldIsSingle: hits == 1,
        fldIsDouble: hits == 2,
        fldIsTriple: hits == 3,
        fldIsMiss: hits == 0,
        fldHits: hits,
        fldIsHalfIt: false,
        fldScorePlayerSnapshot:
            _playerLastScore(seat.player) + (targetValue * hits),
      ),
    );
  }

  void _undoLastThrow(int lane) {
    if (_winnerLane != null || _isResolving) return;
    final laneRecords = gBuLaneRecords(_gameConfig, gamesScoresBox, lane);
    if (laneRecords.isEmpty) return;

    setState(() {
      gamesScoresBox.delete(laneRecords.last.key);
      _progress[lane] = _stepLane(
        lane: lane,
        gameState: GlobalGameState.backwardState,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _gameConfig.fldGameType.tileBackgroundColor,
      appBar: gBuildAppBar(
        gToolbarHeight: _toolbarHeight,
        gAppBarTitle: _gameConfig.fldGameType.tileDisplayName,
        gAppBarColorBg: _gameConfig.fldGameType.tileColor,
        gCallFromMainScreen: false,
        gOnPressed: null,
        gRightPopupMenu: GlobalGameBuildUpPopupMenu(
          enuGameType: _gameConfig.fldGameType,
        ),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _bodyHeight = constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset(
                      'assets/png/tiles/${_gameConfig.fldGameType.tileType}_${_gameConfig.fldGameType.tileCode}.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),

                Container(
                  padding: EdgeInsets.only(
                    left: GlobalAppDisplay.safeWidth * 0.004,
                    right: GlobalAppDisplay.safeWidth * 0.004,
                    top: GlobalAppDisplay.safeWidth * 0.006,
                    bottom: _safeHeight * 0.006,
                  ),
                  height: (_safeHeight - _toolbarHeight),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _rankingWidth = _rankingWidthFor(constraints.maxWidth);
                      return Stack(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildLane(0)),
                              Expanded(child: _buildLane(1)),
                            ],
                          ),

                          // Scoreboard between the two undo buttons
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: _avatarSlicedWidthOuterSize,
                            child: Center(
                              child: _imageButton(
                                asset: 'scoreboard',
                                size: _responsiveTile * 0.16,
                                onPressed: () =>
                                    gShowGameBuildUpScoreboardDialog(
                                      context: context,
                                      gameConfig: _gameConfig,
                                      gamesScoresBox: gamesScoresBox,
                                      gameOptions: _gameOptions,
                                      lanes: [
                                        for (final lane in _lanes)
                                          [
                                            for (
                                              int i = 0;
                                              i < lane.length;
                                              i++
                                            )
                                              (
                                                originalIndex: i,
                                                player: lane[i].player,
                                                playerColor:
                                                    lane[i].playerColor,
                                              ),
                                          ],
                                      ],
                                      responsiveTile: _responsiveTile,
                                      responsiveFontSize: _responsiveFontSize,
                                    ),
                              ),
                            ),
                          ),

                          // Ranking runs from the target row down between the boards
                          Positioned(
                            top: _avatarSlicedWidthOuterSize + _rowGap,
                            bottom: _responsiveTile * 0.017,
                            left: (constraints.maxWidth - _rankingWidth) / 2,
                            width: _rankingWidth,
                            child: _buildRanking(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _rankingWidth = 0;
  double get _rowGap => _responsiveTile * 0.012;
  double get _targetRowHeight => _avatarSlicedWidthOuterSize;
  double get _dartsRowHeight => _avatarSlicedWidthOuterSize * 0.5;

  double get _statsButtonSize => _targetRowHeight * 0.9;

  // The ranking takes the width left between the target rows of both lanes
  // (each lane: two vertical panels and gaps, then the game area).
  double _rankingWidthFor(double totalWidth) {
    final gameAreaWidth =
        totalWidth / 2 -
        2 * _avatarSlicedWidthOuterSize -
        2 * _responsiveTile * 0.008;
    final width =
        2 *
        (gameAreaWidth -
            _avatarHeightOuterSize -
            _statsButtonSize -
            2 * _rowGap);
    return width.clamp(0.0, totalWidth);
  }

  Widget _buildRanking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
            top: _responsiveTile * 0.010,
            bottom: _responsiveTile * 0.004,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withAlpha(200),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_responsiveTile * 0.03),
              topRight: Radius.circular(_responsiveTile * 0.03),
            ),
          ),
          child: Text(
            "RANKING",
            style: gBuildArcadeTextStyle(
              _responsiveFontSize * 1.1,
              gFontWeight: FontWeight.bold,
              gTextColor: Colors.amber,
            ),
          ),
        ),
        Expanded(
          child: gBuildGameAroundClockRankingWidget(
            gameConfig: _gameConfig,
            gamesScoresBox: gamesScoresBox,
            gameOptions: _gameOptions,
            gamePlayers: _gamePlayers,
            gameTeams: [],
            isPlayerMode: true,
            responsiveTile: _responsiveTile,
          ),
        ),
      ],
    );
  }

  // Lane 1 reads [game area][active player][next player]; lane 0 is the
  // mirror image (right-to-left rows), everything staying upright.
  TextDirection _laneDirection(int lane) =>
      lane == 0 ? TextDirection.rtl : TextDirection.ltr;

  Widget _buildLane(int lane) {
    final state = _progress[lane];
    final active = _activeSeat(lane);
    final next = _nextSeat(lane);
    final target = _targets[state.activeTargetIdx];
    final isBullTarget = target.value == 25;
    final isFrozen = _isLaneFrozen(lane);

    return Row(
      textDirection: _laneDirection(lane),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildLaneGameArea(lane, active, target.label)),

        SizedBox(width: _responsiveTile * 0.008),

        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Stack(
              children: [
                gBuildSlicedPlayerAvatarVPanel(
                  player: active.player,
                  avatarHeight: _avatarHeight,
                  avatarHeightOuterSize: _avatarHeightOuterSize,
                  avatarSlicedWidth: _avatarSlicedWidth,
                  avatarSlicedWidthOuterSize: _avatarSlicedWidthOuterSize,
                  slotBgColor: active.playerColor,
                  playerPosition: active.originalIndex,
                  responsiveTile: _responsiveTile,
                  heightBoost: _heightBoostPlayerPanel,
                ),
                _floatingButton(
                  bottom: _responsiveTile * 0.505,
                  asset: 'target_miss',
                  onPressed: isFrozen ? null : () => _processThrow(lane, 0),
                ),
                _floatingButton(
                  bottom: _responsiveTile * 0.34,
                  asset: 'target_single',
                  onPressed: isFrozen ? null : () => _processThrow(lane, 1),
                ),
                _floatingButton(
                  bottom: _responsiveTile * 0.175,
                  asset: 'target_double',
                  onPressed: isFrozen ? null : () => _processThrow(lane, 2),
                ),
                _floatingButton(
                  bottom: _responsiveTile * 0.01,
                  asset: 'target_triple',
                  onPressed: isBullTarget || isFrozen
                      ? null
                      : () => _processThrow(lane, 3),
                ),
              ],
            ),
          ],
        ),

        SizedBox(width: _responsiveTile * 0.008),

        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Stack(
              children: [
                gBuildSlicedPlayerAvatarVPanel(
                  player: next.player,
                  avatarHeight: _avatarHeight,
                  avatarHeightOuterSize: _avatarHeightOuterSize,
                  avatarSlicedWidth: _avatarSlicedWidth,
                  avatarSlicedWidthOuterSize: _avatarSlicedWidthOuterSize,
                  slotBgColor: next.playerColor,
                  playerPosition: next.originalIndex,
                  responsiveTile: _responsiveTile,
                  heightBoost: _heightBoostPlayerPanel,
                  isNextPlayer: true,
                ),
                _floatingButton(
                  bottom: _responsiveTile * 0.005,
                  asset: 'stats',
                  sizeFactor: 0.18,
                  onPressed: () => gShowPlayerStatsGameAroundClockDialog(
                    context: context,
                    player: next.player,
                    isActivePlayer: false,
                    playerColor: next.playerColor,
                    seatIndex: state.nextSeatIdx,
                    responsiveTile: _responsiveTile,
                    responsiveFontSize: _responsiveFontSize,
                    gameConfig: _gameConfig,
                    gamesScoresBox: gamesScoresBox,
                    gameOptions: _gameOptions,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLaneGameArea(int lane, _BuildUpSeat active, String targetLabel) {
    final state = _progress[lane];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Undo of the lane and active player (fixed height so the ranking
        // can start exactly on the second row)
        SizedBox(
          height: _avatarSlicedWidthOuterSize,
          child: Row(
            textDirection: _laneDirection(lane),
            children: [
              const Spacer(),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _imageButton(
                      asset: 'undo',
                      size: _responsiveTile * 0.2,
                      onPressed: _hasLaneStarted(lane) && _winnerLane == null
                          ? () => _undoLastThrow(lane)
                          : null,
                    ),
                  ),
                ),
              ),

              gBuildSlicedPlayerAvatarH(
                player: active.player,
                avatarHeight: _avatarHeight,
                avatarHeightOuterSize: _avatarHeightOuterSize,
                avatarSlicedWidth: _avatarSlicedWidth,
                avatarSlicedWidthOuterSize: _avatarSlicedWidthOuterSize,
                slotBgColor: active.playerColor,
                playerPosition: active.originalIndex,
                responsiveTile: _responsiveTile,
                isTagNickNameLeft: lane == 0,
              ),
            ],
          ),
        ),

        SizedBox(height: _rowGap),

        // Target of the lane
        Row(
          textDirection: lane == 0 ? TextDirection.ltr : TextDirection.rtl,
          children: [
            SizedBox(
              width: _avatarHeightOuterSize,
              height: _targetRowHeight,
              child: _buildTargetContainer(targetLabel, active.playerColor),
            ),
            SizedBox(width: _rowGap),
            _imageButton(
              asset: 'stats',
              size: _statsButtonSize,
              onPressed: () => gShowPlayerStatsGameAroundClockDialog(
                context: context,
                player: active.player,
                isActivePlayer: true,
                playerColor: active.playerColor,
                seatIndex: state.activeSeatIdx,
                responsiveTile: _responsiveTile,
                responsiveFontSize: _responsiveFontSize,
                gameConfig: _gameConfig,
                gamesScoresBox: gamesScoresBox,
                gameOptions: _gameOptions,
              ),
            ),
          ],
        ),

        SizedBox(height: _rowGap),

        Align(
          alignment: lane == 0 ? Alignment.centerLeft : Alignment.centerRight,
          child: SizedBox(
            width: _avatarHeightOuterSize + _rowGap + _statsButtonSize,
            height: _dartsRowHeight,
            child: _buildDartsIndicator(lane, state.activeDartIdx % 3),
          ),
        ),

        SizedBox(height: _rowGap),

        // Interactive dartboard, leaving room for the ranking in the middle
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: lane == 1 ? _rankingWidth / 2 + _rowGap : 0,
              right: lane == 0 ? _rankingWidth / 2 + _rowGap : 0,
            ),
            child: gBuildDartboardInputZone(
              gActiveTargetIdx: state.activeTargetIdx,
              gGame: _gameConfig,
              gIsFrozen: _isLaneFrozen(lane),
              gOnTap: (hits) => _processThrow(lane, hits),
            ),
          ),
        ),

        SizedBox(height: _responsiveTile * 0.017),
      ],
    );
  }

  Widget _buildDartsIndicator(int lane, int dartsThrown) {
    final label = Text(
      "DARTS",
      style: gBuildArcadeTextStyle(
        _responsiveFontSize * 1.2,
        gFontWeight: FontWeight.bold,
        gTextColor: Colors.white,
      ),
    );
    final dots = List.generate(3, (dIdx) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: _responsiveTile * 0.004),
        child: Icon(
          Icons.circle,
          size: _responsiveFontSize * 2.5,
          color: dIdx < dartsThrown
              ? Colors.yellowAccent
              : Colors.grey.shade900,
        ),
      );
    });

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        vertical: _responsiveTile * 0.004,
        horizontal: _responsiveTile * 0.008,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withAlpha(200),
        border: Border.all(
          color: Colors.yellowAccent,
          width: _responsiveTile * 0.006,
        ),
        borderRadius: BorderRadius.circular(_responsiveTile * 0.03),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: lane == 0
              ? [label, SizedBox(width: _responsiveTile * 0.02), ...dots]
              : [...dots, SizedBox(width: _responsiveTile * 0.02), label],
        ),
      ),
    );
  }

  Widget _buildTargetContainer(String label, Color color) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        vertical: _responsiveTile * 0.004,
        horizontal: _responsiveTile * 0.008,
      ),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "TARGET",
              style: gBuildArcadeTextStyle(
                _responsiveFontSize,
                gFontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
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
          ],
        ),
      ),
    );
  }

  Widget _floatingButton({
    required double bottom,
    required String asset,
    required VoidCallback? onPressed,
    double sizeFactor = 0.16,
  }) {
    return Positioned(
      bottom: bottom,
      left: 0,
      right: 0,
      child: Center(
        child: _imageButton(
          asset: asset,
          size: _responsiveTile * sizeFactor,
          onPressed: onPressed,
        ),
      ),
    );
  }

  // Round image button (assets/png/mechanics) dimmed when disabled
  Widget _imageButton({
    required String asset,
    required double size,
    required VoidCallback? onPressed,
  }) {
    final opacity = onPressed == null ? 0.3 : 1.0;
    const fade = Duration(milliseconds: 200);

    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Center(
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: fade,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: opacity),
                        blurRadius: _responsiveTile * 0.015,
                        offset: Offset(
                          _responsiveTile * 0.003,
                          _responsiveTile * 0.003,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: opacity,
                duration: fade,
                child: Image.asset(
                  'assets/png/mechanics/$asset.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
