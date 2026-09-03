// Backend Logic
import 'package:darts_101/global_be.dart';

class ImageConfig {
  final String assetPath;
  final double renderSize;

  const ImageConfig({required this.assetPath, required this.renderSize});
}

// Returns image configuration based on screen width
ImageConfig gGetInformationDialogImageConfig() {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
      // Landscape Small/Narrow Phones
      return const ImageConfig(
        assetPath: 'assets/png/logos/LGGDS_180x180.png',
        renderSize: 180,
      );

    case DisplayMode.display10CompactPhone:
      // Landscape Phones / Compact Tablets
      return const ImageConfig(
        assetPath: 'assets/png/logos/LGGDS_360x360.png',
        renderSize: 360,
      );

    case DisplayMode.display15MediumTablet:
      // 10"-11" Landscape Tablets (Your Galaxy Tab S10 Lite @ 1024dp)
      return const ImageConfig(
        assetPath: 'assets/png/logos/LGGDS_512x512.png',
        renderSize: 512,
      );

    case DisplayMode.display20LargeLapDesk:
      // Laptops & Desktop Displays
      return const ImageConfig(
        assetPath: 'assets/png/logos/LGGDS_720x720.png',
        renderSize: 720,
      );

    case DisplayMode.display25Ultra4K:
      // 4K & Ultra-wide Displays
      return const ImageConfig(
        assetPath: 'assets/png/logos/LGGDS_1000x1000.png',
        renderSize: 1000,
      );
  }
}

// Returns CarouselView tile configuration based on screen width
ImageConfig gGetCarouselTileImageConfig(String tileType, String tileName) {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfig(        
        assetPath: 'assets/png/tiles/${tileType}_${tileName}_256x256.png',
        renderSize: 256,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfig(        
        assetPath: 'assets/png/tiles/${tileType}_${tileName}_512x512.png',
        renderSize: 512,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfig(        
        assetPath: 'assets/png/tiles/${tileType}_${tileName}_768x768.png',
        renderSize: 768,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfig(        
        assetPath: 'assets/png/tiles/${tileType}_${tileName}_1024x1024.png',
        renderSize: 1024,
      );
  }
}

// Returns Accordion Section Header configuration based on screen width
ImageConfig gGetSectionHeaderImageConfig(String sectionCode) {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/section_${sectionCode}_width_128.png',
        renderSize: 128,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/section_${sectionCode}_width_256.png',
        renderSize: 256,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/section_${sectionCode}_width_256.png',
        renderSize: 256,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/section_${sectionCode}_width_512.png',
        renderSize: 512,
      );
  }
}

class ImageConfigArrow {
  final String assetPath;
  final double renderSize;

  const ImageConfigArrow({required this.assetPath, required this.renderSize});
}

// Returns APNG Arrow left or right based on screen width
ImageConfigArrow gGetArrowImageConfig(bool isLeft) {
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

class ImageConfigAvatar {
  final String assetPath;
  final double renderSize;

  const ImageConfigAvatar({required this.assetPath, required this.renderSize});
}

// Returns Framing image for Avatars Picker based on screen width
ImageConfigAvatar gGetAvatarFrameImageConfig() {  
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
ImageConfigAvatar gGetAvatarPlayerImageConfig(String avatarCode) {
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
ImageConfigDummy gGetDummyImageConfig() {
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
ImageConfigPlayerCardFrame gGetCarouselPlayerCardFrameImage() {  
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
ImageConfigPlayerCard gGetCarouselPlayerCardImage(String avatarCode) {
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
ImageConfigTeamCardFrame gGetCarouselTeamCardVFrameImage() {  
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
ImageConfigTeamCardFrame gGetCarouselTeamCardHFrameImage() {  
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
ImageConfigTeamCardFrame gGetMainUITeamCardHFrameImage() {  
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
ImageConfigAvatar gGetAvatarPlayerCardImageConfig(String avatarCode) {
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