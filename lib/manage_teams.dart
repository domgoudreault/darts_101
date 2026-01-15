import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:darts_101/modify_add_team.dart';
import 'package:darts_101/database/player.dart';
import 'package:darts_101/database/team.dart';

class ManageTeams extends StatelessWidget {
  // Define variables to hold the data passed from the previous screen
  final String tileText;
  final Color tileColor;
  final Color tileBackgroundColor;

  const ManageTeams({
    super.key,
    required this.tileText,
    required this.tileColor,
    required this.tileBackgroundColor,  
  });

  // Fonction de navigation when a button is pressed
  void _addTeam(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // The add_player.dart page will be created and shown
        builder: (context) => ModifyAddTeamForm(
          enuFormMode: FormMode.formAdd,         
        ),
      ),
    );
  }

  // Fonction de navigation when a button is pressed
  void _modifyTeam(BuildContext context, Team team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // The add_player.dart page will be created and shown
        builder: (context) => ModifyAddTeamForm(
          enuFormMode: FormMode.formModify,
          modifyTeam: team,         
        ),
      ),
    );
  }

  void _deleteTeam(Team team) {
    team.deleted = true;
    team.save();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Access the box you opened in main.dart
    final teamsBox = Hive.box<Team>('teamsBox');
    final playersBox = Hive.box<Player>('playersBox');   

    return Scaffold(
      //pour le background color en bas du titre et pour le reste de la page
      backgroundColor: tileBackgroundColor,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: tileColor,
        
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
                  'assets/png/darts_101_logo_48x48.png', // Replace with your image path (PNG, JPG, or SVG)
                  fit: BoxFit.contain, // Ensures the image fits within the box
                ),
              ),
            ),
            // pour le titre de la tuile
            Text(
              tileText,              
              style: const TextStyle(color: Colors.white),
            ),
          ]          
        ),
      ),
      body: Column(
        children: [                    
          // construit la liste des joueurs         
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: teamsBox.listenable(),
              builder: (context, Box<Team> box, _) {
                final teams = box.values.where((team) => team.deleted == false).toList();

                if (teams.isEmpty) {
                  return const Center(
                    child: Text(
                      "No teams in database.",
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
                            "Number of Teams: ${teams.length}",
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final Team team = teams[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            child: ListTile(
                              leading: team.idPlayer1 == team.idPlayer2 ? Image.asset('assets/png/dummy_24x24.png') : Image.asset('assets/png/darts_team_24x24.png'),
                              visualDensity: VisualDensity(vertical: -4),
                              title: Text(team.surName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                team.idPlayer1 == team.idPlayer2 ? "${playersBox.get(team.idPlayer1)?.nickName}, ${playersBox.get(team.idPlayer2)?.nickName} (Dummy)" : "${playersBox.get(team.idPlayer1)?.nickName}, ${playersBox.get(team.idPlayer2)?.nickName}", 
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),                              
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.red.shade400,
                                    child: IconButton(
                                      icon: Image.asset('assets/png/edit_24x24.png'),                            
                                      hoverColor: Colors.red.shade400,
                                      highlightColor: Colors.red.shade400,                            
                                      onPressed: () => _modifyTeam(context, team),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.red.shade400,
                                    child: IconButton(
                                      icon: Image.asset('assets/png/garbage_24x24.png'),                            
                                      hoverColor: Colors.red.shade400,
                                      highlightColor: Colors.red.shade400,                            
                                      onPressed: () => _deleteTeam(team),
                                    ),
                                  ),
                                ]
                              ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red.shade900,
        onPressed: () => _addTeam(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0), 
          child: Image.asset(
            'assets/png/add2_36x36.png',            
          ),
        ),
      ),
    );
  }  
}