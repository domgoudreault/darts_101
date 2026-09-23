// Flutter basics
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_avatar.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';
import 'package:darts_101/database/tbl_game_options.dart';
import 'package:darts_101/database/enum_game_type.dart';

Future<void> gSeedHiveAvatars(Box<TblAvatar> avatarsBox) async {
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
    TblAvatar(fldAvatarCode: 'carl', fldIsMale: true),
    TblAvatar(fldAvatarCode: '12', fldIsMale: false),
    TblAvatar(fldAvatarCode: 'question', fldIsMale: true),
  ];

  await avatarsBox.addAll(listAvatars);
}

Future<void> gSeedHiveLeaguePlayers(Box<TblPlayer> playersBox) async {
  final avatarsBox = Hive.box<TblAvatar>('avatarsBox');

  // seed Players
  List<TblPlayer> listPlayers = [
    TblPlayer(fldFirstName: 'Dominique', fldLastName: 'Goudreault', fldNickName: 'Domi', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'domi')),
    TblPlayer(fldFirstName: 'Éric', fldLastName: 'St-Pierre', fldNickName: 'Ricky', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'ricky')),
    TblPlayer(fldFirstName: 'Christopher', fldLastName: 'Lafond', fldNickName: 'Christo', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'christo')),
    TblPlayer(fldFirstName: 'Frédéric', fldLastName: 'Gagnon', fldNickName: 'Marcel', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'marcel')),
    TblPlayer(fldFirstName: 'Frederik', fldLastName: 'Peeters Bélanger', fldNickName: 'Fred', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'fred')),
    TblPlayer(fldFirstName: 'Simon', fldLastName: 'Drouin', fldNickName: 'Drou', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'drou')),
    TblPlayer(fldFirstName: 'Étienne', fldLastName: 'Lefrançois', fldNickName: 'Ti-ti', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'titi')),
    TblPlayer(fldFirstName: 'Marc-Olivier', fldLastName: 'Fortin', fldNickName: 'Marco', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'marco')),
    TblPlayer(fldFirstName: 'Ludovick', fldLastName: 'Gosselin', fldNickName: 'Ludo', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'ludo')),
    TblPlayer(fldFirstName: 'Maxime', fldLastName: 'Gagnon', fldNickName: 'Max', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'max')),
    TblPlayer(fldFirstName: 'Michel', fldLastName: 'Deschênes', fldNickName: 'Papy', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'papy')),
    TblPlayer(fldFirstName: 'Charles', fldLastName: 'Lirette', fldNickName: 'Charles', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'charles')),
    TblPlayer(fldFirstName: 'Bryan', fldLastName: 'Bryan', fldNickName: 'Bryan', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'bryan')),
    TblPlayer(fldFirstName: 'Carl', fldLastName: 'Dubé', fldNickName: 'Le Livreur', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'carl')),
    TblPlayer(fldFirstName: 'Carmel', fldLastName: 'Fortin', fldNickName: 'Carmel', fldIsDeleted: false, 
      fldIsLeagueMember: true, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'carmel')),
  ];

  await playersBox.addAll(listPlayers);
}

