import 'package:hive_ce/hive_ce.dart';

part 'tbl_player.g.dart';

@HiveType(typeId: 1) // Unique ID for your model
class TblPlayer extends HiveObject {
  @HiveField(0)
  String firstName;

  @HiveField(1)
  String lastName;

  @HiveField(2)
  String nickName;

  @HiveField(3, defaultValue: false)
  bool isDeleted;

  TblPlayer({
    required this.firstName, 
    required this.lastName, 
    required this.nickName, 
    this.isDeleted = false,
  });
}