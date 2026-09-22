// Flutter basics
import 'package:hive_ce/hive_ce.dart';

// Database Models
import 'package:darts_101/database/enum_game_type.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

part 'tbl_game.g.dart';

@HiveType(typeId: 4) // Unique ID for your model
class TblGame extends HiveObject {
  @HiveField(0)
  GlobalGameType fldGameType;

  @HiveField(1, defaultValue: true)
  bool fldPlayersGM; // true = PlayersGameMode, false = TeamsGameMode
 
  @HiveField(2)
  List<TblPlayer> fldPlayers;

  @HiveField(3)
  List<TblTeam>? fldTeams;

  @HiveField(4)
  List<TblPlayer>? fldPlayersWinner;

  @HiveField(5)
  List<TblTeam>? fldTeamsWinner;

  @HiveField(6, defaultValue: false)
  bool fldIsEnded;

  TblGame({
    required this.fldGameType,
    this.fldPlayersGM = true,
    required this.fldPlayers, 
    this.fldTeams, 
    this.fldPlayersWinner, 
    this.fldTeamsWinner, 
    this.fldIsEnded = false,
  });
}