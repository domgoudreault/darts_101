// Flutter basics
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// Database Models
import 'package:darts_101/database/tbl_avatar.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_half_it.dart';
import 'package:darts_101/database/tbl_game_build_up.dart';
import 'package:darts_101/hive_registrar.g.dart';

// Backend Logic
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_assets.dart';
import 'package:darts_101/helpers_database.dart';
import 'package:darts_101/global_be.dart';

// UI Screens
import 'package:darts_101/settings_players.dart';
import 'package:darts_101/settings_teams.dart';
import 'package:darts_101/game_selection.dart';

enum MainScreenSection {
  section05Games,
  section10Settings,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensures modern transparent edge-to-edge system bar rendering
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 🔒 Lock app to landscape mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Hive.initFlutter();
  Hive.registerAdapters(); // Register all adapters automatically in one line:
  
  // Open ALL 6 boxes concurrently
  final results = await Future.wait([
    Hive.openBox<TblAvatar>('avatarsBox'),
    Hive.openBox<TblPlayer>('playersBox'),
    Hive.openBox<TblTeam>('teamsBox'),
    Hive.openBox<TblGame>('gamesBox'),
    Hive.openBox<TblGameHalfIt>('gameHalfItBox'),
    Hive.openBox<TblGameBuildUp>('gameBuildUpBox'),
  ]);

  // Extract the box references you need for seeding:
  final avatarsBox = results[0] as Box<TblAvatar>;
  
