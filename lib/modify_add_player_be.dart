import 'package:darts_101/global_be.dart';

class ImageConfig {
  final String assetPath;
  final double renderSize;

  const ImageConfig({required this.assetPath, required this.renderSize});
}

// Returns Framing image for Main UI based on screen width
ImageConfig getAvatarFrameMainImageConfig() {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/player_avatar_128x128.png',
        renderSize: 128,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/player_avatar_256x256.png',
        renderSize: 256,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/player_avatar_256x256.png',
        renderSize: 256,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/player_avatar_512x512.png',
        renderSize: 512,
      );
  }
}

// Returns Player image for Main UI based on screen width
ImageConfig getAvatarPlayerMainImageConfig(String avatarCode) {
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
      return ImageConfig(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_128x128.png',
        renderSize: 128,
      );
    case DisplayMode.display15MediumTablet:
      return ImageConfig(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
      );
    case DisplayMode.display20LargeLapDesk:
      return ImageConfig(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfig(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_512x512.png',
        renderSize: 512,
      );
  }
}

// Returns Framing image for Avatars Picker based on screen width
ImageConfig getAvatarFramePickerImageConfig() {  
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
    case DisplayMode.display15MediumTablet:
    case DisplayMode.display20LargeLapDesk:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/player_avatar_128x128.png',
        renderSize: 128,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfig(        
        assetPath: 'assets/png/mechanics/player_avatar_256x256.png',
        renderSize: 256,
      );
  }
}

// Returns Player image for Avatars Picker based on screen width
ImageConfig getAvatarPlayerPickerImageConfig(String avatarCode) {
  switch (AppDisplay.displayMode) {
    case DisplayMode.display05SmallPhone:
    case DisplayMode.display10CompactPhone:
    case DisplayMode.display15MediumTablet:
    case DisplayMode.display20LargeLapDesk:
      return ImageConfig(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_128x128.png',
        renderSize: 128,
      );
    case DisplayMode.display25Ultra4K:
      return ImageConfig(        
        assetPath: 'assets/png/avatars/avatar_${avatarCode}_256x256.png',
        renderSize: 256,
      );
  }
}