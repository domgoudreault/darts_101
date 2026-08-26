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
  required BuildContext context,
  required String leadingText,
  required String trailingText,
  required FormMode formMode,
  required VoidCallback onTap,
}) {
  final double responsiveTile = AppDisplay.carouselTileSize;
  final double responsiveFontSize = (responsiveTile * 0.035).clamp(10.0, 40.0);

  final ImageConfigArrow leftArrowConfig = getArrowImageConfig(true);
  final ImageConfigArrow rightArrowConfig = getArrowImageConfig(false);
  final String svgAssetPath = (formMode == FormMode.formAdd)
      ? 'assets/svg/ui_buttons/player_team_add.svg'
      : 'assets/svg/ui_buttons/player_team_save.svg';

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
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
            Container(
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
                    leadingText,
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
                    trailingText,
                    style: gBuildArcadeTextStyle(
                      responsiveFontSize,
                      gTextColor: Colors.lightBlueAccent,
                    ),
                  ),
                ],
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
    ),
  );
}