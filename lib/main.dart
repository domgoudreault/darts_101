// Flutter basics
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';

// Database Models
import 'package:darts_101/database/player.dart';
import 'package:darts_101/database/team.dart';
import 'package:darts_101/database/game.dart';
import 'package:darts_101/database/gamehalfit.dart';
import 'package:darts_101/database/gamebuildup.dart';
import 'package:darts_101/hive_registrar.g.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/main_be.dart';

// UI Screens
import 'package:darts_101/manage_players.dart';
import 'package:darts_101/manage_teams.dart';
import 'package:darts_101/game_selection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Lock app to landscape mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Hive.initFlutter();
  Hive.registerAdapters(); // Register all adapters automatically in one line:
  
  // Open ALL 5 boxes concurrently
  final results = await Future.wait([
    Hive.openBox<Player>('playersBox'),
    Hive.openBox<Team>('teamsBox'),
    Hive.openBox<Game>('gamesBox'),
    Hive.openBox<GameHalfIt>('gameHalfItBox'),
    Hive.openBox<GameBuildUp>('gameTeamBuildUpBox'),
  ]);

  // Extract the box references you need for seeding:
  final playersBox = results[0] as Box<Player>;
  final teamsBox = results[1] as Box<Team>;
  
  // Only seeds if we are in Debug Mode AND the database is empty
  if (kDebugMode) {
    // AutoFill for testing           
    if (playersBox.isEmpty){
      await seedHivePlayers(playersBox);
      await seedHiveTeams(playersBox, teamsBox);
    }
  }

  // Wrap runApp with DevicePreview
  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Darts 101',      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),        
      ),

      builder: (context, child) {
        final size = MediaQuery.sizeOf(context);
        AppDisplay.width = size.width;
        AppDisplay.height = size.height;
        AppDisplay.displayMode = getDisplayMode(size.width);

        return child!;
      },
      home: const MyHomePage(title: 'Darts 101'),
    );
    /* return LayoutBuilder(
      builder: (context, constraints) {
        // 💡 UPDATED ONCE AT THE ROOT FOR THE ENTIRE APP
        final size = MediaQuery.sizeOf(context);
        AppDisplay.width = size.width;
        AppDisplay.height = size.height;
        AppDisplay.displayMode = getDisplayMode(size.width);

        
      },
    ); */        
  }
}

