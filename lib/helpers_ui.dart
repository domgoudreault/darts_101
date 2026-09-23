// Flutter basics
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gif_view/gif_view.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';

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
        offset: Offset(-(gFontSize * 0.12), gFontSize * 0.12),
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
  final double responsiveTile = GlobalAppDisplay.safeHeight * 0.6;
  final double responsiveFontSize = (responsiveTile * 0.035).clamp(10.0, 40.0);

  final String svgAssetPath = (gFormMode == FormMode.formAdd)
      ? 'assets/svg/ui_buttons/player_team_add.svg'
      : 'assets/svg/ui_buttons/player_team_save.svg';

  return Material(
    color: Colors.transparent,
    child: Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Right Arrow on left side
          GifView.asset(
            'assets/png/mechanics/arrow_right.png',
            height: responsiveTile * 0.15,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
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
            'assets/png/mechanics/arrow_left.png',
            height: responsiveTile * 0.15,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
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
        left: GlobalAppDisplay.safeHeight * 0.056,
        right: GlobalAppDisplay.safeHeight * 0.056,
        bottom: GlobalAppDisplay.safeHeight * 0.056,
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
  required String noButtonText1,
  required String? noButtonText2,
  required String yesButtonText1,
  required String? yesButtonText2,
  required void Function(BuildContext dialogContext) onNoPressed,
  required void Function(BuildContext dialogContext) onYesPressed,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      MediaQuery.sizeOf(context);

      return AlertDialog(
        backgroundColor: Colors.grey.shade800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlobalAppDisplay.safeWidth * 0.015),
          side: BorderSide(color: Colors.white24, width: GlobalAppDisplay.safeHeight * 0.003),
        ),
        title: null,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: GlobalAppDisplay.safeWidth * 0.3,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Builder(
                    builder: (context) {
                      return SizedBox(
                        width: GlobalAppDisplay.safeWidth * 0.3,
                        height: GlobalAppDisplay.safeWidth * 0.3,
                        child: Stack(
                          children: [
                            // 1. Color fill tucked inside fixed canvas dimensions
                            Align(
                              alignment: Alignment.center,
                              child: FractionallySizedBox(
                                widthFactor: 0.94, // Adjust percentage to taste (e.g. 0.94 leaves a clean 3% border)
                                heightFactor: 0.94,
                                child: Container(color: tileColor),
                              ),
                            ),
                            // 2. PNG frame overlaid on top with transparency support
                            Positioned.fill(
                              child: Image.asset(
                                assetFullPath,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.high,
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
            
            SizedBox(width: GlobalAppDisplay.safeWidth * 0.016),
            
            // Column 2: Right-Side Stack (Title, Content, and Buttons)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Styled Title Box
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: GlobalAppDisplay.safeWidth * 0.008,
                        horizontal: GlobalAppDisplay.safeWidth * 0.016
                        ),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(GlobalAppDisplay.safeWidth * 0.008),
                        border: Border.all(color: tileBackgroundColor, width: GlobalAppDisplay.safeHeight * 0.003),
                      ),
                      child: Text(
                        headerText,
                        textAlign: TextAlign.center,
                        style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.015, gTextColor: Colors.amber),
                      ),
                    ),

                    SizedBox(height: GlobalAppDisplay.safeWidth * 0.026),
                    
                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.015),
                    ),
                    
                    SizedBox(height: GlobalAppDisplay.safeWidth * 0.026),

                    // Content Question Text
                    Text(
                      questionText,
                      style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.015),
                    ),

                    SizedBox(height: GlobalAppDisplay.safeWidth * 0.026),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white, width: GlobalAppDisplay.safeHeight * 0.003),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(GlobalAppDisplay.safeWidth * 0.025),
                              ),
                              backgroundColor: Colors.red.shade800,
                              padding: EdgeInsets.symmetric(horizontal: GlobalAppDisplay.safeWidth * 0.016, vertical: GlobalAppDisplay.safeWidth * 0.016),
                            ),
                            onPressed: () => onNoPressed(dialogContext),
                            child: Column(
                              children: [
                                  Text(
                                  noButtonText1,
                                  textAlign: TextAlign.center,
                                  style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.015),
                                ),
                                if (noButtonText2 != null)
                                  SizedBox(height: GlobalAppDisplay.safeWidth * 0.006),

                                  Text(
                                    noButtonText2!,
                                    textAlign: TextAlign.center,
                                    style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.015),
                                  ),
                              ],
                            ),
                          ),
                        ),
                          
                        SizedBox(width: GlobalAppDisplay.safeWidth * 0.008),
                          
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.amber, width: GlobalAppDisplay.safeHeight * 0.003),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(GlobalAppDisplay.safeWidth * 0.025),
                              ),
                              backgroundColor: Colors.green.shade600,
                              padding: EdgeInsets.symmetric(horizontal: GlobalAppDisplay.safeWidth * 0.016, vertical: GlobalAppDisplay.safeWidth * 0.016),
                            ),
                            onPressed: () => onYesPressed(dialogContext),
                            child: Column(
                              children: [
                                  Text(
                                    yesButtonText1,
                                    textAlign: TextAlign.center,
                                    style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.015),
                                  ),
                                  if (yesButtonText2 != null)
                                    SizedBox(height: GlobalAppDisplay.safeWidth * 0.006),
                                    
                                    Text(
                                      yesButtonText2!,
                                      textAlign: TextAlign.center,
                                      style: gBuildArcadeTextStyle(GlobalAppDisplay.safeWidth * 0.015),
                                    ),
                                ],
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
  required double avatarHeight, 
  required Color bgColor,
  required bool isSlicedAvatar,
  required bool isSlicedVertical,
  required bool isTagNickNameLeft,
}) {
  return Center(
    child: AspectRatio(
      aspectRatio: 1.0,
      child: FittedBox(
        fit: BoxFit.contain, // Forces artwork and text to scale together proportionally
        child: SizedBox(
          width: avatarHeight,
          height: avatarHeight,
          child: Stack(
            children: [
              // 1. Dynamic Circle Background Layer
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: avatarHeight,
                child: Center(
                  child: Container(
                    width: avatarHeight * 0.95,
                    height: avatarHeight * 0.95,
                    decoration: BoxDecoration(
                      color: bgColor,
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
                height: avatarHeight,
                child: Image.asset(
                  'assets/png/avatars/avatar_${player.fldAvatar.fldAvatarCode}_v1.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // 3. Metallic Frame Overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: avatarHeight,
                child: Image.asset(
                  'assets/png/mechanics/player_avatar.png',
                  fit: BoxFit.contain,
                ),
              ),

              if (isSlicedAvatar) ...[
                if (isSlicedVertical) ...[
                  Positioned(
                    right: avatarHeight * 0.265,
                    top: 0,
                    bottom: 0,
                    child: RotatedBox(
                      quarterTurns: 3, // Rotates the pill vertically 90 degrees
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: avatarHeight * 0.03,
                            vertical: avatarHeight * 0.015,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.shade100.withAlpha(200),
                            borderRadius: BorderRadius.circular(avatarHeight * 0.04),
                            border: Border.all(
                              color: Colors.purpleAccent.shade700,
                              width: avatarHeight * 0.006,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              player.fldNickName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: gBuildArcadeTextStyle(
                                avatarHeight * 0.05,
                                gFontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Positioned(
                    left: isTagNickNameLeft ? 0 : null,
                    right: isTagNickNameLeft ? null : 0,
                    top: -avatarHeight * 0.34,
                    bottom: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: avatarHeight * 0.03,
                              vertical: avatarHeight * 0.012,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.shade100.withAlpha(200),
                              borderRadius: BorderRadius.circular(avatarHeight * 0.04),
                              border: Border.all(
                                color: Colors.purpleAccent.shade700,
                                width: avatarHeight * 0.006,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                player.fldNickName.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: gBuildArcadeTextStyle(
                                  avatarHeight * 0.05,
                                  gFontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]
                    ),
                  ),
                ]
              ] else ...[
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: avatarHeight * 0.045,
                        vertical: avatarHeight * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(avatarHeight * 0.04),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: avatarHeight * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          player.fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(
                            avatarHeight * 0.062,
                            gFontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]
              
            ],
          ),
        ),
      ),
    ),
  );
}

Widget gBuildTeamCardH({
  required double cardHeight,
  required double cardWidth,
  required TblPlayer? selectedPlayer1,
  required TblPlayer? selectedPlayer2,
  required bool isDummyTeam,
  required Color colorBgAvatar,
  required bool isSlicedCard,
}) {
  final avatarHeightCard = cardHeight * 1.45 / 2;

  return Center(
    child: AspectRatio(
      aspectRatio: 1.4628,
      child: FittedBox(
        fit: BoxFit.contain, // Forces height and width to scale down together proportionally
        child: SizedBox(
          height: cardHeight,
          width: cardWidth,
          child: Stack(
            children: [
              // 1. Player 1 Solid Color Circle (Left Background)
              Positioned(
                top: 0, // Positions inside top metallic ring
                bottom: 0,
                left: cardWidth * 0.02,
                width: avatarHeightCard,
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
                right: cardWidth * 0.02,
                width: avatarHeightCard,
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
                left: cardWidth * 0.01,
                width: avatarHeightCard,
                child: Image.asset(
                  'assets/png/avatars/avatar_${selectedPlayer1 != null ? selectedPlayer1.fldAvatar.fldAvatarCode : 'question'}_v1.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // 4. Player 2 Avatar Artwork (Right Half)
              Positioned(
                top: 0,
                bottom: 0,
                right: cardWidth * 0.01,
                width: avatarHeightCard,
                child: Image.asset(
                  'assets/png/avatars/avatar_${selectedPlayer2 != null ? selectedPlayer2.fldAvatar.fldAvatarCode : 'question'}_v1.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // 5. Metallic Frame Overlay
              Positioned.fill(
                child: Image.asset(
                  'assets/png/mechanics/team_card_frame_H.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // 6. Dummy Player Layer
              if (isDummyTeam) // e.g., checking if this slot is a dummy
                Positioned.fill(
                  child: Image.asset(
                    'assets/png/mechanics/player_dummy_H.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              
              // 7. Player 1 Nickname Pill (Left Slot)
              if (selectedPlayer1 != null && !isSlicedCard) ...[
                Positioned(
                  bottom: cardHeight * 0.13,
                  left: 0,
                  width: avatarHeightCard,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: avatarHeightCard * 0.045,
                        vertical: avatarHeightCard * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(avatarHeightCard * 0.04),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: avatarHeightCard * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selectedPlayer1.fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(
                            avatarHeightCard * 0.067,
                            gFontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (selectedPlayer1 != null && isSlicedCard) ...[
                Positioned(
                  bottom: cardHeight * 0.255,
                  left: 0,
                  width: avatarHeightCard,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: avatarHeightCard * 0.045,
                        vertical: avatarHeightCard * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100.withAlpha(200),
                        borderRadius: BorderRadius.circular(avatarHeightCard * 0.04),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: avatarHeightCard * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selectedPlayer1.fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(
                            avatarHeightCard * 0.067,
                            gFontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              
              // 8. Player 2 Nickname Pill (Right Slot)
              if (selectedPlayer2 != null && !isSlicedCard) ...[
                Positioned(
                  bottom: cardHeight * 0.13,
                  right: 0,
                  width: avatarHeightCard,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: avatarHeightCard * 0.045,
                        vertical: avatarHeightCard * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(avatarHeightCard * 0.04),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: avatarHeightCard * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selectedPlayer2.fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(
                            avatarHeightCard * 0.067,
                            gFontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (selectedPlayer2 != null && isSlicedCard) ...[
                Positioned(
                  bottom: cardHeight * 0.255,
                  right: 0,
                  width: avatarHeightCard,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: avatarHeightCard * 0.045,
                        vertical: avatarHeightCard * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100.withAlpha(200),
                        borderRadius: BorderRadius.circular(avatarHeightCard * 0.04),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: avatarHeightCard * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selectedPlayer2.fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(
                            avatarHeightCard * 0.067,
                            gFontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

PreferredSizeWidget gBuildAppBar({
  required double gToolbarHeight,
  required String gAppBarTitle,
  required Color gAppBarColorBg,
  required bool gCallFromMainScreen,
  required VoidCallback? gOnPressed,
  Widget? gRightPopupMenu,
}) {
  return AppBar(
    toolbarHeight: gToolbarHeight,
    backgroundColor: gAppBarColorBg,
    iconTheme: const IconThemeData(
      color: Colors.white, // Hardcoded leading/icon color here
    ),
    title: Row (
      children: [
        Padding(
          padding: EdgeInsets.all((GlobalAppDisplay.safeHeight * 0.12).clamp(4.0, 12.0)),
          child: SizedBox(
            height: (GlobalAppDisplay.safeHeight * 0.08).clamp(48.0, 128.0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: SvgPicture.asset(
                'assets/svg/logos/darts_101_logo.svg', // Update with your actual SVG logo path
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              gAppBarTitle, 
              style: gBuildArcadeTextStyle((GlobalAppDisplay.safeWidth * 0.02).clamp(18.0, 60.0)),
            ),
          ),
        ),
      ]          
    ),
    actions: [
      if (kDebugMode && gCallFromMainScreen) ...[
        
          TextButton.icon(
            onPressed: gOnPressed,
            icon: Icon(Icons.aspect_ratio, color: Colors.amber, size: GlobalAppDisplay.safeHeight * 0.03),
            label: Text(
              'Reset DB',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: GlobalAppDisplay.safeHeight * 0.022,
              ),
            ),
          ),
          
          ?gRightPopupMenu,
        ]
    ],
  );
}

Widget gBuildSlicedPlayerAvatarV({
  required TblPlayer player,
  required double avatarHeight,
  required double avatarHeightOuterSize,
  required double avatarSlicedWidth,
  required double avatarSlicedWidthOuterSize,
  required Color slotBgColor,
  required int playerPosition,
  required double responsiveTile,
}) {
  //Fits with asset of badge P1 or T1
  final ratioPlayerTeamBadge = 345 / 260;

  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          blurRadius: responsiveTile * 0.015,
          offset: Offset(responsiveTile * 0.006, responsiveTile * 0.006),
        ),
      ],
    ),
    child: SizedBox(
      width: avatarSlicedWidthOuterSize,
      height: avatarHeightOuterSize,
      child: Stack(
        children: [
          Container(
            width: avatarSlicedWidthOuterSize,
            height: avatarHeightOuterSize,
            decoration: BoxDecoration(
              color: slotBgColor,
              borderRadius: BorderRadius.circular(avatarSlicedWidthOuterSize * 0.15),
              border: Border.all(
                color: Colors.yellowAccent,
                width: avatarHeightOuterSize * 0.012,
              ),
            ),
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                alignment: Alignment.center,
                child: SizedBox(
                  width: avatarHeight,
                  height: avatarHeight,
                  child: gBuildPlayerAvatarCard(
                    player: player,
                    avatarHeight: avatarHeight,
                    bgColor: Colors.transparent,
                    isSlicedAvatar: true,
                    isSlicedVertical: true,
                    isTagNickNameLeft: false,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.0, -0.94),
            child: SizedBox(
              width: avatarHeight * 0.20 * ratioPlayerTeamBadge,
              height: avatarHeight * 0.20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(avatarSlicedWidthOuterSize * 0.07),
                  border: Border.all(
                    color: Colors.yellowAccent,
                    width: avatarSlicedWidthOuterSize * 0.015,
                  ),
                ),
                child: Image.asset(
                  'assets/png/mechanics/rs_tag_p_${playerPosition + 1}.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget gBuildSlicedPlayerAvatarVPanel({
  required TblPlayer player,
  required double avatarHeight,
  required double avatarHeightOuterSize,
  required double avatarSlicedWidth,
  required double avatarSlicedWidthOuterSize,
  required Color slotBgColor,
  required int playerPosition,
  required double responsiveTile,
  required double heightBoost,
  bool isEmptyPanel = false,
}) {
  //Fits with asset of badge P1 or T1
  final ratioPlayerTeamBadge = 345 / 260;

  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          blurRadius: responsiveTile * 0.015,
          offset: Offset(responsiveTile * 0.006, responsiveTile * 0.006),
        ),
      ],
    ),
    child: SizedBox(
      width: avatarSlicedWidthOuterSize,
      height: avatarHeightOuterSize + heightBoost,
      child: Container(
        width: avatarSlicedWidthOuterSize,
        height: avatarHeightOuterSize + heightBoost,
        decoration: BoxDecoration(
          color: slotBgColor,
          borderRadius: BorderRadius.circular(avatarSlicedWidthOuterSize * 0.15),
          border: Border.all(
            color: Colors.yellowAccent,
            width: avatarHeightOuterSize * 0.012,
          ),
        ),
        child: isEmptyPanel
          ? Stack(
              children:[
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: responsiveTile * 0.050),
                    child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          "WAITING...",
                          style: gBuildArcadeTextStyle(responsiveTile * 0.035),
                        ),
                      ),
                  ),
                )
              ]
            )
          : Stack(
              alignment: Alignment.topCenter,
              children: [
                ClipRect(
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: avatarHeight,
                      height: avatarHeight,
                      child: gBuildPlayerAvatarCard(
                        player: player,
                        avatarHeight: avatarHeight,
                        bgColor: Colors.transparent,
                        isSlicedAvatar: true,
                        isSlicedVertical: true,
                        isTagNickNameLeft: false,
                      ),
                    ),
                  ),
                ),
              
                Align(
                  alignment: const Alignment(0.0, -0.99),
                  child: SizedBox(
                    width: avatarHeight * 0.20 * ratioPlayerTeamBadge,
                    height: avatarHeight * 0.20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(avatarSlicedWidthOuterSize * 0.07),
                        border: Border.all(
                          color: Colors.yellowAccent,
                          width: avatarSlicedWidthOuterSize * 0.015,
                        ),
                      ),
                      child: Image.asset(
                        'assets/png/mechanics/rs_tag_p_${playerPosition + 1}.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    ),
  );
}

Widget gBuildSlicedPlayerAvatarH({
  required TblPlayer player,
  required double avatarHeight,
  required double avatarHeightOuterSize,
  required double avatarSlicedWidth,
  required double avatarSlicedWidthOuterSize,
  required Color slotBgColor,
  required int playerPosition,
  required double responsiveTile,
  required bool isTagNickNameLeft,
  bool isEmptyPanel = false,
}) {
  //Fits with asset of badge P1 or T1
  final ratioPlayerTeamBadge = 345 / 260;

  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          blurRadius: responsiveTile * 0.015,
          offset: Offset(responsiveTile * 0.006, responsiveTile * 0.006),
        ),
      ],
    ),
    child: SizedBox(
      width: avatarHeightOuterSize,
      height: avatarSlicedWidthOuterSize,
      child: isEmptyPanel
        ? Stack(
            children: [
              Container(
                width: avatarHeightOuterSize,
                height: avatarSlicedWidthOuterSize,
                decoration: BoxDecoration(
                  color: slotBgColor,
                  borderRadius: BorderRadius.circular(avatarSlicedWidthOuterSize * 0.15),
                  border: Border.all(
                    color: Colors.yellowAccent,
                    width: avatarHeightOuterSize * 0.012,
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "WAITING...",
                      style: gBuildArcadeTextStyle(responsiveTile * 0.035),
                    ),
                  ),
                ),
              ),
            ],
          )
        : Stack(
          children: [
            Container(
              width: avatarHeightOuterSize,
              height: avatarSlicedWidthOuterSize,
              decoration: BoxDecoration(
                color: slotBgColor,
                borderRadius: BorderRadius.circular(avatarSlicedWidthOuterSize * 0.15),
                border: Border.all(
                  color: Colors.yellowAccent,
                  width: avatarHeightOuterSize * 0.012,
                ),
              ),
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: avatarHeight,
                    height: avatarHeight,
                    child: gBuildPlayerAvatarCard(
                      player: player,
                      avatarHeight: avatarHeight,
                      bgColor: Colors.transparent,
                      isSlicedAvatar: true,
                      isSlicedVertical: false,
                      isTagNickNameLeft: isTagNickNameLeft,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: isTagNickNameLeft
                ? const Alignment(-0.86, -0.1)
                : const Alignment(0.86, -0.1),
              child: SizedBox(
                width: avatarHeight * 0.17 * ratioPlayerTeamBadge,
                height: avatarHeight * 0.17,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(avatarSlicedWidthOuterSize * 0.07),
                    border: Border.all(
                      color: Colors.yellowAccent,
                      width: avatarSlicedWidthOuterSize * 0.015,
                    ),
                  ),
                  child: Image.asset(
                    'assets/png/mechanics/rs_tag_p_${playerPosition + 1}.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ],
        ),
    ),
  );
}

Widget gBuildSlicedTeamCardV({
  required TblTeam team,
  required double cardHeight,
  required double cardWidth,
  required double cardWidthOuterSize,
  required double cardSlicedHeight,
  required double cardSlicedHeightOuterSize,
  required Color slotBgColor,
  required int teamPosition,
  required double responsiveTile,
}) {
  //Fits with asset of badge P1 or T1
  final ratioPlayerTeamBadge = 345 / 260;
  final isDummy = (team.fldPlayers[0] == team.fldPlayers[1]);

  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          blurRadius: responsiveTile * 0.015,
          offset: Offset(responsiveTile * 0.006, responsiveTile * 0.006),
        ),
      ],
    ),
    child: SizedBox(
      width: cardSlicedHeightOuterSize,
      height: cardWidthOuterSize,
      child: Stack(
        children: [
          Container(
            width: cardSlicedHeightOuterSize,
            height: cardWidthOuterSize,
            decoration: BoxDecoration(
              color: slotBgColor,
              borderRadius: BorderRadius.circular(cardSlicedHeightOuterSize * 0.15),
              border: Border.all(
                color: Colors.yellowAccent,
                width: cardWidthOuterSize * 0.008,
              ),
            ),
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                alignment: Alignment.center,
                child: SizedBox(
                  width: cardHeight,
                  height: cardWidth,
                  child: gBuildTeamCardV(
                    team: team,
                    cardHeight: cardWidth,
                    cardWidth: cardHeight,
                    colorBgAvatar: slotBgColor,
                    isSlicedCard: true,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: !isDummy
                ? const Alignment(0.0, 0.0)
                : const Alignment(0.0, -0.96),
            child: SizedBox(
              width: cardHeight * 0.2 * ratioPlayerTeamBadge,
              height: cardHeight * 0.2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(cardSlicedHeightOuterSize * 0.07),
                  border: Border.all(
                    color: Colors.yellowAccent,
                    width: cardSlicedHeightOuterSize * 0.015,
                  ),
                ),
                child: Image.asset(
                  'assets/png/mechanics/rs_tag_t_${teamPosition + 1}.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget gBuildSlicedTeamCardVPanel({
  required TblTeam team,
  required double cardHeight,
  required double cardWidth,
  required double cardWidthOuterSize,
  required double cardSlicedHeight,
  required double cardSlicedHeightOuterSize,
  required Color slotBgColor,
  required int teamPosition,
  required double responsiveTile,
  required double heightBoost,
  bool isEmptyPanel = false,
}) {
  //Fits with asset of badge P1 or T1
  final ratioPlayerTeamBadge = 345 / 260;
  final isDummy = (team.fldPlayers[0] == team.fldPlayers[1]);

  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          blurRadius: responsiveTile * 0.015,
          offset: Offset(responsiveTile * 0.006, responsiveTile * 0.006),
        ),
      ],
    ),
    child: SizedBox(
      width: cardSlicedHeightOuterSize,
      height: cardWidthOuterSize + heightBoost,
      child: Container(
        width: cardSlicedHeightOuterSize,
        height: cardWidthOuterSize + heightBoost,
        decoration: BoxDecoration(
          color: slotBgColor,
          borderRadius: BorderRadius.circular(cardSlicedHeightOuterSize * 0.15),
          border: Border.all(
            color: Colors.yellowAccent,
            width: cardWidthOuterSize * 0.008,
          ),
        ),
        child: isEmptyPanel
          ? Stack(
              children:[
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: responsiveTile * 0.050),
                    child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          "WAITING...",
                          style: gBuildArcadeTextStyle(responsiveTile * 0.035),
                        ),
                      ),
                  ),
                )
              ]
            )
          : Stack(
              alignment: Alignment.topCenter,
              children: [
                ClipRect(
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: cardHeight,
                      height: cardWidth,
                      child: gBuildTeamCardV(
                        team: team,
                        cardHeight: cardWidth,
                        cardWidth: cardHeight,
                        colorBgAvatar: slotBgColor,
                        isSlicedCard: true,
                      ),
                    ),
                  ),
                ),
            
                Align(
                  alignment: !isDummy
                      ? const Alignment(0.0, -0.63)
                      : const Alignment(0.0, -0.23),
                  child: SizedBox(
                    width: cardHeight * 0.2 * ratioPlayerTeamBadge,
                    height: cardHeight * 0.2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(cardSlicedHeightOuterSize * 0.07),
                        border: Border.all(
                          color: Colors.yellowAccent,
                          width: cardSlicedHeightOuterSize * 0.015,
                        ),
                      ),
                      child: Image.asset(
                        'assets/png/mechanics/rs_tag_t_${teamPosition + 1}.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    ),
  );
}

Widget gBuildSlicedTeamCardH({
  required TblTeam team,
  required double cardHeight,
  required double cardWidth,
  required double cardWidthOuterSize,
  required double cardSlicedHeight,
  required double cardSlicedHeightOuterSize,
  required Color slotBgColor,
  required int teamPosition,
  required double responsiveTile,
}) {
  //Fits with asset of badge P1 or T1
  final ratioPlayerTeamBadge = 345 / 260;
  final isDummy = (team.fldPlayers[0] == team.fldPlayers[1]);

  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          blurRadius: responsiveTile * 0.015,
          offset: Offset(responsiveTile * 0.006, responsiveTile * 0.006),
        ),
      ],
    ),
    child: SizedBox(
      width: cardWidthOuterSize,
      height: cardSlicedHeightOuterSize,
      child: Stack(
        children: [
          Container(
            width: cardWidthOuterSize,
            height: cardSlicedHeightOuterSize,
            decoration: BoxDecoration(
              color: slotBgColor,
              borderRadius: BorderRadius.circular(cardSlicedHeightOuterSize * 0.15),
              border: Border.all(
                color: Colors.yellowAccent,
                width: cardWidthOuterSize * 0.008,
              ),
            ),
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                alignment: Alignment.center,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: gBuildTeamCardH(
                    cardHeight: cardHeight,
                    cardWidth: cardWidth,
                    selectedPlayer1: team.fldPlayers[0],
                    selectedPlayer2: team.fldPlayers[1],
                    isDummyTeam: isDummy,
                    colorBgAvatar: Colors.transparent,
                    isSlicedCard: true,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: !isDummy
                ? const Alignment(0.0, 0.0)
                : teamPosition.isEven
                    ? const Alignment(-0.95, -0.80)
                    : const Alignment(0.95, -0.80),
            child: SizedBox(
              width: cardWidth * 0.15 * ratioPlayerTeamBadge,
              height: cardWidth * 0.15,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(cardSlicedHeightOuterSize * 0.07),
                  border: Border.all(
                    color: Colors.yellowAccent,
                    width: cardSlicedHeightOuterSize * 0.015,
                  ),
                ),
                child: Image.asset(
                  'assets/png/mechanics/rs_tag_t_${teamPosition + 1}.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget gBuildTeamCardV({
  required TblTeam team,
  required double cardHeight,
  required double cardWidth,
  required Color colorBgAvatar,
  required bool isSlicedCard,
}) {
  final bool isDummyTeam = team.fldPlayers[0] == team.fldPlayers[1];

  return Center(
    child: AspectRatio(
      aspectRatio: 0.6836,
      child: FittedBox(
        fit: BoxFit.contain, // Forces height and width to scale down together proportionally
        child: SizedBox(
          height: cardHeight,
          width: cardWidth,
          child: Stack(
            children: [
              // 1. Top Dynamic Circle Background Layer
              Positioned(
                top: cardHeight * 0.03, // Positions inside top metallic ring
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: cardHeight / 2,
                    height: cardHeight / 2,
                    decoration: BoxDecoration(
                      color: colorBgAvatar, // Or gender color for Player 1
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // 2. Bottom Dynamic Circle Background Layer
              Positioned(
                bottom: cardHeight * 0.03, // Positions inside bottom metallic ring
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: cardHeight / 2,
                    height: cardHeight / 2,
                    decoration: BoxDecoration(
                      color: colorBgAvatar, // Or gender color for Player 2
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              
              // 3. Top Player Avatar Layer
              Positioned(
                top: cardHeight * 0.015,
                left: 0,
                right: 0,
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/png/avatars/avatar_${team.fldPlayers[0].fldAvatar.fldAvatarCode}_v1.png',
                      width: cardHeight / 2,
                      height: cardHeight / 2,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),

              // 4. Bottom Player Avatar Layer
              Positioned(
                bottom: cardHeight * 0.005,
                left: 0,
                right: 0,
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/png/avatars/avatar_${team.fldPlayers[1].fldAvatar.fldAvatarCode}_v1.png',
                      width: cardHeight / 2,
                      height: cardHeight / 2,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),

              // 5. PNG Frame Overlay
              Positioned.fill(
                child: Image.asset(
                  'assets/png/mechanics/team_card_frame_V.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // 6. Dummy Player Layer
              if (isDummyTeam)
                Positioned.fill(
                  child: Image.asset(
                    'assets/png/mechanics/player_dummy_V.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),

              // 7. Player 1 Nickname Pill (Centered Top)
              if (!isSlicedCard) ...[
                Positioned(
                  top: cardHeight * 0.01,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: cardHeight * 0.035,
                        vertical: cardHeight * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(
                          cardHeight * 0.04,
                        ),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: cardHeight * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          team.fldPlayers[0].fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(cardHeight * 0.032,gFontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Positioned(
                  top: 0,
                  bottom: cardHeight * 0.5,
                  right: cardHeight * 0.175,
                  child: RotatedBox(
                    quarterTurns: 3, // Rotates the pill vertically 90 degrees
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardWidth * 0.035,
                          vertical: cardWidth * 0.006,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.shade100.withAlpha(200),
                          borderRadius: BorderRadius.circular(
                            cardWidth * 0.04,
                          ),
                          border: Border.all(
                            color: Colors.purpleAccent.shade700,
                            width: cardWidth * 0.006,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            team.fldPlayers[0].fldNickName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: gBuildArcadeTextStyle(cardHeight * 0.032,gFontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // 8. Player 2 Nickname Pill (Centered Bottom)
              if (!isSlicedCard) ...[
                Positioned(
                  bottom: cardHeight * 0.01,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: cardHeight * 0.035,
                        vertical: cardHeight * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.shade100,
                        borderRadius: BorderRadius.circular(
                          cardHeight * 0.04,
                        ),
                        border: Border.all(
                          color: Colors.purpleAccent.shade700,
                          width: cardHeight * 0.006,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          team.fldPlayers[1].fldNickName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: gBuildArcadeTextStyle(cardHeight * 0.032, gFontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Positioned(
                  top: cardHeight * 0.5,
                  bottom: 0,
                  right: cardHeight * 0.175,
                  child: RotatedBox(
                    quarterTurns: 3, // Rotates the pill vertically 90 degrees
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardWidth * 0.035,
                          vertical: cardWidth * 0.006,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.shade100.withAlpha(200),
                          borderRadius: BorderRadius.circular(
                            cardWidth * 0.04,
                          ),
                          border: Border.all(
                            color: Colors.purpleAccent.shade700,
                            width: cardWidth * 0.006,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            team.fldPlayers[1].fldNickName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: gBuildArcadeTextStyle(cardHeight * 0.032,gFontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}