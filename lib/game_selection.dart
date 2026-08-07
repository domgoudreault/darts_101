import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:darts_101/game_halfit.dart';
import 'package:darts_101/game_build_up.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
import 'package:darts_101/database/tbl_game.dart';

enum GameMode{
  gamePlayers,
  gameTeams
}

enum GameType{
  gameHalfIt,
  gameBuildUp
}

enum TextType{
  title,
  subtitle,
  icon
}

class GameSelection extends StatefulWidget {
  // Define variables to hold the data passed from the previous screen
  final String tileType;
  final Color tileColor;
  final Color tileBackgroundColor;
  final String tileDescription;
  final GameMode enuGameMode;
  final GameType enuGameType;

  const GameSelection({
    super.key,
    required this.tileType,
    required this.tileColor,
    required this.tileBackgroundColor,
    required this.tileDescription,
    required this.enuGameMode,
    required this.enuGameType,
  });

  @override
  State<GameSelection> createState() => _GameSelectionState();
}

class _GameSelectionState extends State<GameSelection> {  
  final List<int> _selectedIds = [];
  int? _highlightedId;
  bool _isHighlightInTop = false;

  // Access boxes
  late Box<TblPlayer> playersBox;
  late Box<TblTeam> teamsBox;

  @override
  void initState() {
    super.initState();
    playersBox = Hive.box<TblPlayer>('playersBox');
    teamsBox = Hive.box<TblTeam>('teamsBox');
  }

  Set<TblPlayer> _getBusyPlayers() {
    final busyPlayers = <TblPlayer>{};
    for (int teamId in _selectedIds) {
      final team = teamsBox.get(teamId);
      if (team != null) {
        busyPlayers.add(team.fldPlayers[0]);
        busyPlayers.add(team.fldPlayers[1]);
      }
    }
    return busyPlayers;
  }

  String _getTextByMode(TextType textType, int id) {        
    if (widget.enuGameMode == GameMode.gamePlayers) {
      switch (textType){
        case TextType.title: return playersBox.get(id)!.fldNickName;
        case TextType.subtitle: return '${playersBox.get(id)!.fldFirstName} ${playersBox.get(id)!.fldLastName}';
        case TextType.icon: return 'assets/png/darts_player_24x24.png';
      }
    } else {
      switch (textType){
        case TextType.title: return teamsBox.get(id)!.fldSurName;
        case TextType.subtitle:
          if (teamsBox.get(id)!.fldPlayers[0] == teamsBox.get(id)!.fldPlayers[1]) {
            return '${playersBox.get(teamsBox.get(id)!.fldPlayers[0])?.fldNickName}, ${playersBox.get(teamsBox.get(id)!.fldPlayers[1])?.fldNickName} (Dummy)';
          } else {
            return '${playersBox.get(teamsBox.get(id)!.fldPlayers[0])?.fldNickName}, ${playersBox.get(teamsBox.get(id)!.fldPlayers[1])?.fldNickName}';
          }          
        case TextType.icon: return teamsBox.get(id)!.fldPlayers[0] == teamsBox.get(id)!.fldPlayers[1] ? 'assets/png/dummy_24x24.png' : 'assets/png/darts_team_24x24.png';
      }
    }
  }

