// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_database.dart';

// UI Screens
import 'package:darts_101/modify_add_team.dart';

class SettingsTeams extends StatefulWidget {
  // Define variables to hold the data passed from the previous screen
  final GlobalSettingType enuSettingType;

  const SettingsTeams({super.key, required this.enuSettingType});

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

  List<TblTeam> _activeTeams(Box<TblTeam> teamsBox) {
    return teamsBox.values.where((team) => !team.fldIsDeleted).toList();
  }

  List<TblTeam> _filteredTeams(Iterable<TblTeam> activeTeams) {
    return activeTeams
        .where((team) => _matchesTeamQuery(team, _searchQuery))
        .toList();
  }

  // Fonctions de navigation when a button is pressed
  void _addTeam(BuildContext context, double cardWidth) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // The modify_add_team.dart page will be created and shown
        builder: (context) => ModifyAddTeamForm(
          enuFormMode: GlobalFormMode.formAdd,
          enuSettingType: widget.enuSettingType,
        ),
      ),
    );

    if (result == true && mounted) {
      if (_searchQuery.isNotEmpty) {
        _searchController.clear();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activeTeams = _activeTeams(Hive.box<TblTeam>('teamsBox'));

        if (activeTeams.isNotEmpty && _carouselController.hasClients) {
          _carouselController.animateTo(
            activeTeams.length * cardWidth,
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
          enuFormMode: GlobalFormMode.formModify,
          modifyTeam: team,
          enuSettingType: widget.enuSettingType,
        ),
      ),
    );
  }

  void _checkAndPromptTeamSeeding() {
    final teamsBox = Hive.box<TblTeam>(
      'teamsBox',
    ).values.where((team) => !team.fldIsDeleted);
    final playersBox = Hive.box<TblPlayer>(
      'playersBox',
    ).values.where((player) => !player.fldIsDeleted);

    if (teamsBox.isEmpty && playersBox.isNotEmpty) {
      _showTeamsSeedDialog();
    }
  }

  // 1. GENERIC AUTO-GENERATED SEED DIALOG (Release Mode OR Declined League Data)
  void _showTeamsSeedDialog() {
    gShowDatabaseSeedDialog(
      context,
      tileColor: widget.enuSettingType.tileColor,
      tileBackgroundColor: widget.enuSettingType.tileBackgroundColor,
      assetFullPath: 'assets/png/tiles/settings_teams.png',
      headerText: 'SAMPLE DEFAULT TEAMS ?',
      titleText: 'No teams found.',
      questionText:
          'Would you like us to auto-generate sample default teams for you?',
      noButtonText1: 'NO',
      noButtonText2: '(LATER)',
      yesButtonText1: 'YES',
      yesButtonText2: '(NOW)',
      onNoPressed: (dialogContext) {
        Navigator.pop(
          dialogContext,
        ); // Uses the dialogContext passed from the helper
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
      final bool isDummyTeam = p1 == p2;

      // If the toggle is ON and this isn't a dummy team, exclude it immediately
      if (!isDummyTeam) return false;
    }

    // 2. SEARCH BAR TEXT CHECK
    if (query.isEmpty) return true;

    // Split query into individual search terms and remove empty spaces
    final terms = query.split(' ').where((term) => term.isNotEmpty).toList();
    if (terms.isEmpty) return true;

    // Helper function to check if a single term matches a player
    bool matchesPlayer(TblPlayer player, String term) {
      return player.fldFirstName.toLowerCase().contains(term) ||
          player.fldLastName.toLowerCase().contains(term) ||
          player.fldNickName.toLowerCase().contains(term);
    }

    // EVERY term must match either Player 1 or Player 2
    return terms.every(
      (term) => matchesPlayer(p1, term) || matchesPlayer(p2, term),
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    // 1. Access the Hive box opened during initialization
    final teamsBox = Hive.box<TblTeam>('teamsBox');
    final safeHeight = GlobalAppDisplay.safeHeight;
    final safeWidth = GlobalAppDisplay.safeWidth;
    final toolbarHeight = (safeHeight * 0.10).clamp(56.0, 142.0);
    final cardHeight = (safeHeight - toolbarHeight) * (3 / 4);
    final cardWidth = cardHeight * 0.6836;

    return Scaffold(
      backgroundColor: widget.enuSettingType.tileBackgroundColor,
      appBar: gBuildAppBar(
        gToolbarHeight: toolbarHeight,
        gAppBarTitle: widget.enuSettingType.tileDisplayName,
        gAppBarColorBg: widget.enuSettingType.tileColor,
        gCallFromMainScreen: false,
        gOnPressed: null,
        gRightPopupMenu: null,
      ),

      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP SEGMENTED TOGGLE BAR (Takes (1/4 * 0.9) - toolbarHeight of screen free space)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: safeWidth * 0.008,
                vertical: safeHeight * 0.008,
              ),
              height: (safeHeight - toolbarHeight) * (1 / 4) * 0.9,
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  // 1.1 Add Team Banner
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(
                          child: gBuildArcadeActionBanner(
                            gLeadingText: 'ADD NEW',
                            gTrailingText: 'TEAM',
                            gFormMode: GlobalFormMode.formAdd,
                            gOnTap: () => _addTeam(context, cardWidth),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isDummyFilterActive = !_isDummyFilterActive;
                                });

                                if (_isDummyFilterActive) {
                                  gShowArcadeErrorSnackBar(
                                    gContext: context,
                                    gFontSize: (safeHeight * 0.015).clamp(
                                      10.0,
                                      60.0,
                                    ),
                                    gMessage: 'FILTER DUMMY TEAMS ACTIVATED',
                                    gDuration: 3,
                                    gBbackgroundColor: Color.fromRGBO(
                                      247,
                                      120,
                                      9,
                                      1.0,
                                    ),
                                  );
                                }
                              },
                              child: SizedBox(
                                width: safeHeight * 0.105,
                                height: safeHeight * 0.105,
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
                                        'assets/png/mechanics/player_dummy_icon.png',
                                        width: safeHeight * 0.105,
                                        height: safeHeight * 0.105,
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
                                                ? Color.fromRGBO(
                                                    247,
                                                    120,
                                                    9,
                                                    1.0,
                                                  )
                                                : Colors.amber,
                                            width:
                                                ((safeHeight * 0.105) * 0.03),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: safeHeight * 0.010),

                  // 1.2 Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: safeHeight * 0.075,
                          child: FocusScope(
                            node: FocusScopeNode(),
                            child: TextField(
                              controller: _searchController,
                              style: gBuildArcadeTextStyle(safeHeight * 0.0195),
                              decoration: InputDecoration(
                                hintText:
                                    'Search names or nicknames (space separated)...',
                                hintStyle: gBuildArcadeTextStyle(
                                  safeHeight * 0.0195,
                                  gTextColor: Colors.grey.shade400,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.amber,
                                  size: safeHeight * 0.060,
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize
                                      .min, // Essential so it doesn't expand to fill the bar
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
                                          size: safeHeight * 0.045,
                                        ),
                                        onPressed: () =>
                                            _searchController.clear(),
                                      ),

                                    // Gap between clear button and counter pill
                                    SizedBox(width: safeWidth * 0.0065),

                                    // 2. Embedded Arcade Counter Pill
                                    ValueListenableBuilder<Box<TblTeam>>(
                                      valueListenable: teamsBox.listenable(),
                                      builder: (context, box, _) {
                                        final activeTeams = _activeTeams(box);
                                        final filteredCount = _filteredTeams(
                                          activeTeams,
                                        ).length;

                                        return Container(
                                          margin: EdgeInsets.only(
                                            right: safeHeight * 0.01,
                                            top: safeHeight * 0.01,
                                            bottom: safeHeight * 0.01,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: safeHeight * 0.015,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade900,
                                            borderRadius: BorderRadius.circular(
                                              safeHeight * 0.01,
                                            ),
                                            border: Border.all(
                                              color: Colors.amber,
                                              width: (safeHeight * 0.003).clamp(
                                                1.0,
                                                2.0,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                (_searchQuery.isEmpty &&
                                                        !_isDummyFilterActive)
                                                    ? '$filteredCount'
                                                    : '$filteredCount/${activeTeams.length}',
                                                style: gBuildArcadeTextStyle(
                                                  safeHeight * 0.020,
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
                                  borderRadius: BorderRadius.circular(
                                    safeHeight * 0.02,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    safeHeight * 0.02,
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.amber,
                                    width: (safeHeight * 0.005).clamp(1.5, 4.0),
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

            // 2. LIVE TEAM CAROUSEL DISPLAY AREA (Takes 3/4 - toolbarHeight of screen free space)
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: safeWidth,
                  child: ValueListenableBuilder<Box<TblTeam>>(
                    valueListenable: teamsBox.listenable(),
                    builder: (context, box, _) {
                      final activeTeams = _activeTeams(box);

                      // Filter by First Name, Last Name, or Nickname
                      final teams = _filteredTeams(activeTeams);

                      if (teams.isEmpty) {
                        return Center(
                          child: Text(
                            'No teams found.',
                            style: gBuildArcadeTextStyle(safeHeight * 0.023),
                          ),
                        );
                      }

                      return CarouselView(
                        controller: _carouselController,
                        itemExtent: cardWidth,
                        shrinkExtent: cardWidth * 0.5,
                        backgroundColor: Colors.transparent,
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        onTap: (int index) {
                          final team = teams[index];
                          _onTeamTapped(context, team);
                        },
                        children: teams
                            .map(
                              (team) => gBuildTeamCardV(
                                team: team,
                                cardHeight: cardHeight,
                                cardWidth: cardWidth,
                                colorBgAvatar: widget.enuSettingType.tileColor,
                                isSlicedCard: false,
                              ),
                            )
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
}
