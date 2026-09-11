// Backend Logic
import 'package:darts_101/global_be.dart';

class ImageConfigAvatar {
  final String assetPath;
  final double renderSize;

  const ImageConfigAvatar({required this.assetPath, required this.renderSize});
}

// Returns Framing image for Avatars Picker based on screen width
ImageConfigAvatar gGetAvatarFrameImageConfig() {  
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_128x128.png',
        renderSize: 128,
      );
    case GlobalEnumDisplayMode.display15MediumTablet:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_256x256.png',
        renderSize: 256,
      );
    case GlobalEnumDisplayMode.display20LargeLapDesk:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_384x384.png',
        renderSize: 384,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_512x512.png',
        renderSize: 512,
      );
  }
}

// Returns Player image for Avatars Picker based on screen width
ImageConfigAvatar gGetAvatarPlayerImageConfig(String avatarCode) {
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_128x128.png',
        renderSize: 128,
      );
    case GlobalEnumDisplayMode.display15MediumTablet:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
      );
    case GlobalEnumDisplayMode.display20LargeLapDesk:  
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_384x384.png',
        renderSize: 384,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
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
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
      return ImageConfigDummy(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_42x42.png',
        renderSize: 42,
      );
    case GlobalEnumDisplayMode.display15MediumTablet:
      return ImageConfigDummy(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_84x84.png',
        renderSize: 84,
      );
    case GlobalEnumDisplayMode.display20LargeLapDesk:
      return ImageConfigDummy(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_126x126.png',
        renderSize: 126,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
      return ImageConfigDummy(        
        assetPath: 'assets/png/mechanics/player_dummy_icon_168x168.png',
        renderSize: 168,
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

// Returns MainUI(modify_add_team) TeamCard Horizontal based on screen width
ImageConfigTeamCardFrame gGetMainUITeamCardHFrameImage() {  
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_256x175.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_256x175.png',
        renderWidth: 256,
        renderHeight: 175,
      );
    case GlobalEnumDisplayMode.display15MediumTablet:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_512x350.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_512x350.png',
        renderWidth: 512,
        renderHeight: 350,
      );
    case GlobalEnumDisplayMode.display20LargeLapDesk:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_768x525.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_768x525.png',
        renderWidth: 768,
        renderHeight: 525,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
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
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_128x128.png',
        renderSize: 128,
      );
    case GlobalEnumDisplayMode.display15MediumTablet:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
      ); 
    case GlobalEnumDisplayMode.display20LargeLapDesk:  
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_384x384.png',
        renderSize: 384,
      );    
    case GlobalEnumDisplayMode.display25Ultra4K:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_512x512.png',
        renderSize: 512,
      );
  }
}

class ImageConfigCenterRS {
  final String assetPath;
  final double renderSize;
  final double scaleFactor;

  const ImageConfigCenterRS({required this.assetPath, required this.renderSize, required this.scaleFactor});
}

// Returns Center tile configuration based on screen width for RostersSelection
ImageConfigCenterRS gGetCenterTileImageConfigRS(String tileType, String tileCode) {  
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
      return ImageConfigCenterRS(        
        assetPath: 'assets/png/tiles/${tileType}_${tileCode}_128x128.png',
        renderSize: 128,
        scaleFactor: 0.50,
      );
    case GlobalEnumDisplayMode.display15MediumTablet:
      return ImageConfigCenterRS(        
        assetPath: 'assets/png/tiles/${tileType}_${tileCode}_128x128.png',
        renderSize: 128,
        scaleFactor: 1.0,
      );
    case GlobalEnumDisplayMode.display20LargeLapDesk:
      return ImageConfigCenterRS(        
        assetPath: 'assets/png/tiles/${tileType}_${tileCode}_256x256.png',
        renderSize: 256,
        scaleFactor: 1.0,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
      return ImageConfigCenterRS(        
        assetPath: 'assets/png/tiles/${tileType}_${tileCode}_512x512.png',
        renderSize: 512,
        scaleFactor: 1.0,
      );
  }
}

// Returns Framing image for Players Picker based on screen width for RostersSelection
ImageConfigAvatar gGetAvatarPlayerFrameImageConfigRS() {  
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
    case GlobalEnumDisplayMode.display15MediumTablet:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_128x128.png',
        renderSize: 128,
      );
    case GlobalEnumDisplayMode.display20LargeLapDesk:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_256x256.png',
        renderSize: 256,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_512x512.png',
        renderSize: 512,
      );
  }
}

// Returns Player image for Players Picker based on screen width for RostersSelection
ImageConfigAvatar gGetAvatarPlayerImageConfigRS(String avatarCode) {
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
    case GlobalEnumDisplayMode.display15MediumTablet:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_128x128.png',
        renderSize: 128,
      );
    case GlobalEnumDisplayMode.display20LargeLapDesk:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_512x512.png',
        renderSize: 512,
      );
  }
}

// Returns Framing image TeamCard Horizontal for Teams Picker based on screen width for RostersSelection
ImageConfigTeamCardFrame gGetCarouselTeamCardHFrameImageRS() {  
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
    
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_128x87.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_128x87.png',
        renderWidth: 128,
        renderHeight: 87,
      );
    case GlobalEnumDisplayMode.display15MediumTablet:
    case GlobalEnumDisplayMode.display20LargeLapDesk:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_256x175.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_256x175.png',
        renderWidth: 256,
        renderHeight: 175,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
      return ImageConfigTeamCardFrame(        
        assetPathFrame: 'assets/png/mechanics/team_card_frame_512x350.png',
        assetPathIsDummyPlayer: 'assets/png/mechanics/player_dummy_512x350.png',
        renderWidth: 512,
        renderHeight: 350,
      );
  }
}

// Returns Player image for Avatars Picker based on screen width for RostersSelection
ImageConfigAvatar gGetAvatarTeamCardImageConfigRS(String avatarCode) {
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
    
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_64x64.png',
        renderSize: 64,
      );
    case GlobalEnumDisplayMode.display15MediumTablet:
    case GlobalEnumDisplayMode.display20LargeLapDesk:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_128x128.png',
        renderSize: 128,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
      );
  }
}

// Returns Framing image for Players Grid Background based on screen width for RostersSelection
ImageConfigAvatar gGetAvatarPlayerFrameImageConfigGB() {  
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_64x64.png',
        renderSize: 64,
      );
    case GlobalEnumDisplayMode.display15MediumTablet:
    case GlobalEnumDisplayMode.display20LargeLapDesk:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_128x128.png',
        renderSize: 128,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/mechanics/player_avatar_256x256.png',
        renderSize: 256,
      );
  }
}

// Returns Player image for Players Grid Background based on screen width for RostersSelection
ImageConfigAvatar gGetAvatarPlayerImageConfigGB(String avatarCode) {
  switch (GlobalAppDisplay.displayMode) {
    case GlobalEnumDisplayMode.display05SmallPhone:
    case GlobalEnumDisplayMode.display10CompactPhone:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_64x64.png',
        renderSize: 64,
      );
    case GlobalEnumDisplayMode.display15MediumTablet:
    case GlobalEnumDisplayMode.display20LargeLapDesk:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_128x128.png',
        renderSize: 128,
      );
    case GlobalEnumDisplayMode.display25Ultra4K:
      return ImageConfigAvatar(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
      );
  }
}