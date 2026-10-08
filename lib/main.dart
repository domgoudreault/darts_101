// Flutter basics
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// Database Models
import 'package:darts_101/database/enum_game_type.dart';
import 'package:darts_101/database/tbl_avatar.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_game_score.dart';
import 'package:darts_101/database/tbl_game_options.dart';
import 'package:darts_101/hive_registrar.g.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';
import 'package:darts_101/helpers_database.dart';

// UI Screens
import 'package:darts_101/options_game.dart';
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
  ),

  section15Options(
    sectionCode: 'options',
    assetPath: 'assets/svg/mechanics/section_options.svg',
  );

  final String sectionCode;
  final String assetPath;

  const MainScreenSection({required this.sectionCode, required this.assetPath});
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
    Hive.openBox<TblGameScore>('gamesScoresBox'),
    Hive.openBox<TblGameOptions>('gameOptionsBox'),
  ]);

  // Extract the box references you need for seeding:
  final avatarsBox = results[0] as Box<TblAvatar>;
  final optionsBox = results[5] as Box<TblGameOptions>;

  // Only seeds avatars if the database is empty
  if (avatarsBox.isEmpty) {
    await gSeedHiveAvatars(avatarsBox);
  }

  // Only seed game options if the box is empty
  if (optionsBox.isEmpty) {
    await gSeedHiveGameOptions(optionsBox);
  }

  // Wrap runApp with DevicePreview
  runApp(
    DevicePreview(enabled: false, builder: (context) => const Darts101App()),
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
        GlobalAppDisplay.globalEnumDisplayMode(context);

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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: (GlobalAppDisplay.safeWidth * 0.026),
            ),
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
                          padding: EdgeInsets.symmetric(
                            vertical: GlobalAppDisplay.safeHeight * 0.022,
                          ),
                          child: Text(
                            "Overview",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: (GlobalAppDisplay.safeWidth * 0.020),
                            ),
                          ),
                        ),
                        Text(
                          gGetPrivacyPolicySection(1),
                          style: TextStyle(
                            fontSize: (GlobalAppDisplay.safeWidth * 0.017),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: GlobalAppDisplay.safeHeight * 0.022,
                          ),
                          child: Text(
                            "Information Collection and Use",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: (GlobalAppDisplay.safeWidth * 0.020),
                            ),
                          ),
                        ),
                        Text(
                          gGetPrivacyPolicySection(2),
                          style: TextStyle(
                            fontSize: (GlobalAppDisplay.safeWidth * 0.017),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: GlobalAppDisplay.safeHeight * 0.022,
                          ),
                          child: Text(
                            "Third-Party Services & Analytics",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: (GlobalAppDisplay.safeWidth * 0.020),
                            ),
                          ),
                        ),

                        Text(
                          gGetPrivacyPolicySection(3),
                          style: TextStyle(
                            fontSize: (GlobalAppDisplay.safeWidth * 0.017),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: GlobalAppDisplay.safeHeight * 0.022,
                          ),
                          child: Text(
                            "Log Data & Device Permissions",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: (GlobalAppDisplay.safeWidth * 0.020),
                            ),
                          ),
                        ),
                        Text(
                          gGetPrivacyPolicySection(4),
                          style: TextStyle(
                            fontSize: (GlobalAppDisplay.safeWidth * 0.017),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: GlobalAppDisplay.safeHeight * 0.022,
                          ),
                          child: Text(
                            "Data Retention & Account Deletion",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: (GlobalAppDisplay.safeWidth * 0.020),
                            ),
                          ),
                        ),
                        Text(
                          gGetPrivacyPolicySection(5),
                          style: TextStyle(
                            fontSize: (GlobalAppDisplay.safeWidth * 0.017),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: GlobalAppDisplay.safeHeight * 0.022,
                          ),
                          child: Text(
                            "Contact Us",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: (GlobalAppDisplay.safeWidth * 0.020),
                            ),
                          ),
                        ),
                        Text(
                          gGetPrivacyPolicySection(6),
                          style: TextStyle(
                            fontSize: (GlobalAppDisplay.safeWidth * 0.017),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () async {
                              final Uri url = Uri.parse(
                                gGetPrivacyPolicySection(7),
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
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
                Divider(
                  thickness: GlobalAppDisplay.safeHeight * 0.003,
                  height: GlobalAppDisplay.safeHeight * 0.04,
                ),
                SizedBox(
                  width: double.infinity,
                  height: GlobalAppDisplay.safeWidth * 0.052,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          GlobalAppDisplay.safeWidth * 0.012,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: gBuildArcadeTextStyle(
                        GlobalAppDisplay.safeWidth * 0.014,
                      ),
                    ),
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
                                padding: EdgeInsets.symmetric(
                                  vertical: GlobalAppDisplay.safeHeight * 0.022,
                                ),
                                child: Text(
                                  gGetInformationSection(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        GlobalAppDisplay.safeWidth * 0.020,
                                  ),
                                ),
                              ),
                              Text(
                                "Version: ${packageInfo.version}\nBuild: ${packageInfo.buildNumber}",
                                style: TextStyle(
                                  fontSize: GlobalAppDisplay.safeWidth * 0.017,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: GlobalAppDisplay.safeHeight * 0.022,
                                ),
                                child: Text(
                                  "\nLatest Changes:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        GlobalAppDisplay.safeWidth * 0.020,
                                  ),
                                ),
                              ),
                              Text(
                                gGetInformationSection(2),
                                style: TextStyle(
                                  fontSize:
                                      (GlobalAppDisplay.safeWidth * 0.017),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: GlobalAppDisplay.safeHeight * 0.022,
                                ),
                                child: Text(
                                  "Artwork Attributions:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        GlobalAppDisplay.safeWidth * 0.020,
                                  ),
                                ),
                              ),
                              Text(
                                gGetInformationSection(3),
                                style: TextStyle(
                                  fontSize:
                                      (GlobalAppDisplay.safeWidth * 0.017),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: GlobalAppDisplay.safeWidth * 0.007,
                        ), // Space between text and image
                        // THE IMAGE ON THE RIGHT
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  GlobalAppDisplay.safeWidth * 0.012,
                                ),
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
                Divider(
                  thickness: GlobalAppDisplay.safeHeight * 0.003,
                  height: GlobalAppDisplay.safeHeight * 0.04,
                ),
                SizedBox(
                  width: double.infinity,
                  height: GlobalAppDisplay.safeWidth * 0.052,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          GlobalAppDisplay.safeWidth * 0.012,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: gBuildArcadeTextStyle(
                        GlobalAppDisplay.safeWidth * 0.014,
                      ),
                    ),
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
      child: Text(
        text,
        style: gBuildArcadeTextStyle(
          (GlobalAppDisplay.safeWidth * 0.012).clamp(11.0, 18.0),
        ),
      ),
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
  MainScreenSection _activeSection = MainScreenSection.section10Settings;

  bool _isCached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isCached || !mounted) {
        return;
      }

      _isCached = true;
      _precacheAllAssets();
    });
  }

  Future<void> _precacheAllAssets() async {
    final assetPaths = <String>[];

    for (final tile in GlobalGameType.values) {
      assetPaths.add('assets/png/tiles/${tile.tileType}_${tile.tileCode}.png');
    }
    for (final tile in GlobalSettingType.values) {
      assetPaths.add('assets/png/tiles/${tile.tileType}_${tile.tileCode}.png');
    }

    assetPaths.addAll([
      'assets/png/logos/LGGDS.png',
      'assets/png/mechanics/arrow_left.png',
      'assets/png/mechanics/arrow_right.png',
      'assets/png/mechanics/database.png',
      'assets/png/mechanics/hits.png',
      'assets/png/mechanics/player_avatar.png',
      'assets/png/mechanics/player_card_bg.png',
      'assets/png/mechanics/player_card_frame.png',
      'assets/png/mechanics/player_dummy_H.png',
      'assets/png/mechanics/player_dummy_icon.png',
      'assets/png/mechanics/player_dummy_V.png',
      'assets/png/mechanics/player_league_member.png',
      'assets/png/mechanics/resume_game.png',
      'assets/png/mechanics/save_game.png',
      'assets/png/mechanics/scoreboard.png',
      'assets/png/mechanics/section_games.png',
      'assets/png/mechanics/section_settings.png',
      'assets/png/mechanics/section_options.png',
      'assets/png/mechanics/shuffle_players.png',
      'assets/png/mechanics/shuffle_teams.png',
      'assets/png/mechanics/start_game.png',
      'assets/png/mechanics/stats.png',
      'assets/png/mechanics/team_card_frame_H.png',
      'assets/png/mechanics/team_card_frame_V.png',
      'assets/png/mechanics/undo.png',
      'assets/png/mechanics/target_miss.png',
      'assets/png/mechanics/target_single.png',
      'assets/png/mechanics/target_double.png',
      'assets/png/mechanics/target_triple.png',
      'assets/png/mechanics/trophy.png',
    ]);

    for (int i = 1; i <= 12; i++) {
      assetPaths.add('assets/png/mechanics/rs_tag_p_$i.png');
      assetPaths.add('assets/png/mechanics/rs_tag_t_$i.png');
    }

    final avatarsBox = Hive.box<TblAvatar>('avatarsBox');
    for (final avatar in avatarsBox.values) {
      if (avatar.fldAvatarCode != 'question') {
        assetPaths.add(
          'assets/png/avatars/avatar_${avatar.fldAvatarCode}_player_card.png',
        );
      }
      assetPaths.add(
        'assets/png/avatars/avatar_${avatar.fldAvatarCode}_v1.png',
      );
    }

    if (!mounted) return;

    await Future.wait(
      assetPaths.map((path) => precacheImage(AssetImage(path), context)),
    );
  }

  // Fonction de navigation when a button is pressed
  void _onTileTapped(BuildContext context, dynamic tile) {
    Widget? destination;

    if (tile is GlobalGameType) {
      if (_activeSection == MainScreenSection.section15Options) {
        showDialog(
          context: context,
          builder: (_) => GameOptionsDialog(enuGameType: tile),
        );
        return;
      } else {
        destination = RostersSelection(enuGameType: tile);
      }
    } else if (tile is GlobalSettingType) {
      destination = switch (tile) {
        GlobalSettingType.players => SettingsPlayers(enuSettingType: tile),
        GlobalSettingType.teams => SettingsTeams(enuSettingType: tile),
      };
    }

    if (destination != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
      return;
    }

    gShowArcadeErrorSnackBar(
      gContext: context,
      gFontSize: (GlobalAppDisplay.safeWidth * 0.011).clamp(14.0, 28.0),
      gMessage: _activeSection == MainScreenSection.section15Options
          ? 'Configure options for ${tile.tileDisplayName}!'
          : '${tile.tileDisplayName} was clicked!',
      gDuration: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final safeWidth = size.width;
    final safeHeight = size.height;
    final toolbarHeight = (safeHeight * 0.10).clamp(56.0, 142.0);
    final contentHeight = safeHeight - toolbarHeight;
    final activeTiles = [];
    
    switch (_activeSection) {
      case MainScreenSection.section05Games:
        activeTiles.addAll(GlobalGameType.values);
        break;
      case MainScreenSection.section10Settings:
        activeTiles.addAll(GlobalSettingType.values);
        break;
      case MainScreenSection.section15Options:
        final optionsBox = Hive.box<TblGameOptions>('gameOptionsBox');

        for (final gameType in GlobalGameType.values) {
          final options = optionsBox.values.firstWhere(
            (opt) => opt.fldGameType == gameType,
          );

          if (options.hasVisibleOptions) {
            activeTiles.add(gameType);
          }
        }
        break;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade800,
      appBar: gBuildAppBar(
        gToolbarHeight: toolbarHeight,
        gAppBarTitle: widget.title,
        gAppBarColorBg: Colors.grey.shade800,
        gCallFromMainScreen: true,
        gOnPressed: () => _showDebugCarouselImageDialog(context),
        gRightPopupMenu: const MainScreenPopupMenu(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: safeWidth * 0.008,
                vertical: safeHeight * 0.008,
              ),
              height: contentHeight * (7 / 32),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  _buildSectionToggleButton(
                    section: MainScreenSection.section05Games,
                  ),
                  SizedBox(width: safeWidth * 0.012),
                  _buildSectionToggleButton(
                    section: MainScreenSection.section10Settings,
                  ),
                  SizedBox(width: safeWidth * 0.012),
                  _buildSectionToggleButton(
                    section: MainScreenSection.section15Options,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: (contentHeight * (25 / 32)) * activeTiles.length,
                  child: CarouselView(
                    itemExtent: contentHeight * (25 / 32),
                    shrinkExtent: contentHeight * 0.15,
                    backgroundColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    onTap: (int index) {
                      _onTileTapped(context, activeTiles[index]);
                    },
                    children: activeTiles
                        .map(
                          (tile) =>
                              _buildMainScreenTile(context, tile, safeWidth),
                        )
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

  Widget _buildMainScreenTile(
    BuildContext context,
    dynamic tile,
    double safeWidth,
  ) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: SizedBox(
          width: safeWidth * 0.40,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  widthFactor: 0.94,
                  heightFactor: 0.94,
                  child: Container(color: tile.tileColor),
                ),
              ),
              Positioned.fill(
                child: Image.asset(
                  'assets/png/tiles/${tile.tileType}_${tile.tileCode}.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // Top-right corner options badge overlay
              if (_activeSection == MainScreenSection.section15Options) ...[
                Positioned(
                  top: safeWidth * 0.005,
                  right: safeWidth * 0.005,
                  child: Container(
                    padding: EdgeInsets.all(safeWidth * 0.003),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900.withAlpha(150),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber,
                        width: safeWidth * 0.003,
                      ),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.amber,
                      size: safeWidth * 0.04,
                    ),
                  ),
                ),

                Positioned(
                  top: safeWidth * 0.005,
                  left: safeWidth * 0.005,
                  child: Container(
                    padding: EdgeInsets.all(safeWidth * 0.003),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900.withAlpha(150),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber,
                        width: safeWidth * 0.003,
                      ),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.amber,
                      size: safeWidth * 0.04,
                    ),
                  ),
                ),

                Positioned(
                  bottom: safeWidth * 0.005,
                  left: safeWidth * 0.005,
                  child: Container(
                    padding: EdgeInsets.all(safeWidth * 0.003),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900.withAlpha(150),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber,
                        width: safeWidth * 0.003,
                      ),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.amber,
                      size: safeWidth * 0.04,
                    ),
                  ),
                ),

                Positioned(
                  bottom: safeWidth * 0.005,
                  right: safeWidth * 0.005,
                  child: Container(
                    padding: EdgeInsets.all(safeWidth * 0.003),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900.withAlpha(150),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber,
                        width: safeWidth * 0.003,
                      ),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.amber,
                      size: safeWidth * 0.04,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionToggleButton({required MainScreenSection section}) {
    final bool isSelected = _activeSection == section;
    final size = MediaQuery.sizeOf(context);
    final safeWidth = size.width;
    final safeHeight = size.height;

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
            padding: EdgeInsets.symmetric(vertical: safeHeight * 0.004),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.amber : Colors.transparent,
                width: safeWidth * 0.004,
              ),
              borderRadius: BorderRadius.circular(safeWidth * 0.012),
            ),
            child: Center(
              child: AspectRatio(
                aspectRatio: 2.04266,
                child: SizedBox(
                  width: safeWidth * 0.20,
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
  await Hive.box<TblGameScore>('gamesScoresBox').clear();
  await Hive.box<TblGame>('gamesBox').clear();
  await Hive.box<TblPlayer>('playersBox').clear();
  await Hive.box<TblTeam>('teamsBox').clear();
  gSelectedPlayers.clear();
  gSelectedTeams.clear();

  if (context.mounted) {
    gShowArcadeErrorSnackBar(
      gContext: context,
      gFontSize: 16,
      gMessage: 'PLAYERS & TEAMS CLEARED!',
      gDuration: 2,
    );
  }
}

Future<void> _clearHiveGames(BuildContext context) async {
  // Clear primary user data and game logs
  await Hive.box<TblGameScore>('gamesScoresBox').clear();
  await Hive.box<TblGame>('gamesBox').clear();

  if (context.mounted) {
    gShowArcadeErrorSnackBar(
      gContext: context,
      gFontSize: 16,
      gMessage: 'GAMES CLEARED!',
      gDuration: 2,
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
          style: gBuildArcadeTextStyle(
            (GlobalAppDisplay.safeWidth * 0.015).clamp(14.0, 32.0),
          ),
        ),
        content: SizedBox(
          height: GlobalAppDisplay.safeHeight * 0.7,
          width: GlobalAppDisplay.safeWidth * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safe Screen Width: ${GlobalAppDisplay.safeWidth.toStringAsFixed(1)} dp',
                  style: gBuildArcadeTextStyle(
                    (GlobalAppDisplay.safeWidth * 0.011).clamp(10.0, 28.0),
                  ),
                ),
                SizedBox(height: GlobalAppDisplay.safeHeight * 0.002),
                Text(
                  'Safe Screen Height: ${GlobalAppDisplay.safeHeight.toStringAsFixed(1)} dp',
                  style: gBuildArcadeTextStyle(
                    (GlobalAppDisplay.safeWidth * 0.011).clamp(10.0, 28.0),
                  ),
                ),
                Divider(
                  color: Colors.white24,
                  height: GlobalAppDisplay.safeHeight * 0.044,
                ),
                Text(
                  'Database Utilities !!!',
                  style: gBuildArcadeTextStyle(
                    (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                    gTextColor: Colors.amber,
                  ),
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
                    icon: Icon(
                      Icons.delete_sweep,
                      size: GlobalAppDisplay.safeHeight * 0.016,
                    ),
                    label: Text(
                      'DELETE PLAYERS & TEAMS',
                      style: gBuildArcadeTextStyle(
                        (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _clearHiveGames(context);
                    },
                    icon: Icon(
                      Icons.delete_sweep,
                      size: GlobalAppDisplay.safeHeight * 0.016,
                    ),
                    label: Text(
                      'DELETE GAMES & SCORES',
                      style: gBuildArcadeTextStyle(
                        (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await gSeedHiveGameHalfItPlayerWinner();
                    },
                    icon: Icon(
                      Icons.add_alarm,
                      size: GlobalAppDisplay.safeHeight * 0.016,
                    ),
                    label: Text(
                      'CREATE HALF-IT PLAYER WINNER',
                      style: gBuildArcadeTextStyle(
                        (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await gSeedHiveGameHalfItPlayerTie();
                    },
                    icon: Icon(
                      Icons.add_link,
                      size: GlobalAppDisplay.safeHeight * 0.016,
                    ),
                    label: Text(
                      'CREATE HALF-IT PLAYER TIE',
                      style: gBuildArcadeTextStyle(
                        (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await gSeedHiveGameHalfItTeamWinner();
                    },
                    icon: Icon(
                      Icons.add_alarm,
                      size: GlobalAppDisplay.safeHeight * 0.016,
                    ),
                    label: Text(
                      'CREATE HALF-IT TEAM WINNER',
                      style: gBuildArcadeTextStyle(
                        (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await gSeedHiveGameHalfItTeamTie();
                    },
                    icon: Icon(
                      Icons.add_link,
                      size: GlobalAppDisplay.safeHeight * 0.016,
                    ),
                    label: Text(
                      'CREATE HALF-IT TEAM TIE',
                      style: gBuildArcadeTextStyle(
                        (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await gSeedHiveGame7DartsPlayerWinner();
                    },
                    icon: Icon(
                      Icons.add_alarm,
                      size: GlobalAppDisplay.safeHeight * 0.016,
                    ),
                    label: Text(
                      'CREATE 7-DARTS PLAYER WINNER',
                      style: gBuildArcadeTextStyle(
                        (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await gSeedHiveGame7DartsPlayerTie();
                    },
                    icon: Icon(
                      Icons.add_link,
                      size: GlobalAppDisplay.safeHeight * 0.016,
                    ),
                    label: Text(
                      'CREATE 7-DARTS PLAYER TIE',
                      style: gBuildArcadeTextStyle(
                        (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await gSeedHiveGame7DartsTeamWinner();
                    },
                    icon: Icon(
                      Icons.add_alarm,
                      size: GlobalAppDisplay.safeHeight * 0.016,
                    ),
                    label: Text(
                      'CREATE 7-DARTS TEAM WINNER',
                      style: gBuildArcadeTextStyle(
                        (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await gSeedHiveGame7DartsTeamTie();
                    },
                    icon: Icon(
                      Icons.add_link,
                      size: GlobalAppDisplay.safeHeight * 0.016,
                    ),
                    label: Text(
                      'CREATE 7-DARTS TEAM TIE',
                      style: gBuildArcadeTextStyle(
                        (GlobalAppDisplay.safeWidth * 0.012).clamp(12.0, 28.0),
                      ),
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
            child: Text(
              'Close',
              style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.014),
            ),
          ),
        ],
      );
    },
  );
}