class MainPopupMenu extends StatelessWidget {
  const MainPopupMenu({super.key});

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Registers this dialog as a listener for screen size changes (it does nothing else)
        MediaQuery.sizeOf(context);
        
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: SizedBox(
            height: AppDisplay.height * 0.7,
            width: AppDisplay.width * 0.8,
            child: Column(
              children: [
                // 1. SCROLLABLE TEXT AREA
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(getPrivacyPolicySection(1), style: const TextStyle(fontSize: 14)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Information Collection and Use", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Text(getPrivacyPolicySection(2)),
                        // List of services
                        ...['Google Play Services', 'AdMob', 'Fabric', 'Firebase Analytics', 'Crashlytics']
                            .map((service) => Padding(
                                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                                  child: Text("• $service", style: const TextStyle(fontWeight: FontWeight.w500)),
                                )),
                        Text(getPrivacyPolicySection(3)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Log Data and Error Reporting",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Text(getPrivacyPolicySection(4)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Cookies",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Text(getPrivacyPolicySection(5)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Security",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Text(getPrivacyPolicySection(6)),
                      ],
                    ),
                  ),
                ),
                // 2. FIXED DIVIDER AND BUTTON
                const Divider(thickness: 1, height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInformationDialog(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Registers this dialog as a listener for screen size changes (it does nothing else)
        MediaQuery.sizeOf(context);

        InfoDialogImgCfg imageConfig = getInformationDialogImageConfig();

        return AlertDialog(
          title: Text('Information [${AppDisplay.displayMode.name}] : ${imageConfig.assetPath}'),
          content: SizedBox(
            // Set a fixed height so the dialog doesn't jump around
            height: AppDisplay.height * 0.7,
            width: AppDisplay.width * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT SIDE (All Text Details)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  getInformationSection(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                "Version: ${packageInfo.version}\nBuild: ${packageInfo.buildNumber}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  "\nLatest Changes:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(getInformationSection(2)),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  "Artwork Attributions:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(getInformationSection(3)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10), // Space between text and image
                        // THE IMAGE ON THE RIGHT
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                          child: Image.asset(
                            imageConfig.assetPath,
                            width: imageConfig.renderSize,
                            height: imageConfig.renderSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 2. FIXED DIVIDER AND BUTTON
                const Divider(thickness: 1, height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close', style: TextStyle(fontSize: 16)),
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
    return PopupMenuButton<String>(
      color: Colors.blueAccent,
      iconColor: Colors.white,
      onSelected: (String value) {
        switch (value) {
          case 'main_pop_menu_privacy':
            _showPrivacyDialog(context);
            break;
          case 'main_pop_menu_info':
            _showInformationDialog(context);
            break;          
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildMenuItem('main_pop_menu_info', 'Information'),
        _buildMenuItem('main_pop_menu_privacy', 'Privacy Policy'),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application.
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {  
  // Fonction de navigation when a button is pressed
  void _onTileTapped(BuildContext context, String tileText, String tileCode, Color tileColor, Color tileBackgroundColor) {    
    switch (tileCode){
      case 'manage_players':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManagePlayers(
              tileText: tileText,
              tileColor: tileColor,
              tileBackgroundColor: tileBackgroundColor,
            ),
          ),
        );
        break;

      case 'manage_teams':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageTeams(
              tileText: tileText,
              tileColor: tileColor,
              tileBackgroundColor: tileBackgroundColor,
            ),
          ),
        );
        break;

      case 'half_it_game_teams':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameSelection(
              tileText: tileText,
              tileColor: tileColor,
              tileBackgroundColor: tileBackgroundColor,
              enuGameMode: GameMode.gameTeams,
              enuGameType: GameType.gameHalfIt,
            ),
          ),
        );
        break;
      
      case 'half_it_game_players':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameSelection(
              tileText: tileText,
              tileColor: tileColor,
              tileBackgroundColor: tileBackgroundColor,
              enuGameMode: GameMode.gamePlayers,
              enuGameType: GameType.gameHalfIt,
            ),
          ),
        );
        break;

      case 'team_build_up':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameSelection(
              tileText: tileText,
              tileColor: tileColor,
              tileBackgroundColor: tileBackgroundColor,
              enuGameMode: GameMode.gamePlayers,
              enuGameType: GameType.gameBuildUp,
            ),
          ),
        );
        break;

      default:
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$tileText was clicked!'),
            duration: const Duration(milliseconds: 800),
          ),
        );
        break;
    }
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,        
        title: Row (
          children: [
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
            Text(
              widget.title,              
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ]          
        ),
        actions: const [
          MainPopupMenu(), // Cleanly calling the extracted widget
        ],
      ),
      
      // The body starts right under the AppBar
      /* body: Column(
        // Set the Column's main axis size to min to keep it tight, 
        // or leave it at default (max) if you want the buttons at the top.
        mainAxisSize: MainAxisSize.max, 
        
        children: <Widget>[
          const Divider(height: 1, thickness: 1),

          _buildDarts101Tile(
            context,
            tileText: 'New Players Half-It Game',
            tileCode: 'half_it_game_players',
            tileImageAsset: 'assets/png/dartboard_player_48x48.png',
            tileColor: Colors.lightBlue.shade400,
            tileBackgroundColor: Colors.lightBlue.shade200,
          ),

          _buildDarts101Tile(
            context,
            tileText: 'New Teams Half-It Game',
            tileCode: 'half_it_game_teams',
            tileImageAsset: 'assets/png/dartboard_team_48x48.png',
            tileColor: Colors.green.shade400,
            tileBackgroundColor: Colors.green.shade200,
          ),
          
          _buildDarts101Tile(
            context,
            tileText: 'Team build up',
            tileCode: 'team_build_up',
            tileImageAsset: 'assets/png/team_build_up_48x48.png',
            tileColor: Colors.grey.shade700,
            tileBackgroundColor: Colors.grey.shade400,
          ),

          _buildDarts101Tile(
            context,
            tileText: 'Manage Players',
            tileCode: 'manage_players',
            tileImageAsset: 'assets/png/darts_player_48x48.png',
            tileColor: Colors.deepOrange.shade400,
            tileBackgroundColor: Colors.deepOrange.shade200,
          ),
          
          _buildDarts101Tile(
            context,
            tileText: 'Manage Teams',
            tileCode: 'manage_teams',
            tileImageAsset: 'assets/png/darts_team_48x48.png',
            tileColor: Colors.red.shade900,
            tileBackgroundColor: Colors.red.shade400,
          ), 

          /* _buildDarts101Tile(
            context,
            tileText: 'Statistics',
            tileCode: 'stats',
            tileImageAsset: 'assets/png/statistics_48x48.png',
            tileColor: Colors.purple.shade400,
          ), */
          
          const Spacer(),
        ],
      ), */
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 3, // 3 square tiles per row (or 4 depending on preference)
          crossAxisSpacing: 16.0, // Horizontal space between tiles
          mainAxisSpacing: 16.0,  // Vertical space between rows
          childAspectRatio: 1.0,  // Forces exact square dimensions (1:1 aspect ratio)
          children: <Widget>[
            _buildDarts101Tile(
              context,
              tileText: 'New Players Half-It Game',
              tileCode: 'half_it_game_players',
              //tileImageAsset: 'assets/png/dartboard_player_48x48.png',
              tileImageAsset: 'assets/png/trophy_2_players_48x120.png',
              tileColor: Colors.lightBlue.shade400,
              tileBackgroundColor: Colors.lightBlue.shade200,
            ),
            _buildDarts101Tile(
              context,
              tileText: 'New Teams Half-It Game',
              tileCode: 'half_it_game_teams',
              tileImageAsset: 'assets/png/dartboard_team_48x48.png',
              tileColor: Colors.green.shade400,
              tileBackgroundColor: Colors.green.shade200,
            ),
            _buildDarts101Tile(
              context,
              tileText: 'Team build up',
              tileCode: 'team_build_up',
              tileImageAsset: 'assets/png/team_build_up_48x48.png',
              tileColor: Colors.grey.shade700,
              tileBackgroundColor: Colors.grey.shade400,
            ),
            _buildDarts101Tile(
              context,
              tileText: 'Manage Players',
              tileCode: 'manage_players',
              tileImageAsset: 'assets/png/darts_player_48x48.png',
              tileColor: Colors.deepOrange.shade400,
              tileBackgroundColor: Colors.deepOrange.shade200,
            ),
            _buildDarts101Tile(
              context,
              tileText: 'Manage Teams',
              tileCode: 'manage_teams',
              tileImageAsset: 'assets/png/darts_team_48x48.png',
              tileColor: Colors.red.shade900,
              tileBackgroundColor: Colors.red.shade400,
            ),
          ],
        ),
      ),
    );
  }
  
  /* Widget _buildDarts101Tile(
      BuildContext context, {
      required String tileCode,
      required String tileText,
      required String tileImageAsset,
      required Color tileColor,
      required Color tileBackgroundColor,
  }) {
    return InkWell( // InkWell provides a beautiful ripple effect on tap
      onTap: () => _onTileTapped(context, tileText, tileCode, tileColor, tileBackgroundColor),
      child: Container(
        width: double.infinity, // Ensures the tile fills the width
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        margin: const EdgeInsets.only(bottom: 1.0), // Small line separator
        decoration: BoxDecoration(
          color: tileColor,
          border: Border(
            bottom: BorderSide(color: Colors.white, width: 1),
          ),
        ),
        child: Row(
          children: [
            Image.asset(tileImageAsset),
            const SizedBox(width: 16.0),
            Text(
              tileText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  } */

  Widget _buildDarts101Tile(
      BuildContext context, {
      required String tileCode,
      required String tileText,
      required String tileImageAsset,
      required Color tileColor,
      required Color tileBackgroundColor,
  }) {
    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(12.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onTileTapped(context, tileText, tileCode, tileColor, tileBackgroundColor),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon scaled up slightly for square cards
              Image.asset(
                tileImageAsset,
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 12.0),
              Text(
                tileText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
