import 'package:hive_ce/hive_ce.dart';

part 'tbl_game.g.dart';

@HiveType(typeId: 3) // Unique ID for your model
class TblGame extends HiveObject {
  @HiveField(0)
  int? idGame;

  @HiveField(1)
  // gameType = [1, Half-it], [2, Team Build-up], etc...
  int gameType;
 
  // gameMode = [1, Players], [2, Teams]
  @HiveField(2)
  int gameMode;

  @HiveField(3)
  List<int>? teamsIDs;

  @HiveField(4)
  int? idTeamWinner;

  @HiveField(5)
  List<int> playersIDs;

  @HiveField(6)
  int? idPlayerWinner;

  @HiveField(7, defaultValue: false)
  bool isEnded;

  TblGame({
    this.idGame,
    required this.gameType, 
    required this.gameMode, 
    this.teamsIDs, 
    this.idTeamWinner, 
    required this.playersIDs, 
    this.idPlayerWinner, 
    this.isEnded = false,
  });
}