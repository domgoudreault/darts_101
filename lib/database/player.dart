import 'package:hive/hive.dart';

part 'player.g.dart';

@HiveType(typeId: 1) // Unique ID for your model
class Player extends HiveObject {
  @HiveField(0)
  int? idPlayer;

  @HiveField(1)
  String firstName;

  @HiveField(2)
  String lastName;

  @HiveField(3)
  String nickName;

  @HiveField(4, defaultValue: false)
  bool? deleted;

  Player({this.idPlayer, required this.firstName, required this.lastName, required this.nickName, this.deleted});
}