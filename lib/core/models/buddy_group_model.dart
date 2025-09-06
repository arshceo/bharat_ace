// lib/core/models/buddy_group_model.dart
class Student {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String classId;
  final String schoolId;
  final bool isOnline;
  final DateTime? lastSeen;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.classId,
    required this.schoolId,
    this.isOnline = false,
    this.lastSeen,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      classId: json['classId'] ?? '',
      schoolId: json['schoolId'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastSeen:
          json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'classId': classId,
      'schoolId': schoolId,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
}

class BuddyGroup {
  final String id;
  final String name;
  final String createdBy;
  final List<String> memberIds;
  final DateTime createdAt;
  final bool isActive;
  final StudySession? currentSession;

  BuddyGroup({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.memberIds,
    required this.createdAt,
    this.isActive = true,
    this.currentSession,
  });

  factory BuddyGroup.fromJson(Map<String, dynamic> json) {
    return BuddyGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdBy: json['createdBy'] ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      currentSession: json['currentSession'] != null
          ? StudySession.fromJson(json['currentSession'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'currentSession': currentSession?.toJson(),
    };
  }
}

class StudySession {
  final String id;
  final String groupId;
  final List<String> tasks;
  final DateTime startTime;
  final Map<String, bool> memberReadiness; // member_id -> ready status
  final SessionStatus status;

  StudySession({
    required this.id,
    required this.groupId,
    required this.tasks,
    required this.startTime,
    required this.memberReadiness,
    required this.status,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      tasks: List<String>.from(json['tasks'] ?? []),
      startTime:
          DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      memberReadiness: Map<String, bool>.from(json['memberReadiness'] ?? {}),
      status: SessionStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => SessionStatus.waiting,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'tasks': tasks,
      'startTime': startTime.toIso8601String(),
      'memberReadiness': memberReadiness,
      'status': status.name,
    };
  }

  bool get allMembersReady => memberReadiness.values.every((ready) => ready);
}

enum SessionStatus {
  waiting,
  ready,
  active,
  completed,
  cancelled,
}

class LeaveApplication {
  final String id;
  final String studentId;
  final String reason;
  final DateTime leaveDate;
  final LeaveType type;
  final String? documentUrl;
  final DateTime appliedAt;
  final LeaveStatus status;
  final String? teacherComment;
  final DateTime? reviewedAt;

  LeaveApplication({
    required this.id,
    required this.studentId,
    required this.reason,
    required this.leaveDate,
    required this.type,
    this.documentUrl,
    required this.appliedAt,
    this.status = LeaveStatus.pending,
    this.teacherComment,
    this.reviewedAt,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      reason: json['reason'] ?? '',
      leaveDate:
          DateTime.parse(json['leaveDate'] ?? DateTime.now().toIso8601String()),
      type: LeaveType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => LeaveType.preDL,
      ),
      documentUrl: json['documentUrl'],
      appliedAt:
          DateTime.parse(json['appliedAt'] ?? DateTime.now().toIso8601String()),
      status: LeaveStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => LeaveStatus.pending,
      ),
      teacherComment: json['teacherComment'],
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'reason': reason,
      'leaveDate': leaveDate.toIso8601String(),
      'type': type.name,
      'documentUrl': documentUrl,
      'appliedAt': appliedAt.toIso8601String(),
      'status': status.name,
      'teacherComment': teacherComment,
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }
}

enum LeaveType {
  preDL, // Pre-leave application
  postDL, // Post-leave application
}

enum LeaveStatus {
  pending,
  approved,
  rejected,
}
