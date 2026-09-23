// Flutter basics
import 'package:hive_ce/hive_ce.dart';

// Database Models
import 'package:darts_101/database/enum_game_type.dart';

part 'tbl_game_options.g.dart';

@HiveType(typeId: 7) // Unique ID for your model
class TblGameOptions extends HiveObject {
  @HiveField(0)
  GlobalGameType fldGameType;

  @HiveField(1)
  int fldMinNbrPlayers;

  @HiveField(2)
  int fldMinNbrTeams;

  @HiveField(3)
  int fldMaxNbrPlayers;

  @HiveField(4)
  int fldMaxNbrTeams;

  @HiveField(5)
  int fldNbrLives;

  @HiveField(6, defaultValue: false)
  bool fldShowOptNbrLives;

  @HiveField(7)
  int fldStartingScore;

  @HiveField(8, defaultValue: false)
  bool fldShowOptStartingScore;

  TblGameOptions({
    required this.fldGameType,
    required this.fldMinNbrPlayers,
    required this.fldMinNbrTeams,
    required this.fldMaxNbrPlayers,
    required this.fldMaxNbrTeams,
    required this.fldNbrLives,
    this.fldShowOptNbrLives = false,
    required this.fldStartingScore,
    this.fldShowOptStartingScore = false,
  });
}