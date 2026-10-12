// Flutter basics
import 'package:hive_ce/hive_ce.dart';

// Database Models
import 'package:darts_101/database/enum_game_type.dart';
import 'package:darts_101/database/tbl_player.dart';
import 'package:darts_101/database/tbl_team.dart';

part 'tbl_game.g.dart';

@HiveType(typeId: 4) // Unique ID for your model
class TblGame extends HiveObject {
  @HiveField(0)
  GlobalGameType fldGameType;

  @HiveField(1, defaultValue: true)
  bool fldPlayersGM; // true = PlayersGameMode, false = TeamsGameMode
 
  @HiveField(2)
  List<TblPlayer> fldPlayers;

  @HiveField(3)
  List<TblTeam>? fldTeams;

  @HiveField(4)
  List<TblPlayer>? fldPlayersWinner;

  @HiveField(5)
  List<TblTeam>? fldTeamsWinner;

  @HiveField(6, defaultValue: false)
  bool fldIsEnded;

  @HiveField(7, defaultValue: 0)
  int fldAroundClockMode;

  TblGame({
    required this.fldGameType,
    this.fldPlayersGM = true,
    required this.fldPlayers, 
    this.fldTeams, 
    this.fldPlayersWinner, 
    this.fldTeamsWinner, 
    this.fldIsEnded = false,
    required this.fldAroundClockMode,
  });

  // Returns 0 (none), 1 (one bull), or 2 (two bulls) for start/end
  // bits 1-2 = 00 = 0
  // bits 1-2 = 01(fldStartEndBull) = 1
  // bits 1-2 = 10(fldStartEndDoubleBull) = 2
  int get getACModeNbrStartEndBulls => fldAroundClockMode & 0x03;

  // Returns 0 (none), 1 (one middle bull), or 2 (two middle bulls) for up & down
  // bits 3-4 = 0000 = 0
  // bits 3-4 = 0100(fldUpDownMidBull) = 1
  // bits 3-4 = 1000(fldUpDownMidDoubleBull) = 2
  int get getACModeNbrMiddleBulls => (fldAroundClockMode >> 2) & 0x03;

  // Returns true if players cannot skip over bullseyes
  // bit 5 = 10000(fldNoSkipWhenBull)
  bool get getACModeisNoSkip => (fldAroundClockMode & 0x10) != 0;
}