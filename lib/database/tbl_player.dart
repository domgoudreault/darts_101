// Flutter basics
import 'package:hive_ce/hive_ce.dart';

// Database Models
import 'package:darts_101/database/tbl_avatar.dart';

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

  @HiveField(5)
  TblAvatar fldAvatar;

  TblPlayer({
    required this.fldFirstName, 
    required this.fldLastName, 
    required this.fldNickName, 
    this.fldIsDeleted = false,
    this.fldIsLeagueMember = false,
    required this.fldAvatar,
  });
}