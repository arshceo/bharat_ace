// lib/core/models/student_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For listEquals and mapEquals

class StudentModel {
  final String id;
  final String username;
  final String name;
  final String email;
  final String phone;
  final String school;
  final String board;
  final String grade;
  final List<String> enrolledSubjects;
  final Timestamp createdAt;
  final Timestamp lastActive;
  final int xp;
  final int coins;
  final int dailyStreak;
  final Timestamp? lastXpEarnedDate;
  final bool isPremium;
  final String avatar;
  final Map<String, dynamic> deviceInfo;
  final String? bio;
  final String? studyGoal;
  final int contributionsCount;
  final int studyBuddiesCount;
  final DateTime? examDate; // ✨ NEW: Exam Date
  final DateTime? mstDate;
  StudentModel({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.phone,
    required this.school,
    required this.board,
    required this.grade,
    required this.enrolledSubjects,
    required this.createdAt,
    required this.lastActive,
    required this.xp,
    required this.coins,
    required this.dailyStreak,
    this.lastXpEarnedDate,
    required this.isPremium,
    required this.avatar,
    required this.deviceInfo,
    this.bio,
    this.studyGoal,
    this.contributionsCount = 0,
    this.studyBuddiesCount = 0,
    this.examDate,
    this.mstDate, // ✨ NEW: Added to constructor
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json["id"] ?? "",
      username: json["username"] ?? "",
      name: json["name"] ?? "",
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
      school: json["school"] ?? "",
      board: json["board"] ?? "",
      grade: json["grade"] ?? "6",
      enrolledSubjects: List<String>.from(json["enrolledSubjects"] ?? []),
      createdAt: json["createdAt"] as Timestamp? ?? Timestamp.now(),
      lastActive: json["lastActive"] as Timestamp? ?? Timestamp.now(),
      xp: json["xp"] as int? ?? 0,
      coins: json["coins"] as int? ?? 0,
      dailyStreak: json["dailyStreak"] as int? ?? 0,
      lastXpEarnedDate: json["lastXpEarnedDate"] as Timestamp?,
      isPremium: json["isPremium"] as bool? ?? false,
      avatar: json["avatar"] ?? "",
      deviceInfo: Map<String, dynamic>.from(json["deviceInfo"] ?? {}),
      bio: json["bio"] as String?,
      studyGoal: json["studyGoal"] as String?,
      contributionsCount: json["contributionsCount"] as int? ?? 0,
      studyBuddiesCount: json["studyBuddiesCount"] as int? ?? 0,
      examDate: json['examDate'] != null
          ? (json['examDate'] as Timestamp).toDate()
          : null,
      mstDate: json['mstDate'] != null
          ? (json['mstDate'] as Timestamp).toDate()
          : null, // ✨ NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "name": name,
      "email": email,
      "phone": phone,
      "school": school,
      "board": board,
      "grade": grade,
      "enrolledSubjects": enrolledSubjects,
      "createdAt": createdAt,
      "lastActive": lastActive,
      "xp": xp,
      "coins": coins,
      "dailyStreak": dailyStreak,
      "lastXpEarnedDate": lastXpEarnedDate,
      "isPremium": isPremium,
      "avatar": avatar,
      "deviceInfo": deviceInfo,
      "bio": bio,
      "studyGoal": studyGoal,
      "contributionsCount": contributionsCount,
      "studyBuddiesCount": studyBuddiesCount,
      "examDate": examDate != null ? Timestamp.fromDate(examDate!) : null,
      "mstDate": mstDate != null
          ? Timestamp.fromDate(mstDate!)
          : null, // ✨ NEW// ✨ NEW: Adding examDate to JSON
    };
  }

