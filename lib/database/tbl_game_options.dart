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

  @HiveField(9)
  int fldNbrRounds;

  @HiveField(10, defaultValue: false)
  bool fldShowOptNbrRounds;

  @HiveField(11, defaultValue: false)
  bool fldStartEndBull;

  @HiveField(12, defaultValue: false)
  bool fldShowOptStartEndBull;

  @HiveField(13, defaultValue: false)
  bool fldStartEndDoubleBull;

  @HiveField(14, defaultValue: false)
  bool fldShowOptStartEndDoubleBull;

  @HiveField(15, defaultValue: false)
  bool fldUpDownBull;

  @HiveField(16, defaultValue: false)
  bool fldShowOptUpDownBull;

  @HiveField(17, defaultValue: false)
  bool fldMidDoubleBull;

  @HiveField(18, defaultValue: false)
  bool fldShowOptMidDoubleBull;

  @HiveField(19, defaultValue: false)
  bool fldNoSkipWhenBull;

  @HiveField(20, defaultValue: false)
  bool fldShowOptNoSkipWhenBull;


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
    required this.fldNbrRounds,
    this.fldShowOptNbrRounds = false,
    required this.fldStartEndBull,
    this.fldShowOptStartEndBull = false,
    required this.fldStartEndDoubleBull,
    this.fldShowOptStartEndDoubleBull = false,
    required this.fldUpDownBull,
    this.fldShowOptUpDownBull = false,
    required this.fldMidDoubleBull,
    this.fldShowOptMidDoubleBull = false,
    required this.fldNoSkipWhenBull,
    this.fldShowOptNoSkipWhenBull = false,
  });

  bool get hasVisibleOptions {
    return fldShowOptNbrLives || 
           fldShowOptStartingScore || 
           fldShowOptNbrRounds || 
           fldShowOptStartEndBull || 
           fldShowOptStartEndDoubleBull || 
           fldShowOptUpDownBull || 
           fldShowOptMidDoubleBull || 
           fldShowOptNoSkipWhenBull;
  }
}