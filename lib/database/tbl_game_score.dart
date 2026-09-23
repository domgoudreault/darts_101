// Flutter basics
import 'package:hive_ce/hive_ce.dart';

// Database Models
import 'package:darts_101/database/tbl_game.dart';
import 'package:darts_101/database/tbl_player.dart';

part 'tbl_game_score.g.dart';

@HiveType(typeId: 5) // Unique ID for your model
class TblGameScore extends HiveObject {
  @HiveField(0)
  TblGame fldGame;

  @HiveField(1)
  TblPlayer fldPlayer;

  @HiveField(2)
  int? fldLaneIndex; //position of the player in wich lane during the whole game

  @HiveField(3)
  int fldSeatIndex; //position of the player in his lane during the whole game

  @HiveField(4)
  int fldDartIndex; //wich throw it was for that player

  @HiveField(5)
  // The fldGameType in the fldGame(TblGame) contains the max nbr of rounds
  // example, a split game has 12 rounds [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, bull]
  // example, a build up game has 12 rounds [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, bull]
  int fldRound;

  //TO DO find a way to register lives removal
  //nbrLives: 0

  @HiveField(6)
  int fldTargetIndex;
  
  @HiveField(7)
  // example, a split game has values [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25]
  // example, a build up game has values [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25]
  int fldTargetValue;

  @HiveField(8)
  int? fldNextTargetIndex;
  
  @HiveField(9)
  int? fldNextTargetValue; //The next target to be hit.

  @HiveField(10, defaultValue: false)
  bool fldIsSingle;

  @HiveField(11, defaultValue: false)
  bool fldIsDouble;

  @HiveField(12, defaultValue: false)
  bool fldIsTriple;

  @HiveField(13, defaultValue: false)
  bool fldIsMiss;

  @HiveField(14)
  int fldHits;

  @HiveField(15, defaultValue: false)
  bool fldIsHalfIt;

  @HiveField(16)
  int fldScorePlayerSnapshot; //The running total after the hits or halving.

  @HiveField(17)
  int? fldScoreTeamSnapshot; //The running total after the hits or halving.

  TblGameScore({
    required this.fldGame,
    required this.fldPlayer,
    this.fldLaneIndex,
    required this.fldSeatIndex,
    required this.fldDartIndex,
    required this.fldRound,
    required this.fldTargetIndex,
    required this.fldTargetValue,
    this.fldNextTargetIndex,
    this.fldNextTargetValue,
    this.fldIsSingle = false,
    this.fldIsDouble = false,
    this.fldIsTriple = false,
    this.fldIsMiss = false,
    required this.fldHits,
    this.fldIsHalfIt = false,
    required this.fldScorePlayerSnapshot,
    this.fldScoreTeamSnapshot,
  });
}