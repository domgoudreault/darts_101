import 'package:hive/hive.dart';

part 'gamebuildup.g.dart';

@HiveType(typeId: 5) // Unique ID for your model
class GameBuildUp extends HiveObject {
  @HiveField(0)
  int? idGameBuildUp;

  @HiveField(1)
  int idGame;

  @HiveField(2)
  int idPlayer;

  @HiveField(3)
  int seatIndex; //position of the player during the whole game

  @HiveField(4)
  // example, a build up game has values [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25]
  int targetValue;

  @HiveField(5, defaultValue: false)
  bool hitDouble;

  @HiveField(6, defaultValue: false)
  bool hitTriple;

  @HiveField(7)
  int nextTargetValue; //The next target to be hit.

  GameBuildUp({
    required this.idGame,
    required this.idPlayer, 
    required this.seatIndex, 
    required this.targetValue, 
    required this.hitDouble, 
    required this.hitTriple,
    required this.nextTargetValue,
  });
}