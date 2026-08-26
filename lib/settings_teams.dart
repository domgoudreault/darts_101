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

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    // 1. Access the Hive box opened during initialization
    final teamsBox = Hive.box<TblTeam>('teamsBox');
    final ImageCardFrameConfig imageCardFrameConfig = getCarouselCardFrameImageConfig();

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
                  gBuildArcadeActionBanner(
                    context: context,
                    leadingText: 'ADD NEW',
                    trailingText: 'TEAM',
                    formMode: FormMode.formAdd,
                    onTap: () => _addTeam(context),
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
                              hintText: 'Search player name, nickname or team surname...',
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
                                      final filteredCount = _searchQuery.isEmpty
                                          ? activeTeams.length
                                          : activeTeams.where((team) {
                                              final query = _searchQuery.toLowerCase();
                                              return team.fldSurName.toLowerCase().contains(query);
                                            }).length;

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
                                              _searchQuery.isEmpty 
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
                      final teams = _searchQuery.isEmpty
                          ? activeTeams
                          : activeTeams.where((team) {
                              final surName = team.fldSurName.toLowerCase();

                              return surName.contains(_searchQuery);
                            }).toList();

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
                // 1. PNG Frame Background
                Positioned.fill(
                  child: Image.asset(
                    imageCardFrameConfig.assetPathBackground,
                    fit: BoxFit.fill,
                  ),
                ),

                // 2. Avatar Layer
                /* Positioned.fill(
                  child: Image.asset(
                    getCarouselTeamImageConfig(team.fldAvatarCode).assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle,
                      size: 64,
                      color: Colors.white38,
                    ),
                  ),
                ), */

                // 3. PNG Frame Overlay
                Positioned.fill(
                  child: Image.asset(
                    imageCardFrameConfig.assetPathFrame,
                    fit: BoxFit.fill,
                  ),
                ),
                
                // 4. Team Data Text Overlay Layer (On top of white card area)
                Positioned(
                  top: imageCardFrameConfig.renderHeight * 0.52,
                  left: imageCardFrameConfig.renderHeight * 0.08,
                  right: imageCardFrameConfig.renderHeight * 0.08,
                  bottom: imageCardFrameConfig.renderHeight * 0.06,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Gap 1: Picture bottom -> First Name
                      SizedBox(height: imageCardFrameConfig.renderHeight * 0.015),
                      
                      /* // First Name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          team.fldFirstName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: imageCardFrameConfig.renderHeight * 0.035,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Gap 2: First Name -> Last Name
                      SizedBox(height: imageCardFrameConfig.renderHeight * 0.010),

                      // Last Name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          team.fldLastName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: imageCardFrameConfig.renderHeight * 0.048,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Gap 3: Last Name -> Divider
                      SizedBox(height: imageCardFrameConfig.renderHeight * 0.024),

                      // Divider Accent
                      Container(
                        height: (imageCardFrameConfig.renderHeight * 0.009),
                        width: imageCardFrameConfig.renderHeight * 0.50,
                        color: widget.tileColor,
                      ),
                      
                      // Gap 4: Divider -> Nickname
                      SizedBox(height: imageCardFrameConfig.renderHeight * 0.022), */

                      // Elliptic Arcade Badge around Nickname
                      Container(
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
                            team.fldSurName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: gBuildArcadeTextStyle(imageCardFrameConfig.renderHeight * 0.032, gFontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
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