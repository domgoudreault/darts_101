// Flutter basics
import 'package:hive_ce/hive_ce.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_game.dart';

// Backend Logic

part 'tbl_game_half_it.g.dart';

@HiveType(typeId: 5) // Unique ID for your model
class TblGameHalfIt extends HiveObject {
  @HiveField(0)
  TblGame fldGame;

  @HiveField(1)
  TblPlayer fldPlayer;
 
  @HiveField(2)
  int fldSeatIndex; //position of the player during the whole game

  @HiveField(3)
  // example, a split game has 12 rounds [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, bull]
  int fldRound;

  @HiveField(4)
  // example, a split game has values [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25]
  int fldTargetValue;

  @HiveField(5)
  int fldHits;

  @HiveField(6)
  int fldScoreSnapshot; //The running total after the hits or halving.

  @HiveField(7)
  int fldsScoreTeamSnapshot; //The running total after the hits or halving.

  @HiveField(8, defaultValue: false)
  bool fldIsHalfIt;
  
  TblGameHalfIt({
    required this.fldGame,
    required this.fldPlayer,
    required this.fldSeatIndex, 
    required this.fldRound, 
    required this.fldTargetValue, 
    required this.fldHits, 
    required this.fldScoreSnapshot, 
    required this.fldsScoreTeamSnapshot,
    this.fldIsHalfIt = false,
  });
}