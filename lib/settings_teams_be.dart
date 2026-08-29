// Flutter basics
import 'package:darts_101/global_be.dart';
//import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
//import 'package:darts_101/database/tbl_player.dart';

class ImageConfig {
  final String assetPath;
  final double renderSize;

  const ImageConfig({required this.assetPath, required this.renderSize});
}

class ImageCardFrameConfig {
  final String assetPathFrame;
  final String assetPathIsDummyPlayer;
  final double renderWidth;
  final double renderHeight;

  const ImageCardFrameConfig({
    required this.assetPathFrame,
    required this.assetPathIsDummyPlayer,
    required this.renderWidth,
    required this.renderHeight,
  });
}

// Returns CarouselView tile configuration based on screen width
ImageCardFrameConfig getCarouselCardFrameImageConfig() {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageCardFrameConfig(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_175x256.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_175x256.png',
        renderWidth: 175,
        renderHeight: 256,
      );
    case DisplayMode.display15MediumTablet:
      return ImageCardFrameConfig(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_350x512.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_350x512.png',
        renderWidth: 350,
        renderHeight: 512,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageCardFrameConfig(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_525x768.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_525x768.png',
        renderWidth: 525,
        renderHeight: 768,
      );
    case DisplayMode.display25Ultra4K:
      return ImageCardFrameConfig(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_700x1024.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_700x1024.png',
        renderWidth: 700,
        renderHeight: 1024,
      );
  }
}

// Returns Player image based on screen width
ImageConfig getCarouselPlayerImageConfig(String avatarCode) {
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfig(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_128x128.png',
        renderSize: 256,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfig(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 512,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfig(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_384x384.png',
        renderSize: 768,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfig(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_512x512.png',
        renderSize: 1024,
      );
  }
}

// Returns Player image based on screen width
ImageConfig getFilterDummyImageConfig() {
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_42x42.png',
        renderSize: 42,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_84x84.png',
        renderSize: 84,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_126x126.png',
        renderSize: 126,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_168x168.png',
        renderSize: 168,
      );
  }
}