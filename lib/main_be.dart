// Flutter basics
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_avatar.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';

Future<void> seedHiveAvatars(Box<TblAvatar> avatarsBox) async {
  // seed Avatars
  List<TblAvatar> listAvatars = [
    TblAvatar(fldAvatarCode: 'domi', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'ricky', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'christo', fldIsMale: true),
    TblAvatar(fldAvatarCode: '02', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'marcel', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'fred', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'drou', fldIsMale: true),
    TblAvatar(fldAvatarCode: '01', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'titi', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'marco', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'ludo', fldIsMale: true),
    TblAvatar(fldAvatarCode: '03', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'max', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'papy', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'charles', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'bryan', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'carmel', fldIsMale: true),
    TblAvatar(fldAvatarCode: '04', fldIsMale: true),
    TblAvatar(fldAvatarCode: '05', fldIsMale: true),
    TblAvatar(fldAvatarCode: 'question', fldIsMale: true),
  ];

  await avatarsBox.addAll(listAvatars);
}

Future<void> seedHivePlayers(Box<TblPlayer> playersBox) async {
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
    TblPlayer(fldFirstName: 'Carl', fldLastName: 'Girard', fldNickName: 'Carl', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: '05'),
    TblPlayer(fldFirstName: 'Carmel', fldLastName: 'Fortin', fldNickName: 'Carmel', fldIsDeleted: false, fldIsLeagueMember: true, fldAvatarCode: 'carmel'),
    TblPlayer(fldFirstName: 'Francine', fldLastName: 'Halmos', fldNickName: 'Frankie', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '01'),
    TblPlayer(fldFirstName: 'Valérie', fldLastName: 'Morin', fldNickName: 'Val', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '02'),
    TblPlayer(fldFirstName: 'Sandra', fldLastName: 'Desgagnés-Laberge', fldNickName: 'San', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '03'),
    TblPlayer(fldFirstName: 'Alexis', fldLastName: 'Goudreault', fldNickName: 'San', fldIsDeleted: false, fldIsLeagueMember: false, fldAvatarCode: '04'),
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

      // Format surName based on whether it's a self-team or normal team
      final String teamName = (i == j)
          ? '${p1.fldNickName} Twice'
          : '${p1.fldNickName}, ${p2.fldNickName}';

      listTeams.add(
        TblTeam(
          fldPlayers: [p1, p2],
          fldSurName: teamName,
          fldIsDeleted: false,
        ),
      );
    }
  } 

  await teamsBox.addAll(listTeams);
}

String getPrivacyPolicySection(int section) {
  switch (section) {
    case 1:      
      return "Darts 101 is a free, ad-supported app and is intended for use as is.\n\n"
             "If you choose to use the Darts 101 app, then you agree to the collection and use of information in relation to this policy. The Personal Information collected by Darts 101 is used for improving Darts 101 and will not be shared with anyone except as described in this Privacy Policy.";
    case 2:
      return "Darts 101 uses third party services that might collect information used to identify you. The privacy policy URLs for the third party service providers used by Darts 101 are shown below:\n";
    case 3:
      return "\nDarts 101 does not require you to provide personally identifiable information, but the above third party services might.";
    case 4:
      return "Darts 101 collects data through third party products on your device called Log Data, which may include information such as your device's Internet Protocol address, device name, operating system version, the times you use Darts 101, and other statistics.\n\n"
             "When Darts 101 crashes, the details of the crash are collected by the third party products; such as when the crash occurred, which screen Darts 101 was showing, etc., and this information is used to improve the stability of Darts 101.";
    case 5:
      return "Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers. These are sent to your browser from the websites that you visit and are stored on your device's internal memory.\n\n"
             "Darts 101 does not directly use \"cookies\" of any type, but the third party libraries used by Darts 101 might use \"cookies\" to collect information.";
    case 6:
      return "Darts 101 does not directly request, read, collect, transmit nor store any of your Personal Information, but the third party services used by Darts 101 might make use of your Personal Information to provide their services.";
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