  StudentModel copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? phone,
    String? school,
    String? board,
    String? grade,
    List<String>? enrolledSubjects,
    Timestamp? createdAt,
    Timestamp? lastActive,
    int? xp,
    int? coins,
    int? dailyStreak,
    ValueGetter<Timestamp?>? lastXpEarnedDateOption,
    bool? isPremium,
    String? avatar,
    Map<String, dynamic>? deviceInfo,
    ValueGetter<String?>? bioOption,
    ValueGetter<String?>? studyGoalOption,
    int? contributionsCount,
    int? studyBuddiesCount,
    ValueGetter<DateTime?>? examDateOption,
    ValueGetter<DateTime?>? mstDateOption, // ✨ NEW
    // ✨ NEW: To allow setting examDate to null or new value
  }) {
    return StudentModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      school: school ?? this.school,
      board: board ?? this.board,
      grade: grade ?? this.grade,
      enrolledSubjects: enrolledSubjects ?? this.enrolledSubjects,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastXpEarnedDate: lastXpEarnedDateOption != null
          ? lastXpEarnedDateOption()
          : this.lastXpEarnedDate,
      isPremium: isPremium ?? this.isPremium,
      avatar: avatar ?? this.avatar,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      bio: bioOption != null ? bioOption() : this.bio,
      studyGoal: studyGoalOption != null ? studyGoalOption() : this.studyGoal,
      contributionsCount: contributionsCount ?? this.contributionsCount,
      studyBuddiesCount: studyBuddiesCount ?? this.studyBuddiesCount,
      examDate: examDateOption != null ? examDateOption() : this.examDate,
      mstDate: mstDateOption != null
          ? mstDateOption()
          : this.mstDate, // ✨ NEW: Handling examDate in copyWith
    );
  }

  @override
  String toString() {
    return 'StudentModel(id: $id, username: $username, name: $name, email: $email, phone: $phone, school: $school, board: $board, grade: $grade, enrolledSubjects: $enrolledSubjects, createdAt: $createdAt, lastActive: $lastActive, xp: $xp, coins: $coins, dailyStreak: $dailyStreak, lastXpEarnedDate: $lastXpEarnedDate, isPremium: $isPremium, avatar: $avatar, deviceInfo: $deviceInfo, bio: $bio, studyGoal: $studyGoal, contributionsCount: $contributionsCount, studyBuddiesCount: $studyBuddiesCount, examDate: $examDate)'; // ✨ NEW
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StudentModel &&
        other.id == id &&
        other.username == username &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.school == school &&
        other.board == board &&
        other.grade == grade &&
        listEquals(other.enrolledSubjects, enrolledSubjects) &&
        other.createdAt == createdAt &&
        other.lastActive == lastActive &&
        other.xp == xp &&
        other.coins == coins &&
        other.dailyStreak == dailyStreak &&
        other.lastXpEarnedDate == lastXpEarnedDate &&
        other.isPremium == isPremium &&
        other.avatar == avatar &&
        mapEquals(other.deviceInfo, deviceInfo) &&
        other.bio == bio &&
        other.studyGoal == studyGoal &&
        other.contributionsCount == contributionsCount &&
        other.studyBuddiesCount == studyBuddiesCount &&
        other.examDate == examDate && // ✨ NEW
        other.mstDate == mstDate; // ✨ NEW
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        school.hashCode ^
        board.hashCode ^
        grade.hashCode ^
        enrolledSubjects.hashCode ^ // Simplified for list
        createdAt.hashCode ^
        lastActive.hashCode ^
        xp.hashCode ^
        coins.hashCode ^
        dailyStreak.hashCode ^
        lastXpEarnedDate.hashCode ^
        isPremium.hashCode ^
        avatar.hashCode ^
        deviceInfo.hashCode ^ // Simplified for map
        bio.hashCode ^
        studyGoal.hashCode ^
        contributionsCount.hashCode ^
        studyBuddiesCount.hashCode ^
        examDate.hashCode ^ // ✨ NEW: Include examDate in hashCode
        mstDate.hashCode; // ✨ NEW
  }
}