  Future<void> _resumeGame(BuildContext context, TblGame game) async {
    final bool isTeamGameMode = (game.gameMode == 2);

    if (game.gameType == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameHalfItScreen(
            game: game,
            gameText: isTeamGameMode ? 'Teams Half-It Game' : 'Players Half-It Game',
            tileBackgroundColor: widget.tileBackgroundColor,
            resumeMode: true,
          ),
        ),
      );
    } else if (game.gameType == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameBuildUpScreen(
            game: game,
            gameText: 'Players Team Build Up Game',
            tileBackgroundColor: widget.tileBackgroundColor,
            resumeMode: true,
          ),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _startGame(BuildContext context) async {
    final bool isTeamGameMode = (widget.enuGameMode == GameMode.gameTeams);    
    final List<int> selectedPlayersIds = [];

    // Get the gamesBox from Hive
    final gamesBox = Hive.box<TblGame>('gamesBox');    

    if (isTeamGameMode) {
      // build List<int> of players that are contained in the teams selected Id's
      // Pass 1: Add the first player of every selected team
      for (int teamId in _selectedIds) {
        final team = teamsBox.get(teamId);
        if (team != null) {
          selectedPlayersIds.add(team.fldPlayers[0].key as int);
        }
      }

      // Pass 2: Add the second player of every selected team
      for (int teamId in _selectedIds) {
        final team = teamsBox.get(teamId);
        if (team != null) {
          selectedPlayersIds.add(team.fldPlayers[1].key as int);
        }
      }
    }
    
    int idGameType = 0;
    switch (widget.enuGameType) {
      case GameType.gameHalfIt:
        idGameType = 1;
        break;
      case GameType.gameBuildUp:
        idGameType = 2;
        break;
    }

    // Create the game object
    final game = TblGame(
      gameType: idGameType,
      gameMode: isTeamGameMode ? 2 : 1,
      teamsIDs: isTeamGameMode ? _selectedIds : null,
      playersIDs: isTeamGameMode ? selectedPlayersIds : _selectedIds,
      isEnded: false,
    );

    // Add to Hive        
    gamesBox.add(game);

    // Get the auto-increment key that was generated
    game.idGame = game.key as int;

    // Save the player with the auto-increment id that was generated By Hive
    game.save(); 
    
    if (widget.enuGameType == GameType.gameHalfIt) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          // The add_player.dart page will be created and shown
          builder: (context) => GameHalfItScreen(
            game: game,
            gameText: isTeamGameMode ? 'Teams Half-It Game' : 'Players Half-It Game',
            tileBackgroundColor: widget.tileBackgroundColor,
            resumeMode: false,
          ),
        ),
      );
    }else if (widget.enuGameType == GameType.gameBuildUp){
      await Navigator.push(
        context,
        MaterialPageRoute(
          // The add_player.dart page will be created and shown
          builder: (context) => GameBuildUpScreen(
            game: game,
            gameText: 'Players Team Build Up Game',
            tileBackgroundColor: widget.tileBackgroundColor,
            resumeMode: false,
          ),
        ),
      );
    }    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {    
    int minNbPlayers = 0;
    switch (widget.enuGameType) {
      case GameType.gameHalfIt:
        minNbPlayers = 2;
        break;
      case GameType.gameBuildUp:
        minNbPlayers = 4;
        break;
    }

    final gamesBox = Hive.box<TblGame>('gamesBox');
    int currentTargetGameMode = widget.enuGameMode == GameMode.gamePlayers ? 1 : 2;
    int currentTargetGameType = widget.enuGameType == GameType.gameHalfIt ? 1 : 2;
    final TblGame? lastActiveGame = gamesBox.values.cast<TblGame?>()
        .where((g) => g != null && g.isEnded == false && g.gameMode == currentTargetGameMode && g.gameType == currentTargetGameType)
        .lastOrNull;

    return Scaffold(
      //pour le background color en bas du titre et pour le reste de la page
      backgroundColor: widget.tileBackgroundColor,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: widget.tileColor,
        
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
              widget.tileDescription,              
              style: const TextStyle(color: Colors.white),
            ),
          ]          
        ),
      ),
      
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0), //EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.enuGameMode == GameMode.gameTeams 
                        ? "Teams in game (${_selectedIds.length})" 
                        : "Players in game (${_selectedIds.length})",
                    style: TextStyle(
                      fontSize: 20, 
                      color: Colors.black, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (lastActiveGame != null) 
                    ElevatedButton.icon(
                      onPressed: () {
                        _resumeGame(context, lastActiveGame);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.history),
                      label: const Text("RESUME LAST GAME"),
                    ),
                  ElevatedButton.icon(
                    // Enable button if at least the minimum number of players or teams are selected
                    onPressed: _selectedIds.length < minNbPlayers 
                        ? null 
                        : () {
                            _startGame(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("START NEW GAME"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildList(isTop: true),
            ),

            // --- MIDDLE BUTTONS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                  onPressed: (_highlightedId != null && !_isHighlightInTop) 
                    ? () => setState(() {
                        _selectedIds.add(_highlightedId!);
                        _highlightedId = null;
                      }) 
                    : null,
                  child: const Icon(Icons.arrow_upward),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                  onPressed: (_highlightedId != null && _isHighlightInTop)
                    ? () => setState(() {
                        _selectedIds.remove(_highlightedId!);
                        _highlightedId = null;
                      })
                    : null,
                  child: const Icon(Icons.arrow_downward),
                ),
              ],
            ),

            // --- BOTTOM LIST (Available) ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.enuGameMode == GameMode.gameTeams 
                        ? "Available Teams (${teamsBox.values.where((t) => !(t.fldIsDeleted)).length - _selectedIds.length})" 
                        : "Available Players (${playersBox.values.where((p) => !(p.fldIsDeleted)).length - _selectedIds.length})",
                    style: TextStyle(
                      fontSize: 20, 
                      color: Colors.black, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              ),
            ),
            Expanded(
              child: _buildList(isTop: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList({required bool isTop}) {
    List<int> allIds;
    
    if (widget.enuGameMode == GameMode.gamePlayers) {
      allIds = playersBox.values
          .where((player) => player.fldIsDeleted == false) // Filter active players
          .map((player) => player.key as int) // Extract native Hive integer key
          .toList();
    } else {
      final busyPlayers = _getBusyPlayers();

      allIds = teamsBox.values.where((team) {
        if (team.fldIsDeleted) return false;

        // Only filter the BOTTOM (Available) list
        if (!isTop) {
          bool p1Busy = busyPlayers.contains(team.fldPlayers[0]);
          bool p2Busy = busyPlayers.contains(team.fldPlayers[1]);
          // If either player is already "in game" via another team, hide this team
          if (p1Busy || p2Busy) return false;
        }

        return true;
      }).map((team) => team.key as int).toList();
    }

    // Filter based on whether they are in the selection or not
    final displayIds = isTop 
        ? _selectedIds 
        : allIds.where((id) => !_selectedIds.contains(id)).toList();

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isTop 
        ? ReorderableListView(
            padding: const EdgeInsets.only(top: 4.0),
            proxyDecorator: (Widget child, int index, Animation<double> animation) {
            return Material(
              // ignore: sort_child_properties_last
              child: child,
              color: Colors.transparent, // Removes the rectangular background
              borderRadius: BorderRadius.circular(12), // Matches your Card radius
              elevation: 4, // Optional: makes it look "lifted"
            );
          },
            onReorderItem : (int oldIndex, int newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final int item = _selectedIds.removeAt(oldIndex);
                _selectedIds.insert(newIndex, item);
              });
            },
            children: [
              for (int index = 0; index < displayIds.length; index++)
                _buildTile(displayIds[index], isTop),
            ],
          )
        : ListView.builder(
            padding: const EdgeInsets.only(top: 4.0),
            itemCount: displayIds.length,
            itemBuilder: (context, index) {
              return _buildTile(displayIds[index], isTop);
            },
          ),
    );
  }

  // Helper to keep your existing ListTile logic consistent
  Widget _buildTile(int id, bool isTop) {
    final isHighlighted = _highlightedId == id;
    return Card(
      key: ValueKey(id), // Required for ReorderableListView
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        selected: isHighlighted,
        selectedTileColor: Colors.deepOrange.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Image.asset(_getTextByMode(TextType.icon, id)),
        visualDensity: const VisualDensity(vertical: -4),
        title: Text(_getTextByMode(TextType.title, id), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(_getTextByMode(TextType.subtitle, id), style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
        // Added a drag icon only for the top list
        trailing: isTop ? const Icon(Icons.drag_handle, color: Colors.grey) : null,
        onTap: () {
          setState(() {
            _highlightedId = id;
            _isHighlightInTop = isTop;
          });
        },
      ),
    );
  }
}