// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Database Models
import 'package:darts_101/database/tbl_avatar.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_assets.dart';

class ModifyAddPlayerForm extends StatefulWidget {  
  final FormMode enuFormMode;
  final TblPlayer? modifyPlayer;
  final GlobalSettingType enuSettingType;

  const ModifyAddPlayerForm({
    super.key,
    required this.enuFormMode,
    this.modifyPlayer,
    required this.enuSettingType,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ModifyAddPlayerFormState createState() => _ModifyAddPlayerFormState();
}

class _ModifyAddPlayerFormState extends State<ModifyAddPlayerForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to retrieve text values
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nickNameController = TextEditingController();

  late String _selectedAvatarCode;

  double get _responsiveTile => GlobalAppDisplay.carouselTileSize;
  double get _responsiveFontSize => (_responsiveTile * 0.035).clamp(10.0, 60.0);

  // 2. Clean up controllers when the widget is destroyed
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nickNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // If we are modifying, fill the controllers with existing data
    if (widget.enuFormMode == FormMode.formModify && widget.modifyPlayer != null) {
      _firstNameController.text = widget.modifyPlayer!.fldFirstName;
      _lastNameController.text = widget.modifyPlayer!.fldLastName;
      _nickNameController.text = widget.modifyPlayer!.fldNickName;
      _selectedAvatarCode = widget.modifyPlayer!.fldAvatarCode;
    }
    else {
      _selectedAvatarCode = 'question';
    }    
  }

  void _savePlayer() {
    // 1. Check if an avatar was selected (block if still placeholder 'question')
    if (_selectedAvatarCode == 'question') {
      gShowArcadeErrorSnackBar(
        gContext: context, 
        gFontSize: (_responsiveFontSize * 0.70).clamp(10.0, 60.0), 
        gMessage: 'PLEASE SELECT AN AVATAR!',
        gDuration: 2
      );
      return;
    }

    // 2. Validate form fields
    if (_nickNameController.text.trim().isEmpty) {
      gShowArcadeErrorSnackBar(
        gContext: context, 
        gMessage: 'NICKNAME IS REQUIRED!', 
        gFontSize: _responsiveFontSize,
        gDuration: 2
      );
      return;
    }

    // 3. Validate duplicate nickname in Hive Database
    final Iterable<TblPlayer> activePlayers;

    if (widget.enuFormMode == FormMode.formAdd) {
      activePlayers = Hive.box<TblPlayer>('playersBox').values
        .where((player) => !player.fldIsDeleted);
    } else {
      activePlayers = Hive.box<TblPlayer>('playersBox').values
        .where((player) => !player.fldIsDeleted && player.key != widget.modifyPlayer?.key);
    }
    
    final bool isDuplicateNickName = activePlayers.any(
      (player) => player.fldNickName.trim().toLowerCase() == _nickNameController.text.trim().toLowerCase(),
    );

    if (isDuplicateNickName) {
      gShowArcadeErrorSnackBar(
        gContext: context, 
        gMessage: 'NICKNAME ALREADY EXISTS!', 
        gFontSize: _responsiveFontSize,
        gDuration: 2
      );
      return;
    }

    // 4. Save to Hive database if everything is ok
    // Get the playersBox from Hive
    final playersBox = Hive.box<TblPlayer>('playersBox');

    if (widget.enuFormMode == FormMode.formAdd){
      // Create the player object
      final player = TblPlayer(
        fldFirstName: _firstNameController.text.trim(),
        fldLastName: _lastNameController.text.trim(),
        fldNickName: _nickNameController.text.trim(),
        fldIsDeleted: false,
        fldIsLeagueMember: false,
        fldAvatarCode: _selectedAvatarCode,
      );

      // Add to Hive        
      playersBox.add(player);
      
      // Return to previous screen
      Navigator.pop(context, true);    

    } else {
        widget.modifyPlayer?.fldFirstName = _firstNameController.text.trim();
        widget.modifyPlayer?.fldLastName = _lastNameController.text.trim();
        widget.modifyPlayer?.fldNickName = _nickNameController.text.trim();
        widget.modifyPlayer?.fldAvatarCode = _selectedAvatarCode;

        // Save to Hive        
        widget.modifyPlayer?.save();

        // Return to previous screen
        Navigator.pop(context, false);
    }
  }

