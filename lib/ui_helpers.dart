// Flutter basics
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gif_view/gif_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';

enum FormMode{
  formAdd,
  formModify
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

class ImageConfigArrow {
  final String assetPath;
  final double renderSize;

  const ImageConfigArrow({required this.assetPath, required this.renderSize});
}

// Returns APNG Arrow left or right based on screen width
ImageConfigArrow getArrowImageConfig(bool isLeft) {
  final String direction = isLeft ? 'left' : 'right';

  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfigArrow(        
        assetPath: 'assets/png/mechanics/arrow_${direction}_40x32.png',
        renderSize: 32,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfigArrow(        
        assetPath: 'assets/png/mechanics/arrow_${direction}_80x64.png',
        renderSize: 64,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfigArrow(        
        assetPath: 'assets/png/mechanics/arrow_${direction}_120x96.png',
        renderSize: 96,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfigArrow(        
        assetPath: 'assets/png/mechanics/arrow_${direction}_160x128.png',
        renderSize: 128,
      );
  }
}

Widget gBuildArcadeActionBanner({
  required String gLeadingText,
  required String gTrailingText,
  required FormMode gFormMode,
  required VoidCallback gOnTap,
}) {
  final double responsiveTile = AppDisplay.carouselTileSize;
  final double responsiveFontSize = (responsiveTile * 0.035).clamp(10.0, 40.0);

  final ImageConfigArrow leftArrowConfig = getArrowImageConfig(true);
  final ImageConfigArrow rightArrowConfig = getArrowImageConfig(false);
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
        left: AppDisplay.safeWidth * 0.05,
        right: AppDisplay.safeWidth * 0.05,
        bottom: AppDisplay.safeHeight * 0.05,
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

class ImageConfigAvatar {
  final String assetPath;
  final double renderSize;

  const ImageConfigAvatar({required this.assetPath, required this.renderSize});
}

// Returns Framing image for Avatars Picker based on screen width
ImageConfigAvatar getAvatarFrameImageConfig() {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_128x128.png',
        renderSize: 128,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_256x256.png',
        renderSize: 256,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_384x384.png',
        renderSize: 384,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_512x512.png',
        renderSize: 512,
      );
  }
}

// Returns Player image for Avatars Picker based on screen width
ImageConfigAvatar getAvatarPlayerImageConfig(String avatarCode) {
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_128x128.png',
        renderSize: 128,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
      );
    case DisplayMode.display20LargeLapDesk:  
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_384x384.png',
        renderSize: 384,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_512x512.png',
        renderSize: 512,
      );
  }
}

class ImageConfigDummy {
  final String assetPath;
  final double renderSize;

  const ImageConfigDummy({required this.assetPath, required this.renderSize});
}

