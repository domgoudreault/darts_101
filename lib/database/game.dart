import 'package:hive/hive.dart';

part 'game.g.dart';

@HiveType(typeId: 3) // Unique ID for your model
class Game extends HiveObject {
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
  bool ended;

  Game({
    required this.gameType, 
    required this.gameMode, 
    required this.teamsIDs, 
    this.idTeamWinner, 
    required this.playersIDs, 
    this.idPlayerWinner, 
    required this.ended
  });
}