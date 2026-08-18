import 'package:hive_ce/hive_ce.dart';

part 'tbl_avatar.g.dart';

@HiveType(typeId: 3) // Unique ID for your model
class TblAvatar extends HiveObject {
  @HiveField(0)
  String fldAvatarCode;  

  @HiveField(1, defaultValue: true)
  bool fldIsMale;

  TblAvatar({
    required this.fldAvatarCode,
    this.fldIsMale = true,
  });
}