// Returns Player image based on screen width
ImageConfigDummy getDummyImageConfig() {
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfigDummy(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_42x42.png',
        renderSize: 42,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfigDummy(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_84x84.png',
        renderSize: 84,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfigDummy(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_126x126.png',
        renderSize: 126,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfigDummy(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_168x168.png',
        renderSize: 168,
      );
  }
}

class ImageConfigPlayerCardFrame {
  final String assetPathFrame;
  final String assetPathBackground;
  final String assetPathIsLeagueMember;
  final double renderWidth;
  final double renderHeight;

  const ImageConfigPlayerCardFrame({
    required this.assetPathFrame,
    required this.assetPathBackground,
    required this.assetPathIsLeagueMember,
    required this.renderWidth,
    required this.renderHeight,
  });
}

// Returns CarouselView tile configuration based on screen width
ImageConfigPlayerCardFrame getCarouselPlayerCardFrameImage() {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfigPlayerCardFrame(        
        assetPathFrame: 'assets/png/mechanics/player_card_frame_175x256.png',
        assetPathBackground: 'assets/png/mechanics/player_card_bg_175x256.png',
        assetPathIsLeagueMember: 'assets/png/mechanics/player_league_member_175x256.png',
        renderWidth: 175,
        renderHeight: 256,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfigPlayerCardFrame(        
        assetPathFrame: 'assets/png/mechanics/player_card_frame_350x512.png',
        assetPathBackground: 'assets/png/mechanics/player_card_bg_350x512.png',
        assetPathIsLeagueMember: 'assets/png/mechanics/player_league_member_350x512.png',
        renderWidth: 350,
        renderHeight: 512,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfigPlayerCardFrame(        
        assetPathFrame: 'assets/png/mechanics/player_card_frame_525x768.png',
        assetPathBackground: 'assets/png/mechanics/player_card_bg_525x768.png',
        assetPathIsLeagueMember: 'assets/png/mechanics/player_league_member_525x768.png',
        renderWidth: 525,
        renderHeight: 768,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfigPlayerCardFrame(        
        assetPathFrame: 'assets/png/mechanics/player_card_frame_700x1024.png',
        assetPathBackground: 'assets/png/mechanics/player_card_bg_700x1024.png',
        assetPathIsLeagueMember: 'assets/png/mechanics/player_league_member_700x1024.png',
        renderWidth: 700,
        renderHeight: 1024,
      );
  }
}

class ImageConfigPlayerCard {
  final String assetPath;
  final double renderSize;

  const ImageConfigPlayerCard({required this.assetPath, required this.renderSize});
}

// Returns Player image based on screen width
ImageConfigPlayerCard getCarouselPlayerCardImage(String avatarCode) {
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfigPlayerCard(
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_175x256.png',
        renderSize: 256,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfigPlayerCard(
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_350x512.png',
        renderSize: 512,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfigPlayerCard(
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_525x768.png',
        renderSize: 768,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfigPlayerCard(
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_700x1024.png',
        renderSize: 1024,
      );
  }
}

class ImageConfigTeamCardFrame {
  final String assetPathFrame;
  final String assetPathIsDummyPlayer;
  final double renderWidth;
  final double renderHeight;

  const ImageConfigTeamCardFrame({
    required this.assetPathFrame,
    required this.assetPathIsDummyPlayer,
    required this.renderWidth,
    required this.renderHeight,
  });
}

// Returns CarouselView TeamCard Vertical based on screen width
ImageConfigTeamCardFrame getCarouselTeamCardVFrameImage() {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_175x256.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_175x256.png',
        renderWidth: 175,
        renderHeight: 256,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_350x512.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_350x512.png',
        renderWidth: 350,
        renderHeight: 512,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_525x768.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_525x768.png',
        renderWidth: 525,
        renderHeight: 768,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_700x1024.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_700x1024.png',
        renderWidth: 700,
        renderHeight: 1024,
      );
  }
}

// Returns CarouselView(Game Selection) TeamCard Horizontal based on screen width
ImageConfigTeamCardFrame getCarouselTeamCardHFrameImage() {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_128x87.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_128x87.png',
        renderWidth: 128,
        renderHeight: 87,
      );
    case DisplayMode.display15MediumTablet:
    case DisplayMode.display20LargeLapDesk:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_512x350.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_512x350.png',
        renderWidth: 256,
        renderHeight: 175,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_768x525.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_768x525.png',
        renderWidth: 512,
        renderHeight: 350,
      );
  }
}

// Returns MainUI(modify_add_team) TeamCard Horizontal based on screen width
ImageConfigTeamCardFrame getMainUITeamCardHFrameImage() {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_256x175.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_256x175.png',
        renderWidth: 256,
        renderHeight: 175,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_512x350.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_512x350.png',
        renderWidth: 512,
        renderHeight: 350,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_768x525.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_768x525.png',
        renderWidth: 768,
        renderHeight: 525,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_1024x700.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_1024x700.png',
        renderWidth: 1024,
        renderHeight: 700,
      );
  }
}

