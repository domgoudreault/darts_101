// Flutter basics
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
import 'package:darts_101/modify_add_team.dart';

class SettingsTeams extends StatefulWidget {
  // Define variables to hold the data passed from the previous screen
  final String tileType;
  final Color tileColor;
  final Color tileBackgroundColor;
  final String tileDescription;

  const SettingsTeams({
    super.key,
    required this.tileType,
    required this.tileColor,
    required this.tileBackgroundColor,
    required this.tileDescription,
  });

  @override
  State<SettingsTeams> createState() => _SettingsTeamsState();
}

class _SettingsTeamsState extends State<SettingsTeams> {
  final TextEditingController _searchController = TextEditingController();
  final CarouselController _carouselController = CarouselController();
  
  String _searchQuery = '';
  bool _isDummyFilterActive = false;

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
      _checkAndPromptTeamSeeding();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  // Fonctions de navigation when a button is pressed
  void _addTeam(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // The modify_add_team.dart page will be created and shown
        builder: (context) => ModifyAddTeamForm(
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
        final activeTeams = Hive.box<TblTeam>('teamsBox').values.where((p) => !p.fldIsDeleted).toList();
        
        if (activeTeams.isNotEmpty && _carouselController.hasClients) {
          _carouselController.animateTo(
            activeTeams.length * gGetCarouselTeamCardVFrameImage().renderWidth,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _onTeamTapped(BuildContext context, TblTeam team) {    
    Navigator.push(
      context,
      MaterialPageRoute(
        // The modify_add_team.dart page will be created and shown
        builder: (context) => ModifyAddTeamForm(
          enuFormMode: FormMode.formModify,
          modifyTeam: team,
          tileColor: widget.tileColor,
          tileBackgroundColor: widget.tileBackgroundColor,
        ),
      ),
    );
  }

  void _checkAndPromptTeamSeeding() {
    final teamsBox = Hive.box<TblTeam>('teamsBox').values.where((team) => !team.fldIsDeleted);
    final playersBox = Hive.box<TblPlayer>('playersBox').values.where((player) => !player.fldIsDeleted);

    if (teamsBox.isEmpty && playersBox.isNotEmpty) {
      _showTeamsSeedDialog();
    }
  }

  // 1. GENERIC AUTO-GENERATED SEED DIALOG (Release Mode OR Declined League Data)
  void _showTeamsSeedDialog() {
    gShowDatabaseSeedDialog(
      context, 
      tileColor: widget.tileColor,
      tileBackgroundColor: widget.tileBackgroundColor,
      assetFullPath: 'assets/png/tiles/settings_teams_256x256.png',
      headerText: 'SAMPLE DEFAULT TEAMS ?',
      titleText: 'No teams found.',
      questionText: 'Would you like us to auto-generate sample default teams for you?',
      noButtonText: 'NO,\nI\'LL ADD BY HAND',
      yesButtonText: 'YES,\nGENERATE FOR ME',
      onNoPressed: (dialogContext) {
        Navigator.pop(dialogContext); // Uses the dialogContext passed from the helper
      },
      onYesPressed: (dialogContext) async {
        Navigator.pop(dialogContext);
        
        final playersBox = Hive.box<TblPlayer>('playersBox');
        final teamsBox = Hive.box<TblTeam>('teamsBox');
        
        // Assuming you have a generic team seeding function available, 
        // or you can call your team creation backend logic here:
        await gSeedHiveTeams(playersBox, teamsBox);
        
        setState(() {});
      },
    );
  }

  bool _matchesTeamQuery(TblTeam team, String query) {
    final p1 = team.fldPlayers[0];
    final p2 = team.fldPlayers[1];

    // 1. DUMMY FILTER CHECK
    if (_isDummyFilterActive) {
      // Check if team is a dummy team (both players share avatar code)
      final bool isDummyTeam = p1.fldAvatarCode == p2.fldAvatarCode;
      
      // If the toggle is ON and this isn't a dummy team, exclude it immediately
      if (!isDummyTeam) return false;
    }

    // 2. SEARCH BAR TEXT CHECK
    if (query.isEmpty) return true;

    // Split query into individual search terms and remove empty spaces
    final terms = query.split(' ').where((term) => term.isNotEmpty).toList();
    if (terms.isEmpty) return true;

    // Helper function to check if a single term matches a player
    bool matchesPlayer(dynamic player, String term) {
      return player.fldFirstName.toLowerCase().contains(term) ||
            player.fldLastName.toLowerCase().contains(term) ||
            player.fldNickName.toLowerCase().contains(term);
    }

    // EVERY term must match either Player 1 or Player 2
    return terms.every((term) => matchesPlayer(p1, term) || matchesPlayer(p2, term));
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    // 1. Access the Hive box opened during initialization
    final teamsBox = Hive.box<TblTeam>('teamsBox');
    final ImageConfigTeamCardFrame teamCardFrameImageConfig = gGetCarouselTeamCardVFrameImage();
    final ImageConfigDummy dummyImageConfig = gGetDummyImageConfig();

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
                horizontal: teamCardFrameImageConfig.renderHeight * 0.06,
                vertical: teamCardFrameImageConfig.renderHeight * 0.02,
              ),
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  // 1.1 Add Team Banner
                  Row(
                    children: [
                      Expanded(
                        child: gBuildArcadeActionBanner(
                          gLeadingText: 'ADD NEW',
                          gTrailingText: 'TEAM',
                          gFormMode: FormMode.formAdd,
                          gOnTap: () => _addTeam(context),
                        ),
                      ),
                      SizedBox(width: teamCardFrameImageConfig.renderHeight * 0.02),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDummyFilterActive = !_isDummyFilterActive;
                            });

                            if (_isDummyFilterActive) {
                              gShowArcadeErrorSnackBar(
                                gContext: context, 
                                gFontSize: (AppDisplay.carouselTileSize * 0.025).clamp(10.0, 60.0), 
                                gMessage: 'FILTER DUMMY TEAMS ACTIVATED', 
                                gDuration: 3,
                                gBbackgroundColor: Color.fromRGBO(247, 120, 9, 1.0)
                              );
                            }
                          },
                          child: SizedBox(
                            width: dummyImageConfig.renderSize,
                            height: dummyImageConfig.renderSize,
                            child: Stack(
                              children: [
                                // 1. Bottom Layer: Dynamic Solid Fill Background
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isDummyFilterActive
                                          ? Color.fromRGBO(247, 120, 9, 1.0)
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),

                                // 2. Middle Layer: Crisp PNG Icon Asset
                                Positioned.fill(
                                  child: Image.asset(
                                    dummyImageConfig.assetPath,
                                    width: dummyImageConfig.renderSize,
                                    height: dummyImageConfig.renderSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                // 3. Top Overlay Layer: Circular Border Ring
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _isDummyFilterActive
                                            ? Color.fromRGBO(247, 120, 9, 1.0)
                                            : Colors.amber,
                                        width: (dummyImageConfig.renderSize * 0.03),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: teamCardFrameImageConfig.renderHeight * 0.015),

                  // 1.2 Seach Bar
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: teamCardFrameImageConfig.renderHeight * 0.12,
                          child: FocusScope(
                            node: FocusScopeNode(),
                            child: TextField(
                              controller: _searchController,
                              style: gBuildArcadeTextStyle(teamCardFrameImageConfig.renderHeight * 0.035),
                              decoration: InputDecoration(
                                hintText: 'Search names or nicknames (space separated)...',
                                hintStyle: gBuildArcadeTextStyle(teamCardFrameImageConfig.renderHeight * 0.035, gTextColor: Colors.grey.shade400),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.amber,
                                  size: teamCardFrameImageConfig.renderHeight * 0.09,
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
                                          size: teamCardFrameImageConfig.renderHeight * 0.065,
                                        ),
                                        onPressed: () => _searchController.clear(),
                                      ),

                                    // Gap between clear button and counter pill
                                    SizedBox(width: teamCardFrameImageConfig.renderHeight * 0.015),

                                    // 2. Embedded Arcade Counter Pill
                                    ValueListenableBuilder<Box<TblTeam>>(
                                      valueListenable: teamsBox.listenable(),
                                      builder: (context, box, _) {
                                        final activeTeams = box.values.where((p) => !p.fldIsDeleted).toList();
                                        final filteredCount = activeTeams.where((team) => _matchesTeamQuery(team, _searchQuery)).length;

                                        return Container(
                                          margin: EdgeInsets.only(
                                            right: teamCardFrameImageConfig.renderHeight * 0.015,
                                            top: teamCardFrameImageConfig.renderHeight * 0.015,
                                            bottom: teamCardFrameImageConfig.renderHeight * 0.015,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: teamCardFrameImageConfig.renderHeight * 0.025,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade900,
                                            borderRadius: BorderRadius.circular(teamCardFrameImageConfig.renderHeight * 0.02),
                                            border: Border.all(
                                              color: Colors.amber,
                                              width: (teamCardFrameImageConfig.renderHeight * 0.005).clamp(1.0, 2.0),
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                (_searchQuery.isEmpty && !_isDummyFilterActive)
                                                  ? '$filteredCount' 
                                                  : '$filteredCount/${activeTeams.length}',
                                                style: gBuildArcadeTextStyle(
                                                  teamCardFrameImageConfig.renderHeight * 0.035,
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
                                  horizontal: teamCardFrameImageConfig.renderHeight * 0.045,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade800,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(teamCardFrameImageConfig.renderHeight * 0.03),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(teamCardFrameImageConfig.renderHeight * 0.03),
                                  borderSide: BorderSide(
                                    color: Colors.amber,
                                    width: (teamCardFrameImageConfig.renderHeight * 0.008).clamp(1.5, 4.0),
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

            // 2. LIVE TEAM CAROUSEL DISPLAY AREA
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: AppDisplay.carouselTileSize,
                  child: ValueListenableBuilder<Box<TblTeam>>(
                    valueListenable: teamsBox.listenable(),
                    builder: (context, box, _) {
                      final activeTeams = box.values.where((team) => !team.fldIsDeleted).toList();

                      // Filter by First Name, Last Name, or Nickname
                      final teams = activeTeams.where((team) => _matchesTeamQuery(team, _searchQuery)).toList();

                      if (teams.isEmpty) {
                        return Center(
                          child: Text(
                            'No teams found.',
                            style: gBuildArcadeTextStyle(18),
                          ),
                        );
                      }

                      return CarouselView(
                        controller: _carouselController,
                        itemExtent: teamCardFrameImageConfig.renderWidth,
                        shrinkExtent: 80,
                        backgroundColor: Colors.transparent,
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        onTap: (int index) {
                          final team = teams[index];
                          _onTeamTapped(context, team);
                        },
                        children: teams
                            .map((team) => _buildTeamCard(context, team))
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

  Widget _buildTeamCard(
    BuildContext context,
    TblTeam team,
  ) {
    final ImageConfigTeamCardFrame teamCardFrameImageConfig = gGetCarouselTeamCardVFrameImage();
    final ImageConfigAvatar avatarPlayer1ImageConfig = gGetAvatarPlayerCardImageConfig(team.fldPlayers[0].fldAvatarCode);
    final ImageConfigAvatar avatarPlayer2ImageConfig = gGetAvatarPlayerCardImageConfig(team.fldPlayers[1].fldAvatarCode);
    final bool isDummyTeam = team.fldPlayers[0].fldAvatarCode == team.fldPlayers[1].fldAvatarCode;

    return Center(
      child: AspectRatio(
        aspectRatio: teamCardFrameImageConfig.renderWidth / teamCardFrameImageConfig.renderHeight,
        child: FittedBox(
          fit: BoxFit.contain, // Forces height and width to scale down together proportionally
          child: SizedBox(
            width: teamCardFrameImageConfig.renderWidth,
            height: teamCardFrameImageConfig.renderHeight,
            child: Stack(
              children: [
                // 1. Top Dynamic Circle Background Layer
                Positioned(
                  top: teamCardFrameImageConfig.renderHeight * 0.03, // Positions inside top metallic ring
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: avatarPlayer1ImageConfig.renderSize,
                      height: avatarPlayer1ImageConfig.renderSize,
                      decoration: BoxDecoration(
                        color: widget.tileColor, // Or gender color for Player 1
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                // 2. Bottom Dynamic Circle Background Layer
                Positioned(
                  bottom: teamCardFrameImageConfig.renderHeight * 0.03, // Positions inside bottom metallic ring
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: avatarPlayer2ImageConfig.renderSize,
                      height: avatarPlayer2ImageConfig.renderSize,
                      decoration: BoxDecoration(
                        color: widget.tileColor, // Or gender color for Player 2
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                
                // 3. Top Player Avatar Layer
                Positioned(
                  top: teamCardFrameImageConfig.renderHeight * 0.005,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        avatarPlayer1ImageConfig.assetPath,
                        width: avatarPlayer1ImageConfig.renderSize,
                        height: avatarPlayer1ImageConfig.renderSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // 4. Bottom Player Avatar Layer
                Positioned(
                  bottom: teamCardFrameImageConfig.renderHeight * 0.005,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        avatarPlayer2ImageConfig.assetPath,
                        width: avatarPlayer2ImageConfig.renderSize,
                        height: avatarPlayer2ImageConfig.renderSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // 5. PNG Frame Overlay
                Positioned.fill(
                  child: Image.asset(
                    teamCardFrameImageConfig.assetPathFrame,
                    fit: BoxFit.fill,
                  ),
                ),

                // 6. Dummy Player Layer
                if (isDummyTeam)
                  Positioned.fill(
                    child: Image.asset(
                      teamCardFrameImageConfig.assetPathIsDummyPlayer,
                      fit: BoxFit.fill,
                    ),
                  ),

                // 7. Player 1 Nickname Pill (Centered Top)
                Positioned(
                  top: teamCardFrameImageConfig.renderHeight * 0.01,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: teamCardFrameImageConfig.renderHeight * 0.035,
                        vertical: teamCardFrameImageConfig.renderHeight * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(
                          teamCardFrameImageConfig.renderHeight * 0.04,
                        ),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: teamCardFrameImageConfig.renderHeight * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          team.fldPlayers[0].fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(teamCardFrameImageConfig.renderHeight * 0.032,gFontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ),

                // 8. Player 2 Nickname Pill (Centered Bottom)
                Positioned(
                  bottom: teamCardFrameImageConfig.renderHeight * 0.01,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: teamCardFrameImageConfig.renderHeight * 0.035,
                        vertical: teamCardFrameImageConfig.renderHeight * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(
                          teamCardFrameImageConfig.renderHeight * 0.04,
                        ),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: teamCardFrameImageConfig.renderHeight * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          team.fldPlayers[1].fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(teamCardFrameImageConfig.renderHeight * 0.032, gFontWeight: FontWeight.w800),
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
    );
  }
}