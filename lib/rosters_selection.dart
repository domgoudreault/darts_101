// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:gif_view/gif_view.dart';

// Database Models
import 'package:darts_101/database/enum_game_type.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_options.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_database.dart';

// UI Screens
import 'package:darts_101/game_half_it.dart';

class RostersSelection extends StatefulWidget {
  // Define variables to hold the data passed from the previous screen
  final GlobalGameType enuGameType;

  const RostersSelection({
    super.key,
    required this.enuGameType,
  });

  @override
  State<RostersSelection> createState() => _RostersSelectionState();
}

class _RostersSelectionState extends State<RostersSelection> {  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Access boxes
  late Box<TblPlayer> playersBox;
  late Box<TblTeam> teamsBox;

  // Track whether we are selecting players or teams
  bool _isPlayersSelection = true;
  List<TblPlayer> get _selectedPlayers => gSelectedPlayers;
  List<TblTeam> get _selectedTeams => gSelectedTeams;

  double get _responsiveTile => GlobalAppDisplay.safeHeight * 0.67;
  double get _responsiveFontSize => (_responsiveTile * 0.035).clamp(8.0, 60.0);

  TblGameOptions get _gameOptions => gGetGameOptions(widget.enuGameType);
  int get _minNbrPlayers => _gameOptions.fldMinNbrPlayers;
  int get _minNbrTeams => _gameOptions.fldMinNbrTeams;
  int get _maxNbrPlayers => _gameOptions.fldMaxNbrPlayers;
  int get _maxNbrTeams => _gameOptions.fldMaxNbrTeams;


  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    playersBox = Hive.box<TblPlayer>('playersBox');
    teamsBox = Hive.box<TblTeam>('teamsBox');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    List<TblPlayer> resolveGamePlayers() {
      if (_isPlayersSelection) {
        return List<TblPlayer>.from(_selectedPlayers);
      }

      // Team mode resolution
      List<TblPlayer> firstHalf = [];
      List<TblPlayer> secondHalf = [];

      for (var team in _selectedTeams) {
        List<TblPlayer> shuffled = List<TblPlayer>.from(team.fldPlayers)..shuffle();
        firstHalf.add(shuffled[0]);
        secondHalf.add(shuffled[1]);
      }
      return [...firstHalf, ...secondHalf];
    }
    
    // 1. Instantiate the new TblGame using your model fields
    final newGame = TblGame(
      fldGameType: widget.enuGameType,
      fldPlayersGM: _isPlayersSelection,
      fldPlayers: resolveGamePlayers(),
      fldTeams: !_isPlayersSelection ? List<TblTeam>.from(_selectedTeams) : null,
      fldIsEnded: false,
    );

    // 2. Save it to the games Hive box right away
    final gamesBox = Hive.box<TblGame>('gamesBox');
    await gamesBox.add(newGame);
    
    // Guard against any async gaps if needed
    if (!mounted) return;

