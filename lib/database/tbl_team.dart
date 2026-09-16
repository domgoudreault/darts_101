// Flutter basics
import 'package:hive_ce/hive_ce.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';

part 'tbl_team.g.dart';

@HiveType(typeId: 2) // Unique ID for your model
class TblTeam extends HiveObject {
  @HiveField(0)
  List<TblPlayer> fldPlayers;

  @HiveField(1, defaultValue: false)
  bool fldIsDeleted;

  TblTeam({
    required this.fldPlayers, 
    this.fldIsDeleted = false,
  });

  int get playersCount => fldPlayers.length;
}