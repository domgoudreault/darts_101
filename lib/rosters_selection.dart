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
    playersBox = Hive.box<TblPlayer>('playersBox');
    teamsBox = Hive.box<TblTeam>('teamsBox');
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

    final ImageConfigArrow leftArrowConfig = gGetArrowImageConfig(true);
    final ImageConfigArrow rightArrowConfig = gGetArrowImageConfig(false);
  
    
    return Scaffold(
      backgroundColor: widget.enuGameType.tileBackgroundColor,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: widget.enuGameType.tileColor,
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
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rosters Selection (${widget.enuGameType.tileDisplayName})',
                  style: gBuildArcadeTextStyle(20),
                ),
              ),
            ),
          ],
        ),
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Toggle Button
                      // PLAYERS BUTTON (Left side rounded, right side flat)
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
                                width: (avatarPlayerFrameImageConfigRS.renderSize * 0.025).clamp(1.5, 4.0),
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
                      
                      // TEAMS BUTTON (Left side flat, right side rounded - the mirror)
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
                                width: (avatarPlayerFrameImageConfigRS.renderSize * 0.025).clamp(1.5, 4.0),
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
                      
                      SizedBox(width: _responsiveTile * 0.015),
                      // Left Arrow on right side
                      GifView.asset(
                        leftArrowConfig.assetPath,
                        height: leftArrowConfig.renderSize,
                        fit: BoxFit.contain,
                      ),

                      const Spacer(),

                      // Right Arrow on left side
                      GifView.asset(
                        rightArrowConfig.assetPath,
                        height: rightArrowConfig.renderSize,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: _responsiveTile * 0.015),

                      ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          'START NEW GAME',
                          style: gBuildArcadeTextStyle(_responsiveFontSize),
                        ),
                      ),
                    ],
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
                        // 1. Center Game Tile
                        SizedBox(
                          width: gameCenterTileImageConfigRS.renderSize,
                          height: gameCenterTileImageConfigRS.renderSize,
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

                        // 2. Surrounding Arcade Roster Slots (Positioned dynamically based on index)
                        ..._buildArcadeRosterSlots(avatarPlayerFrameImageConfigRS),




                    
                      ],
                    ),
                  ),
                ),

                // 3. Persistent Bottom Panel (Aligned horizontally with the box above, zero safe-area interference)
                Container(
                  width: GlobalAppDisplay.safeWidth * 0.84,
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 3.0),
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                        child: Text(
                          _isPlayersSelection ? 'SELECT PLAYERS' : 'SELECT TEAMS',
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle((_responsiveFontSize * 0.70).clamp(10.0, 60.0)),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Expanded(
                        child: _isPlayersSelection
                          ? ValueListenableBuilder<Box<TblPlayer>>(
                              valueListenable: playersBox.listenable(),
                              builder: (context, box, _) {
                                // Filter out players that are already selected in the roster
                                final playerList = box.values
                                    .where((player) => !player.fldIsDeleted && !_selectedPlayers.contains(player))
                                    .toList();

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
                                      enuSettingType: GlobalSettingType.players,
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

  List<Widget> _buildArcadeRosterSlots(ImageConfigAvatar frameConfig) {
    // Define relative coordinate offsets (percentages or alignment factors) 
    // corresponding to your arcade slots 1 through 12 layout blueprint.
    final List<Alignment> slotAlignments = [
      const Alignment(-0.35, -0.60), // Slot 1
      const Alignment( 0.35,  0.60), // Slot 2
      const Alignment(-0.35,  0.30), // Slot 3
      const Alignment( 0.35, -0.30), // Slot 4
      const Alignment( 0.00,  0.75), // Slot 5
      const Alignment( 0.00, -0.75), // Slot 6
      const Alignment(-0.70, -0.75), // Slot 7
      const Alignment( 0.70,  0.75), // Slot 8
      const Alignment(-0.70,  0.00), // Slot 9
      const Alignment( 0.70,  0.00), // Slot 10
      const Alignment(-0.70,  0.75), // Slot 11
      const Alignment( 0.70, -0.75), // Slot 12
    ];

    List<Widget> widgets = [];
    double slotSize = frameConfig.renderSize; // Scale down slightly to fit nicely around the center tile

    for (int i = 0; i < _selectedPlayers.length && i < slotAlignments.length; i++) {
      final player = _selectedPlayers[i];
      final alignment = slotAlignments[i];

      widgets.add(
        Align(
          alignment: alignment,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPlayers.removeAt(i);
              });
            },
            child: SizedBox(
              width: slotSize,
              height: slotSize,
              child: gBuildPlayerAvatarCard(
                avatarFrameImageConfig: frameConfig,
                avatarPlayerImageConfig: gGetAvatarPlayerImageConfigRS(player.fldAvatarCode),
                enuSettingType: GlobalSettingType.players,
                player: player,
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}