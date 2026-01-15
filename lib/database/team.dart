import 'package:hive/hive.dart';

part 'team.g.dart';

@HiveType(typeId: 2) // Unique ID for your model
class Team extends HiveObject {
  @HiveField(0)
  int? idTeam;

  @HiveField(1)
  int idPlayer1;

  @HiveField(2)
  int idPlayer2;

  @HiveField(3)
  String surName;

  @HiveField(4, defaultValue: false)
  bool? deleted;

  Team({required this.idPlayer1, required this.idPlayer2, required this.surName, this.deleted});
}