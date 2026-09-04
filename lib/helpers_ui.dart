// Flutter basics
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gif_view/gif_view.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/helpers_assets.dart';

enum FormMode{
  formAdd,
  formModify
}

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
      return "This app was created for :\nThe LGGDS Darts League\nStoneham-et-Tewkesbury, Quebec\nCanada";
    case 2:      
      return "1. First deployment\n";
    case 3:
      return "Some artworks in this app are used with a license I bought from iconscout.com\n"
             "The rest of artworks were created by me.";
    default:
      return "";
  }
}

// Returns a retro arcade Text widget with a hard pixel drop shadow.
TextStyle gBuildArcadeTextStyle(
  double gFontSize, {
  FontWeight gFontWeight = FontWeight.normal,
  Color gTextColor = Colors.white,
  Color gShadowColor = Colors.black,
}) {
  return GoogleFonts.pressStart2p(
    fontSize: gFontSize,
    color: gTextColor,
    shadows: [
      Shadow(
        offset: const Offset(-2.0, 2.0),
        color: gShadowColor,
        blurRadius: 0.0,
      ),
    ],
  );
}

Widget gBuildArcadeActionBanner({
  required String gLeadingText,
  required String gTrailingText,
  required FormMode gFormMode,
  required VoidCallback gOnTap,
}) {
  final double responsiveTile = GlobalAppDisplay.carouselTileSize;
  final double responsiveFontSize = (responsiveTile * 0.035).clamp(10.0, 40.0);

  final ImageConfigArrow leftArrowConfig = gGetArrowImageConfig(true);
  final ImageConfigArrow rightArrowConfig = gGetArrowImageConfig(false);
  final String svgAssetPath = (gFormMode == FormMode.formAdd)
      ? 'assets/svg/ui_buttons/player_team_add.svg'
      : 'assets/svg/ui_buttons/player_team_save.svg';

  return Material(
    color: Colors.transparent,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: responsiveTile * 0.02),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Right Arrow on left side
          GifView.asset(
            rightArrowConfig.assetPath,
            height: rightArrowConfig.renderSize,
            fit: BoxFit.contain,
          ),
          SizedBox(width: responsiveTile * 0.015),
          
          // INKWELL WRAPS ONLY THE PILL NOW
          InkWell(
            onTap: gOnTap,
            borderRadius: BorderRadius.circular(responsiveTile * 0.04),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsiveTile * 0.035,
                vertical: responsiveTile * 0.01,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade800,
                borderRadius: BorderRadius.circular(responsiveTile * 0.04),
                border: Border.all(
                  color: Colors.white,
                  width: responsiveTile * 0.006,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gLeadingText,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize,
                      gTextColor: Colors.lightBlueAccent,
                    ),
                  ),
                  SizedBox(width: responsiveTile * 0.02),
                  SvgPicture.asset(
                    svgAssetPath,
                    width: (responsiveTile * 0.07).clamp(24.0, 128.0),
                    height: (responsiveTile * 0.07).clamp(24.0, 128.0),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: responsiveTile * 0.02),
                  Text(
                    gTrailingText,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize,
                      gTextColor: Colors.lightBlueAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(width: responsiveTile * 0.015),
          // Left Arrow on right side
          GifView.asset(
            leftArrowConfig.assetPath,
            height: leftArrowConfig.renderSize,
            fit: BoxFit.contain,
          ),
        ],
      ),
    ),
  );
}

void gShowArcadeErrorSnackBar({
  required BuildContext gContext,
  required double gFontSize,
  required String gMessage,
  required int gDuration,
  Color? gBbackgroundColor,
}){
  ScaffoldMessenger.of(gContext).hideCurrentSnackBar();
  ScaffoldMessenger.of(gContext).showSnackBar(
    SnackBar(
      backgroundColor: gBbackgroundColor ?? Colors.red.shade800,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        left: GlobalAppDisplay.safeWidth * 0.05,
        right: GlobalAppDisplay.safeWidth * 0.05,
        bottom: GlobalAppDisplay.safeHeight * 0.05,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      content: Center(
        child: Text(
          gMessage,
          style: gBuildArcadeTextStyle((gFontSize * 0.70).clamp(10.0, 60.0)),
        ),
      ),
      duration: Duration(seconds: gDuration),
    ),
  );
}

