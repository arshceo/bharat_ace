import 'package:cloud_firestore/cloud_firestore.dart';

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
  final bool isPremium;
  final String avatar;
  final Map<String, dynamic> deviceInfo;

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
    required this.isPremium,
    required this.avatar,
    required this.deviceInfo,
  });

  /// ✅ Convert Firestore document to StudentModel
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json["id"],
      username: json["username"],
      name: json["name"],
      email: json["email"],
      phone: json["phone"],
      school: json["school"],
      board: json["board"],
      grade: json["grade"] ?? "6",
      enrolledSubjects: List<String>.from(json["enrolledSubjects"] ?? []),
      createdAt: json["createdAt"] ?? Timestamp.now(),
      lastActive: json["lastActive"] ?? Timestamp.now(),
      xp: json["xp"] ?? 0,
      isPremium: json["isPremium"] ?? false,
      avatar: json["avatar"] ?? "",
      deviceInfo: json["deviceInfo"] ?? {},
    );
  }

  /// ✅ Convert StudentModel to JSON (for saving to Firestore)
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
      "isPremium": isPremium,
      "avatar": avatar,
      "deviceInfo": deviceInfo,
    };
  }

  /// ✅ Update specific fields in StudentModel
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
    bool? isPremium,
    String? avatar,
    Map<String, dynamic>? deviceInfo,
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
      isPremium: isPremium ?? this.isPremium,
      avatar: avatar ?? this.avatar,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}
