// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Database Models
//import 'package:darts_101/database/tbl_avatar.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/ui_helpers.dart';
//import 'package:darts_101/modify_add_team_be.dart';

class ModifyAddTeamForm extends StatefulWidget {  
  final FormMode enuFormMode;
  final TblTeam? modifyTeam;
  final Color tileColor;
  final Color tileBackgroundColor;

  const ModifyAddTeamForm({
    super.key,
    required this.enuFormMode,
    this.modifyTeam,
    required this.tileColor,
    required this.tileBackgroundColor,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ModifyAddTeamFormState createState() => _ModifyAddTeamFormState();
}

class _ModifyAddTeamFormState extends State<ModifyAddTeamForm> {
  bool _isDummyTeam = false;
  TblPlayer? _selectedPlayer1;
  TblPlayer? _selectedPlayer2;
  
  late String _selectedAvatarCodePlayer1;
  late String _selectedAvatarCodePlayer2;

  double get _responsiveTile => AppDisplay.carouselTileSize;
  double get _responsiveFontSize => (_responsiveTile * 0.035).clamp(10.0, 60.0);

  // 2. Clean up controllers when the widget is destroyed
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // If we are modifying, fill the controllers with existing data
    if (widget.enuFormMode == FormMode.formModify && widget.modifyTeam != null) {
      _selectedAvatarCodePlayer1 = widget.modifyTeam!.fldPlayers[0].fldAvatarCode;
      _selectedAvatarCodePlayer2 = widget.modifyTeam!.fldPlayers[1].fldAvatarCode;
    }
    else {
      _selectedAvatarCodePlayer1 = 'question';
      _selectedAvatarCodePlayer2 = 'question';
    }    
  }

  void _pickPlayer1() async {
    final player = await _showPlayerPicker();
    if (player != null) {
      setState(() {
        _selectedPlayer1 = player;
        _selectedAvatarCodePlayer1 = player.fldAvatarCode;
      });
    }
  }

  void _pickPlayer2() async {
    final player = await _showPlayerPicker();
    if (player != null) {
      setState(() {
        _selectedPlayer2 = player;
        _selectedAvatarCodePlayer2 = player.fldAvatarCode;
      });
    }
  }

  void _showArcadeDummySnackBar(String message, int timer) {
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

  void _saveTeam() {
    /* // 1. Check if an avatar was selected (block if still placeholder 'question')
    if (_selectedAvatarCode == 'question') {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          // Uses purely AppDisplay ratios to keep the SnackBar above safe boundaries
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
              'PLEASE SELECT AN AVATAR!',
              style: gBuildArcadeTextStyle((_responsiveFontSize * 0.70).clamp(10.0, 60.0)),
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    } */

    // 3. Save to Hive database if everything is ok
    // Get the playersBox from Hive
    //final teamsBox = Hive.box<TblTeam>('teamsBox');

    if (widget.enuFormMode == FormMode.formAdd){
      // Create the player object
      /* final team = TblTeam(
        fldSurName: _surNameController.text.trim(),
        fldIsDeleted: false,
      ); */

      /* // Add to Hive        
      teamsBox.add(team);
       */
      // Return to previous screen
      Navigator.pop(context, true);    

    } else {
        //TODO Push the two players selection in the Team Hive Database
        
        // Save to Hive        
        widget.modifyTeam?.save();

        // Return to previous screen
        Navigator.pop(context, false);
    }
  }

  void _deleteTeam() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          title: Text(
            'DELETE TEAM?',
            style: gBuildArcadeTextStyle(18, gTextColor: Colors.redAccent),
          ),
          content: Text(
            'Are you sure you want to remove the team?',
            style: TextStyle(
              color: Colors.white, 
              fontSize: (_responsiveFontSize * 0.90).clamp(10.0, 60.0),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'CANCEL',
                style: gBuildArcadeTextStyle(14, gTextColor: Colors.grey.shade400),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
              ),
              onPressed: () {
                // Soft delete: set flag to true and save to Hive
                widget.modifyTeam?.fldIsDeleted = true;
                widget.modifyTeam?.save();

                Navigator.of(ctx).pop();    // Close dialog
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: Text(
                'DELETE',
                style: gBuildArcadeTextStyle(14, gTextColor: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<TblPlayer?> _showPlayerPicker() async {
    final playersBox = Hive.box<TblPlayer>('playersBox');
    final List<TblPlayer> playerList = playersBox.values
      .where((player) => !player.fldIsDeleted)
      .toList();
    final ImageConfigAvatar avatarFrameImageConfig = getAvatarFrameImageConfig();

    return showModalBottomSheet<TblPlayer>(
      context: context,
      useSafeArea: true,
      backgroundColor: widget.tileColor,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            width: AppDisplay.safeWidth * 0.775,
            height: (avatarFrameImageConfig.renderSize + 80.0).clamp(0.0, AppDisplay.safeHeight * 0.9),
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade600,
                    border: Border.all(
                      color: Colors.white, // Or widget.tileColor / whatever border color you want
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18.0), // Matches outer 20px sheet curve perfectly
                      bottom: Radius.zero,       // Sharp, edgy straight cut at the bottom
                    ),
                  ),
                  child: Text(
                    'SELECT A PLAYER',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      (_responsiveFontSize * 0.70).clamp(10.0, 60.0)
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: avatarFrameImageConfig.renderSize,
                  child: CarouselView(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    itemExtent: avatarFrameImageConfig.renderSize + 4.0,
                    shrinkExtent: avatarFrameImageConfig.renderSize * 0.8,
                    // Native CarouselView callback receives the tapped item index directly
                    onTap: (int index) {
                      final selectedPlayer = playerList[index];
                      Navigator.pop(context, selectedPlayer);
                    },
                    children: playerList.map((player) {
                      return _buildPlayerAvatarCard(player);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerAvatarCard(TblPlayer player) {
    final ImageConfigAvatar avatarFrameImageConfig = getAvatarFrameImageConfig();
    final ImageConfigAvatar avatarPlayerImageConfig = getAvatarPlayerImageConfig(player.fldAvatarCode);

    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: FittedBox(
          fit: BoxFit.contain, // Forces artwork and text to scale together proportionally
          child: SizedBox(
            width: avatarFrameImageConfig.renderSize,
            height: avatarFrameImageConfig.renderSize,
            child: Stack(
              children: [
                // 1. Dynamic Circle Background Layer
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: avatarFrameImageConfig.renderSize,
                  child: Center(
                    child: Container(
                      width: avatarFrameImageConfig.renderSize * 0.95,
                      height: avatarFrameImageConfig.renderSize * 0.95,
                      decoration: BoxDecoration(
                        color: widget.tileBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                // 2. Avatar Artwork
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: avatarFrameImageConfig.renderSize,
                  child: Image.asset(
                    avatarPlayerImageConfig.assetPath,
                    fit: BoxFit.contain,
                  ),
                ),

                // 3. Metallic Frame Overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: avatarFrameImageConfig.renderSize,
                  child: Image.asset(
                    avatarFrameImageConfig.assetPath,
                    fit: BoxFit.contain,
                  ),
                ),

                // 4. Player Nickname Pill (Positioned relative to total cardHeight like _buildTeamCard)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: avatarFrameImageConfig.renderSize * 0.045,
                        vertical: avatarFrameImageConfig.renderSize * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(avatarFrameImageConfig.renderSize * 0.04),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: avatarFrameImageConfig.renderSize * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          player.fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(
                            avatarFrameImageConfig.renderSize * 0.062,
                            gFontWeight: FontWeight.w800,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context); // Triggers re-render on resize

    //final ImageCardFrameConfig imageCardFrameConfig = getCarouselCardFrameImageConfig();
    final ImageConfigDummy dummyImageConfig = getDummyImageConfig();

    return Scaffold(
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
            Text(widget.enuFormMode == FormMode.formAdd ? 'Add a team' : 'Modify a team', style: gBuildArcadeTextStyle(20)),
          ],
        ),
      ),
      
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP SEGMENTED TOGGLE BAR (Reserved for sub-filters if needed)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDisplay.carouselTileSize * 0.06,
                vertical: AppDisplay.carouselTileSize * 0.02,
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
                          leadingText: 'SAVE',
                          trailingText: 'TEAM',
                          formMode: FormMode.formAdd,
                          onTap: () => _saveTeam(),
                        ),
                      ),
                      SizedBox(width: _responsiveTile * 0.02),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDummyTeam = !_isDummyTeam;
                            });

                            if (_isDummyTeam) {
                              _showArcadeDummySnackBar('DUMMY PLAYER MODE ACTIVATED', 3);
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
                                      color: _isDummyTeam
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
                                        color: _isDummyTeam
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

                  //SizedBox(height: imageCardFrameConfig.renderHeight * 0.015),

                  /* // 1.2 Seach Bar
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
                  ), */
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PLAYER 1 SLOT
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPlayerAvatarMainUI(
                            selectedAvatarCodePlayer: _selectedAvatarCodePlayer1,
                            selectedPlayer: _selectedPlayer1,
                            onTap: _pickPlayer1,
                          ),
                          const SizedBox(height: 12),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _pickPlayer1,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (_responsiveTile * 0.02).clamp(8.0, 24.0),
                                  vertical: (_responsiveTile * 0.015).clamp(6.0, 20.0),
                                ),
                                decoration: BoxDecoration(
                                  color: widget.tileColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: (_responsiveTile * 0.006).clamp(1.5, 4.0),
                                  ),
                                ),
                                child: Text(
                                  'SELECT PLAYER 1',
                                  textAlign: TextAlign.center,
                                  style: gBuildArcadeTextStyle(
                                    (_responsiveFontSize * 0.70).clamp(10.0, 60.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // PLAYER 2 SLOT (Avatar + Button, hidden if Dummy Mode is active)
                      if (!_isDummyTeam) ...[
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPlayerAvatarMainUI(
                              selectedAvatarCodePlayer: _selectedAvatarCodePlayer2,
                              selectedPlayer: _selectedPlayer2,
                              onTap: _pickPlayer2,
                            ),
                            const SizedBox(height: 12),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _pickPlayer2,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (_responsiveTile * 0.02).clamp(8.0, 24.0),
                                    vertical: (_responsiveTile * 0.015).clamp(6.0, 20.0),
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.tileColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: (_responsiveTile * 0.006).clamp(1.5, 4.0),
                                    ),
                                  ),
                                  child: Text(
                                    'SELECT PLAYER 2',
                                    textAlign: TextAlign.center,
                                    style: gBuildArcadeTextStyle(
                                      (_responsiveFontSize * 0.70).clamp(10.0, 60.0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(width: 12), // Spacing between columns

                      // RIGHT COLUMN: AVATAR PREVIEW & PICKER BUTTON
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTeamCardMainUI(),
                                    const SizedBox(height: 12),
                                    
                                    // Delete Team button
                                    if (widget.enuFormMode == FormMode.formModify &&
                                      widget.modifyTeam != null) ...[
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: _deleteTeam,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: (_responsiveTile * 0.005).clamp(4.0, 24.0),
                                                vertical: (_responsiveTile * 0.005).clamp(4.0, 24.0),
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade800,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: (_responsiveTile * 0.006).clamp(1.5, 4.0),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/svg/ui_buttons/player_team_delete.svg',
                                                    width: (_responsiveTile * 0.13).clamp(48.0, 160.0),
                                                    height: (_responsiveTile * 0.13).clamp(48.0, 160.0),
                                                    fit: BoxFit.contain,
                                                  ),
                                                  //const SizedBox(width: 2),
                                                  Text(
                                                    'DELETE',
                                                    style: gBuildArcadeTextStyle(
                                                      (_responsiveFontSize * 0.80).clamp(10.0, 60.0),
                                                      gTextColor: Colors.lightBlueAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
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
          ]
        ),
      ),
    );
  }

  Widget _buildTeamCardMainUI() {
    final ImageConfigTeamCardFrame teamCardFrameImageConfig = getMainUITeamCardHFrameImage();
    final ImageConfigAvatar avatarPlayer1ImageConfig = getAvatarPlayerHImageConfig(_selectedAvatarCodePlayer1);
    final ImageConfigAvatar avatarPlayer2ImageConfig = getAvatarPlayerHImageConfig(_selectedAvatarCodePlayer2);

    return SizedBox(
      width: teamCardFrameImageConfig.renderWidth,
      height: teamCardFrameImageConfig.renderHeight,
      child: Stack(
        children: [
          // 1. Player 1 Solid Color Circle (Left Half Background)
          Positioned(
            top: 0,
            bottom: 0,
            left: teamCardFrameImageConfig.renderWidth * 0.03,
            width: avatarPlayer1ImageConfig.renderSize,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.tileColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // 2. Player 2 Solid Color Circle (Right Background)
          Positioned(
            top: 0,
            bottom: 0,
            right: teamCardFrameImageConfig.renderWidth * 0.03,
            width: avatarPlayer2ImageConfig.renderSize,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.tileColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // 3. Player 1 Avatar Artwork (Left Half)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: avatarPlayer1ImageConfig.renderSize,
            child: Image.asset(
              avatarPlayer1ImageConfig.assetPath,
              fit: BoxFit.contain,
            ),
          ),

          // 4. Player 2 Avatar Artwork (Right Half)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: avatarPlayer2ImageConfig.renderSize,
            child: Image.asset(
              avatarPlayer2ImageConfig.assetPath,
              fit: BoxFit.contain,
            ),
          ),

          // 5. Metallic Frame Overlay (Top-most layer)
          Positioned.fill(
            child: Image.asset(
              teamCardFrameImageConfig.assetPathFrame,
              fit: BoxFit.contain,
            ),
          ),

          // 6. Player 1 Nickname Pill (Left Slot)
          if (_selectedPlayer1 != null)
            Positioned(
              bottom: teamCardFrameImageConfig.renderHeight * 0.13,
              left: 0,
              width: avatarPlayer1ImageConfig.renderSize,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: avatarPlayer1ImageConfig.renderSize * 0.045,
                    vertical: avatarPlayer1ImageConfig.renderSize * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.shade100,
                    borderRadius: BorderRadius.circular(avatarPlayer1ImageConfig.renderSize * 0.04),
                    border: Border.all(
                      color: Colors.purpleAccent.shade700,
                      width: avatarPlayer1ImageConfig.renderSize * 0.006,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _selectedPlayer1!.fldNickName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: gBuildArcadeTextStyle(
                        avatarPlayer1ImageConfig.renderSize * 0.062,
                        gFontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // 7. Player 2 Nickname Pill (Right Slot)
          if (_selectedPlayer2 != null)
            Positioned(
              bottom: teamCardFrameImageConfig.renderHeight * 0.13,
              right: 0,
              width: avatarPlayer2ImageConfig.renderSize,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: avatarPlayer2ImageConfig.renderSize * 0.045,
                    vertical: avatarPlayer2ImageConfig.renderSize * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.shade100,
                    borderRadius: BorderRadius.circular(avatarPlayer2ImageConfig.renderSize * 0.04),
                    border: Border.all(
                      color: Colors.purpleAccent.shade700,
                      width: avatarPlayer2ImageConfig.renderSize * 0.006,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _selectedPlayer2!.fldNickName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: gBuildArcadeTextStyle(
                        avatarPlayer2ImageConfig.renderSize * 0.062,
                        gFontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ]
      ),
    );
  }

  Widget _buildPlayerAvatarMainUI({
    required String selectedAvatarCodePlayer,
    required TblPlayer? selectedPlayer,
    required VoidCallback onTap,
  }) {
    final ImageConfigAvatar avatarFrameImageConfig = getAvatarFrameImageConfig();
    final ImageConfigAvatar avatarPlayerImageConfig = getAvatarPlayerImageConfig(selectedAvatarCodePlayer);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: avatarFrameImageConfig.renderSize,
          height: avatarFrameImageConfig.renderSize,
          child: Stack(
            children: [
              // 1. Solid Color Circle (Bottom-most layer behind the avatar)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.tileColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // 2. Avatar Artwork (Transparent PNG)
              Positioned.fill(
                child: Image.asset(
                  avatarPlayerImageConfig.assetPath,
                  fit: BoxFit.contain,
                ),
              ),

              // 3. Metallic Frame Overlay (Top-most layer)
              Positioned.fill(
                child: Image.asset(
                  avatarFrameImageConfig.assetPath,
                  fit: BoxFit.contain,
                ),
              ),

              // 4. Player Nickname Pill
              if (selectedPlayer != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: avatarFrameImageConfig.renderSize * 0.045,
                        vertical: avatarFrameImageConfig.renderSize * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(avatarFrameImageConfig.renderSize * 0.04),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: avatarFrameImageConfig.renderSize * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selectedPlayer.fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(
                            avatarFrameImageConfig.renderSize * 0.062,
                            gFontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}