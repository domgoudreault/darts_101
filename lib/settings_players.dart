// Flutter basics
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_assets.dart';
import 'package:darts_101/helpers_database.dart';

// UI Screens
import 'package:darts_101/modify_add_player.dart';

class SettingsPlayers extends StatefulWidget {
  // Define variables to hold the data passed from the previous screen
  final String tileType;
  final Color tileColor;
  final Color tileBackgroundColor;
  final String tileDescription;

  const SettingsPlayers({
    super.key,
    required this.tileType,
    required this.tileColor,
    required this.tileBackgroundColor,
    required this.tileDescription,
  });

  @override
  State<SettingsPlayers> createState() => _SettingsPlayersState();
}

class _SettingsPlayersState extends State<SettingsPlayers> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final CarouselController _carouselController = CarouselController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    // Check database status right after the screen renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptPlayerSeeding();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  // Fonctions de navigation when a button is pressed
  void _addPlayer(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // The add_player.dart page will be created and shown
        builder: (context) => ModifyAddPlayerForm(
          enuFormMode: FormMode.formAdd,
          tileColor: widget.tileColor,
          tileBackgroundColor: widget.tileBackgroundColor,
        ),
      ),
    );

    if (result == true && mounted) {
      if (_searchQuery.isNotEmpty) {
        _searchController.clear();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activePlayers = Hive.box<TblPlayer>('playersBox').values.where((player) => !player.fldIsDeleted).toList();
        
        if (activePlayers.isNotEmpty && _carouselController.hasClients) {
          _carouselController.animateTo(
            activePlayers.length * gGetCarouselPlayerCardFrameImage().renderWidth,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _onPlayerTapped(BuildContext context, TblPlayer player) {    
    Navigator.push(
      context,
      MaterialPageRoute(
        // The add_player.dart page will be created and shown
        builder: (context) => ModifyAddPlayerForm(
          enuFormMode: FormMode.formModify,
          modifyPlayer: player,
          tileColor: widget.tileColor,
          tileBackgroundColor: widget.tileBackgroundColor,
        ),
      ),
    );
  }

  void _checkAndPromptPlayerSeeding() {
    final playersBox = Hive.box<TblPlayer>('playersBox').values.where((player) => !player.fldIsDeleted);

    if (playersBox.isEmpty) {
      if (kDebugMode) {
        _showLeaguePlayersSeedDialog();
      } else {
        _showPlayersSeedDialog();
      }
    }
  }

  // 1. LEAGUE SEED DIALOG (kDebugMode only)
  void _showLeaguePlayersSeedDialog() {
    gShowDatabaseSeedDialog(
      context, 
      tileColor: widget.tileColor,
      tileBackgroundColor: widget.tileBackgroundColor,
      assetFullPath: 'assets/png/logos/LGGDS_360x360.png',
      headerText: 'SAMPLE LGGDS LEAGUE DATA ?',
      titleText: 'No players found.',
      questionText: 'Would you like to seed default LEAGUE players and teams for testing?',
      noButtonText: 'NO,\nI\'LL ADD BY HAND',
      yesButtonText: 'YES,\nGENERATE LEAGUE FOR ME',
      onNoPressed: (dialogContext) {
        Navigator.pop(dialogContext);
        _showPlayersSeedDialog();
      },
      onYesPressed: (dialogContext) async {
        Navigator.pop(dialogContext);
        // Only seeds players from my league if we are in Debug Mode AND the database is empty
        final playersBox = Hive.box<TblPlayer>('playersBox');
        final teamsBox = Hive.box<TblTeam>('teamsBox');

        await gSeedHiveLeaguePlayers(playersBox);
        await gSeedHiveTeams(playersBox, teamsBox);
        
        setState(() {});
      },
    );     
  }

  // 2. GENERIC AUTO-GENERATED SEED DIALOG (Release Mode OR Declined League Data)
  void _showPlayersSeedDialog() {
    gShowDatabaseSeedDialog(
      context, 
      tileColor: widget.tileColor,
      tileBackgroundColor: widget.tileBackgroundColor,
      assetFullPath: 'assets/png/tiles/settings_players_256x256.png',
      headerText: 'SAMPLE DEFAULT PLAYERS ?',
      titleText: 'No players found.',
      questionText: 'Would you like us to auto-generate sample default players for you?',
      noButtonText: 'NO,\nI\'LL ADD BY HAND',
      yesButtonText: 'YES,\nGENERATE FOR ME',
      onNoPressed: (dialogContext) {
        Navigator.pop(dialogContext); // Uses the dialogContext passed from the helper
      },
      onYesPressed: (dialogContext) async {
        Navigator.pop(dialogContext); // Uses the dialogContext passed from the helper
        final playersBox = Hive.box<TblPlayer>('playersBox');
        await gSeedHiveGenericPlayers(playersBox);
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    // 1. Access the Hive box opened during initialization
    final playersBox = Hive.box<TblPlayer>('playersBox');
    final ImageConfigPlayerCardFrame playerCardFrameImageConfig = gGetCarouselPlayerCardFrameImage();

    return Scaffold(
      //pour le background color en bas du titre et pour le reste de la page
      backgroundColor: widget.tileBackgroundColor,
      appBar: AppBar(        
        foregroundColor: Colors.white,
        backgroundColor: widget.tileColor,
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
                  widget.tileDescription,
                  style: gBuildArcadeTextStyle(20),
                ),
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP SEGMENTED TOGGLE BAR (Reserved for sub-filters if needed)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: playerCardFrameImageConfig.renderHeight * 0.06,
                vertical: playerCardFrameImageConfig.renderHeight * 0.02,
              ),
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  // 1.1 Add Player Banner
                  gBuildArcadeActionBanner(
                    gLeadingText: 'ADD NEW',
                    gTrailingText: 'PLAYER',
                    gFormMode: FormMode.formAdd,
                    gOnTap: () => _addPlayer(context),
                  ),

                  SizedBox(height: playerCardFrameImageConfig.renderHeight * 0.015),

                  // 1.2 Seach Bar
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: playerCardFrameImageConfig.renderHeight * 0.12,
                          child: FocusScope(
                            node: FocusScopeNode(),
                            child: TextField(
                              controller: _searchController,
                              style: gBuildArcadeTextStyle(playerCardFrameImageConfig.renderHeight * 0.035),
                              decoration: InputDecoration(
                                hintText: 'Search player name or nickname...',
                                hintStyle: gBuildArcadeTextStyle(playerCardFrameImageConfig.renderHeight * 0.035, gTextColor: Colors.grey.shade400),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.amber,
                                  size: playerCardFrameImageConfig.renderHeight * 0.09,
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
                                          size: playerCardFrameImageConfig.renderHeight * 0.065,
                                        ),
                                        onPressed: () => _searchController.clear(),
                                      ),

                                    // Gap between clear button and counter pill
                                    SizedBox(width: playerCardFrameImageConfig.renderHeight * 0.015),

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
                                            right: playerCardFrameImageConfig.renderHeight * 0.015,
                                            top: playerCardFrameImageConfig.renderHeight * 0.015,
                                            bottom: playerCardFrameImageConfig.renderHeight * 0.015,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: playerCardFrameImageConfig.renderHeight * 0.025,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade900,
                                            borderRadius: BorderRadius.circular(playerCardFrameImageConfig.renderHeight * 0.02),
                                            border: Border.all(
                                              color: Colors.amber,
                                              width: (playerCardFrameImageConfig.renderHeight * 0.005).clamp(1.0, 2.0),
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
                                                  playerCardFrameImageConfig.renderHeight * 0.035,
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
                                  horizontal: playerCardFrameImageConfig.renderHeight * 0.045,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade800,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(playerCardFrameImageConfig.renderHeight * 0.03),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(playerCardFrameImageConfig.renderHeight * 0.03),
                                  borderSide: BorderSide(
                                    color: Colors.amber,
                                    width: (playerCardFrameImageConfig.renderHeight * 0.008).clamp(1.5, 4.0),
                                  ),
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
            ),            

            // 2. LIVE PLAYER CAROUSEL DISPLAY AREA
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: AppDisplay.carouselTileSize,
                  child: ValueListenableBuilder<Box<TblPlayer>>(
                    valueListenable: playersBox.listenable(),
                    builder: (context, box, _) {
                      final activePlayers = box.values.where((player) => !player.fldIsDeleted).toList();

                      // Filter by First Name, Last Name, or Nickname
                      final players = _searchQuery.isEmpty
                          ? activePlayers
                          : activePlayers.where((player) {
                              final firstName = player.fldFirstName.toLowerCase();
                              final lastName = player.fldLastName.toLowerCase();
                              final nickName = player.fldNickName.toLowerCase();

                              return firstName.contains(_searchQuery) ||
                                  lastName.contains(_searchQuery) ||
                                  nickName.contains(_searchQuery);
                            }).toList();

                      if (players.isEmpty) {
                        return Center(
                          child: Text(
                            'No players found.',
                            style: gBuildArcadeTextStyle(playerCardFrameImageConfig.renderHeight * 0.035),
                          ),
                        );
                      }

                      return CarouselView(
                        controller: _carouselController,
                        itemExtent: playerCardFrameImageConfig.renderWidth,
                        shrinkExtent: 80,
                        backgroundColor: Colors.transparent,
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        onTap: (int index) {
                          final player = players[index];
                          _onPlayerTapped(context, player);
                        },
                        children: players
                            .map((player) => _buildPlayerCard(context, player))
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(
    BuildContext context,
    TblPlayer player,
  ) {
    final ImageConfigPlayerCardFrame playerCardFrameImageConfig = gGetCarouselPlayerCardFrameImage();

    return Center(
      child: AspectRatio(
        aspectRatio: playerCardFrameImageConfig.renderWidth / playerCardFrameImageConfig.renderHeight,
        child: FittedBox(
          fit: BoxFit.contain, // Forces height and width to scale down together proportionally
          child: SizedBox(
            width: playerCardFrameImageConfig.renderWidth,
            height: playerCardFrameImageConfig.renderHeight,
            child: Stack(
              children: [
                // 1. PNG Frame Background
                Positioned.fill(
                  child: Image.asset(
                    playerCardFrameImageConfig.assetPathBackground,
                    fit: BoxFit.fill,
                  ),
                ),

                // 2. Avatar Layer
                Positioned.fill(
                  child: Image.asset(
                    gGetCarouselPlayerCardImage(player.fldAvatarCode).assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle,
                      size: 64,
                      color: Colors.white38,
                    ),
                  ),
                ),

                // 3. PNG Frame Overlay
                Positioned.fill(
                  child: Image.asset(
                    playerCardFrameImageConfig.assetPathFrame,
                    fit: BoxFit.fill,
                  ),
                ),
                
                // 4. Player Data Text Overlay Layer (On top of white card area)
                Positioned(
                  top: playerCardFrameImageConfig.renderHeight * 0.52,
                  left: playerCardFrameImageConfig.renderHeight * 0.08,
                  right: playerCardFrameImageConfig.renderHeight * 0.08,
                  bottom: playerCardFrameImageConfig.renderHeight * 0.06,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Gap 1: Picture bottom -> First Name
                      SizedBox(height: playerCardFrameImageConfig.renderHeight * 0.015),
                      
                      // First Name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          player.fldFirstName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: playerCardFrameImageConfig.renderHeight * 0.035,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Gap 2: First Name -> Last Name
                      SizedBox(height: playerCardFrameImageConfig.renderHeight * 0.010),

                      // Last Name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          player.fldLastName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: playerCardFrameImageConfig.renderHeight * 0.048,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Gap 3: Last Name -> Divider
                      SizedBox(height: playerCardFrameImageConfig.renderHeight * 0.024),

                      // Divider Accent
                      Container(
                        height: (playerCardFrameImageConfig.renderHeight * 0.009),
                        width: playerCardFrameImageConfig.renderHeight * 0.50,
                        color: widget.tileColor,
                      ),
                      
                      // Gap 4: Divider -> Nickname
                      SizedBox(height: playerCardFrameImageConfig.renderHeight * 0.022),

                      // Elliptic Arcade Badge around Nickname
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: playerCardFrameImageConfig.renderHeight * 0.035,
                          vertical: playerCardFrameImageConfig.renderHeight * 0.006,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.shade100,
                          borderRadius: BorderRadius.circular(
                            playerCardFrameImageConfig.renderHeight * 0.04,
                          ),
                          border: Border.all(
                            color: Colors.purpleAccent.shade700,
                            width: playerCardFrameImageConfig.renderHeight * 0.006,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            player.fldNickName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: gBuildArcadeTextStyle(playerCardFrameImageConfig.renderHeight * 0.032, gFontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. PNG if Player Is League Member Patch
                if (player.fldIsLeagueMember) 
                  Positioned.fill(
                    child: Image.asset(
                      playerCardFrameImageConfig.assetPathIsLeagueMember,
                      fit: BoxFit.fill,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}