// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

part 'enum_game_type.g.dart';

// Global enum representing supported game modes
@HiveType(typeId: 6)
enum GlobalGameType {
  @HiveField(0)
  halfIt(
    tileType: 'games', tileCode: 'half-it', tileColor: Color(0xFF29B6F6), tileBackgroundColor: Color(0xFF81D4FA),
    tileDisplayName: 'Half-It Game', minNbrPlayers: 2, minNbrTeams: 2, maxNbrPlayers: 12, maxNbrTeams: 6,
    nbrLives: 0, nbrRounds: 0,
  ),
  @HiveField(1)
  aroundClock(
    tileType: 'games', tileCode: 'around-clock', tileColor: Color(0xFF26A69A), tileBackgroundColor: Color(0xFF80CBC4),
    tileDisplayName: 'Around the Clock (skip the numbers) Game', minNbrPlayers: 2, minNbrTeams: 2, maxNbrPlayers: 12, maxNbrTeams: 6,
    nbrLives: 0, nbrRounds: 0,
  ),
  @HiveField(2)
  sevenDarts(
    tileType: 'games', tileCode: '7-darts', tileColor: Color(0xFF66BB6A), tileBackgroundColor: Color(0xFFA5D6A7),
    tileDisplayName: '7 Darts Game', minNbrPlayers: 2, minNbrTeams: 2, maxNbrPlayers: 12, maxNbrTeams: 6,
    nbrLives: 0, nbrRounds: 3,
  ),
  @HiveField(3)
  allFives(
    tileType: 'games', tileCode: 'all-fives', tileColor: Color(0xFFCE93D8), tileBackgroundColor: Color(0xFFE1BEE7),
    tileDisplayName: 'All Fives / 51 by 5\'s Game', minNbrPlayers: 2, minNbrTeams: 2, maxNbrPlayers: 12, maxNbrTeams: 6,
    nbrLives: 0, nbrRounds: 0,
  ),
  @HiveField(4)
  killers(
    tileType: 'games', tileCode: 'killers', tileColor: Color(0xFF9E9E9E), tileBackgroundColor: Color(0xFFEEEEEE),
    tileDisplayName: 'Killers Game', minNbrPlayers: 2, minNbrTeams: 2, maxNbrPlayers: 12, maxNbrTeams: 6,
    nbrLives: 7, nbrRounds: 0,
  ),
  @HiveField(5)
  suddenDeath(
    tileType: 'games', tileCode: 'sudden-death', tileColor: Color(0xFFB71C1C), tileBackgroundColor: Color(0xFFEF5350),
    tileDisplayName: 'Sudden Death Game', minNbrPlayers: 3, minNbrTeams: 3, maxNbrPlayers: 12, maxNbrTeams: 6,
    nbrLives: 0, nbrRounds: 0,
  ),
  @HiveField(6)
  buildUp(
    tileType: 'games', tileCode: 'build-up', tileColor: Color(0xFF7E57C2), tileBackgroundColor: Color(0xFFB39DDB),
    tileDisplayName: 'Team Build-up Game', minNbrPlayers: 4, minNbrTeams: 0, maxNbrPlayers: 12, maxNbrTeams: 0,
    nbrLives: 0, nbrRounds: 0,
  );

  final String tileType;
  final String tileCode;
  final Color tileColor;
  final Color tileBackgroundColor;
  final String tileDisplayName;
  final int minNbrPlayers;
  final int minNbrTeams;
  final int maxNbrPlayers;
  final int maxNbrTeams;
  final int nbrLives;
  final int nbrRounds;

  const GlobalGameType({
    required this.tileType,
    required this.tileCode,
    required this.tileColor,
    required this.tileBackgroundColor,
    required this.tileDisplayName,
    required this.minNbrPlayers,
    required this.minNbrTeams,
    required this.maxNbrPlayers,
    required this.maxNbrTeams,
    required this.nbrLives,
    required this.nbrRounds,
  });

  static GlobalGameType getTile(String tileCode) {
    return GlobalGameType.values.firstWhere(
      (e) => e.tileCode == tileCode,
      orElse: () => GlobalGameType.halfIt,
    );
  }
}