void gShowDatabaseSeedDialog(
  BuildContext context, {
  required Color tileColor,
  required Color tileBackgroundColor,
  required String assetFullPath,
  required String headerText,
  required String titleText,
  required String questionText,
  required String noButtonText,
  required String yesButtonText,
  required void Function(BuildContext dialogContext) onNoPressed,
  required void Function(BuildContext dialogContext) onYesPressed,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: Colors.white24, width: 1.0),
        ),
        title: null,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: GlobalAppDisplay.carouselTileSize * 0.45,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Builder(
                    builder: (context) {
                      return SizedBox(
                        width: GlobalAppDisplay.carouselTileSize,
                        height: GlobalAppDisplay.carouselTileSize,
                        child: Stack(
                          children: [
                            // 1. Color fill tucked inside fixed canvas dimensions
                            Positioned.fill(
                              child: Padding(
                                padding: EdgeInsets.all(GlobalAppDisplay.carouselTileSize * 0.03),
                                child: Container(color: tileColor),
                              ),
                            ),
                            // 2. PNG frame overlaid on top with transparency support
                            Positioned.fill(
                              child: Image.asset(
                                assetFullPath,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            SizedBox(width: GlobalAppDisplay.carouselTileSize * 0.13),
            
            // Column 2: Right-Side Stack (Title, Content, and Buttons)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Styled Title Box
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: tileBackgroundColor, width: 1.5),
                      ),
                      child: Text(
                        headerText,
                        textAlign: TextAlign.center,
                        style: gBuildArcadeTextStyle(GlobalAppDisplay.carouselTileSize * 0.035, gTextColor: Colors.amber),
                      ),
                    ),

                    SizedBox(height: GlobalAppDisplay.carouselTileSize * 0.06),
                    
                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: gBuildArcadeTextStyle(GlobalAppDisplay.carouselTileSize * 0.035),
                    ),
                    
                    SizedBox(height: GlobalAppDisplay.carouselTileSize * 0.06),

                    // Content Question Text
                    Text(
                      questionText,
                      style: gBuildArcadeTextStyle(GlobalAppDisplay.carouselTileSize * 0.035),
                    ),

                    SizedBox(height: GlobalAppDisplay.carouselTileSize * 0.03),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              backgroundColor: Colors.red.shade800,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                            ),
                            onPressed: () => onNoPressed(dialogContext),
                            child: Text(
                              noButtonText,
                              textAlign: TextAlign.center,
                              style: gBuildArcadeTextStyle(GlobalAppDisplay.carouselTileSize * 0.035),
                            ),
                          ),
                        ),
                          
                        SizedBox(width: GlobalAppDisplay.carouselTileSize * 0.02),
                          
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.amber, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                            ),
                            onPressed: () => onYesPressed(dialogContext),
                            child: Text(
                              yesButtonText,
                              textAlign: TextAlign.center,
                              style: gBuildArcadeTextStyle(GlobalAppDisplay.carouselTileSize * 0.035),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: const [], // Empty since buttons are contained in the right column
      );
    },
  );
}