    // 4. Navigate to the game screen if it's Half-It
    if (widget.enuGameType.tileCode == 'half-it') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameHalfItScreen(
            game: newGame,
            resumeMode: false,
          ),
        ),
      );
    }
    
    if (!mounted) return;
    setState(() {});
  }

  bool get _hasUnfinishedGame {
    final gamesBox = Hive.box<TblGame>('gamesBox');
    // Check if there is any game of this type where fldIsEnded is false
    return gamesBox.values.any((g) => g.fldGameType == widget.enuGameType && !g.fldIsEnded);
  }

  Future<void> _resumeGame() async {
    final gamesBox = Hive.box<TblGame>('gamesBox');
    
    // Find the last uncompleted game matching the current game type
    final lastUnfinishedGame = gamesBox.values.lastWhere(
      (g) => g.fldGameType == widget.enuGameType && !g.fldIsEnded,
    );

    if (widget.enuGameType.tileCode == 'half-it') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameHalfItScreen(
            game: lastUnfinishedGame,
            resumeMode: true,
          ),
        ),
      );
    }
    // Add other game types here if needed (e.g., build-up)

    if (!mounted) return;
    setState(() {});
  }

  bool get _isPlayersTeamsMinSelectionValid {
    if (_isPlayersSelection) {
      return _minNbrPlayers > 0 && _selectedPlayers.length >= _minNbrPlayers;
    } else {
      return _minNbrTeams > 0 && _selectedTeams.length >= _minNbrTeams;
    }
  }

  bool get _isPlayersTeamsMaxSelectionValid {
    if (_isPlayersSelection) {
      return _maxNbrPlayers > 0 && _selectedPlayers.length < _maxNbrPlayers;
    } else {
      return _maxNbrTeams > 0 && _selectedTeams.length < _maxNbrTeams;
    }
  }

  bool _matchesPlayerQuery(TblPlayer player, String query) {
    if (query.isEmpty) return true;
    final terms = query.split(' ').where((term) => term.isNotEmpty).toList();
    if (terms.isEmpty) return true;

    // Use .any() so a player matches if they contain ANY of the space-separated terms
    return terms.any((term) =>
        player.fldFirstName.toLowerCase().contains(term) ||
        player.fldLastName.toLowerCase().contains(term) ||
        player.fldNickName.toLowerCase().contains(term));
  }

  bool _matchesTeamQuery(TblTeam team, String query) {
    if (query.isEmpty) return true;
    final terms = query.split(' ').where((term) => term.isNotEmpty).toList();
    if (terms.isEmpty) return true;

    final p1 = team.fldPlayers[0];
    final p2 = team.fldPlayers[1];

    bool matchesPlayer(TblPlayer player, String term) {
      return player.fldFirstName.toLowerCase().contains(term) ||
          player.fldLastName.toLowerCase().contains(term) ||
          player.fldNickName.toLowerCase().contains(term);
    }

    // Every space-separated term must match either Player 1 or Player 2
    return terms.every((term) => matchesPlayer(p1, term) || matchesPlayer(p2, term));
  }

  @override
  Widget build(BuildContext context) {    
    MediaQuery.sizeOf(context);
    
    // Define all responsive height and width of the rosters selection UI
    final toolbarHeight = (GlobalAppDisplay.safeHeight * 0.10).clamp(56.0, 142.0);
    final avatarHeight = (GlobalAppDisplay.safeHeight - toolbarHeight) * 0.279;
    final avatarHeightOuterSize = avatarHeight * 1.12;
    final avatarSlicedWidth = avatarHeight * 0.42;
    final avatarSlicedWidthOuterSize = avatarSlicedWidth * 1.12;
    final cardHeight = avatarHeight;
    final cardWidth = cardHeight * 1.4628;
    final cardWidthOuterSize = cardWidth * 1.12;
    final cardSlicedHeight = cardWidth * 0.305;
    final cardSlicedHeightOuterSize = cardSlicedHeight * 1.12;
    
    // Sort slot alignments to match player positions
    final playersSlotColors = GlobalPlayersGridConfig.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    
    // Sort slot alignments to match team positions
    final teamsSlotColors = GlobalTeamsGridConfig.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    // Pair each selected player with their original index and slot configuration (including background color)
    final pairedPlayers = List.generate(_selectedPlayers.length, (index) {
      return (
        player: _selectedPlayers[index],
        originalIndex: index,
        slotConfig: playersSlotColors[index],
      );
    });

    // Pair each selected team with their original index and slot configuration (including background color)
    final pairedTeams = List.generate(_selectedTeams.length, (index) {
      return (
        team: _selectedTeams[index],
        originalIndex: index,
        slotConfig: teamsSlotColors[index],
      );
    });

    // Filter into target lists for left (even) and right (odd) slots
    final leftPlayers = pairedPlayers.where((item) => item.originalIndex.isEven).toList();
    final rightPlayers = pairedPlayers.where((item) => item.originalIndex.isOdd).toList();

    // Filter into target lists for left (even) and right (odd) slots
    final leftTeams = pairedTeams.where((item) => item.originalIndex.isEven).toList();
    final rightTeams = pairedTeams.where((item) => item.originalIndex.isOdd).toList();
    
    return Scaffold(
      backgroundColor: widget.enuGameType.tileBackgroundColor,
      appBar: 
        gBuildAppBar(
          gToolbarHeight: toolbarHeight,
          gAppBarTitle: widget.enuGameType.tileDisplayName, 
          gAppBarColorBg: widget.enuGameType.tileColor,
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
                  'assets/png/tiles/${widget.enuGameType.tileType}_${widget.enuGameType.tileCode}.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Column(
              children: [
                // 1. Top Area including Search, Start Game and Resume Game buttons
                Row(
                  children: [
                    SizedBox(width: _responsiveTile * 0.04),
                    
                    // 1.1 Resume Game Button
                    AnimatedOpacity(
                      opacity: _hasUnfinishedGame ? 1.0 : 0.3,
                      duration: const Duration(milliseconds: 200),
                      child: MouseRegion(
                        cursor: _hasUnfinishedGame 
                          ? SystemMouseCursors.click 
                          : SystemMouseCursors.basic,
                        child: GestureDetector(
                          onTap: _hasUnfinishedGame ? () => _resumeGame() : null,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(100),
                                  blurRadius: _responsiveTile * 0.04,
                                  offset: Offset(_responsiveTile * 0.006, _responsiveTile * 0.006), // Casts shadow upward onto the screen content
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: avatarHeight * 0.5,
                                height: avatarHeight * 0.5,
                                child: Image.asset(
                                  'assets/png/mechanics/resume_game.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 1.2 Left Arrow pointing Resume Game Button
                    AnimatedOpacity(
                      opacity: _hasUnfinishedGame ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: GifView.asset(
                          'assets/png/mechanics/arrow_left.png',
                          height: _responsiveTile * 0.08,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                    ),

                    SizedBox(width: _responsiveTile * 0.06),

                    // 1.3 Search Bar
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(150),
                              blurRadius: _responsiveTile * 0.012,
                              offset: Offset(_responsiveTile * 0.008, _responsiveTile * 0.008), // Casts shadow upward onto the screen content
                            ),
                          ],
                        ), 
                        child: SizedBox(
                          height: _responsiveTile * 0.1175,
                          child: FocusScope(
                            node: FocusScopeNode(),
                            child: TextField(
                              controller: _searchController,
                              style: gBuildArcadeTextStyle(_responsiveFontSize),
                              decoration: InputDecoration(
                                hintText: 'Search player name or nickname...',
                                hintStyle: gBuildArcadeTextStyle(_responsiveFontSize, gTextColor: Colors.grey.shade400),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.amber,
                                  size: _responsiveTile * 0.0875,
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min, // Essential so it doesn't expand to fill the bar
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // 1. Clear Button (Only shows when search is active)
                                    if (_searchQuery.isNotEmpty)
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.white54,
                                          size: _responsiveTile * 0.0625,
                                        ),
                                        onPressed: () => _searchController.clear(),
                                      ),

                                    // Gap between clear button and counter pill
                                    SizedBox(width: _responsiveTile * 0.015),

                                    // 2. Embedded Arcade Counter Pill
                                    _isPlayersSelection
                                      ? ValueListenableBuilder<Box<TblPlayer>>(
                                        valueListenable: playersBox.listenable(),
                                        builder: (context, box, _) {
                                          final activePlayers = box.values.where((player) => !player.fldIsDeleted).toList();
                                          final filteredCount = _searchQuery.isEmpty
                                            ? activePlayers.length
                                            : activePlayers.where((player) => _matchesPlayerQuery(player, _searchQuery)).length;

                                          return Container(
                                            margin: EdgeInsets.only(
                                              right: GlobalAppDisplay.safeHeight * 0.01,
                                              top: GlobalAppDisplay.safeHeight * 0.01,
                                              bottom: GlobalAppDisplay.safeHeight * 0.01,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: GlobalAppDisplay.safeHeight * 0.015,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(GlobalAppDisplay.safeHeight * 0.01),
                                              border: Border.all(
                                                color: Colors.amber,
                                                width: (GlobalAppDisplay.safeHeight * 0.003).clamp(1.0, 2.0),
                                              ),
                                            ),
                                            child: Center(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  _searchQuery.isEmpty 
                                                      ? '$filteredCount' 
                                                      : '$filteredCount/${activePlayers.length}',
                                                  style: gBuildArcadeTextStyle(
                                                    _responsiveFontSize,
                                                    gTextColor: Colors.amber,
                                                    gFontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : ValueListenableBuilder<Box<TblTeam>>(
                                        valueListenable: teamsBox.listenable(),
                                        builder: (context, box, _) {
                                          final activeTeams = box.values.where((team) => !team.fldIsDeleted).toList();
                                          final filteredCount = _searchQuery.isEmpty
                                            ? activeTeams.length
                                            : activeTeams.where((team) => _matchesTeamQuery(team, _searchQuery)).length;

                                          return Container(
                                            margin: EdgeInsets.only(
                                              right: GlobalAppDisplay.safeHeight * 0.01,
                                              top: GlobalAppDisplay.safeHeight * 0.01,
                                              bottom: GlobalAppDisplay.safeHeight * 0.01,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: GlobalAppDisplay.safeHeight * 0.015,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(GlobalAppDisplay.safeHeight * 0.01),
                                              border: Border.all(
                                                color: Colors.amber,
                                                width: (GlobalAppDisplay.safeHeight * 0.003).clamp(1.0, 2.0),
                                              ),
                                            ),
                                            child: Center(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  _searchQuery.isEmpty 
                                                      ? '$filteredCount' 
                                                      : '$filteredCount/${activeTeams.length}',
                                                  style: gBuildArcadeTextStyle(
                                                    _responsiveFontSize,
                                                    gTextColor: Colors.amber,
                                                    gFontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade800,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(GlobalAppDisplay.safeHeight * 0.02),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(GlobalAppDisplay.safeHeight * 0.02),
                                  borderSide: BorderSide(
                                    color: Colors.amber,
                                    width: (GlobalAppDisplay.safeHeight * 0.005).clamp(1.5, 4.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: _responsiveTile * 0.06),
                    
                    // 1.4 Right Arrow pointing Start Button
                    AnimatedOpacity(
                      opacity: _isPlayersTeamsMinSelectionValid ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: GifView.asset(
                          'assets/png/mechanics/arrow_right.png',
                          height: _responsiveTile * 0.08,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                    ),
                    
                    // 1.5 Start Button
                    AnimatedOpacity(
                      opacity: _isPlayersTeamsMinSelectionValid ? 1.0 : 0.3,
                      duration: const Duration(milliseconds: 200),
                      child: MouseRegion(
                        cursor: _isPlayersTeamsMinSelectionValid 
                          ? SystemMouseCursors.click 
                          : SystemMouseCursors.basic,
                        child: GestureDetector(
                          onTap: _isPlayersTeamsMinSelectionValid 
                            ? () => _startGame() 
                            : null,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(150),
                                  blurRadius: _responsiveTile * 0.012,
                                  offset: Offset(_responsiveTile * 0.006, _responsiveTile * 0.006), // Casts shadow upward onto the screen content
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: avatarHeight * 0.5,
                                height: avatarHeight * 0.5,
                                child: Image.asset(
                                  'assets/png/mechanics/start_game.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: _responsiveTile * 0.04),
                  ],
                ),

                SizedBox(height: _isPlayersSelection ? _responsiveTile * 0.07 : _responsiveTile * 0.012),
                
                // 2. Middle Area: Players or Teams CarouselViews and Start Button
                Container(
                  margin: EdgeInsets.symmetric(horizontal: _responsiveTile * 0.004, vertical: _responsiveTile * 0.004),
                  padding: EdgeInsets.all(_responsiveTile * 0.004),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: _responsiveTile * 0.022),

                      // 1. Left Players or Teams CarouselView
                      Expanded(
                        child:Align(
                          alignment: Alignment.center,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isPlayersSelection) ...[
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: avatarHeightOuterSize,
                                  width: (avatarSlicedWidthOuterSize * (leftPlayers.isEmpty ? 1 : leftPlayers.length)) + 
                                        (leftPlayers.isEmpty ? 0 : (leftPlayers.length - 1) * (_responsiveTile * 0.015)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: () {
                                      final slots = _buildPlayersSlotsH(
                                        targetPlayers: leftPlayers,
                                        avatarHeight: avatarHeight,
                                        avatarHeightOuterSize: avatarHeightOuterSize,
                                        avatarSlicedWidth: avatarSlicedWidth,
                                        avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                        onTap: (originalIndex) {
                                          setState(() {
                                            _selectedPlayers.removeWhere((p) => _selectedPlayers.indexOf(p) == originalIndex);
                                          });
                                        },
                                      );
                                      
                                      if (slots.isEmpty) return <Widget>[];

                                      return slots.expand((widget) => [
                                        widget,
                                        SizedBox(width: _responsiveTile * 0.015),
                                      ]).toList()..removeLast();
                                    }(),
                                  ),
                                ),
                              ),
                            ] else ...[
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: (cardSlicedHeightOuterSize * (leftTeams.isEmpty ? 1 : leftTeams.length)) + 
                                      (leftTeams.isEmpty ? 0 : (leftTeams.length - 1) * (_responsiveTile * 0.015)),
                                  width: cardWidthOuterSize,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.max,
                                    children: () {
                                      final slots = _buildTeamsSlotsV(
                                        targetTeams: leftTeams,
                                        cardHeight: cardHeight,
                                        cardWidth: cardWidth,
                                        cardWidthOuterSize: cardWidthOuterSize,
                                        cardSlicedHeight: cardSlicedHeight,
                                        cardSlicedHeightOuterSize: cardSlicedHeightOuterSize,
                                        onTap: (originalIndex) {
                                          setState(() {
                                            _selectedTeams.removeWhere((p) => _selectedTeams.indexOf(p) == originalIndex);
                                          });
                                        },
                                      );

                                      if (slots.isEmpty) return <Widget>[];

                                      return slots.expand((widget) => [
                                        widget,
                                        SizedBox(height: _responsiveTile * 0.015),
                                      ]).toList()..removeLast();
                                    }(),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        ),
                      ),

                      SizedBox(width: _responsiveTile * 0.015),
                      
                      // 2. Center Right Start Button
                      AnimatedOpacity(
                        opacity: _isPlayersTeamsMinSelectionValid ? 1.0 : 0.3,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 2.1 Bottom Arrow on top side
                            AnimatedOpacity(
                              opacity: _isPlayersTeamsMinSelectionValid ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: GifView.asset(
                                  'assets/png/mechanics/arrow_right.png',
                                  height: _responsiveTile * 0.08,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),

                            SizedBox(height: _responsiveTile * 0.015),

                            // 2.2 Shuffle Button
                            MouseRegion(
                              cursor: _isPlayersTeamsMinSelectionValid 
                                ? SystemMouseCursors.click 
                                : SystemMouseCursors.basic,
                              child: GestureDetector(
                                onTap: _isPlayersTeamsMinSelectionValid 
                                  ? _isPlayersSelection
                                    ? () async {
                                        setState(() {
                                          _selectedPlayers.shuffle();
                                        });
                                      }
                                    : () async {
                                        setState(() {
                                          _selectedTeams.shuffle();
                                        });
                                      }
                                  : null,
                                child: Center(
                                  child: Stack(
                                    children: [
                                      // 1. Bottom Layer: Dynamic Solid Fill Background
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.blue,
                                            boxShadow: [
                                              BoxShadow(
                                                //color: Colors.black.withAlpha(150),
                                                blurRadius: _responsiveTile * 0.015,
                                                offset: Offset(_responsiveTile * 0.006, _responsiveTile * 0.006), // Casts shadow upward onto the screen content
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      // 2. Middle Layer: Crisp PNG Icon Asset
                                      SizedBox(
                                        width: avatarHeight * 0.5,
                                        height: avatarHeight * 0.5,
                                        child: Image.asset(
                                          _isPlayersSelection 
                                            ? 'assets/png/mechanics/shuffle_players.png' 
                                            : 'assets/png/mechanics/shuffle_teams.png',
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                      
                                      // 3. Top Overlay Layer: Circular Border Ring
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.amber.shade300,
                                              width: ((GlobalAppDisplay.safeHeight * 0.105) * 0.03),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 2.3 Up Arrow on bottom side
                            SizedBox(height: _responsiveTile * 0.015),
                            
                            AnimatedOpacity(
                              opacity: _isPlayersTeamsMinSelectionValid ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: GifView.asset(
                                  'assets/png/mechanics/arrow_left.png',
                                  height: _responsiveTile * 0.08,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: _responsiveTile * 0.015),

                      // 3. Right Players or Teams CarouselView
                      Expanded(
                        child:Align(
                          alignment: Alignment.center,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isPlayersSelection) ...[
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: avatarHeightOuterSize,
                                  width: (avatarSlicedWidthOuterSize * (rightPlayers.isEmpty ? 1 : rightPlayers.length)) + 
                                        (rightPlayers.isEmpty ? 0 : (rightPlayers.length - 1) * (_responsiveTile * 0.015)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: () {
                                      final slots = _buildPlayersSlotsH(
                                        targetPlayers: rightPlayers,
                                        avatarHeight: avatarHeight,
                                        avatarHeightOuterSize: avatarHeightOuterSize,
                                        avatarSlicedWidth: avatarSlicedWidth,
                                        avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
                                        onTap: (originalIndex) {
                                          setState(() {
                                            _selectedPlayers.removeWhere((p) => _selectedPlayers.indexOf(p) == originalIndex);
                                          });
                                        },
                                      );
                                      
                                      if (slots.isEmpty) return <Widget>[];

                                      return slots.expand((widget) => [
                                        widget,
                                        SizedBox(width: _responsiveTile * 0.015),
                                      ]).toList()..removeLast();
                                    }(),
                                  ),
                                ),
                              ),
                            ] else ...[
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: (cardSlicedHeightOuterSize * (rightTeams.isEmpty ? 1 : rightTeams.length)) + 
                                      (rightTeams.isEmpty ? 0 : (rightTeams.length - 1) * (_responsiveTile * 0.015)),
                                  width: cardWidthOuterSize,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.max,
                                    children: () {
                                      final slots = _buildTeamsSlotsV(
                                        targetTeams: rightTeams,
                                        cardHeight: cardHeight,
                                        cardWidth: cardWidth,
                                        cardWidthOuterSize: cardWidthOuterSize,
                                        cardSlicedHeight: cardSlicedHeight,
                                        cardSlicedHeightOuterSize: cardSlicedHeightOuterSize,
                                        onTap: (originalIndex) {
                                          setState(() {
                                            _selectedTeams.removeWhere((p) => _selectedTeams.indexOf(p) == originalIndex);
                                          });
                                        },
                                      );

                                      if (slots.isEmpty) return <Widget>[];

                                      return slots.expand((widget) => [
                                        widget,
                                        SizedBox(height: _responsiveTile * 0.015),
                                      ]).toList()..removeLast();
                                    }(),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                        ),
                      ),

                      SizedBox(width: _responsiveTile * 0.022),
                    ],
                  ),
                ),

                const Spacer(),

                // 3. Persistent Bottom Panel (Aligned horizontally with the box above, zero safe-area interference)
                Container(
                  width: GlobalAppDisplay.safeWidth * 0.85,
                  height: _isPlayersSelection 
                    ? avatarHeight + _responsiveTile * 0.127 
                    : cardHeight + _responsiveTile * 0.127,
                  margin: EdgeInsets.symmetric(horizontal: _responsiveTile * 0.025),
                  padding: EdgeInsets.symmetric(vertical: _responsiveTile * 0.005),
                  decoration: BoxDecoration(
                    color: _isPlayersSelection ? GlobalSettingType.players.tileColor : GlobalSettingType.teams.tileColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_responsiveTile * 0.042),
                      bottom: Radius.zero,
                    ),
                    border: Border.all(
                      color: Colors.amber, // Or Colors.white depending on the contrast you want
                      width: _responsiveTile * 0.003,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(150),
                        blurRadius: _responsiveTile * 0.015,
                        offset: Offset(0, -_responsiveTile * 0.006), // Casts shadow upward onto the screen content
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: _responsiveTile * 0.005),
                        padding: EdgeInsets.symmetric(vertical: _responsiveTile * 0.006),
                        decoration: BoxDecoration(
                          color: _isPlayersSelection ? GlobalSettingType.players.tilePickerColor : GlobalSettingType.teams.tilePickerColor,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(_responsiveTile * 0.036),
                            bottom: Radius.zero,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: _responsiveTile * 0.0025,
                          ),
                        ),
                        
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  _isPlayersSelection ? 'SELECT PLAYERS' : 'SELECT TEAMS',
                                  style: gBuildArcadeTextStyle((_responsiveFontSize * 0.70).clamp(8.0, 60.0)),
                                ),
                              ),
                            ),
                            _buildTogglePlayersTeams(),
                          ],
                        )
                      ),

                      SizedBox(height: _responsiveTile * 0.015),

                      Expanded(
                        child: _isPlayersSelection
                          ? ValueListenableBuilder<Box<TblPlayer>>(
                              valueListenable: playersBox.listenable(),
                              builder: (context, box, _) {
                                // Filter out deleted and already selected players
                                final activePlayers = box.values
                                    .where((player) => !player.fldIsDeleted && !_selectedPlayers.contains(player))
                                    .toList();

                                // Apply search filter on top of active players
                                final playerList = _searchQuery.isEmpty
                                  ? activePlayers
                                  : activePlayers.where((player) => _matchesPlayerQuery(player, _searchQuery)).toList();

                                if (playerList.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No players found.',
                                      style: gBuildArcadeTextStyle(
                                        (_responsiveFontSize * 0.80).clamp(10.0, 60.0),
                                        gTextColor: Colors.white,
                                      ),
                                    ),
                                  );
                                }

                                return CarouselView(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                                  itemExtent: avatarHeight + 2.0,
                                  shrinkExtent: avatarHeight * 0.8,
                                  onTap: (int index) {
                                    if (_isPlayersTeamsMaxSelectionValid) {
                                      setState(() {
                                        _selectedPlayers.add(playerList[index]);
                                      });
                                    } else {
                                      gShowArcadeErrorSnackBar(
                                        gContext: context,
                                        gFontSize: _responsiveFontSize,
                                        gMessage: 'Maximum $_maxNbrPlayers players allowed!',
                                        gDuration: 2,
                                      );
                                    }
                                  },
                                  children: playerList.map((player) {
                                    return gBuildPlayerAvatarCard(
                                      player: player,
                                      avatarHeight: avatarHeight,
                                      bgColor: GlobalSettingType.players.tileBackgroundColor,
                                      isSlicedAvatar: false,
                                      isSlicedVertical: false,
                                      isTagNickNameLeft: false,
                                      );
                                  }).toList(),
                                );
                              },
                            )
                          : ValueListenableBuilder<Box<TblTeam>>(
                              valueListenable: teamsBox.listenable(),
                              builder: (context, box, _) {
                                // Filter out deleted and already selected teams
                                final activeTeams = box.values.where((team) {
                                  if (team.fldIsDeleted || _selectedTeams.contains(team)) return false;
                                  
                                  // Check if any player in this team is already present in any already-selected team
                                  final isPlayerAlreadySelected = team.fldPlayers.any((player) =>
                                      _selectedTeams.any((selectedTeam) => selectedTeam.fldPlayers.contains(player)));

                                  return !isPlayerAlreadySelected;
                                }).toList();

                                // Apply search filter on top of active players
                                final teamList = _searchQuery.isEmpty
                                  ? activeTeams
                                  : activeTeams.where((team) => _matchesTeamQuery(team, _searchQuery)).toList();
                              
                                if (teamList.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No teams found.',
                                      style: gBuildArcadeTextStyle(
                                        (_responsiveFontSize * 0.80).clamp(10.0, 60.0),
                                        gTextColor: Colors.white,
                                      ),
                                    ),
                                  );
                                }
                                return CarouselView(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                                  itemExtent: cardWidth + 2.0,
                                  shrinkExtent: cardWidth * 0.8,
                                  onTap: (int index) {
                                    if (_isPlayersTeamsMaxSelectionValid) {
                                      setState(() {
                                        _selectedTeams.add(teamList[index]);
                                      });
                                    } else {
                                      gShowArcadeErrorSnackBar(
                                        gContext: context,
                                        gFontSize: _responsiveFontSize,
                                        gMessage: 'Maximum $_maxNbrTeams teams allowed!',
                                        gDuration: 2,
                                      );
                                    }
                                  },
                                  children: teamList.map((team) {
                                    return Center(
                                      child: AspectRatio(
                                        aspectRatio: cardWidth / cardHeight,
                                        child: gBuildTeamCardH(
                                          cardHeight: cardHeight,
                                          cardWidth: cardWidth,
                                          selectedPlayer1: team.fldPlayers[0],
                                          selectedPlayer2: team.fldPlayers[1],
                                          isDummyTeam: team.fldPlayers[0] == team.fldPlayers[1],
                                          colorBgAvatar: GlobalSettingType.teams.tileBackgroundColor,
                                          isSlicedCard: false,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
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

  List<Widget> _buildPlayersSlotsH({
    required List<({TblPlayer player, int originalIndex, GlobalPlayersGridConfig slotConfig})> targetPlayers,
    required double avatarHeight,
    required double avatarHeightOuterSize,
    required double avatarSlicedWidth,
    required double avatarSlicedWidthOuterSize,
    required void Function(int originalIndex) onTap,
  }) {
    return List.generate(targetPlayers.length, (index) {
      final item = targetPlayers[index];
      final player = item.player;
      final originalIndex = item.originalIndex;
      final slotColor = item.slotConfig;

      // The core visual card content
      final cardWidget = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onTap(originalIndex),
          child: gBuildSlicedPlayerAvatarV(
            player: player,
            avatarHeight: avatarHeight,
            avatarHeightOuterSize: avatarHeightOuterSize,
            avatarSlicedWidth: avatarSlicedWidth,
            avatarSlicedWidthOuterSize: avatarSlicedWidthOuterSize,
            slotBgColor: slotColor.bgColor,
            playerPosition: originalIndex,
            responsiveTile: _responsiveTile,
          ),
        ),
      );

      // Wrap with DragTarget to accept dropped players and swap positions
      return DragTarget<PlayerDragData>(
        onWillAcceptWithDetails: (details) => details.data.originalIndex != originalIndex,
        onAcceptWithDetails: (details) {
          final draggedIndex = details.data.originalIndex;
          setState(() {
            // Swap the two players in the global _selectedPlayers list
            final temp = _selectedPlayers[draggedIndex];
            _selectedPlayers[draggedIndex] = _selectedPlayers[originalIndex];
            _selectedPlayers[originalIndex] = temp;
          });
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          // Wrap the card with a dynamic highlight/glow effect when hovered
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(avatarSlicedWidthOuterSize * 0.15),
              boxShadow: isHovering
                  ? [
                      BoxShadow(
                        color: Colors.yellowAccent.withAlpha(220),
                        blurRadius: avatarSlicedWidthOuterSize * 0.15,
                        spreadRadius: avatarSlicedWidthOuterSize * 0.05,
                      )
                    ]
                  : [],
            ),
            child: Draggable<PlayerDragData>(
              data: PlayerDragData(originalIndex),
              feedback: Material(
                color: Colors.transparent,
                child: Opacity(
                  opacity: 0.85,
                  child: cardWidget,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: cardWidget,
              ),
              child: cardWidget,
            ),
          );
        },
      );
    });
  }

  List<Widget> _buildTeamsSlotsV({
    required List<({TblTeam team, int originalIndex, GlobalTeamsGridConfig slotConfig})> targetTeams,
    required double cardHeight,
    required double cardWidth,
    required double cardWidthOuterSize,
    required double cardSlicedHeight,
    required double cardSlicedHeightOuterSize,
    required void Function(int originalIndex) onTap,
  }) {
    return List.generate(targetTeams.length, (index) {
      final item = targetTeams[index];
      final team = item.team;
      final originalIndex = item.originalIndex;
      final slotColor = item.slotConfig;
      
      // The core visual card content
      final cardWidget = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onTap(originalIndex), // <--- Trigger the removal using originalIndex
          child: gBuildSlicedTeamCardH(
            team: team,
            cardHeight: cardHeight,
            cardWidth: cardWidth,
            cardWidthOuterSize: cardWidthOuterSize,
            cardSlicedHeight: cardSlicedHeight,
            cardSlicedHeightOuterSize: cardSlicedHeightOuterSize,
            slotBgColor: slotColor.bgColor,
            teamPosition: originalIndex,
            responsiveTile: _responsiveTile,
          ),
        ),
      );

      // Wrap with DragTarget to accept dropped players and swap positions
      return DragTarget<PlayerDragData>(
        onWillAcceptWithDetails: (details) => details.data.originalIndex != originalIndex,
        onAcceptWithDetails: (details) {
          final draggedIndex = details.data.originalIndex;
          setState(() {
            // Swap the two players in the global _selectedPlayers list
            final temp = _selectedTeams[draggedIndex];
            _selectedTeams[draggedIndex] = _selectedTeams[originalIndex];
            _selectedTeams[originalIndex] = temp;
          });
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          // Wrap the card with a dynamic highlight/glow effect when hovered
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardSlicedHeightOuterSize * 0.15),
              boxShadow: isHovering
                  ? [
                      BoxShadow(
                        color: Colors.yellowAccent.withAlpha(220),
                        blurRadius: cardSlicedHeightOuterSize * 0.15,
                        spreadRadius: cardSlicedHeightOuterSize * 0.05,
                      )
                    ]
                  : [],
            ),
            child: Draggable<PlayerDragData>(
              data: PlayerDragData(originalIndex),
              feedback: Material(
                color: Colors.transparent,
                child: Opacity(
                  opacity: 0.85,
                  child: cardWidget,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: cardWidget,
              ),
              child: cardWidget,
            ),
          );
        },
      );
    });
  }

  Widget _buildTogglePlayersTeams() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Right Arrow on left side
        GifView.asset(
          'assets/png/mechanics/arrow_right.png',
          height: _responsiveTile * 0.08,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),

        SizedBox(width: _responsiveTile * 0.006),
        
        // 2. PLAYERS Left Toggle Button
        MouseRegion(
          key: const ValueKey('players_toggle_btn'),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (!_isPlayersSelection) {
                setState(() {
                  _isPlayersSelection = true;
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                //color: _isPlayersSelection ? GlobalSettingType.players.tileColor : Colors.grey.shade800,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(_responsiveTile * 0.03),
                  right: Radius.zero,
                ),
                border: Border.all(
                  color: _isPlayersSelection ? Colors.amber : Colors.white, 
                  width: _responsiveTile * 0.003,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // First child: Background fading effect
                  if (_isPlayersSelection)
                    Positioned.fill(
                      child: Center(
                        child: SizedBox(
                          width: _responsiveTile * 0.26,
                          height: _responsiveTile * 0.06,
                          child: FadingEllipseAnimation(colorEllipse: Colors.amber),
                        ),
                      ),
                    ),
                  
                  // Second child: Container with padding and text
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _responsiveTile * 0.03, 
                      vertical: _responsiveTile * 0.015,
                    ),
                    child: Text(
                      'PLAYERS',
                      style: gBuildArcadeTextStyle(
                        _responsiveFontSize * 0.85, 
                        gTextColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // 3. TEAMS Right Toggle Button
        MouseRegion(
          key: const ValueKey('teams_toggle_btn'),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (_isPlayersSelection) {
                setState(() {
                  _isPlayersSelection = false;
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.zero,
                  right: Radius.circular(_responsiveTile * 0.03),
                ),
                border: Border.all(
                  color: !_isPlayersSelection ? Colors.amber : Colors.white,
                  width: _responsiveTile * 0.003,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // First child: Background fading effect
                  if (!_isPlayersSelection)
                    Positioned.fill(
                      child: Center(
                        child: SizedBox(
                          width: _responsiveTile * 0.197,
                          height: _responsiveTile * 0.06,
                          child: FadingEllipseAnimation(colorEllipse: Colors.amber),
                        ),
                      ),
                    ),
                  
                  // Second child: Container with padding and text
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _responsiveTile * 0.03, 
                      vertical: _responsiveTile * 0.015,
                    ),
                    child: Text(
                      'TEAMS',
                      style: gBuildArcadeTextStyle(
                        _responsiveFontSize * 0.85, 
                        gTextColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              /* child: Text(
                'TEAMS',
                style: gBuildArcadeTextStyle(
                  _responsiveFontSize * 0.85, 
                  gTextColor: _isPlayersSelection ? Colors.white : Colors.amber,
                ),
              ), */
            ),
          ),
        ),
        
        SizedBox(width: _responsiveTile * 0.015),
      ],
    );
  }
}

class FadingEllipseAnimation extends StatefulWidget {
  final Color colorEllipse;

  const FadingEllipseAnimation({
    super.key,
    required this.colorEllipse,
  });

  @override
  State<FadingEllipseAnimation> createState() => _FadingEllipseAnimationState();
}

class _FadingEllipseAnimationState extends State<FadingEllipseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _opacityAnimation = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          color: widget.colorEllipse,
          borderRadius: BorderRadius.all(
            Radius.elliptical(75, 50),
          ),
        ),
      ),
    );
  }
}

class PlayerDragData {
  final int originalIndex;
  PlayerDragData(this.originalIndex);
}