  void _deletePlayer() {
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
            'DELETE THIS PLAYER?',
            style: gBuildArcadeTextStyle(_responsiveFontSize * 1.4, gTextColor: Colors.redAccent),
          ),
          content: Text(
            'Are you sure you want to remove ${_nickNameController.text}?',
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
                // 1. Soft delete the player
                final player = widget.modifyPlayer;
                if (player != null) {
                  player.fldIsDeleted = true;
                  player.save();

                  // 2. Cascade delete: Soft-delete all teams containing this player
                  final teamsBox = Hive.box<TblTeam>('teamsBox');
                  for (final team in teamsBox.values) {
                    if (!team.fldIsDeleted && team.fldPlayers.contains(player)) {
                      team.fldIsDeleted = true;
                      team.save();
                    }
                  }
                }

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

  void _showAvatarPicker() {
    final avatarsBox = Hive.box<TblAvatar>('avatarsBox');
    final List<TblAvatar> avatarList = avatarsBox.values
      .where((avatar) => avatar.fldAvatarCode != 'question')
      .toList();
    final ImageConfigAvatar avatarFrameImageConfig = gGetAvatarFrameImageConfig();

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: widget.enuSettingType.tileColor,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            width: GlobalAppDisplay.safeWidth * 0.775,
            height: (avatarFrameImageConfig.renderSize + 80.0).clamp(0.0, GlobalAppDisplay.safeHeight * 0.9),
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: GlobalSettingType.players.tilePickerColor,
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
                    'SELECT AN AVATAR',
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
                      final selectedAvatar = avatarList[index];
                      setState(() {
                        _selectedAvatarCode = selectedAvatar.fldAvatarCode;
                      });
                      Navigator.pop(context);
                    },
                    children: avatarList.map((avatar) {
                      return Center(
                        child: _buildAvatarPicker(
                          avatar: avatar,
                        ),
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

    return Scaffold(
      backgroundColor: widget.enuSettingType.tileBackgroundColor,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: widget.enuSettingType.tileColor,
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
            Text(widget.enuFormMode == FormMode.formAdd ? 'Add a player' : 'Modify a player', style: gBuildArcadeTextStyle(20)),
          ],
        ),
      ),
      
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP SEGMENTED TOGGLE BAR (Reserved for sub-filters if needed)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: GlobalAppDisplay.carouselTileSize * 0.06,
                vertical: GlobalAppDisplay.carouselTileSize * 0.02,
              ),
              color: Colors.grey.shade900,
              child: 
                // 1.1 Save Player Banner
                gBuildArcadeActionBanner(
                  gLeadingText: 'SAVE',
                  gTrailingText: 'PLAYER',
                  gFormMode: FormMode.formModify,
                  gOnTap: () => _savePlayer(),
                ),
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: 
                    // SIDE-BY-SIDE MAIN CONTAINER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT COLUMN: AVATAR PREVIEW & PICKER BUTTON
                        Expanded(
                          flex: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildAvatarMainUI(),
                                  const SizedBox(height: 12),
                                  // Trigger button for the upcoming avatar picker dialog/pop-up
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _showAvatarPicker,
                                      child: Container(                                        
                                        padding: EdgeInsets.symmetric(
                                          horizontal: (_responsiveTile * 0.02).clamp(8.0, 24.0),
                                          vertical: (_responsiveTile * 0.015).clamp(6.0, 20.0),
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.enuSettingType.tileColor,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: (_responsiveTile * 0.006).clamp(1.5, 4.0),
                                          ),
                                        ),
                                        child: Text(
                                          'SELECT AVATAR', 
                                          style: gBuildArcadeTextStyle((_responsiveFontSize * 0.70).clamp(10.0, 60.0))
                                        ),
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
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(50.0), // Pill shape
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50.0),
                            child: SizedBox(
                              width: _responsiveTile * 0.01,
                              height: _responsiveTile * 0.75,
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: LinearProgressIndicator(
                                  value: 1,
                                  backgroundColor: Colors.transparent,
                                  color: widget.enuSettingType.tileColor,
                                  minHeight: 4.0,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: _responsiveTile * 0.08),

                        // RIGHT COLUMN: TEXT FIELDS
                        Expanded(
                          child: Column(
                            children: [
                              _buildTextField(_firstNameController, 'First Name'),
                              const SizedBox(height: 12),
                              _buildTextField(_lastNameController, 'Last Name'),
                              const SizedBox(height: 12),
                              _buildTextField(_nickNameController, 'Nickname'),

                              // DELETE PLAYER BUTTON
                              if (widget.enuFormMode == FormMode.formModify &&
                                    widget.modifyPlayer != null &&
                                    !widget.modifyPlayer!.fldIsLeagueMember) ...[
                                
                                SizedBox(height: _responsiveTile * 0.10),

                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _deletePlayer,
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
                                            'DELETE THIS PLAYER',
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
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    bool isFocused = false;

    return SizedBox(
      height: (_responsiveTile * 0.12).clamp(40.0, 200.0),
      child: StatefulBuilder(
        builder: (context, setState) {
          return Focus(
            onFocusChange: (hasFocus) {
              setState(() {
                isFocused = hasFocus;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _responsiveTile * 0.045,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(_responsiveTile * 0.04),
                border: Border.all(
                  color: isFocused ? Colors.purpleAccent.shade700 : Colors.grey.shade700,
                  width: isFocused ? (_responsiveTile * 0.008).clamp(2.0, 4.0) : 1.5,
                ),
              ),
              child: TextFormField(
                controller: controller,
                style: gBuildArcadeTextStyle(_responsiveFontSize),
                textCapitalization: TextCapitalization.words,
                textInputAction: label == 'Nickname' ? TextInputAction.done : TextInputAction.next,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: label,
                  labelStyle: gBuildArcadeTextStyle(
                    (_responsiveFontSize * 0.70).clamp(10.0, 60.0),
                    gTextColor: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: _responsiveTile * 0.02,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarMainUI() {
    final ImageConfigAvatar avatarFrameImageConfig = gGetAvatarFrameImageConfig();
    final ImageConfigAvatar avatarPlayerImageConfig = gGetAvatarPlayerImageConfig(_selectedAvatarCode);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showAvatarPicker,
        child: SizedBox(
          width: avatarFrameImageConfig.renderSize,
          height: avatarFrameImageConfig.renderSize,
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
                  avatarPlayerImageConfig.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // 3. Metallic Frame Overlay (Top-most layer)
              Positioned.fill(
                child: Image.asset(
                  avatarFrameImageConfig.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker({
    required TblAvatar avatar,
  }) {
    final ImageConfigAvatar avatarFrameImageConfig = gGetAvatarFrameImageConfig();
    final ImageConfigAvatar avatarPlayerImageConfig = gGetAvatarPlayerImageConfig(avatar.fldAvatarCode);

    return SizedBox(
      width: avatarFrameImageConfig.renderSize,
      height: avatarFrameImageConfig.renderSize,
      child: Stack(
        children: [
          // 1. Dynamic Circle Background Layer
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: avatar.fldIsMale ? Colors.blue.shade200 : Colors.pink.shade200,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Avatar Artwork
          Positioned.fill(
            child: Image.asset(
              avatarPlayerImageConfig.assetPath,
              fit: BoxFit.contain,
              //filterQuality: FilterQuality.none,
            ),
          ),

          // 3. Metallic Frame Overlay
          Positioned.fill(
            child: Image.asset(
              avatarFrameImageConfig.assetPath,
              fit: BoxFit.contain,
              //filterQuality: FilterQuality.none,
            ),
          ),
        ],
      ),
    );
  }
}