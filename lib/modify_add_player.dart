// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_avatar.dart';
import 'package:darts_101/database/tbl_player.dart';

// Backend Logic
import 'package:darts_101/modify_add_player_be.dart';

enum FormMode{
  formAdd,
  formModify
}

enum TextType{
  title,
  button,
  icon
}

class ModifyAddPlayerForm extends StatefulWidget {  
  final FormMode enuFormMode;
  final TblPlayer? modifyPlayer;
  final Color tileColor;
  final Color tileBackgroundColor;

  const ModifyAddPlayerForm({
    super.key,
    required this.enuFormMode,
    this.modifyPlayer,
    required this.tileColor,
    required this.tileBackgroundColor,
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

  String _getTextByMode(TextType textType) {
    final isAdd = widget.enuFormMode == FormMode.formAdd;

    switch (textType){
      case TextType.title:  return isAdd ? 'Add a player' : 'Modify a player';
      case TextType.button: return isAdd ? 'Add Player' : 'Modify Player';
      case TextType.icon:   return isAdd ? 'assets/png/ui_buttons/player_team_add_36x36.png' : 'assets/png/ui_buttons/player_team_edit_24x24.png';
    }    
  }

  void _savePlayer() {
    if (_formKey.currentState!.validate()) {      
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

      } else {
          widget.modifyPlayer?.fldFirstName = _firstNameController.text.trim();
          widget.modifyPlayer?.fldLastName = _lastNameController.text.trim();
          widget.modifyPlayer?.fldNickName = _nickNameController.text.trim();
          widget.modifyPlayer?.fldAvatarCode = _selectedAvatarCode;

          // Save to Hive        
          widget.modifyPlayer?.save();
      }
            
      // Return to previous screen
      Navigator.pop(context);
    }
  }

  void _showAvatarPicker() {
    final avatarsBox = Hive.box<TblAvatar>('avatarsBox');
    final List<TblAvatar> avatarList = avatarsBox.values
      .where((avatar) => avatar.fldAvatarCode != 'question')
      .toList();
    final ImageConfig pickerConfig = getAvatarFramePickerImageConfig();

    showModalBottomSheet(
      context: context,
      backgroundColor: widget.tileColor,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final double screenWidth = MediaQuery.sizeOf(context).width;

        return Container(
          width: screenWidth * 0.8,
          height: pickerConfig.renderSize + 80.0, // Scales sheet height dynamically with picker size
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              const Text(
                'Select Avatar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: CarouselView(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  itemExtent: pickerConfig.renderSize + 16.0,
                  shrinkExtent: pickerConfig.renderSize * 0.8,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context); // Triggers re-render on resize

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
            Text(
              _getTextByMode(TextType.title),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // SIDE-BY-SIDE MAIN CONTAINER
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: TEXT FIELDS
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField(_firstNameController, 'First Name'),
                        const SizedBox(height: 12),
                        _buildTextField(_lastNameController, 'Last Name'),
                        const SizedBox(height: 12),
                        _buildTextField(_nickNameController, 'Nickname'),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24), // Spacing between columns

                  // RIGHT COLUMN: AVATAR PREVIEW & PICKER BUTTON
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAvatarMainUI(),
                        const SizedBox(height: 12),
                        // Trigger button for the upcoming avatar picker dialog/pop-up
                        ElevatedButton.icon(
                          onPressed: _showAvatarPicker,
                          icon: const Icon(Icons.style, color: Colors.white),
                          label: const Text(
                            'Select Avatar',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.tileColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // MAIN SAVE ACTION BUTTON
              FloatingActionButton.extended(
                backgroundColor: widget.tileColor,
                label: Text(
                  _getTextByMode(TextType.button),
                  style: const TextStyle(color: Colors.white),
                ),
                icon: Image.asset(_getTextByMode(TextType.icon)),
                onPressed: _savePlayer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,      
      textCapitalization: TextCapitalization.words,
      // Improves UX: Shows "Next" on keyboard until the last field
      textInputAction: label == 'Nickname' ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label, 
        filled: true,
        fillColor: Colors.white,
        border:  UnderlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if ((label == 'Nickname') && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Widget _buildAvatarMainUI() {
    final ImageConfig frameImageConfig = getAvatarFrameMainImageConfig();
    final ImageConfig playerImageConfig = getAvatarPlayerMainImageConfig(_selectedAvatarCode);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showAvatarPicker,
        child: SizedBox(
          width: frameImageConfig.renderSize,
          height: frameImageConfig.renderSize,
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
                  playerImageConfig.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // 3. Metallic Frame Overlay (Top-most layer)
              Positioned.fill(
                child: Image.asset(
                  frameImageConfig.assetPath,
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
    final ImageConfig frameImageConfig = getAvatarFramePickerImageConfig();
    final ImageConfig playerImageConfig = getAvatarPlayerPickerImageConfig(avatar.fldAvatarCode);

    return SizedBox(
      width: frameImageConfig.renderSize,
      height: frameImageConfig.renderSize,
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
              playerImageConfig.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),

          // 3. Metallic Frame Overlay
          Positioned.fill(
            child: Image.asset(
              frameImageConfig.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}