import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

enum FormMode{
  formAdd,
  formModify
}

enum TextType{
  title,
  button,
  icon
}

class ModifyAddTeamForm extends StatefulWidget {  
  final FormMode enuFormMode;
  final TblTeam? modifyTeam;

  const ModifyAddTeamForm({
    super.key,
    required this.enuFormMode,
    this.modifyTeam,
  });  

  @override
  // ignore: library_private_types_in_public_api
  _ModifyAddTeamFormState createState() => _ModifyAddTeamFormState();
}

class _ModifyAddTeamFormState extends State<ModifyAddTeamForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to retrieve text values
  final _surNameController = TextEditingController();

  // To track if Dummy Mode is activated
  bool _isSoloPlayer = false;

  // Track selected IDs here
  List<TblPlayer> _selectedPlayers = [];

  // 2. Clean up controllers when the widget is destroyed
  @override
  void dispose() {
    _surNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // If we are modifying, fill the controllers with existing data
    if (widget.enuFormMode == FormMode.formModify && widget.modifyTeam != null) {
      _surNameController.text = widget.modifyTeam!.fldSurName;      
    }
  }

  String _getTextByMode(TextType textType) {
    final isAdd = widget.enuFormMode == FormMode.formAdd;

    switch (textType){
      case TextType.title:  return isAdd ? 'Add a team' : 'Modify a team';
      case TextType.button: return isAdd ? 'Add Team' : 'Modify Team';
      case TextType.icon:   return isAdd ? 'assets/png/add2_36x36.png' : 'assets/png/edit_24x24.png';
    }    
  }

  void _saveTeam() {
    if (_formKey.currentState!.validate()) {      
      // Get the playersBox from Hive
      final teamsBox = Hive.box<TblTeam>('teamsBox');

      if (widget.enuFormMode == FormMode.formAdd){
        if (!_isSoloPlayer && _selectedPlayers.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least two players or use Dummy Mode.')),
          );
          return;
        }
        
        // Create the player object
        final team = TblTeam(
          fldPlayers: [_selectedPlayers[0], _isSoloPlayer ? _selectedPlayers[0] : _selectedPlayers[1]],
          fldSurName: _surNameController.text.trim(),
          fldIsDeleted: false,
        );

        // Add to Hive        
        teamsBox.add(team);        

      } else {
          widget.modifyTeam?.fldSurName = _surNameController.text.trim();          

          // Save to Hive        
          widget.modifyTeam?.save();
      }
            
      // Return to previous screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Access the box you opened in main.dart
    final playersBox = Hive.box<TblPlayer>('playersBox');

    return Scaffold(
      //pour le background color en bas du titre et pour le reste de la page
      backgroundColor: Colors.red.shade400,
      appBar: AppBar(        
        foregroundColor: Colors.white,
        backgroundColor: Colors.red.shade900,
        
        // pour le titre et l'icone de l'Application        
        title: Row (
          children: [
            // pour l'icone de l'Application
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 48.0,
                height: 48.0,
                child: Image.asset(
                  'assets/png/logos/darts_101_logo_48x48.png', // Replace with your image path (PNG, JPG, or SVG)
                  fit: BoxFit.contain, // Ensures the image fits within the box
                ),
              ),
            ),
            // pour le titre de la tuile
            Text(
              _getTextByMode(TextType.title),              
              style: const TextStyle(color: Colors.white),
            ),
          ]          
        ),
      ),
      body: Column(
        children: [                    
          Form (
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTextField(_surNameController, 'Team Name'),                  
                  const SizedBox(height: 20),
                  FloatingActionButton.extended(
                    backgroundColor: Colors.red.shade900,
                    label: Text(_getTextByMode(TextType.button), style: const TextStyle(color: Colors.white)),
                    icon: Image.asset(_getTextByMode(TextType.icon)),
                    onPressed: _saveTeam,               
                  ),
                ],
              ),
            ),
          ),
          
          if (widget.enuFormMode == FormMode.formAdd)
            // construit la liste des joueurs         
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: playersBox.listenable(),
                builder: (context, Box<TblPlayer> box, _) {
                  final players = box.values.where((player) => player.fldIsDeleted == false).toList();

                  if (players.isEmpty) {
                    return const Center(
                      child: Text(
                        "No players in database.",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      )
                    );
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0, right: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Dummy Mode: ${_isSoloPlayer ? 'ON' : 'OFF'}",
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final player = players[index];
                            final bool isSelected = _selectedPlayers.contains(player);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: CheckboxListTile(
                                // This moves the checkbox to the left
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: Colors.red.shade900,
                                value: isSelected,
                                secondary: isSelected 
                                  ? Container(
                                      decoration: BoxDecoration(
                                        // Changes background color based on Solo Mode state
                                        color: _isSoloPlayer ? Colors.green.shade300 : Colors.grey.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Image.asset(
                                          'assets/png/dummy_24x24.png',                                          
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isSoloPlayer = !_isSoloPlayer;
                                            if (_isSoloPlayer) {
                                              // clean the players list and add twice the same player
                                              _selectedPlayers = [];
                                              _selectedPlayers.add(player);
                                              // Optional: Clear any error snackbars
                                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                            }
                                          });
                                        },
                                        tooltip: "Play twice",
                                      )
                                    )
                                  : null,                                

                                title: Row (
                                  children: [
                                    Image.asset('assets/png/darts_player_24x24.png'),
                                    const SizedBox(width: 12),                                  
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player.fldNickName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "${player.fldFirstName} ${player.fldLastName}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]
                                ),

                                onChanged: (bool? checked) {
                                  setState(() {
                                    if (checked == true) {
                                      // Limit to 2 players for a team
                                      if (_selectedPlayers.length < 2) {
                                        _selectedPlayers.add(player);
                                      } else {                                        
                                        // Show a SnackBar saying "Max 2 players"
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Clear previous
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('A team consists of maximum 2 players.')),
                                        );
                                      }
                                    } else {
                                      _selectedPlayers.remove(player);
                                    }
                                    if (_selectedPlayers.length != 1) {
                                      //remove the dummy mode
                                      _isSoloPlayer = false;
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,      
      textCapitalization: TextCapitalization.words,
      // Improves UX: Shows "Next" on keyboard until the last field
      textInputAction: label == 'Team Name' ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label, 
        filled: true,
        fillColor: Colors.white,
        border:  UnderlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if ((label == 'Team Name') && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}

