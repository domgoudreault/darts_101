import 'package:hive_ce/hive_ce.dart';

part 'tbl_player.g.dart';

@HiveType(typeId: 1) // Unique ID for your model
class TblPlayer extends HiveObject {
  @HiveField(0)
  String fldFirstName;

  @HiveField(1)
  String fldLastName;

  @HiveField(2)
  String fldNickName;

  @HiveField(3, defaultValue: false)
  bool fldIsDeleted;

  @HiveField(4, defaultValue: false)
  bool fldIsLeagueMember;

  @HiveField(5, defaultValue: 'avatar_01')
  String fldAvatarCode;

  TblPlayer({
    required this.fldFirstName, 
    required this.fldLastName, 
    required this.fldNickName, 
    this.fldIsDeleted = false,
    this.fldIsLeagueMember = false,
    required this.fldAvatarCode,
  });
}