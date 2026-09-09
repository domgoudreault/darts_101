// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:gif_view/gif_view.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
//import 'package:darts_101/database/tbl_game.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_assets.dart';

// UI Screens
//import 'package:darts_101/game_halfit.dart';
//import 'package:darts_101/game_build_up.dart';

enum GameType{
  gameHalfIt,
  gameBuildUp
}

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
  final List<TblPlayer> _selectedPlayers = [];

  double get _responsiveTile => GlobalAppDisplay.carouselTileSize;
  double get _responsiveFontSize => (_responsiveTile * 0.035).clamp(10.0, 60.0);

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

  /* Future<void> _resumeGame(BuildContext context, TblGame game) async {
    final bool isTeamGameMode = (game.gameMode == 2);

    if (game.gameType == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameHalfItScreen(
            game: game,
            gameText: isTeamGameMode ? 'Teams Half-It Game' : 'Players Half-It Game',
            tileBackgroundColor: widget.enuGameType.tileBackgroundColor,
            resumeMode: true,
          ),
        ),
      );
    } else if (game.gameType == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameBuildUpScreen(
            game: game,
            gameText: 'Players Team Build Up Game',
            tileBackgroundColor: widget.enuGameType.tileBackgroundColor,
            resumeMode: true,
          ),
        ),
      );
    }
    setState(() {});
  } */

  @override
  Widget build(BuildContext context) {    
    MediaQuery.sizeOf(context);
    
    // Fetch the asset config for the current game type
    final gameCenterTileImageConfigRS = gGetCenterTileImageConfigRS(widget.enuGameType.tileType, widget.enuGameType.tileCode);
    final ImageConfigAvatar avatarPlayerFrameImageConfigRS = gGetAvatarPlayerFrameImageConfigRS();
    final teamCardFrameImageConfig = gGetCarouselTeamCardHFrameImageRS();
    final ImageConfigAvatar avatarPlayerFrameImageConfigGB = gGetAvatarPlayerFrameImageConfigGB();

    final toolbarHeight = (GlobalAppDisplay.safeHeight * 0.10).clamp(56.0, 142.0);
  
    
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
                  'assets/png/tiles/${widget.enuGameType.tileType}_${widget.enuGameType.tileCode}_1024x1024.png',
                  //gameTileImageConfig.assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Column(
              children: [
                // 1.2 Seach Bar
                Center(
                  child: SizedBox(
                    width: GlobalAppDisplay.safeWidth * 0.85,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: _responsiveTile * 0.02),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: GlobalAppDisplay.carouselTileSize * 0.12,
                              child: FocusScope(
                                node: FocusScopeNode(),
                                child: TextField(
                                  controller: _searchController,
                                  style: gBuildArcadeTextStyle(GlobalAppDisplay.carouselTileSize * 0.035),
                                  decoration: InputDecoration(
                                    hintText: 'Search player name or nickname...',
                                    hintStyle: gBuildArcadeTextStyle(GlobalAppDisplay.carouselTileSize * 0.035, gTextColor: Colors.grey.shade400),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.amber,
                                      size: GlobalAppDisplay.carouselTileSize * 0.09,
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
                                              size: GlobalAppDisplay.carouselTileSize * 0.065,
                                            ),
                                            onPressed: () => _searchController.clear(),
                                          ),

                                        // Gap between clear button and counter pill
                                        SizedBox(width: GlobalAppDisplay.carouselTileSize * 0.015),

                                        // 2. Embedded Arcade Counter Pill
                                        ValueListenableBuilder<Box<TblPlayer>>(
                                          valueListenable: playersBox.listenable(),
                                          builder: (context, box, _) {
                                            final activePlayers = box.values.where((player) => !player.fldIsDeleted).toList();
                                            final filteredCount = _searchQuery.isEmpty
                                                ? activePlayers.length
                                                : activePlayers.where((player) {
                                                    final query = _searchQuery.toLowerCase();
                                                    return player.fldFirstName.toLowerCase().contains(query) ||
                                                        player.fldLastName.toLowerCase().contains(query) ||
                                                        player.fldNickName.toLowerCase().contains(query);
                                                  }).length;

                                            return Container(
                                              margin: EdgeInsets.only(
                                                right: GlobalAppDisplay.carouselTileSize * 0.015,
                                                top: GlobalAppDisplay.carouselTileSize * 0.015,
                                                bottom: GlobalAppDisplay.carouselTileSize * 0.015,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: GlobalAppDisplay.carouselTileSize * 0.025,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade900,
                                                borderRadius: BorderRadius.circular(GlobalAppDisplay.carouselTileSize * 0.02),
                                                border: Border.all(
                                                  color: Colors.amber,
                                                  width: (GlobalAppDisplay.carouselTileSize * 0.005).clamp(1.0, 2.0),
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
                                                      GlobalAppDisplay.carouselTileSize * 0.035,
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
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 0,
                                      horizontal: GlobalAppDisplay.carouselTileSize * 0.045,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade800,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(GlobalAppDisplay.carouselTileSize * 0.03),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(GlobalAppDisplay.carouselTileSize * 0.03),
                                      borderSide: BorderSide(
                                        color: Colors.amber,
                                        width: (GlobalAppDisplay.carouselTileSize * 0.008).clamp(1.5, 4.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 2. Middle Area: Game Tile & Live Roster Display Grid
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    padding: const EdgeInsets.all(2),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Right Arrow on left side
                            GifView.asset(
                              'assets/png/mechanics/arrow_right.png',
                              // TODO correct the height
                              height: 99,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                            SizedBox(width: _responsiveTile * 0.015),

                            // 2. Center Game Tile
                            SizedBox(
                              width: gameCenterTileImageConfigRS.renderSize * gameCenterTileImageConfigRS.scaleFactor,
                              height: gameCenterTileImageConfigRS.renderSize * gameCenterTileImageConfigRS.scaleFactor,
                              child: Stack(
                                children: [
                                  // 1.1 Color fill tucked inside fixed canvas dimensions
                                  Positioned.fill(
                                    child: Padding(
                                      padding: EdgeInsets.all(gameCenterTileImageConfigRS.renderSize * 0.03),
                                      child: Container(color: widget.enuGameType.tileColor),
                                    ),
                                  ),
                                  // 1.2. PNG frame overlaid on top
                                  Positioned.fill(
                                    child: Image.asset(
                                      gameCenterTileImageConfigRS.assetPath,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3. Left Arrow on right side
                            SizedBox(width: _responsiveTile * 0.015),
                            GifView.asset(
                              'assets/png/mechanics/arrow_left.png',
                              // TODO correct the height
                              height: 99,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ]
                        ),

                        // 2. Surrounding Arcade Roster Slots (Positioned dynamically based on index)
                        ..._buildPlayersSlots(avatarPlayerFrameImageConfigGB),




                    
                      ],
                    ),
                  ),
                ),

                // 3. Persistent Bottom Panel (Aligned horizontally with the box above, zero safe-area interference)
                Container(
                  width: GlobalAppDisplay.safeWidth * 0.85,
                  height: _isPlayersSelection 
                    ? avatarPlayerFrameImageConfigRS.renderSize + 64.0 
                    : teamCardFrameImageConfig.renderHeight + 64.0,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  decoration: BoxDecoration(
                    color: _isPlayersSelection ? GlobalSettingType.players.tileColor : GlobalSettingType.teams.tileColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20.0),
                      bottom: Radius.zero,
                    ),
                    border: Border.all(
                      color: Colors.amber, // Or Colors.white depending on the contrast you want
                      width: avatarPlayerFrameImageConfigRS.renderSize * 0.015,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(150),
                        blurRadius: avatarPlayerFrameImageConfigRS.renderSize * 0.08,
                        offset: const Offset(0, -4), // Casts shadow upward onto the screen content
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 3.0),
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          color: _isPlayersSelection ? GlobalSettingType.players.tilePickerColor : GlobalSettingType.teams.tilePickerColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18.0),
                            bottom: Radius.zero,
                          ),
                          border: Border.all(
                            color: Colors.white, // Or widget.tileColor / whatever border color you want
                            width: 1.5,
                          ),
                        ),
                        
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Centered Title Text
                            Text(
                              _isPlayersSelection ? 'SELECT PLAYERS' : 'SELECT TEAMS',
                              style: gBuildArcadeTextStyle((_responsiveFontSize * 0.70).clamp(10.0, 60.0)),
                            ),
                            // Toggle Buttons anchored to the right side
                            Align(
                              alignment: Alignment.centerRight,
                              child: _buildTogglePlayersTeams(avatarPlayerFrameImageConfigRS.renderSize),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

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
                                    : activePlayers.where((player) {
                                        final query = _searchQuery.toLowerCase();
                                        return player.fldFirstName.toLowerCase().contains(query) ||
                                            player.fldLastName.toLowerCase().contains(query) ||
                                            player.fldNickName.toLowerCase().contains(query);
                                      }).toList();

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
                                  itemExtent: avatarPlayerFrameImageConfigRS.renderSize + 4.0,
                                  shrinkExtent: avatarPlayerFrameImageConfigRS.renderSize * 0.8,
                                  onTap: (int index) {
                                    setState(() {
                                      _selectedPlayers.add(playerList[index]);
                                    });
                                  },
                                  children: playerList.map((player) {
                                    return gBuildPlayerAvatarCard(
                                      avatarFrameImageConfig: avatarPlayerFrameImageConfigRS,
                                      avatarPlayerImageConfig: gGetAvatarPlayerImageConfigRS(player.fldAvatarCode),
                                      bgColor: GlobalSettingType.players.tileBackgroundColor,
                                      player: player, );
                                  }).toList(),
                                );
                              },
                            )
                          : ValueListenableBuilder<Box<TblTeam>>(
                              valueListenable: teamsBox.listenable(),
                              builder: (context, box, _) {
                                final teamList = box.values.where((team) => !team.fldIsDeleted).toList();                                
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
                                  itemExtent: teamCardFrameImageConfig.renderWidth + 6.0,
                                  shrinkExtent: avatarPlayerFrameImageConfigRS.renderSize * 0.8,
                                  onTap: (int index) {
                                    //final selectedTeam = teamList[index];
                                    
                                  },
                                  children: teamList.map((team) {
                                    return Center(
                                      child: AspectRatio(
                                        aspectRatio: teamCardFrameImageConfig.renderWidth / teamCardFrameImageConfig.renderHeight,
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: gBuildTeamCardMainUI(
                                            teamCardFrameImageConfig: teamCardFrameImageConfig,
                                            avatarPlayer1ImageConfig: gGetAvatarTeamCardImageConfigRS(team.fldPlayers[0].fldAvatarCode),
                                            avatarPlayer2ImageConfig: gGetAvatarTeamCardImageConfigRS(team.fldPlayers[1].fldAvatarCode),
                                            colorBgAvatar: GlobalSettingType.teams.tileBackgroundColor,
                                            isDummyTeam: team.fldPlayers[0].fldAvatarCode == team.fldPlayers[1].fldAvatarCode,
                                            selectedPlayer1: team.fldPlayers[0],
                                            selectedPlayer2: team.fldPlayers[1],
                                          ),
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

  List<Widget> _buildPlayersSlots(ImageConfigAvatar frameConfig) {
    // Define relative coordinate offsets (percentages or alignment factors)
    final slotAlignments = GlobalPlayersGridConfig.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    List<Widget> widgets = [];
    
    // Give the outer slot a tiny bit of extra room for the amber border padding
    final double outerSize = frameConfig.renderSize * 1.04;

    for (int i = 0; i < _selectedPlayers.length && i < slotAlignments.length; i++) {
      final player = _selectedPlayers[i];
      final slotAlignment = slotAlignments[i];

      widgets.add(
        Align(
          alignment: slotAlignment.alignment,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPlayers.removeAt(i);
              });
            },
            child: SizedBox(
              width: outerSize,
              height: outerSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Layer 1: Background rectangle color / box frame placeholder
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: slotAlignment.bgColor, // Or your preferred background fill color
                        borderRadius: BorderRadius.circular(outerSize * 0.22),
                        border: Border.all(
                          color: Colors.amber,
                          width: outerSize * 0.02,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: outerSize * 0.04,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Layer 2: The exact-size Player Avatar Card sitting cleanly on top
                  SizedBox(
                    width: frameConfig.renderSize,
                    height: frameConfig.renderSize,
                    child: gBuildPlayerAvatarCard(
                      avatarFrameImageConfig: frameConfig,
                      avatarPlayerImageConfig: gGetAvatarPlayerImageConfigGB(player.fldAvatarCode),
                      bgColor: slotAlignment.bgColor,
                      player: player,
                    ),
                  ),

                  // Layer 3: The Player Slot indicator
                  /* Positioned.fill(
                    child: Image.asset(
                      gameCenterTileImageConfigRS.assetPath,
                      fit: BoxFit.fill,
                    ),
                  ), */
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildTogglePlayersTeams(double renderSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: _isPlayersSelection ? GlobalSettingType.players.tileColor : Colors.grey.shade800,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16.0),
                  right: Radius.zero,
                ),
                border: Border.all(
                  color: _isPlayersSelection ? Colors.amber : Colors.white, 
                  width: renderSize * 0.015,
                ),
              ),
              child: Text(
                'PLAYERS',
                style: gBuildArcadeTextStyle(
                  _responsiveFontSize * 0.85, 
                  gTextColor: _isPlayersSelection ? Colors.amber : Colors.white,
                ),
              ),
            ),
          ),
        ),
        MouseRegion(
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: _isPlayersSelection ? Colors.grey.shade800 : GlobalSettingType.teams.tileColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.zero,
                  right: Radius.circular(16.0),
                ),
                border: Border.all(
                  color: _isPlayersSelection ? Colors.white : Colors.amber, 
                  width: renderSize * 0.015,
                ),
              ),
              child: Text(
                'TEAMS',
                style: gBuildArcadeTextStyle(
                  _responsiveFontSize * 0.85, 
                  gTextColor: _isPlayersSelection ? Colors.white : Colors.amber,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}