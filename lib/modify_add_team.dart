// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';

class ModifyAddTeamForm extends StatefulWidget {  
  final FormMode enuFormMode;
  final TblTeam? modifyTeam;
  final GlobalSettingType enuSettingType;

  const ModifyAddTeamForm({
    super.key,
    required this.enuFormMode,
    this.modifyTeam,
    required this.enuSettingType,
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

  double get _responsiveTile => GlobalAppDisplay.safeHeight * 0.67;
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
      _selectedPlayer1 = widget.modifyTeam!.fldPlayers[0];
      _selectedAvatarCodePlayer1 = _selectedPlayer1!.fldAvatar.fldAvatarCode;

      _selectedPlayer2 = widget.modifyTeam!.fldPlayers[1];
      _selectedAvatarCodePlayer2 = _selectedPlayer2!.fldAvatar.fldAvatarCode;

      // Auto-detect if it's a dummy team
      if (_selectedPlayer1 == _selectedPlayer2) {
        _isDummyTeam = true;
      }
    }
    else {
      _selectedAvatarCodePlayer1 = 'question';
      _selectedAvatarCodePlayer2 = 'question';
    }    
  }

  void _pickPlayer1(double avatarHeight) async {
    final player = await _showPlayerPicker(avatarHeight, excludePlayer: _selectedPlayer2);
    if (player != null) {
      setState(() {
        _selectedPlayer1 = player;
        _selectedAvatarCodePlayer1 = player.fldAvatar.fldAvatarCode;

        // Force-push Player 1 into Player 2 at all cost if Dummy Mode is active
        if (_isDummyTeam) {
          _selectedPlayer2 = player;
          _selectedAvatarCodePlayer2 = player.fldAvatar.fldAvatarCode;
        }
      });
    }
  }

  void _pickPlayer2(double avatarHeight) async {
    final player = await _showPlayerPicker(avatarHeight, excludePlayer: _selectedPlayer1);
    if (player != null) {
      setState(() {
        _selectedPlayer2 = player;
        _selectedAvatarCodePlayer2 = player.fldAvatar.fldAvatarCode;
      });
    }
  }

  void _saveTeam() {
    if (_selectedPlayer1 == null) {
      gShowArcadeErrorSnackBar(
        gContext: context,
        gFontSize: _responsiveFontSize,
        gMessage: 'PLEASE SELECT PLAYER 1!',
        gDuration: 2
      );
      return;
    }

    if (!_isDummyTeam) {
      if (_selectedPlayer2 == null) {
        gShowArcadeErrorSnackBar(
          gContext: context,
          gFontSize: _responsiveFontSize,
          gMessage: 'PLEASE SELECT PLAYER 2!',
          gDuration: 2
        );
        return;
      }
    }
    else{
      // Ensure player 2 mirrors player 1 if dummy mode is active
      _selectedPlayer2 = _selectedPlayer1;
      _selectedAvatarCodePlayer2 = _selectedAvatarCodePlayer1;
    }

    // 1. Prepare target player composition
    final List<TblPlayer> targetPlayers = [_selectedPlayer1!, _selectedPlayer2!];

    // 2. Check for existing active team duplicates in Hive
    final teamsBox = Hive.box<TblTeam>('teamsBox');

    final TblTeam? existingTeam = teamsBox.values.where((team) =>
      !team.fldIsDeleted &&
      ((team.fldPlayers[0] == targetPlayers[0] && team.fldPlayers[1] == targetPlayers[1]) ||
       (team.fldPlayers[0] == targetPlayers[1] && team.fldPlayers[1] == targetPlayers[0]))
    ).firstOrNull;

    //Verify self Match
    if (existingTeam != null) {
      bool isSelfMatch = false;
      if (widget.enuFormMode == FormMode.formModify && existingTeam == widget.modifyTeam) {
        isSelfMatch = true;
      }

      if (!isSelfMatch) {
        gShowArcadeErrorSnackBar(
          gContext: context,
          gFontSize: _responsiveFontSize,
          gMessage: 'THIS TEAM ALREADY EXISTS!',
          gDuration: 2
        );
        return;
      }
    }    

    // 3. Save to Hive database if everything is ok
    if (widget.enuFormMode == FormMode.formAdd) {
      final team = TblTeam(
        fldPlayers: targetPlayers,
        fldIsDeleted: false,
      );

      teamsBox.add(team);

      Navigator.pop(context, true);
    } else {
      if (widget.modifyTeam != null) {
        widget.modifyTeam!.fldPlayers = targetPlayers;
        widget.modifyTeam!.save();
      }

      Navigator.pop(context, false);
    }
  }