Widget gBuildPlayerAvatarCard({
  required TblPlayer player, 
  required ImageConfigAvatar avatarFrameImageConfig,
  required ImageConfigAvatar avatarPlayerImageConfig,
  required GlobalSettingType enuSettingType,
}) {
  return Center(
    child: AspectRatio(
      aspectRatio: 1.0,
      child: FittedBox(
        fit: BoxFit.contain, // Forces artwork and text to scale together proportionally
        child: SizedBox(
          width: avatarFrameImageConfig.renderSize,
          height: avatarFrameImageConfig.renderSize,
          child: Stack(
            children: [
              // 1. Dynamic Circle Background Layer
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: avatarFrameImageConfig.renderSize,
                child: Center(
                  child: Container(
                    width: avatarFrameImageConfig.renderSize * 0.95,
                    height: avatarFrameImageConfig.renderSize * 0.95,
                    decoration: BoxDecoration(
                      color: enuSettingType.tileBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // 2. Avatar Artwork
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: avatarFrameImageConfig.renderSize,
                child: Image.asset(
                  avatarPlayerImageConfig.assetPath,
                  fit: BoxFit.contain,
                ),
              ),

              // 3. Metallic Frame Overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: avatarFrameImageConfig.renderSize,
                child: Image.asset(
                  avatarFrameImageConfig.assetPath,
                  fit: BoxFit.contain,
                ),
              ),

              // 4. Player Nickname Pill
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: avatarFrameImageConfig.renderSize * 0.045,
                      vertical: avatarFrameImageConfig.renderSize * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.shade100,
                      borderRadius: BorderRadius.circular(avatarFrameImageConfig.renderSize * 0.04),
                      border: Border.all(
                        color: Colors.purpleAccent.shade700,
                        width: avatarFrameImageConfig.renderSize * 0.006,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        player.fldNickName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: gBuildArcadeTextStyle(
                          avatarFrameImageConfig.renderSize * 0.062,
                          gFontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget gBuildTeamCardMainUI({
  required ImageConfigTeamCardFrame teamCardFrameImageConfig, // = gGetMainUITeamCardHFrameImage(),
  required ImageConfigAvatar avatarPlayer1ImageConfig, // = gGetAvatarPlayerCardImageConfig(_selectedAvatarCodePlayer1);
  required ImageConfigAvatar avatarPlayer2ImageConfig, // = gGetAvatarPlayerCardImageConfig(_selectedAvatarCodePlayer2);
  required Color colorBgAvatar,
  required bool isDummyTeam,
  required TblPlayer? selectedPlayer1,
  required TblPlayer? selectedPlayer2,
}) {
  

  return SizedBox(
    width: teamCardFrameImageConfig.renderWidth,
    height: teamCardFrameImageConfig.renderHeight,
    child: Stack(
      children: [
        // 1. Player 1 Solid Color Circle (Left Half Background)
        Positioned(
          top: 0,
          bottom: 0,
          left: teamCardFrameImageConfig.renderWidth * 0.02,
          width: avatarPlayer1ImageConfig.renderSize,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: colorBgAvatar,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // 2. Player 2 Solid Color Circle (Right Background)
        Positioned(
          top: 0,
          bottom: 0,
          right: teamCardFrameImageConfig.renderWidth * 0.02,
          width: avatarPlayer2ImageConfig.renderSize,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: colorBgAvatar,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // 3. Player 1 Avatar Artwork (Left Half)
        Positioned(
          top: 0,
          bottom: 0,
          left: teamCardFrameImageConfig.renderWidth * 0.01,
          width: avatarPlayer1ImageConfig.renderSize,
          child: Image.asset(
            avatarPlayer1ImageConfig.assetPath,
            fit: BoxFit.contain,
          ),
        ),

        // 4. Player 2 Avatar Artwork (Right Half)
        Positioned(
          top: 0,
          bottom: 0,
          right: teamCardFrameImageConfig.renderWidth * 0.01,
          width: avatarPlayer2ImageConfig.renderSize,
          child: Image.asset(
            avatarPlayer2ImageConfig.assetPath,
            fit: BoxFit.contain,
          ),
        ),

        // 5. Metallic Frame Overlay
        Positioned.fill(
          child: Image.asset(
            teamCardFrameImageConfig.assetPathFrame,
            fit: BoxFit.contain,
          ),
        ),

        // 6. Dummy Player Layer
        if (isDummyTeam) // e.g., checking if this slot is a dummy
          Positioned.fill(
            child: Image.asset(
              teamCardFrameImageConfig.assetPathIsDummyPlayer,
              fit: BoxFit.fill,
            ),
          ),

        // 7. Player 1 Nickname Pill (Left Slot)
        if (selectedPlayer1 != null)
          Positioned(
            bottom: teamCardFrameImageConfig.renderHeight * 0.13,
            left: 0,
            width: avatarPlayer1ImageConfig.renderSize,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: avatarPlayer1ImageConfig.renderSize * 0.045,
                  vertical: avatarPlayer1ImageConfig.renderSize * 0.015,
                ),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.shade100,
                  borderRadius: BorderRadius.circular(avatarPlayer1ImageConfig.renderSize * 0.04),
                  border: Border.all(
                    color: Colors.purpleAccent.shade700,
                    width: avatarPlayer1ImageConfig.renderSize * 0.006,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    selectedPlayer1.fldNickName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      avatarPlayer1ImageConfig.renderSize * 0.062,
                      gFontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        // 8. Player 2 Nickname Pill (Right Slot)
        if (selectedPlayer2 != null)
          Positioned(
            bottom: teamCardFrameImageConfig.renderHeight * 0.13,
            right: 0,
            width: avatarPlayer2ImageConfig.renderSize,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: avatarPlayer2ImageConfig.renderSize * 0.045,
                  vertical: avatarPlayer2ImageConfig.renderSize * 0.015,
                ),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.shade100,
                  borderRadius: BorderRadius.circular(avatarPlayer2ImageConfig.renderSize * 0.04),
                  border: Border.all(
                    color: Colors.purpleAccent.shade700,
                    width: avatarPlayer2ImageConfig.renderSize * 0.006,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    selectedPlayer2.fldNickName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: gBuildArcadeTextStyle(
                      avatarPlayer2ImageConfig.renderSize * 0.062,
                      gFontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]
    ),
  );
}