import 'package:darts_101/database/tbl_player.dart';
import 'package:hive_ce/hive_ce.dart';

part 'tbl_team.g.dart';

@HiveType(typeId: 2) // Unique ID for your model
class TblTeam extends HiveObject {
  @HiveField(0)
  TblPlayer player1;

  @HiveField(1)
  TblPlayer player2;

  @HiveField(2)
  String surName;

  @HiveField(3, defaultValue: false)
  bool isDeleted;

  TblTeam({
    required this.player1, 
    required this.player2, 
    required this.surName, 
    this.isDeleted = false,
  });
}