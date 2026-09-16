// Flutter basics
import 'package:hive_ce/hive_ce.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';

part 'tbl_game.g.dart';

@HiveType(typeId: 4) // Unique ID for your model
class TblGame extends HiveObject {
  @HiveField(0)
  GlobalGameType fldGameType;
 
  @HiveField(1)
  List<TblPlayer>? fldPlayers;

  @HiveField(2)
  List<TblTeam>? fldTeams;

  @HiveField(3)
  TblPlayer? fldPlayerWinner;

  @HiveField(4)
  TblTeam? fldTeamWinner;

  @HiveField(5, defaultValue: false)
  bool fldIsEnded;

  TblGame({
    required this.fldGameType,
    this.fldPlayers, 
    this.fldTeams, 
    this.fldPlayerWinner, 
    this.fldTeamWinner, 
    this.fldIsEnded = false,
  });
}