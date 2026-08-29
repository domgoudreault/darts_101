// Flutter basics
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
//import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/ui_helpers.dart';
import 'package:darts_101/settings_teams_be.dart';

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
  String _searchQuery = '';

  final CarouselController _carouselController = CarouselController();
  bool _isDummyFilterActive = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
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
            activeTeams.length * getCarouselCardFrameImageConfig().renderWidth,
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

  void _showArcadeFilterSnackBar(String message, int timer) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Color.fromRGBO(247, 120, 9, 1.0),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: AppDisplay.safeWidth * 0.05,
          right: AppDisplay.safeWidth * 0.05,
          bottom: AppDisplay.safeHeight * 0.05,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Center(
          child: Text(
            message,
            style: gBuildArcadeTextStyle((AppDisplay.carouselTileSize * 0.025).clamp(10.0, 60.0)),
          ),
        ),
        duration: Duration(seconds: timer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    // 1. Access the Hive box opened during initialization
    final teamsBox = Hive.box<TblTeam>('teamsBox');
    final ImageCardFrameConfig imageCardFrameConfig = getCarouselCardFrameImageConfig();
    final ImageConfig imageConfig = getFilterDummyImageConfig();

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
                horizontal: imageCardFrameConfig.renderHeight * 0.06,
                vertical: imageCardFrameConfig.renderHeight * 0.02,
              ),
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  // 1.1 Add Team Banner
                  Row(
                    children: [
                      Expanded(
                        child: gBuildArcadeActionBanner(
                          context: context,
                          leadingText: 'ADD NEW',
                          trailingText: 'TEAM',
                          formMode: FormMode.formAdd,
                          onTap: () => _addTeam(context),
                        ),
                      ),
                      SizedBox(width: imageCardFrameConfig.renderHeight * 0.02),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDummyFilterActive = !_isDummyFilterActive;
                            });

                            if (_isDummyFilterActive) {
                              _showArcadeFilterSnackBar('FILTER DUMMY TEAMS ACTIVATED', 3);
                            }
                          },
                          child: SizedBox(
                            width: imageConfig.renderSize,
                            height: imageConfig.renderSize,
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
                                    imageConfig.assetPath,
                                    width: imageConfig.renderSize,
                                    height: imageConfig.renderSize,
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
                                        width: (imageConfig.renderSize * 0.03),
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

                  SizedBox(height: imageCardFrameConfig.renderHeight * 0.015),

                  // 1.2 Seach Bar
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: imageCardFrameConfig.renderHeight * 0.12,
                          child: TextField(
                            controller: _searchController,
                            style: gBuildArcadeTextStyle(imageCardFrameConfig.renderHeight * 0.035),
                            decoration: InputDecoration(
                              hintText: 'Search names or nicknames (space separated)...',
                              hintStyle: gBuildArcadeTextStyle(imageCardFrameConfig.renderHeight * 0.035, gTextColor: Colors.grey.shade400),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.amber,
                                size: imageCardFrameConfig.renderHeight * 0.09,
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
                                        size: imageCardFrameConfig.renderHeight * 0.065,
                                      ),
                                      onPressed: () => _searchController.clear(),
                                    ),

                                  // Gap between clear button and counter pill
                                  SizedBox(width: imageCardFrameConfig.renderHeight * 0.015),

                                  // 2. Embedded Arcade Counter Pill
                                  ValueListenableBuilder<Box<TblTeam>>(
                                    valueListenable: teamsBox.listenable(),
                                    builder: (context, box, _) {
                                      final activeTeams = box.values.where((p) => !p.fldIsDeleted).toList();
                                      final filteredCount = activeTeams.where((team) => _matchesTeamQuery(team, _searchQuery)).length;

                                      return Container(
                                        margin: EdgeInsets.only(
                                          right: imageCardFrameConfig.renderHeight * 0.015,
                                          top: imageCardFrameConfig.renderHeight * 0.015,
                                          bottom: imageCardFrameConfig.renderHeight * 0.015,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: imageCardFrameConfig.renderHeight * 0.025,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade900,
                                          borderRadius: BorderRadius.circular(imageCardFrameConfig.renderHeight * 0.02),
                                          border: Border.all(
                                            color: Colors.amber,
                                            width: (imageCardFrameConfig.renderHeight * 0.005).clamp(1.0, 2.0),
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
                                                imageCardFrameConfig.renderHeight * 0.035,
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
                                horizontal: imageCardFrameConfig.renderHeight * 0.045,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade800,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(imageCardFrameConfig.renderHeight * 0.03),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(imageCardFrameConfig.renderHeight * 0.03),
                                borderSide: BorderSide(
                                  color: Colors.amber,
                                  width: (imageCardFrameConfig.renderHeight * 0.008).clamp(1.5, 4.0),
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
                        itemExtent: imageCardFrameConfig.renderWidth,
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
    final ImageCardFrameConfig imageCardFrameConfig = getCarouselCardFrameImageConfig();
    final bool isDummyTeam = team.fldPlayers[0].fldAvatarCode == team.fldPlayers[1].fldAvatarCode;

    return Center(
      child: AspectRatio(
        aspectRatio: imageCardFrameConfig.renderWidth / imageCardFrameConfig.renderHeight,
        child: FittedBox(
          fit: BoxFit.contain, // Forces height and width to scale down together proportionally
          child: SizedBox(
            width: imageCardFrameConfig.renderWidth,
            height: imageCardFrameConfig.renderHeight,
            child: Stack(
              children: [
                // 1. Top Dynamic Circle Background Layer
                Positioned(
                  top: imageCardFrameConfig.renderHeight * 0.03, // Positions inside top metallic ring
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: imageCardFrameConfig.renderWidth * 0.72,
                      height: imageCardFrameConfig.renderWidth * 0.72,
                      decoration: BoxDecoration(
                        color: widget.tileColor, // Or gender color for Player 1
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                // 2. Bottom Dynamic Circle Background Layer
                Positioned(
                  bottom: imageCardFrameConfig.renderHeight * 0.03, // Positions inside bottom metallic ring
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: imageCardFrameConfig.renderWidth * 0.72,
                      height: imageCardFrameConfig.renderWidth * 0.72,
                      decoration: BoxDecoration(
                        color: widget.tileColor, // Or gender color for Player 2
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                
                // 3. Top Player Avatar Layer
                Positioned(
                  top: imageCardFrameConfig.renderHeight * 0.01,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        getCarouselPlayerImageConfig(team.fldPlayers[0].fldAvatarCode).assetPath,
                        width: imageCardFrameConfig.renderWidth * 0.72,
                        height: imageCardFrameConfig.renderWidth * 0.72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // 4. Bottom Player Avatar Layer
                Positioned(
                  bottom: imageCardFrameConfig.renderHeight * 0.01,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        getCarouselPlayerImageConfig(team.fldPlayers[1].fldAvatarCode).assetPath,
                        width: imageCardFrameConfig.renderWidth * 0.72,
                        height: imageCardFrameConfig.renderWidth * 0.72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // 3. PNG Frame Overlay
                Positioned.fill(
                  child: Image.asset(
                    imageCardFrameConfig.assetPathFrame,
                    fit: BoxFit.fill,
                  ),
                ),

                // 3. Dummy Player Layer
                if (isDummyTeam)
                  Positioned.fill(
                    child: Image.asset(
                      imageCardFrameConfig.assetPathIsDummyPlayer,
                      fit: BoxFit.fill,
                    ),
                  ),

                // 5. Player 1 Nickname Pill (Centered Top)
                Positioned(
                  top: imageCardFrameConfig.renderHeight * 0.01,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: imageCardFrameConfig.renderHeight * 0.035,
                        vertical: imageCardFrameConfig.renderHeight * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(
                          imageCardFrameConfig.renderHeight * 0.04,
                        ),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: imageCardFrameConfig.renderHeight * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          team.fldPlayers[0].fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(imageCardFrameConfig.renderHeight * 0.032,gFontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. Player 2 Nickname Pill (Centered Bottom)
                Positioned(
                  bottom: imageCardFrameConfig.renderHeight * 0.01,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: imageCardFrameConfig.renderHeight * 0.035,
                        vertical: imageCardFrameConfig.renderHeight * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(
                          imageCardFrameConfig.renderHeight * 0.04,
                        ),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: imageCardFrameConfig.renderHeight * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          team.fldPlayers[1].fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(imageCardFrameConfig.renderHeight * 0.032, gFontWeight: FontWeight.w800),
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