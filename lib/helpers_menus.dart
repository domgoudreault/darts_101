// Flutter basics
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Database Models
import 'package:darts_101/database/enum_game_type.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_ui.dart';

String gGetPrivacyPolicySection(int section) {
  switch (section) {
    case 1:
      return "Darts 101 is a paid, standalone scorekeeping application designed for darts players.\n"
          "Your privacy is paramount: Darts 101 operates entirely locally on your device and does not collect, transmit, share, or sell any personal or sensitive user data.\n";
    case 2:
      return "Players Data: Any information you enter into the application (such as : player first names, last names, nicknames, and game scores) is stored strictly on your device’s local internal storage.\n"
          "Zero Remote Data Collection: We do not collect, transmit, or back up your information to any remote server, cloud platform, or developer-owned system. We have zero remote access to your device or your saved application data.\n";
    case 3:
      return "Darts 101 does not contain tracking code, third-party advertising SDKs, analytics frameworks (such as Firebase Analytics or Crashlytics), or remote database integrations.\n";
    case 4:
      return "Darts 101 does not track or log your IP address, device IDs, location data, or usage habits. The application only requires standard system execution permissions necessary to run locally on your devices.\n";
    case 5:
      return "Because Darts 101 does not require account creation and stores all data locally on your device, you remain in complete control of your data. You can permanently delete all saved profiles and game statistics at any time by clearing the app data in your device settings or by uninstalling the application.\n";
    case 6:
      return "If you have any questions regarding this Privacy Policy:";
    case 7:
      return "https://sites.google.com/view/darts101-privacy-policy";
    default:
      return "";
  }
}

String gGetInformationSection(int section) {
  switch (section) {
    case 1:
      return "This app was created for :\nThe LGGDS Darts League\nStoneham-et-Tewkesbury, Québec\nCanada";
    case 2:
      return "1. First deployment\n";
    case 3:
      return "Some artworks in this app are used with a license I bought from openart.ai !\n"
          "The rest of artworks were created by me.";
    default:
      return "";
  }
}

String gGetGameRulesSection(GlobalGameType gameType) {
  switch (gameType) {
    case GlobalGameType.halfIt:
      return "Half-It Rules:\n\n"
          "1 • Each player or team starts with a minimum score\n"
          "       (25 points per player by default, can be changed in options of the game)\n\n"
          "2 • Players take turns throwing 3 darts at specific targets\n"
          "       in a set sequence (10 through 20 and finishing with Bullseye)\n\n"
          "3 • Only successful hits on the designated target score points (Singles, Doubles and Triples)\n\n"
          "4 • If you fail to hit the designated target at least once\n"
          "       with all 3 darts, your total accumulated score is HALVED!\n\n"
          "5 • The player or team with the highest score at the end of all rounds wins!";
    case GlobalGameType.sevenDarts:
      return "7 Darts Rules:\n\n"
          "1 • Players take turns throwing 7 completely different darts\n"
          "       with each dart contributed by a different player if possible!\n\n"
          "2 • Since every darts vary in weight, grip, barrels, and flights, adaptability is key!\n\n"
          "3 • The game consists of 3 rounds hitting 7 different target each time\n"
          "       (3 rounds by default, can be changed in options of the game)\n\n"
          "4 • Each round consists of throwing one dart per target\n"
          "       in descending order: 20 through 15 and finishing with Bullseye.\n\n"
          "5 • If you successfully hit a target and then hit the next target in the sequence consecutively\n"
          "       you earn a bonus equal to the score of your previous successful hit added to your current target score!\n\n"
          "6 • The player or team with the highest score at the end of of all rounds wins!";
    case GlobalGameType.aroundClock:
      return "Around the Clock Rules:\n\n"
          "1. Players must hit numbers 1 through 20 in sequential order.\n"
          "2. You can skip numbers or advance faster depending on your variant settings.\n"
          "3. The first player to successfully hit the final target wins.";
    case GlobalGameType.allFives:
      return "All Fives Rules:\n\n"
          "1. Each dart thrown must result in a total score that is divisible by 5 to score points.\n"
          "2. For example, a score of 15 yields 3 points (15 / 5).\n"
          "3. First player to reach the target score wins.";
    case GlobalGameType.killers:
      return "Killers Rules:\n\n"
          "1. Each player is assigned a number on the dartboard.\n"
          "2. First, hit doubles to become a 'Killer'.\n"
          "3. Once a Killer, hit other players' numbers to take away their lives until only one player remains.";
    case GlobalGameType.suddenDeath:
      return "Sudden Death Rules:\n\n"
          "1. High-pressure round where every missed target results in immediate elimination or severe point penalties.\n"
          "2. Precision under pressure decides the ultimate survivor.";
    case GlobalGameType.buildUp:
      return "Team Build-up Rules:\n\n"
          "1. Teams collaborate to build up scores across shared target sectors.\n"
          "2. Strategic coordination between team members maximizes total points per round.";
  }
}

