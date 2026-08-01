// Flutter basics
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_half_it.dart';
import 'package:darts_101/database/tbl_game_build_up.dart';
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
    Hive.openBox<TblPlayer>('playersBox'),
    Hive.openBox<TblTeam>('teamsBox'),
    Hive.openBox<TblGame>('gamesBox'),
    Hive.openBox<TblGameHalfIt>('gameHalfItBox'),
    Hive.openBox<TblGameBuildUp>('gameBuildUpBox'),
  ]);

  // Extract the box references you need for seeding:
  final playersBox = results[0] as Box<TblPlayer>;
  final teamsBox = results[1] as Box<TblTeam>;
  
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
      builder: (context) => const Darts101App(),
    ),
  );
}

class Darts101App extends StatelessWidget {
  const Darts101App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Darts 101',      
      /* theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey.shade800),
        scaffoldBackgroundColor: Colors.grey.shade800,        
      ), */

      builder: (context, child) {
        AppDisplay.updateDisplayMode(context);

        return child!;
      },
      home: const MainScreen(title: 'Darts 101'),
    );
  }
}

class MainScreenPopupMenu extends StatelessWidget {
  const MainScreenPopupMenu({super.key});

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
                      backgroundColor: Colors.grey.shade800,
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

        ImageConfig imageConfig = getInformationDialogImageConfig();

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
                      backgroundColor: Colors.grey.shade800,
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
      color: Colors.grey.shade800,
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});

  // This widget is the home page of your application.
  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {  
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
    MediaQuery.sizeOf(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade800,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,        
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
        actions: [
          // Live badge showing active carousel tile size (256 or 512)
          TextButton.icon(
            onPressed: () {
              // Optional: Tap to trigger your debug dialog if you ever need extra details
              _showDebugCarouselImageDialog(context);
            },
            icon: const Icon(Icons.aspect_ratio, color: Colors.amber, size: 18),
            label: Text(
              '${AppDisplay.carouselTileSize.toInt()}px',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const MainScreenPopupMenu(),
        ],
      ),
      
      // The body starts right under the AppBar
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: SizedBox(
          height: AppDisplay.carouselTileSize,
          child: CarouselView(
            itemExtent: AppDisplay.carouselTileSize,
            shrinkExtent: 80, // Shrinks edge cards into thin vertical rounded pills
            backgroundColor: Colors.transparent,
            /* shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Removes default card clipping shapes
            ), */
            children: [
              _buildMainScreenTile(
                context,
                menuType: 'game',
                tileText: 'New Half-It Game',
                tileCode: 'half-it',
                tileColor: Colors.lightBlue.shade400,
                tileBackgroundColor: Colors.lightBlue.shade200,
              ),
              _buildMainScreenTile(
                context,
                menuType: 'game',
                tileText: 'New 7 darts Game',
                tileCode: '7-darts',
                tileColor: Colors.green.shade400,
                tileBackgroundColor: Colors.green.shade200,
              ),
              _buildMainScreenTile(
                context,
                menuType: 'game',
                tileText: 'New Build-up Teams Game',
                tileCode: 'build-up',
                tileColor: Colors.grey.shade700,
                tileBackgroundColor: Colors.grey.shade400,
              ),
              _buildMainScreenTile(
                context,
                menuType: 'settings',
                tileText: 'Manage Players',
                tileCode: 'players',
                tileColor: Colors.deepOrange.shade400,
                tileBackgroundColor: Colors.deepOrange.shade200,
              ),
              _buildMainScreenTile(
                context,
                menuType: 'settings',
                tileText: 'Manage Teams',
                tileCode: 'teams',
                tileColor: Colors.red.shade900,
                tileBackgroundColor: Colors.red.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainScreenTile(
    BuildContext context, {
    required String menuType,
    required String tileCode,
    required String tileText,
    required Color tileColor,
    required Color tileBackgroundColor,
  }) {
    ImageConfig imageConfig = getCarouselTileImageConfig(menuType, tileCode);

    return InkWell(
      onTap: () => _onTileTapped(context, tileText, tileCode, tileColor, tileBackgroundColor),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.0,
          child: FittedBox(
            fit: BoxFit.contain, // Forces BOTH the color box and the image to scale down TOGETHER
            child: SizedBox(
              width: imageConfig.renderSize,
              height: imageConfig.renderSize,
              child: Stack(
                children: [
                  // 1. Color fill tucked inside fixed canvas dimensions
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(color: tileColor),
                    ),
                  ),
                  // 2. PNG frame overlaid on top
                  Positioned.fill(
                    child: Image.asset(
                      imageConfig.assetPath,
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showDebugCarouselImageDialog(BuildContext context) {
  final ImageConfig config = getCarouselTileImageConfig('game', 'frame');

  // Dynamic scale factor derived directly from dialog viewport height
  final double dialogHeight = AppDisplay.height * 0.7;
  final double baseFontSize = (dialogHeight * 0.045).clamp(14.0, 22.0);
  final double titleFontSize = baseFontSize * 1.25;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Carousel Image Debug Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        content: SizedBox(
          height: dialogHeight,
          width: AppDisplay.width * 0.8,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT SIDE: All text details with scaled typography
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Display Mode: ${AppDisplay.displayMode.name}',
                        style: TextStyle(color: Colors.white70, fontSize: baseFontSize),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Screen Width: ${AppDisplay.width.toStringAsFixed(1)} dp',
                        style: TextStyle(color: Colors.white70, fontSize: baseFontSize),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Screen Height: ${AppDisplay.height.toStringAsFixed(1)} dp',
                        style: TextStyle(color: Colors.white70, fontSize: baseFontSize),
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      Text(
                        'Asset Path:\n${config.assetPath}',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: baseFontSize,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Render Size: ${config.renderSize.toInt()} x ${config.renderSize.toInt()} px',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: baseFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // RIGHT SIDE: Preview image (FittedBox ensures high-DPI scaling)
              Expanded(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        config.assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              '⚠️ Asset Not Found!',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: baseFontSize,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.white, fontSize: baseFontSize),
            ),
          ),
        ],
      );
    },
  );
}