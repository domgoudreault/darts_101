// Flutter basics
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gif_view/gif_view.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    case DisplayMode.display20LargeLapDesk:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_256x256.png',
        renderSize: 256,
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
    case DisplayMode.display20LargeLapDesk:  
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
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
ImageConfigAvatar getAvatarPlayerHImageConfig(String avatarCode) {
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