  // Only seeds avatars if the database is empty
  if (avatarsBox.isEmpty){
    await gSeedHiveAvatars(avatarsBox);
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
      useSafeArea: true,
      builder: (BuildContext context) {
        // Registers this dialog as a listener for screen size changes (it does nothing else)
        MediaQuery.sizeOf(context);
        
        return AlertDialog(
          title: const Text('Darts 101 - Privacy Policy'),
          content: SizedBox(
            height: AppDisplay.safeHeight * 0.7,
            width: AppDisplay.safeWidth * 0.8,
            child: Column(
              children: [
                // 1. SCROLLABLE TEXT AREA
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Overview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Text(gGetPrivacyPolicySection(1), style: const TextStyle(fontSize: 14)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Information Collection and Use", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Text(gGetPrivacyPolicySection(2)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Third-Party Services & Analytics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        
                        Text(gGetPrivacyPolicySection(3)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Log Data & Device Permissions",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Text(gGetPrivacyPolicySection(4)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Data Retention & Account Deletion",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Text(gGetPrivacyPolicySection(5)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text("Contact Us",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Text(gGetPrivacyPolicySection(6)),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () async {
                              final Uri url = Uri.parse(gGetPrivacyPolicySection(7));
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Text(
                              gGetPrivacyPolicySection(7),
                              style: TextStyle(
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blueAccent,
                              ),
                            ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close', style: gBuildArcadeTextStyle(12)),
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
      useSafeArea: true,
      builder: (BuildContext context) {
        // Registers this dialog as a listener for screen size changes (it does nothing else)
        MediaQuery.sizeOf(context);

        ImageConfig leagueLogoImageConfig = gGetInformationDialogImageConfig();

        return AlertDialog(
          content: SizedBox(
            // Set a fixed height so the dialog doesn't jump around
            height: AppDisplay.safeHeight * 0.8,
            width: AppDisplay.safeWidth * 0.8,
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
                                  gGetInformationSection(1),
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
                              Text(gGetInformationSection(2)),
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
                              Text(gGetInformationSection(3)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10), // Space between text and image
                        // THE IMAGE ON THE RIGHT
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                          child: Image.asset(
                            leagueLogoImageConfig.assetPath,
                            width: leagueLogoImageConfig.renderSize,
                            height: leagueLogoImageConfig.renderSize,
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
                    child: Text('Close', style: gBuildArcadeTextStyle(12)),
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
      child: Text(text, style: gBuildArcadeTextStyle(10)),
      //child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

class CarouselTileData {
  final String tileType;
  final String tileCode;
  final Color tileColor;
  final Color tileBackgroundColor;
  final String tileDescription;

  const CarouselTileData({
    required this.tileType,
    required this.tileCode,
    required this.tileColor,
    required this.tileBackgroundColor,
    required this.tileDescription,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});

  // This widget is the home page of your application.
  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {  
  // Accordion State: GAMES active by default
  MainScreenSection _activeSection = MainScreenSection.section05Games;

  // Single Source of Truth for Game Tiles
  List<CarouselTileData> get _gamesTiles => [
    CarouselTileData(
      tileType: 'games',
      tileCode: 'half-it',
      tileColor: Colors.lightBlue.shade400,
      tileBackgroundColor: Colors.lightBlue.shade200,
      tileDescription: 'Half-It Game',
    ),
    CarouselTileData(
      tileType: 'games',
      tileCode: 'around-clock',
      tileColor: Colors.teal.shade400,
      tileBackgroundColor: Colors.teal.shade200,
      tileDescription: 'Game Around the Clock (skip the numbers version)',
    ),
    CarouselTileData(
      tileType: 'games',
      tileCode: '7-darts',
      tileColor: Colors.green.shade400,
      tileBackgroundColor: Colors.green.shade200,
      tileDescription: 'Game 7 Darts',
    ),
    CarouselTileData(
      tileType: 'games',
      tileCode: 'all-fives',
      tileColor: Colors.purple.shade200,
      tileBackgroundColor: Colors.purple.shade100,
      tileDescription: 'Game All Fives / 51 by 5''s',
    ),
    CarouselTileData(
      tileType: 'games',
      tileCode: 'killers',
      tileColor: Colors.grey.shade500,
      tileBackgroundColor: Colors.grey.shade200,      
      tileDescription: 'Game Killers',
    ),
    CarouselTileData(
      tileType: 'games',
      tileCode: 'sudden-death',
      tileColor: Colors.red.shade900,
      tileBackgroundColor: Colors.red.shade400,
      tileDescription: 'Game Sudden Death',
    ),
    CarouselTileData(
      tileType: 'games',
      tileCode: 'build-up',
      tileColor: Colors.deepPurple.shade400,
      tileBackgroundColor: Colors.grey.shade200,
      tileDescription: 'Game Team Build-up',
    ),
  ];

  // Single Source of Truth for Settings Tiles
  List<CarouselTileData> get _settingsTiles => [
    CarouselTileData(
      tileType: 'settings',
      tileCode: 'players',
      tileColor: Colors.deepOrange.shade400,
      tileBackgroundColor: Colors.deepOrange.shade200,
      tileDescription: 'Players Management',
    ),
    CarouselTileData(
      tileType: 'settings',
      tileCode: 'teams',
      tileColor: Colors.indigo.shade400,
      tileBackgroundColor: Colors.indigo.shade200,
      tileDescription: 'Teams Management',
    ),
  ];

  // Fonction de navigation when a button is pressed
  void _onTileTapped(BuildContext context, CarouselTileData tile) {    
    final destination = switch ((tile.tileType, tile.tileCode)) {
      // Games Routes
      ('games', 'half-it') => GameSelection(
          tileType: tile.tileType,
          tileColor: tile.tileColor,
          tileBackgroundColor: tile.tileBackgroundColor,
          tileDescription: tile.tileDescription,
          enuGameType: GameType.gameHalfIt,
        ),
      ('game', 'build-up') => GameSelection(
          tileType: tile.tileType,
          tileColor: tile.tileColor,
          tileBackgroundColor: tile.tileBackgroundColor,
          tileDescription: tile.tileDescription,
          enuGameType: GameType.gameBuildUp,
        ),

      // Settings Routes
      ('settings', 'players') => SettingsPlayers(
          tileType: tile.tileType,
          tileColor: tile.tileColor,
          tileBackgroundColor: tile.tileBackgroundColor,
          tileDescription: tile.tileDescription,
        ),
      ('settings', 'teams') => SettingsTeams(
          tileType: tile.tileType,
          tileColor: tile.tileColor,
          tileBackgroundColor: tile.tileBackgroundColor,
          tileDescription: tile.tileDescription,
        ),

      // Default Fallback
      _ => null,
    };

    if (destination != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      gShowArcadeErrorSnackBar(
        gContext: context, 
        gFontSize: 16, 
        gMessage: '${tile.tileDescription} was clicked!',
        gDuration: 2
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);
    
    // Select active dataset based on section toggle
    final List<CarouselTileData> activeTiles = 
        _activeSection == MainScreenSection.section05Games 
            ? _gamesTiles 
            : _settingsTiles;

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
                  'assets/png/logos/darts_101_logo_48x48.png', // Replace with your image path (PNG, JPG, or SVG)
                  fit: BoxFit.contain, // Ensures the image fits within the box
                ),
              ),
            ),
            Text(widget.title, style: gBuildArcadeTextStyle(20)),
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
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP SEGMENTED TOGGLE BAR (GAMES | SETTINGS Side-by-Side)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  _buildSectionToggleButton(
                    sectionCode: 'games',
                    section: MainScreenSection.section05Games,
                  ),
                  const SizedBox(width: 12),
                  _buildSectionToggleButton(
                    sectionCode: 'settings',
                    section: MainScreenSection.section10Settings,
                  ),
                ],
              ),
            ),

            // 2. FIXED CAROUSEL DISPLAY AREA (Takes remaining vertical screen space)
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: AppDisplay.carouselTileSize,
                  child: CarouselView(
                    itemExtent: AppDisplay.carouselTileSize,
                    shrinkExtent: 80,
                    backgroundColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    onTap: (int index) {
                      _onTileTapped(context, activeTiles[index]);
                    },
                    children: activeTiles
                        .map((tileData) => _buildMainScreenTile(context, tileData))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMainScreenTile(BuildContext context, CarouselTileData tile) {
    ImageConfig gameTileImageConfig = gGetCarouselTileImageConfig(tile.tileType, tile.tileCode);

    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: FittedBox(
          fit: BoxFit.contain, // Forces BOTH the color box and the image to scale down TOGETHER
          child: SizedBox(
            width: gameTileImageConfig.renderSize,
            height: gameTileImageConfig.renderSize,
            child: Stack(
              children: [
                // 1. Color fill tucked inside fixed canvas dimensions
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(gameTileImageConfig.renderSize * 0.03),
                    child: Container(color: tile.tileColor),
                  ),
                ),
                // 2. PNG frame overlaid on top
                Positioned.fill(
                  child: Image.asset(
                    gameTileImageConfig.assetPath,
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionToggleButton({
    required String sectionCode,
    required MainScreenSection section,
  }) {
    final bool isSelected = _activeSection == section;
    final ImageConfig sectionImageConfig = gGetSectionHeaderImageConfig(sectionCode);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            setState(() => _activeSection = section);
          }
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.amber : Colors.transparent,
                width: 8.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SizedBox(
                height: sectionImageConfig.renderSize / 2,
                child: Image.asset(
                  sectionImageConfig.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _clearHiveDatabase(BuildContext context) async {
  // Clear primary user data and game logs
  await Hive.box<TblPlayer>('playersBox').clear();
  await Hive.box<TblTeam>('teamsBox').clear();
  
  if (context.mounted) {
    gShowArcadeErrorSnackBar(
      gContext: context,
      gFontSize: 16,
      gMessage: 'PLAYERS & TEAMS CLEARED!',
      gDuration: 2
    );
  }
}

void _showDebugCarouselImageDialog(BuildContext context) {
  final ImageConfig config = gGetCarouselTileImageConfig('settings', 'players');

  // Dynamic scale factor derived directly from dialog viewport height
  final double dialogHeight = AppDisplay.safeHeight * 0.7;
  final double baseFontSize = (dialogHeight * 0.045).clamp(14.0, 22.0);
  final double titleFontSize = baseFontSize * 1.25;

  showDialog(
    context: context,
    useSafeArea: true,
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
          width: AppDisplay.safeWidth * 0.8,
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
                        'Safe Screen Width: ${AppDisplay.safeWidth.toStringAsFixed(1)} dp',
                        style: TextStyle(color: Colors.white70, fontSize: baseFontSize),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Safe Screen Height: ${AppDisplay.safeHeight.toStringAsFixed(1)} dp',
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
                      Text(
                        'Database Utilities:',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: baseFontSize,
                        ),
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _clearHiveDatabase(context);
                          },
                          icon: const Icon(Icons.delete_sweep, size: 16),
                          label: Text(
                            'CLEAR PLAYERS & TEAMS',
                            style: gBuildArcadeTextStyle((baseFontSize * 0.60).clamp(10.0, 16.0)),
                          ),
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
            child: Text('Close', style: gBuildArcadeTextStyle(baseFontSize)),
          ),
        ],
      );
    },
  );
}