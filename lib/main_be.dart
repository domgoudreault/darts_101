// Flutter basics
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_avatar.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';

Future<void> seedHiveAvatars(Box<TblAvatar> avatarsBox) async {
  // seed Avatars
  List<TblAvatar> listAvatars = [
    TblAvatar(fldAvatarCode: 'domi', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'ricky', fldIsMale: true),
    TblAvatar(fldAvatarCode: '02', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'christo', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'marcel', fldIsMale: true),
    TblAvatar(fldAvatarCode: '01', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'fred', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'drou', fldIsMale: true),
    TblAvatar(fldAvatarCode: '03', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'titi', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'marco', fldIsMale: true),
    TblAvatar(fldAvatarCode: '08', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'ludo', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'max', fldIsMale: true),
    TblAvatar(fldAvatarCode: '07', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'papy', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'charles', fldIsMale: true),
    TblAvatar(fldAvatarCode: '10', fldIsMale: false),
    TblAvatar(fldAvatarCode: '04', fldIsMale: true),
    TblAvatar(fldAvatarCode: '05', fldIsMale: true),
    TblAvatar(fldAvatarCode: '09', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'bryan', fldIsMale: true),
    TblAvatar(fldAvatarCode: '06', fldIsMale: true),
    TblAvatar(fldAvatarCode: '11', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'carmel', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'question', fldIsMale: true),
  ];

  await avatarsBox.addAll(listAvatars);
}

String getPrivacyPolicySection(int section) {
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

String getInformationSection(int section) {
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

class ImageConfig {
  final String assetPath;
  final double renderSize;

  const ImageConfig({required this.assetPath, required this.renderSize});
}

// Returns image configuration based on screen width
ImageConfig getInformationDialogImageConfig() {  
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
ImageConfig getCarouselTileImageConfig(String tileType, String tileName) {  
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
ImageConfig getSectionHeaderImageConfig(String sectionCode) {  
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