class Reward {
  String studentId;
  int currentStreak;
  int totalPoints;
  List<String> badgesEarned;

  Reward({
    required this.studentId,
    required this.currentStreak,
    required this.totalPoints,
    required this.badgesEarned,
  });

  Map<String, dynamic> toMap() => {
        "studentId": studentId,
        "currentStreak": currentStreak,
        "totalPoints": totalPoints,
        "badgesEarned": badgesEarned,
      };

  factory Reward.fromMap(Map<String, dynamic> map) => Reward(
        studentId: map["studentId"],
        currentStreak: map["currentStreak"],
        totalPoints: map["totalPoints"],
        badgesEarned: List<String>.from(map["badgesEarned"]),
      );
}
