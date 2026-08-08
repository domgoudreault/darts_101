import 'package:hive_ce/hive_ce.dart';

part 'tbl_game_half_it.g.dart';

@HiveType(typeId: 5) // Unique ID for your model
class TblGameHalfIt extends HiveObject {
  @HiveField(0)
  int? idGameHalfIt;

  @HiveField(1)
  int idGame;

  @HiveField(2)
  int? idTeam;
 
  @HiveField(3)
  int idPlayer;

  @HiveField(4)
  int seatIndex; //position of the player during the whole game

  @HiveField(5)
  // example, a split game has 12 rounds [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, bull]
  int round;

  @HiveField(6)
  // example, a split game has values [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25]
  int targetValue;

  @HiveField(7)
  int hits;

  @HiveField(8)
  int scoreSnapshot; //The running total after the hits or halving.

  @HiveField(9)
  int scoreTeamSnapshot; //The running total after the hits or halving.

  @HiveField(10, defaultValue: false)
  bool isHalfIt;
  
  TblGameHalfIt({
    this.idGameHalfIt,
    required this.idGame,
    this.idTeam,
    required this.idPlayer, 
    required this.seatIndex, 
    required this.round, 
    required this.targetValue, 
    required this.hits, 
    required this.scoreSnapshot, 
    required this.scoreTeamSnapshot,
    this.isHalfIt = false,
  });
}