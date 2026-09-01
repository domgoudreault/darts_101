// Flutter basics
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

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

Future<void> seedHiveLeagueTeams(Box<TblPlayer> playersBox, Box<TblTeam> teamsBox) async {  
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