  void _deleteTeam() {
    String teamPlayer1Nickname = widget.modifyTeam!.fldPlayers[0].fldNickName.toUpperCase();
    String teamPlayer2Nickname = widget.modifyTeam!.fldPlayers[1].fldNickName.toUpperCase();

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.redAccent, width: (_responsiveTile * 0.002).clamp(1.5, 4.0)),
          ),
          title: Text(
            'DELETE THIS TEAM?',
            style: gBuildArcadeTextStyle(_responsiveFontSize * 1.4, gTextColor: Colors.redAccent),
          ),
          content: Text(
            'Are you sure you want to remove the team "$teamPlayer1Nickname & $teamPlayer2Nickname" ?',
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
                style: gBuildArcadeTextStyle(_responsiveFontSize * 0.90, gTextColor: Colors.grey.shade400),
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
                style: gBuildArcadeTextStyle(_responsiveFontSize * 0.90, gTextColor: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<TblPlayer?> _showPlayerPicker(double avatarHeight, {TblPlayer? excludePlayer}) async {
    final playersBox = Hive.box<TblPlayer>('playersBox');
    final List<TblPlayer> playerList = playersBox.values
      .where((player) => !player.fldIsDeleted && player != excludePlayer)
      .toList();
    
    return showModalBottomSheet<TblPlayer>(
      context: context,
      useSafeArea: true,
      backgroundColor: widget.enuSettingType.tileColor,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_responsiveTile * 0.037)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            width: GlobalAppDisplay.safeWidth * 0.775,
            height: _responsiveTile * 0.645,
            padding: EdgeInsets.symmetric(vertical: _responsiveTile * 0.006),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: _responsiveTile * 0.005),
                  padding: EdgeInsets.symmetric(vertical: _responsiveTile * 0.020),
                  decoration: BoxDecoration(
                    color: GlobalSettingType.teams.tilePickerColor,
                    border: Border.all(
                      color: Colors.white, // Or widget.tileColor / whatever border color you want
                      width: GlobalAppDisplay.safeHeight * 0.002,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_responsiveTile * 0.034), // Matches outer 20px sheet curve perfectly
                      bottom: Radius.zero,       // Sharp, edgy straight cut at the bottom
                    ),
                  ),
                  child: Text(
                    'SELECT A PLAYER',
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle((_responsiveFontSize * 0.70).clamp(10.0, 60.0)),
                  ),
                ),
                
                SizedBox(height: _responsiveTile * 0.022),
                
                SizedBox(
                  height: avatarHeight,
                  child: playerList.isEmpty
                    ? Center(
                        child: Text(
                          'No players found.',
                          style: gBuildArcadeTextStyle(
                            (_responsiveFontSize * 0.80).clamp(10.0, 60.0),
                          ),
                        ),
                      )
                    : CarouselView(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        itemExtent: avatarHeight + 4.0,
                        shrinkExtent: avatarHeight * 0.8,
                        // Native CarouselView callback receives the tapped item index directly
                        onTap: (int index) {
                          final selectedPlayer = playerList[index];
                          Navigator.pop(context, selectedPlayer);
                        },
                        children: playerList.map((player) {
                          return gBuildPlayerAvatarCard(
                            player: player,
                            avatarHeight: avatarHeight,
                            bgColor: widget.enuSettingType.tileBackgroundColor,
                            isSlicedAvatar: false,
                            );
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

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context); // Triggers re-render on resize

    //final ImageCardFrameConfig imageCardFrameConfig = getCarouselCardFrameImageConfig();
    final toolbarHeight = (GlobalAppDisplay.safeHeight * 0.10).clamp(56.0, 142.0);
    final avatarHeight = (GlobalAppDisplay.safeHeight - toolbarHeight) * 0.369;
    
    //temp cardWidth assignation
    double cardWidth = GlobalAppDisplay.safeWidth;
    if (_isDummyTeam){
      cardWidth = (GlobalAppDisplay.safeWidth - (avatarHeight * 2));
    }
    else{
      cardWidth = (GlobalAppDisplay.safeWidth - (avatarHeight * 2));
    }
    final cardHeight = cardWidth * 0.6836;
    
    return Scaffold(
      backgroundColor: widget.enuSettingType.tileBackgroundColor,
      appBar: 
        gBuildAppBar(
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
            // 1. TOP SEGMENTED TOGGLE BAR (Takes 2/13 - toolbarHeight of screen free space)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _responsiveTile * 0.06,
                vertical: _responsiveTile * 0.02,
              ),
              height: (GlobalAppDisplay.safeHeight-toolbarHeight) * (2/13),
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  // 1.1 Add Team Banner
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(
                          child: gBuildArcadeActionBanner(
                            gLeadingText: 'SAVE',
                            gTrailingText: 'TEAM',
                            gFormMode: FormMode.formAdd,
                            gOnTap: () => _saveTeam(),
                          ),
                        ),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isDummyTeam = !_isDummyTeam;
                                });

                                if (_isDummyTeam) {
                                  if (_selectedPlayer1 != null) {
                                    _selectedPlayer2 = _selectedPlayer1;
                                    _selectedAvatarCodePlayer2 = _selectedAvatarCodePlayer1;
                                  } else {
                                    _selectedPlayer2 = null;
                                    _selectedAvatarCodePlayer2 = 'question';
                                  }
                                  gShowArcadeErrorSnackBar(
                                    gContext: context,
                                    gFontSize: (GlobalAppDisplay.safeHeight * 0.015).clamp(10.0, 60.0),
                                    gMessage: 'DUMMY PLAYER MODE ACTIVATED',
                                    gDuration: 3,
                                    gBbackgroundColor: Color.fromRGBO(247, 120, 9, 1.0)
                                  );
                                } else {
                                  // Clear out Player 2 when exiting dummy mode
                                  _selectedPlayer2 = null;
                                  _selectedAvatarCodePlayer2 = 'question';
                                }
                              },
                              child: SizedBox(
                                width: GlobalAppDisplay.safeHeight * 0.105,
                                height: GlobalAppDisplay.safeHeight * 0.105,
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
                                        'assets/png/mechanics/player_dummy_icon.png',
                                        width: GlobalAppDisplay.safeHeight * 0.105,
                                        height: GlobalAppDisplay.safeHeight * 0.105,
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. TEAM FORM DISPLAY AREA (Takes 11/13 - toolbarHeight of screen free space)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(_responsiveTile * 0.047),
                child: 
                  // SIDE-BY-SIDE MAIN CONTAINER
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: 2 PLAYERS AVATAR PREVIEW & PICKER BUTTONS
                      Expanded(
                        flex: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              //mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // PLAYER 1 SLOT
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildPlayerAvatarMainUI(
                                      avatarHeight: avatarHeight,
                                      selectedAvatarCodePlayer: _selectedAvatarCodePlayer1,
                                      selectedPlayer: _selectedPlayer1,
                                      onTap: () => _pickPlayer1(avatarHeight),
                                    ),
                                
                                    SizedBox(height: _responsiveTile * 0.022),
                              
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () => _pickPlayer1(avatarHeight),
                                        child: Container(
                                          padding: EdgeInsets.only(
                                            left: _responsiveTile * 0.034,
                                            right: _responsiveTile * 0.034,
                                            top: _responsiveTile * 0.012,
                                            bottom: _responsiveTile * 0.012,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.enuSettingType.tileColor,
                                            borderRadius: BorderRadius.circular(_responsiveTile * 0.08),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: (_responsiveTile * 0.006).clamp(1.5, 4.0),
                                            ),
                                          ),
                                          child: Text(
                                            'SELECT\nPLAYER 1',
                                            textAlign: TextAlign.center,
                                            style: gBuildArcadeTextStyle(
                                              (_responsiveFontSize * 0.70).clamp(7.0, 60.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(width: _responsiveTile * 0.022),

                                // PLAYER 2 SLOT
                                AbsorbPointer(
                                  absorbing: _isDummyTeam,
                                  child: Opacity(
                                    opacity: _isDummyTeam ? 0.45 : 1.0,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildPlayerAvatarMainUI(
                                          avatarHeight: avatarHeight,
                                          selectedAvatarCodePlayer: _selectedAvatarCodePlayer2,
                                          selectedPlayer: _selectedPlayer2,
                                          onTap: () => _pickPlayer2(avatarHeight),
                                        ),
                                    
                                        SizedBox(height: _responsiveTile * 0.022),
                                  
                                        MouseRegion(
                                          cursor: _isDummyTeam ? SystemMouseCursors.basic : SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: _isDummyTeam ? null : () => _pickPlayer2(avatarHeight),
                                            child: Container(
                                              padding: EdgeInsets.only(
                                              left: _responsiveTile * 0.034,
                                              right: _responsiveTile * 0.034,
                                              top: _responsiveTile * 0.012,
                                              bottom: _responsiveTile * 0.012,
                                            ),
                                            decoration: BoxDecoration(
                                              color: widget.enuSettingType.tileColor,
                                              borderRadius: BorderRadius.circular(_responsiveTile * 0.08),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: (_responsiveTile * 0.006).clamp(1.5, 4.0),
                                              ),
                                            ),
                                            child: Text(
                                              'SELECT\nPLAYER 2',
                                              textAlign: TextAlign.center,
                                              style: gBuildArcadeTextStyle(
                                                (_responsiveFontSize * 0.70).clamp(7.0, 60.0),
                                              ),
                                            ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: _responsiveTile * 0.08),
                      
                      Container(
                        padding: EdgeInsets.symmetric(vertical: _responsiveTile * 0.006, horizontal: _responsiveTile * 0.004),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(_responsiveTile * 0.096), // Pill shape
                          border: Border.all(
                            color: Colors.white,
                            width: _responsiveTile * 0.004,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(_responsiveTile * 0.096),
                          child: SizedBox(
                            width: _responsiveTile * 0.01,
                            height: _responsiveTile * 0.75,
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: LinearProgressIndicator(
                                value: 1,
                                backgroundColor: Colors.transparent,
                                color: widget.enuSettingType.tileColor,
                                minHeight: _responsiveTile * 0.0077,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: _responsiveTile * 0.08),

                      // RIGHT COLUMN: AVATAR PREVIEW & PICKER BUTTON
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: gBuildTeamCardH(
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                selectedPlayer1: _selectedPlayer1,
                                selectedPlayer2: _selectedPlayer2,
                                isDummyTeam: _isDummyTeam,
                                colorBgAvatar: widget.enuSettingType.tileColor,
                                isSlicedCard: false,
                              ),
                            ),
                            
                            // Delete Team button
                            if (widget.enuFormMode == FormMode.formModify &&
                              widget.modifyTeam != null) ...[
                                
                                SizedBox(height: _responsiveTile * 0.02),
                            
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _deleteTeam,
                                    child: Container(
                                      padding: EdgeInsets.only(
                                        left: _responsiveTile * 0.014,
                                        right: _responsiveTile * 0.034,
                                        top: _responsiveTile * 0.008,
                                        bottom: _responsiveTile * 0.008,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade800,
                                        borderRadius: BorderRadius.circular(_responsiveTile * 0.08),
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
                                            width: (_responsiveTile * 0.13).clamp(32.0, 160.0),
                                            height: (_responsiveTile * 0.13).clamp(32.0, 160.0),
                                            fit: BoxFit.contain,
                                          ),
                                          //const SizedBox(width: 2),
                                          Text(
                                            'DELETE THIS TEAM',
                                            style: gBuildArcadeTextStyle(
                                              (_responsiveFontSize * 0.80).clamp(7.0, 60.0),
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
                    ],
                  ),
              ),
            ),
          ]
        ),
      ),
    );
  }

  Widget _buildPlayerAvatarMainUI({
    required double avatarHeight,
    required String selectedAvatarCodePlayer,
    required TblPlayer? selectedPlayer,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: avatarHeight,
          height: avatarHeight,
          child: Stack(
            children: [
              // 1. Solid Color Circle (Bottom-most layer behind the avatar)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.enuSettingType.tileColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // 2. Avatar Artwork (Transparent PNG)
              Positioned.fill(
                child: Image.asset(
                  'assets/png/avatars/avatar_${selectedAvatarCodePlayer}_v1.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // 3. Metallic Frame Overlay (Top-most layer)
              Positioned.fill(
                child: Image.asset(
                  'assets/png/mechanics/player_avatar.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
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
                        horizontal: avatarHeight * 0.045,
                        vertical: avatarHeight * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(avatarHeight * 0.04),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: avatarHeight * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selectedPlayer.fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(
                            avatarHeight * 0.062,
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