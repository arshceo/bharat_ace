// lib/core/models/leaderboard_user.dart
class LeaderboardUser {
  final String name;
  final int xp;
  final String? avatarUrl;

  LeaderboardUser({required this.name, required this.xp, this.avatarUrl});
}