void gShowInformationDialog(BuildContext context) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final double safeHeight = GlobalAppDisplay.safeHeight;
  final double safeWidth = GlobalAppDisplay.safeWidth;

  if (!context.mounted) return;

  showDialog(
    context: context,
    useSafeArea: true,
    builder: (BuildContext context) {
      MediaQuery.sizeOf(context);

      return AlertDialog(
        content: SizedBox(
          // Set a fixed height so the dialog doesn't jump around
          height: safeHeight * 0.85,
          width: safeWidth * 0.85,
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
                                vertical: safeHeight * 0.022,
                              ),
                              child: Text(
                                gGetInformationSection(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      safeWidth * 0.020,
                                ),
                              ),
                            ),
                            Text(
                              "Version: ${packageInfo.version}\nBuild: ${packageInfo.buildNumber}",
                              style: TextStyle(
                                fontSize: safeWidth * 0.017,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: safeHeight * 0.022,
                              ),
                              child: Text(
                                "\nLatest Changes:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      safeWidth * 0.020,
                                ),
                              ),
                            ),
                            Text(
                              gGetInformationSection(2),
                              style: TextStyle(
                                fontSize:
                                    (safeWidth * 0.017),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: safeHeight * 0.022,
                              ),
                              child: Text(
                                "Artwork Attributions:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      safeWidth * 0.020,
                                ),
                              ),
                            ),
                            Text(
                              gGetInformationSection(3),
                              style: TextStyle(
                                fontSize:
                                    (safeWidth * 0.017),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: safeWidth * 0.007,
                      ), // Space between text and image
                      // THE IMAGE ON THE RIGHT
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                safeWidth * 0.012,
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
                thickness: safeHeight * 0.003,
                height: safeHeight * 0.04,
              ),
              SizedBox(
                width: double.infinity,
                height: safeWidth * 0.052,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        safeWidth * 0.012,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: gBuildArcadeTextStyle(
                      safeWidth * 0.014,
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

void gShowPrivacyDialog(BuildContext context) {
  final double safeHeight = GlobalAppDisplay.safeHeight;
  final double safeWidth = GlobalAppDisplay.safeWidth;

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
            fontSize: (safeWidth * 0.026),
          ),
        ),
        content: SizedBox(
          height: safeHeight * 0.7,
          width: safeWidth * 0.8,
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
                          vertical: safeHeight * 0.022,
                        ),
                        child: Text(
                          "Overview",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: (safeWidth * 0.020),
                          ),
                        ),
                      ),
                      Text(
                        gGetPrivacyPolicySection(1),
                        style: TextStyle(
                          fontSize: (safeWidth * 0.017),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: safeHeight * 0.022,
                        ),
                        child: Text(
                          "Information Collection and Use",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: (safeWidth * 0.020),
                          ),
                        ),
                      ),
                      Text(
                        gGetPrivacyPolicySection(2),
                        style: TextStyle(
                          fontSize: (safeWidth * 0.017),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: safeHeight * 0.022,
                        ),
                        child: Text(
                          "Third-Party Services & Analytics",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: (safeWidth * 0.020),
                          ),
                        ),
                      ),

                      Text(
                        gGetPrivacyPolicySection(3),
                        style: TextStyle(
                          fontSize: (safeWidth * 0.017),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: safeHeight * 0.022,
                        ),
                        child: Text(
                          "Log Data & Device Permissions",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: (safeWidth * 0.020),
                          ),
                        ),
                      ),
                      Text(
                        gGetPrivacyPolicySection(4),
                        style: TextStyle(
                          fontSize: (safeWidth * 0.017),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: safeHeight * 0.022,
                        ),
                        child: Text(
                          "Data Retention & Account Deletion",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: (safeWidth * 0.020),
                          ),
                        ),
                      ),
                      Text(
                        gGetPrivacyPolicySection(5),
                        style: TextStyle(
                          fontSize: (safeWidth * 0.017),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: safeHeight * 0.022,
                        ),
                        child: Text(
                          "Contact Us",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: (safeWidth * 0.020),
                          ),
                        ),
                      ),
                      Text(
                        gGetPrivacyPolicySection(6),
                        style: TextStyle(
                          fontSize: (safeWidth * 0.017),
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
                              fontSize: (safeWidth * 0.017),
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
                thickness: safeHeight * 0.003,
                height: safeHeight * 0.04,
              ),
              SizedBox(
                width: double.infinity,
                height: safeWidth * 0.052,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        safeWidth * 0.012,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: gBuildArcadeTextStyle(
                      safeWidth * 0.014,
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

// --- Game Rules Dialog Trigger ---
void gShowGameRulesDialog(BuildContext context, GlobalGameType gameType) {
  final double safeHeight = GlobalAppDisplay.safeHeight;
  final double safeWidth = GlobalAppDisplay.safeWidth;
  final ScrollController scrollController = ScrollController();

  showDialog(
    context: context,
    useSafeArea: true,
    builder: (BuildContext context) {
      MediaQuery.sizeOf(context);

      return AlertDialog(
        backgroundColor: Colors.grey.shade500,
        title: Text(
          'Rules: ${gameType.tileDisplayName}',
          style: gBuildArcadeTextStyle(
            (safeWidth * 0.015).clamp(8.0, 60.0),
            gTextColor: Colors.amber,
          ),
        ),
        content: SizedBox(
          height: safeHeight * 0.6,
          width: safeWidth * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RawScrollbar(
                  controller: scrollController,
                    thumbColor: Colors.amber.withAlpha(180),
                    thickness: safeHeight * 0.018,
                    radius: Radius.circular(safeHeight * 0.016),
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                    controller: scrollController,
                    child: Row(
                      children: [
                        Text(
                          gGetGameRulesSection(gameType),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: safeHeight * 0.023,
                          ),
                          textAlign: TextAlign.left
                        ),

                        //SizedBox(width: safeHeight * 0.002),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. FIXED DIVIDER AND BUTTON
              Divider(
                thickness: safeHeight * 0.003,
                height: safeHeight * 0.04,
              ),
              SizedBox(
                width: double.infinity,
                height: safeWidth * 0.052,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        safeWidth * 0.012,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: gBuildArcadeTextStyle(
                      safeWidth * 0.014,
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