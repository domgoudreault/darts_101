import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:darts_101/modify_add_player.dart';
import 'package:darts_101/database/player.dart';

class ManagePlayers extends StatelessWidget {
  // Define variables to hold the data passed from the previous screen
  final String tileText;
  final Color tileColor;
  final Color tileBackgroundColor;

  const ManagePlayers({
    super.key,
    required this.tileText,
    required this.tileColor,
    required this.tileBackgroundColor,
  });

  // Fonction de navigation when a button is pressed
  void _addPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // The add_player.dart page will be created and shown
        builder: (context) => ModifyAddPlayerForm(
          enuFormMode: FormMode.formAdd,          
        ),
      ),
    );
  }

  // Fonction de navigation when a button is pressed
  void _modifyPlayer(BuildContext context, Player player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // The add_player.dart page will be created and shown
        builder: (context) => ModifyAddPlayerForm(
          enuFormMode: FormMode.formModify,
          modifyPlayer: player,         
        ),
      ),
    );
  }

  void _deletePlayer(Player player) {
    player.deleted = true;
    player.save();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Access the box you opened in main.dart
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
              valueListenable: playersBox.listenable(),
              builder: (context, Box<Player> box, _) {
                final players = box.values.where((player) => player.deleted == false).toList();

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
                            "Number of Players: ${players.length}",
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final Player player = players[index];
                          return Card(                            
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            child: ListTile(
                              leading: Image.asset('assets/png/darts_player_24x24.png'),
                              visualDensity: VisualDensity(vertical: -4),
                              title: Text(player.nickName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: Text("${player.firstName} ${player.lastName}", style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),                              
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.deepOrange.shade200,
                                    child: IconButton(
                                      icon: Image.asset('assets/png/edit_24x24.png'),                            
                                      hoverColor: Colors.deepOrange.shade200,
                                      highlightColor: Colors.deepOrange.shade200,                            
                                      onPressed: () => _modifyPlayer(context, player),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.deepOrange.shade200,
                                    child: IconButton(
                                      icon: Image.asset('assets/png/garbage_24x24.png'),                            
                                      hoverColor: Colors.deepOrange.shade200,
                                      highlightColor: Colors.deepOrange.shade200,                            
                                      onPressed: () => _deletePlayer(player),
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
        backgroundColor: Colors.deepOrange.shade400,
        onPressed: () => _addPlayer(context),
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