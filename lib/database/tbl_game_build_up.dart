import 'package:hive_ce/hive_ce.dart';

part 'tbl_game_build_up.g.dart';

@HiveType(typeId: 6) // Unique ID for your model
class TblGameBuildUp extends HiveObject {
  @HiveField(0)
  int? idGameBuildUp;

  @HiveField(1)
  int idGame;

  @HiveField(2)
  int idPlayer;

  @HiveField(3, defaultValue: false)
  bool isLeftLane;

  @HiveField(4)
  int seatIndex; //position of the player in the lane

  @HiveField(5, defaultValue: false)
  bool isSeatedRecord;

  @HiveField(6)
  int round;
  
  @HiveField(7)
  // example, a build up game has values [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25]
  int targetValue;

  @HiveField(8, defaultValue: false)
  bool isSingle;

  @HiveField(9, defaultValue: false)
  bool isDouble;

  @HiveField(10, defaultValue: false)
  bool isTriple;

  @HiveField(11, defaultValue: false)
  bool isMiss;

  @HiveField(12)
  int nextTargetValue; //The next target to be hit.

  TblGameBuildUp({
    this.idGameBuildUp,
    required this.idGame,
    required this.idPlayer, 
    this.isLeftLane = false, 
    required this.seatIndex,
    this.isSeatedRecord = false,
    required this.round,
    required this.targetValue,
    this.isSingle = false,
    this.isDouble = false,
    this.isTriple = false,
    this.isMiss = false,
    required this.nextTargetValue,
  });
}