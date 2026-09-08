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
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_database.dart';

// UI Screens
import 'package:darts_101/settings_players.dart';
import 'package:darts_101/settings_teams.dart';
import 'package:darts_101/rosters_selection.dart';

enum MainScreenSection {
  section05Games(
    sectionCode: 'games',
    assetPath: 'assets/svg/mechanics/section_games.svg',
  ),
  section10Settings(
    sectionCode: 'settings',
    assetPath: 'assets/svg/mechanics/section_settings.svg',
  );

  final String sectionCode;
  final String assetPath;

  const MainScreenSection({
    required this.sectionCode,
    required this.assetPath,
  });
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
        GlobalAppDisplay.updateDisplayMode(context);

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
        MediaQuery.sizeOf(context);
        
        return AlertDialog(
          title: Text(
            'Darts 101 - Privacy Policy',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: (GlobalAppDisplay.safeWidth * 0.026))
            ),
          content: SizedBox(
            height: GlobalAppDisplay.safeHeight * 0.7,
            width: GlobalAppDisplay.safeWidth * 0.8,
            child: Column(
              children: [
                // 1. SCROLLABLE TEXT AREA
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: GlobalAppDisplay.safeHeight * 0.022),
                          child: Text("Overview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: (GlobalAppDisplay.safeWidth * 0.020))),
                        ),
                        Text(gGetPrivacyPolicySection(1), style: TextStyle(fontSize: (GlobalAppDisplay.safeWidth * 0.017))),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: GlobalAppDisplay.safeHeight * 0.022),
                          child: Text("Information Collection and Use", style: TextStyle(fontWeight: FontWeight.bold, fontSize: (GlobalAppDisplay.safeWidth * 0.020))),
                        ),
                        Text(gGetPrivacyPolicySection(2), style: TextStyle(fontSize: (GlobalAppDisplay.safeWidth * 0.017))),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: GlobalAppDisplay.safeHeight * 0.022),
                          child: Text("Third-Party Services & Analytics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: (GlobalAppDisplay.safeWidth * 0.020))),
                        ),
                        
                        Text(gGetPrivacyPolicySection(3), style: TextStyle(fontSize: (GlobalAppDisplay.safeWidth * 0.017))),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: GlobalAppDisplay.safeHeight * 0.022),
                          child: Text("Log Data & Device Permissions",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: (GlobalAppDisplay.safeWidth * 0.020))),
                        ),
                        Text(gGetPrivacyPolicySection(4), style: TextStyle(fontSize: (GlobalAppDisplay.safeWidth * 0.017))),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: GlobalAppDisplay.safeHeight * 0.022),
                          child: Text("Data Retention & Account Deletion",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: (GlobalAppDisplay.safeWidth * 0.020))),
                        ),
                        Text(gGetPrivacyPolicySection(5), style: TextStyle(fontSize: (GlobalAppDisplay.safeWidth * 0.017))),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: GlobalAppDisplay.safeHeight * 0.022),
                          child: Text("Contact Us",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: (GlobalAppDisplay.safeWidth * 0.020))),
                        ),
                        Text(gGetPrivacyPolicySection(6), style: TextStyle(fontSize: (GlobalAppDisplay.safeWidth * 0.017))),
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
                                fontSize: (GlobalAppDisplay.safeWidth * 0.017),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 2. FIXED DIVIDER AND BUTTON
                Divider(thickness: GlobalAppDisplay.safeHeight * 0.003, height: GlobalAppDisplay.safeHeight * 0.04),
                SizedBox(
                  width: double.infinity,
                  height: GlobalAppDisplay.safeWidth * 0.052,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GlobalAppDisplay.safeWidth * 0.012)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close', style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.014)),
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
        MediaQuery.sizeOf(context);

        return AlertDialog(
          content: SizedBox(
            // Set a fixed height so the dialog doesn't jump around
            height: GlobalAppDisplay.safeHeight * 0.85,
            width: GlobalAppDisplay.safeWidth * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT SIDE (All Text Details)
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: GlobalAppDisplay.safeHeight * 0.022),
                                child: Text(
                                  gGetInformationSection(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: GlobalAppDisplay.safeWidth * 0.020,
                                  ),
                                ),
                              ),
                              Text(
                                "Version: ${packageInfo.version}\nBuild: ${packageInfo.buildNumber}",
                                style: TextStyle(fontSize: GlobalAppDisplay.safeWidth * 0.017),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: GlobalAppDisplay.safeHeight * 0.022),
                                child: Text(
                                  "\nLatest Changes:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: GlobalAppDisplay.safeWidth * 0.020,
                                  ),
                                ),
                              ),
                              Text(gGetInformationSection(2), style: TextStyle(fontSize: (GlobalAppDisplay.safeWidth * 0.017))),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: GlobalAppDisplay.safeHeight * 0.022),
                                child: Text(
                                  "Artwork Attributions:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: GlobalAppDisplay.safeWidth * 0.020,
                                  ),
                                ),
                              ),
                              Text(gGetInformationSection(3), style: TextStyle(fontSize: (GlobalAppDisplay.safeWidth * 0.017))),
                            ],
                          ),
                        ),
                        SizedBox(width: GlobalAppDisplay.safeWidth * 0.007), // Space between text and image
                        // THE IMAGE ON THE RIGHT
                        Expanded(
                          flex: 1,
                          child: Center(
                            child:AspectRatio(
                            aspectRatio: 1.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(GlobalAppDisplay.safeWidth * 0.012),
                              child: Image.asset(
                                'assets/png/logos/LGGDS.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                        ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 2. FIXED DIVIDER AND BUTTON
                Divider(thickness: GlobalAppDisplay.safeHeight * 0.003, height: GlobalAppDisplay.safeHeight * 0.04),
                SizedBox(
                  width: double.infinity,
                  height: GlobalAppDisplay.safeWidth * 0.052,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(GlobalAppDisplay.safeWidth * 0.012),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close', style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.014)),
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
      color: Colors.grey.shade700,
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
      child: Text(text, style: gBuildArcadeTextStyle((GlobalAppDisplay.safeWidth * 0.012).clamp(11.0, 18.0))),
      //child: Text(text, style: const TextStyle(color: Colors.white)),
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
  // Accordion State: GAMES active by default
  MainScreenSection _activeSection = MainScreenSection.section05Games;

  // Fonction de navigation when a button is pressed
  void _onTileTapped(BuildContext context, dynamic tile) {    
    Widget? destination;

    if (tile is GlobalGameType) {
      destination = RostersSelection(
        enuGameType: tile,
      );
    } else if (tile is GlobalSettingType) {
      destination = switch (tile) {
        GlobalSettingType.players => SettingsPlayers(
            enuSettingType: tile,
          ),
        GlobalSettingType.teams => SettingsTeams(
            enuSettingType: tile,
          ),
      };
    }

    if (destination != null) {
      final formDestination = destination;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => formDestination),
      );
    } else {
      gShowArcadeErrorSnackBar(
        gContext: context, 
        gFontSize: (GlobalAppDisplay.safeWidth * 0.011).clamp(14.0, 28.0), 
        gMessage: '${tile.tileDisplayName} was clicked!',
        gDuration: 2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);
    
    // Select active dataset based on section toggle    
    final List<dynamic> activeTiles = 
    _activeSection == MainScreenSection.section05Games 
        ? GlobalGameType.values 
        : GlobalSettingType.values;
    final toolbarHeight = (GlobalAppDisplay.safeHeight * 0.10).clamp(56.0, 142.0);

    return Scaffold(
      backgroundColor: Colors.grey.shade800,
      appBar: 
        gBuildAppBar(
          gToolbarHeight: toolbarHeight,
          gAppBarTitle: widget.title, 
          gAppBarColorBg: Colors.grey.shade800,
          gCallFromMainScreen: true,
          gOnPressed: () => _showDebugCarouselImageDialog(context),
          gRightPopupMenu: const MainScreenPopupMenu(),
      ),
      
      // The body starts right under the AppBar      
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP SEGMENTED TOGGLE BAR (Takes 1/4 - toolbarHeight of screen free space)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: GlobalAppDisplay.safeWidth * 0.008,
                vertical: GlobalAppDisplay.safeHeight * 0.008,
              ),
              height: (GlobalAppDisplay.safeHeight-toolbarHeight) * (1/4),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  _buildSectionToggleButton(section: MainScreenSection.section05Games),
                  
                  SizedBox(width: GlobalAppDisplay.safeWidth * 0.012),
                  
                  _buildSectionToggleButton(section: MainScreenSection.section10Settings),
                ],
              ),
            ),

            // 2. FIXED CAROUSEL DISPLAY AREA (Takes 3/4 - toolbarHeight of screen free space)
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: (GlobalAppDisplay.safeWidth),
                  child: CarouselView(
                    itemExtent: (GlobalAppDisplay.safeHeight-toolbarHeight) * (3/4),
                    shrinkExtent: (GlobalAppDisplay.safeHeight-toolbarHeight) * 0.15,
                    backgroundColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    onTap: (int index) {
                      _onTileTapped(context, activeTiles[index]);
                    },
                    children: activeTiles
                        .map((tile) => _buildMainScreenTile(context, tile))
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
  
  Widget _buildMainScreenTile(BuildContext context, dynamic tile) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: SizedBox(
          width: GlobalAppDisplay.safeWidth * 0.40,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  widthFactor: 0.94, // Adjust percentage to taste (e.g. 0.94 leaves a clean 3% border)
                  heightFactor: 0.94,
                  child: Container(color: tile.tileColor),
                ),
              ),
              
              // 2. PNG frame overlaid on top
              Positioned.fill(
                child: Image.asset(
                  //gameTileImageConfig.assetPath,
                  'assets/png/tiles/${tile.tileType}_${tile.tileCode}.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionToggleButton({
    required MainScreenSection section,
  }) {
    final bool isSelected = _activeSection == section;
    
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
            padding: EdgeInsets.symmetric(vertical: GlobalAppDisplay.safeHeight * 0.004),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.amber : Colors.transparent,
                width: GlobalAppDisplay.safeWidth * 0.004,
              ),
              borderRadius: BorderRadius.circular(GlobalAppDisplay.safeWidth * 0.012),
            ),
            child: Center(
              child: AspectRatio(
                aspectRatio: 2.04266,
                child: SizedBox(
                  width: (GlobalAppDisplay.safeWidth * 0.20),
                  child: Image.asset(
                    'assets/png/mechanics/section_${section.sectionCode}.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
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
  showDialog(
    context: context,
    useSafeArea: true,
    builder: (BuildContext context) {
      MediaQuery.sizeOf(context);
      
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Carousel Image Debug Info',
          style: gBuildArcadeTextStyle((GlobalAppDisplay.safeWidth * 0.015).clamp(14.0, 32.0)),
        ),
        content: 
          SizedBox(
            height: GlobalAppDisplay.safeHeight * 0.7,
            width: GlobalAppDisplay.safeWidth * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Display Mode: ${GlobalAppDisplay.displayMode.name}',
                      style: gBuildArcadeTextStyle((GlobalAppDisplay.safeWidth * 0.011).clamp(10.0, 28.0)),
                    ),
                    SizedBox(height: GlobalAppDisplay.safeHeight * 0.002),
                    Text(
                      'Safe Screen Width: ${GlobalAppDisplay.safeWidth.toStringAsFixed(1)} dp',
                      style: gBuildArcadeTextStyle((GlobalAppDisplay.safeWidth * 0.011).clamp(10.0, 28.0)),
                    ),
                    SizedBox(height: GlobalAppDisplay.safeHeight * 0.002),
                    Text(
                      'Safe Screen Height: ${GlobalAppDisplay.safeHeight.toStringAsFixed(1)} dp',
                      style: gBuildArcadeTextStyle((GlobalAppDisplay.safeWidth * 0.011).clamp(10.0, 28.0)),
                    ),
                    Divider(color: Colors.white24, height: GlobalAppDisplay.safeHeight * 0.044),
                    Text(
                      'Database Utilities !!!',
                      style: gBuildArcadeTextStyle((GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0), gTextColor: Colors.amber),
                    ),
                    SizedBox(height: GlobalAppDisplay.safeHeight * 0.004),

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
                        icon: Icon(Icons.delete_sweep, size: GlobalAppDisplay.safeHeight * 0.016),
                        label: Text(
                          'CLEAR PLAYERS & TEAMS',
                          style: gBuildArcadeTextStyle((GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.014)),
          ),
        ],
      );
    },
  );
}