Future<void> gSeedHiveGenericPlayers(Box<TblPlayer> playersBox) async {
  final avatarsBox = Hive.box<TblAvatar>('avatarsBox');
  // seed Players
  List<TblPlayer> listPlayers = [
    TblPlayer(fldFirstName: 'Don Juan', fldLastName: 'De Marco', fldNickName: 'Bow Tie', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'domi')),
    TblPlayer(fldFirstName: 'Viktor', fldLastName: 'Vance', fldNickName: 'Lucky', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'ricky')),
    TblPlayer(fldFirstName: 'Stella', fldLastName: 'Rogue', fldNickName: 'Sniper', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '02')),
    TblPlayer(fldFirstName: 'Diesel', fldLastName: 'Nitro', fldNickName: 'War Hawk', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'christo')),
    TblPlayer(fldFirstName: 'Marcel', fldLastName: 'Steele', fldNickName: 'Double Out', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'marcel')),
    TblPlayer(fldFirstName: 'Elektra', fldLastName: 'Volt', fldNickName: 'Rebel Red', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '01')),
    TblPlayer(fldFirstName: 'Maverick', fldLastName: 'Thunderbolt', fldNickName: 'Turbo', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'fred')),
    TblPlayer(fldFirstName: 'Spike', fldLastName: 'Prowler', fldNickName: 'Clutch', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'drou')),
    TblPlayer(fldFirstName: 'Anita', fldLastName: 'McGee', fldNickName: 'Bounce Out', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '03')),
    TblPlayer(fldFirstName: 'Low', fldLastName: 'Rollings', fldNickName: 'Nerdy', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'titi')),
    TblPlayer(fldFirstName: 'Jimmy', fldLastName: 'Swift', fldNickName: 'Outlaw', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'marco')),
    TblPlayer(fldFirstName: 'Roxie', fldLastName: 'Razor', fldNickName: 'Vixen', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '08')),
    TblPlayer(fldFirstName: 'Duke', fldLastName: 'Sterling', fldNickName: 'Jackpot', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'ludo')),
    TblPlayer(fldFirstName: 'Dizzy', fldLastName: 'Blowgun', fldNickName: 'Dr. Darts', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'max')),
    TblPlayer(fldFirstName: 'Charlotte', fldLastName: 'Purrfect', fldNickName: 'Catnip', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '07')),
    TblPlayer(fldFirstName: 'Earl', fldLastName: 'Montgomery', fldNickName: 'Pops', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'papy')),
    TblPlayer(fldFirstName: 'Roman', fldLastName: 'Vortex', fldNickName: 'The Wizard', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'charles')),
    TblPlayer(fldFirstName: 'Pamela', fldLastName: 'Pennyworth', fldNickName: 'Gold Digger', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '10')),
    TblPlayer(fldFirstName: 'Clay', fldLastName: 'Bentonite', fldNickName: 'Pixie', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '04')),
    TblPlayer(fldFirstName: 'Leo', fldLastName: 'Pawfur', fldNickName: 'Magic Paws', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '05')),
    TblPlayer(fldFirstName: 'Siren', fldLastName: 'Scream', fldNickName: 'Banshee', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '09')),
    TblPlayer(fldFirstName: 'Rex', fldLastName: 'Stone', fldNickName: 'Dart Vader', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'bryan')),
    TblPlayer(fldFirstName: 'Ronald', fldLastName: 'Cummings', fldNickName: 'Preacher', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '06')),
    TblPlayer(fldFirstName: 'Bonnie', fldLastName: 'Banks', fldNickName: 'Cashflow', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '11')),
    TblPlayer(fldFirstName: 'Johnny', fldLastName: 'Danger', fldNickName: 'Bullseye', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'carmel')),
    TblPlayer(fldFirstName: 'Mario', fldLastName: 'Crustini', fldNickName: 'The Slice', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == 'carl')),
    TblPlayer(fldFirstName: 'Harley', fldLastName: 'Stitcher', fldNickName: 'Fatal Sting', fldIsDeleted: false, 
      fldIsLeagueMember: false, fldAvatar: avatarsBox.values.firstWhere((a) => a.fldAvatarCode == '12')),
  ];

  await playersBox.addAll(listPlayers);
}

Future<void> gSeedHiveTeams(Box<TblPlayer> playersBox, Box<TblTeam> teamsBox) async {  
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

Future<void> gSeedHiveGameOptions(Box<TblGameOptions> optionsBox) async {
  List<TblGameOptions> listOptions = [
    TblGameOptions(fldGameType: GlobalGameType.halfIt, fldMinNbrPlayers: 2, fldMinNbrTeams: 2, fldMaxNbrPlayers: 12, fldMaxNbrTeams: 6,
      fldNbrLives: 0, fldShowOptNbrLives: false, fldStartingScore: 100, fldShowOptStartingScore: true),
    TblGameOptions(fldGameType: GlobalGameType.aroundClock, fldMinNbrPlayers: 2, fldMinNbrTeams: 2, fldMaxNbrPlayers: 12, fldMaxNbrTeams: 6,
      fldNbrLives: 0, fldShowOptNbrLives: false, fldStartingScore: 0, fldShowOptStartingScore: false),
    TblGameOptions(fldGameType: GlobalGameType.sevenDarts, fldMinNbrPlayers: 2, fldMinNbrTeams: 2, fldMaxNbrPlayers: 12, fldMaxNbrTeams: 6,
      fldNbrLives: 0, fldShowOptNbrLives: false, fldStartingScore: 0, fldShowOptStartingScore: false),
    TblGameOptions(fldGameType: GlobalGameType.allFives, fldMinNbrPlayers: 2, fldMinNbrTeams: 2, fldMaxNbrPlayers: 12, fldMaxNbrTeams: 6,
      fldNbrLives: 0, fldShowOptNbrLives: false, fldStartingScore: 0, fldShowOptStartingScore: false),
    TblGameOptions(fldGameType: GlobalGameType.killers, fldMinNbrPlayers: 2, fldMinNbrTeams: 2, fldMaxNbrPlayers: 12, fldMaxNbrTeams: 6,
      fldNbrLives: 7, fldShowOptNbrLives: true, fldStartingScore: 0, fldShowOptStartingScore: false),
    TblGameOptions(fldGameType: GlobalGameType.suddenDeath, fldMinNbrPlayers: 3, fldMinNbrTeams: 3, fldMaxNbrPlayers: 12, fldMaxNbrTeams: 6,
      fldNbrLives: 0, fldShowOptNbrLives: false, fldStartingScore: 0, fldShowOptStartingScore: false),
    TblGameOptions(fldGameType: GlobalGameType.buildUp, fldMinNbrPlayers: 4, fldMinNbrTeams: 0, fldMaxNbrPlayers: 12, fldMaxNbrTeams: 0,
      fldNbrLives: 0, fldShowOptNbrLives: false, fldStartingScore: 0, fldShowOptStartingScore: false),
  ];

  await optionsBox.addAll(listOptions);
}

TblGameOptions gGetGameOptions(GlobalGameType gameType) {
  final optionsBox = Hive.box<TblGameOptions>('gameOptionsBox');
  return optionsBox.values.firstWhere((opt) => opt.fldGameType == gameType);
}