// Returns Player image for Avatars for TeamCard Horizontal based on screen width
ImageConfigAvatar getAvatarPlayerCardImageConfig(String avatarCode) {
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_128x128.png',
        renderSize: 128,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
      ); 
    case DisplayMode.display20LargeLapDesk:  
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_384x384.png',
        renderSize: 384,
      );    
    case DisplayMode.display25Ultra4K:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_512x512.png',
        renderSize: 512,
      );
  }
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
              width: AppDisplay.carouselTileSize * 0.45,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Builder(
                    builder: (context) {
                      return SizedBox(
                        width: AppDisplay.carouselTileSize,
                        height: AppDisplay.carouselTileSize,
                        child: Stack(
                          children: [
                            // 1. Color fill tucked inside fixed canvas dimensions
                            Positioned.fill(
                              child: Padding(
                                padding: EdgeInsets.all(AppDisplay.carouselTileSize * 0.03),
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
            
            SizedBox(width: AppDisplay.carouselTileSize * 0.13),
            
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
                        style: gBuildArcadeTextStyle(AppDisplay.carouselTileSize * 0.035, gTextColor: Colors.amber),
                      ),
                    ),

                    SizedBox(height: AppDisplay.carouselTileSize * 0.06),
                    
                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: gBuildArcadeTextStyle(AppDisplay.carouselTileSize * 0.035),
                    ),
                    
                    SizedBox(height: AppDisplay.carouselTileSize * 0.06),

                    // Content Question Text
                    Text(
                      questionText,
                      style: gBuildArcadeTextStyle(AppDisplay.carouselTileSize * 0.035),
                    ),

                    SizedBox(height: AppDisplay.carouselTileSize * 0.03),
                    
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
                              style: gBuildArcadeTextStyle(AppDisplay.carouselTileSize * 0.035),
                            ),
                          ),
                        ),
                          
                        SizedBox(width: AppDisplay.carouselTileSize * 0.02),
                          
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
                              style: gBuildArcadeTextStyle(AppDisplay.carouselTileSize * 0.035),
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

Future<void> seedHiveLeaguePlayers(Box<TblPlayer> playersBox) async {
  // seed Players
  List<TblPlayer> listPlayers = [
    TblPlayer(fldFirstName: 'Dominique', fldLastName: 'Goudreault', fldNickName: 'Domi', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'domi'),
    TblPlayer(fldFirstName: 'Éric', fldLastName: 'St-Pierre', fldNickName: 'Ricky', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'ricky'),
    TblPlayer(fldFirstName: 'Christopher', fldLastName: 'Lafond', fldNickName: 'Christo', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'christo'),
    TblPlayer(fldFirstName: 'Frédéric', fldLastName: 'Gagnon', fldNickName: 'Marcel', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'marcel'),
    TblPlayer(fldFirstName: 'Frederik', fldLastName: 'Peeters Bélanger', fldNickName: 'Fred', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'fred'),
    TblPlayer(fldFirstName: 'Simon', fldLastName: 'Drouin', fldNickName: 'Drou', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'drou'),
    TblPlayer(fldFirstName: 'Étienne', fldLastName: 'Lefrançois', fldNickName: 'Ti-ti', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'titi'),
    TblPlayer(fldFirstName: 'Marc-Olivier', fldLastName: 'Fortin', fldNickName: 'Marco', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'marco'),
    TblPlayer(fldFirstName: 'Ludovick', fldLastName: 'Gosselin', fldNickName: 'Ludo', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'ludo'),
    TblPlayer(fldFirstName: 'Maxime', fldLastName: 'Gagnon', fldNickName: 'Max', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'max'),
    TblPlayer(fldFirstName: 'Michel', fldLastName: 'Deschênes', fldNickName: 'Papy', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'papy'),
    TblPlayer(fldFirstName: 'Charles', fldLastName: 'Lirette', fldNickName: 'Charles', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'charles'),
    TblPlayer(fldFirstName: 'Bryan', fldLastName: 'Bryan', fldNickName: 'Bryan', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'bryan'),
    TblPlayer(fldFirstName: 'Carl', fldLastName: 'Dubé', fldNickName: 'Le Livreur', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'carl'),
    TblPlayer(fldFirstName: 'Carmel', fldLastName: 'Fortin', fldNickName: 'Carmel', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'carmel'),
  ];

  await playersBox.addAll(listPlayers);
}

Future<void> seedHiveGenericPlayers(Box<TblPlayer> playersBox) async {
  // seed Players
  List<TblPlayer> listPlayers = [
    TblPlayer(fldFirstName: 'Don Juan', fldLastName: 'De Marco', fldNickName: 'Bow Tie', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'domi'),
    TblPlayer(fldFirstName: 'Viktor', fldLastName: 'Vance', fldNickName: 'Lucky', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'ricky'),
    TblPlayer(fldFirstName: 'Stella', fldLastName: 'Rogue', fldNickName: 'Sniper', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '02'),
    TblPlayer(fldFirstName: 'Diesel', fldLastName: 'Nitro', fldNickName: 'War Hawk', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'christo'),
    TblPlayer(fldFirstName: 'Marcel', fldLastName: 'Steele', fldNickName: 'Double Out', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'marcel'),
    TblPlayer(fldFirstName: 'Elektra', fldLastName: 'Volt', fldNickName: 'Rebel Red', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '01'),
    TblPlayer(fldFirstName: 'Maverick', fldLastName: 'Thunderbolt', fldNickName: 'Turbo', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'fred'),
    TblPlayer(fldFirstName: 'Spike', fldLastName: 'Prowler', fldNickName: 'Clutch', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'drou'),
    TblPlayer(fldFirstName: 'Anita', fldLastName: 'McGee', fldNickName: 'Bounce Out', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '03'),
    TblPlayer(fldFirstName: 'Low', fldLastName: 'Rollings', fldNickName: 'Nerdy', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'titi'),
    TblPlayer(fldFirstName: 'Jimmy', fldLastName: 'Swift', fldNickName: 'Outlaw', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'marco'),
    TblPlayer(fldFirstName: 'Roxie', fldLastName: 'Razor', fldNickName: 'Vixen', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '08'),
    TblPlayer(fldFirstName: 'Duke', fldLastName: 'Sterling', fldNickName: 'Jackpot', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'ludo'),
    TblPlayer(fldFirstName: 'Dizzy', fldLastName: 'Blowgun', fldNickName: 'Dr. Darts', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'max'),
    TblPlayer(fldFirstName: 'Charlotte', fldLastName: 'Purrfect', fldNickName: 'Catnip', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '07'),
    TblPlayer(fldFirstName: 'Earl', fldLastName: 'Montgomery', fldNickName: 'Pops', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'papy'),
    TblPlayer(fldFirstName: 'Roman', fldLastName: 'Vortex', fldNickName: 'The Wizard', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'charles'),
    TblPlayer(fldFirstName: 'Pamela', fldLastName: 'Pennyworth', fldNickName: 'Gold Digger', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '10'),
    TblPlayer(fldFirstName: 'Clay', fldLastName: 'Bentonite', fldNickName: 'Pixie', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '04'),
    TblPlayer(fldFirstName: 'Leo', fldLastName: 'Pawfur', fldNickName: 'Magic Paws', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '05'),
    TblPlayer(fldFirstName: 'Siren', fldLastName: 'Scream', fldNickName: 'Banshee', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '09'),
    TblPlayer(fldFirstName: 'Rex', fldLastName: 'Stone', fldNickName: 'Dart Vader', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'bryan'),
    TblPlayer(fldFirstName: 'Ronald', fldLastName: 'Cummings', fldNickName: 'Preacher', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '06'),
    TblPlayer(fldFirstName: 'Bonnie', fldLastName: 'Banks', fldNickName: 'Cashflow', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '11'),
    TblPlayer(fldFirstName: 'Johnny', fldLastName: 'Danger', fldNickName: 'Bullseye', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'carmel'),
    TblPlayer(fldFirstName: 'Mario', fldLastName: 'Crustini', fldNickName: 'The Slice', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: 'carl'),
    TblPlayer(fldFirstName: 'Harley', fldLastName: 'Stitcher', fldNickName: 'Fatal Sting', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '12'),
  ];

  await playersBox.addAll(listPlayers);
}

Future<void> seedHiveTeams(Box<TblPlayer> playersBox, Box<TblTeam> teamsBox) async {  
  final players = playersBox.values.toList(); // Grab all saved players from Hive
  final List<TblTeam> listTeams = []; // List to collect teams in memory

  // Dynamically Generate Unique Teams & Self Teams ---
  for (int i = 0; i < players.length; i++) {
    for (int j = i; j < players.length; j++) {
      final p1 = players[i];
      final p2 = players[j];

      listTeams.add(
        TblTeam(
          fldPlayers: [p1, p2],
          fldIsDeleted: false,
        ),
      );
    }
  } 

  await teamsBox.addAll(listTeams);
}