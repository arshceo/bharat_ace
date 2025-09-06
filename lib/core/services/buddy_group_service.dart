// lib/core/services/buddy_group_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/buddy_group_model.dart';

class BuddyGroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static String? get currentUserId => _auth.currentUser?.uid;

  // Get students from the same class
  static Future<List<Student>> getClassmates() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // First get current user's class info
      final userDoc =
          await _firestore.collection('students').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data()!;
      final classId = userData['classId'] as String?;
      final schoolId = userData['schoolId'] as String?;

      if (classId == null || schoolId == null) {
        throw Exception('Class or school information missing');
      }

      // Get all students from the same class
      final classmatesQuery = await _firestore
          .collection('students')
          .where('classId', isEqualTo: classId)
          .where('schoolId', isEqualTo: schoolId)
          .get();

      return classmatesQuery.docs
          .map((doc) => Student.fromJson({...doc.data(), 'id': doc.id}))
          .where((student) =>
              student.id != currentUser.uid) // Exclude current user
          .toList();
    } catch (e) {
      print('Error getting classmates: $e');
      return [];
    }
  }

  // Create a new buddy group
  static Future<String?> createBuddyGroup({
    required String groupName,
    required List<String> memberIds,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Include current user in the group
      final allMemberIds = [currentUser.uid, ...memberIds];

      final groupData = BuddyGroup(
        id: '', // Will be set by Firestore
        name: groupName,
        createdBy: currentUser.uid,
        memberIds: allMemberIds,
        createdAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection('buddy_groups').add(groupData.toJson());

      // Update the document with its ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      print('Error creating buddy group: $e');
      return null;
    }
  }

  // Get user's buddy groups
  static Future<List<BuddyGroup>> getUserBuddyGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final query = await _firestore
          .collection('buddy_groups')
          .where('memberIds', arrayContains: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => BuddyGroup.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting buddy groups: $e');
      return [];
    }
  }

  // Start a study session for a group
  static Future<bool> startGroupStudySession({
    required String groupId,
    required List<String> taskIds,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get group members
      final groupDoc =
          await _firestore.collection('buddy_groups').doc(groupId).get();

      if (!groupDoc.exists) return false;

      final group = BuddyGroup.fromJson({...groupDoc.data()!, 'id': groupId});

      // Create member readiness map (all false initially)
      final memberReadiness = <String, bool>{};
      for (String memberId in group.memberIds) {
        memberReadiness[memberId] = false;
      }

      final session = StudySession(
        id: '', // Will be set by Firestore
        groupId: groupId,
        tasks: taskIds,
        startTime: DateTime.now(),
        memberReadiness: memberReadiness,
        status: SessionStatus.waiting,
      );

      final sessionRef =
          await _firestore.collection('study_sessions').add(session.toJson());

      // Update session with its ID
      await sessionRef.update({'id': sessionRef.id});

      // Update group with current session
      await _firestore.collection('buddy_groups').doc(groupId).update({
        'currentSession': session.toJson(),
      });

      return true;
    } catch (e) {
      print('Error starting group study session: $e');
      return false;
    }
  }

  // Mark user as ready for study session
  static Future<bool> markUserReady(String sessionId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore.collection('study_sessions').doc(sessionId).update({
        'memberReadiness.${currentUser.uid}': true,
      });

      return true;
    } catch (e) {
      print('Error marking user ready: $e');
      return false;
    }
  }

  // Listen to study session updates
  static Stream<StudySession?> listenToStudySession(String sessionId) {
    return _firestore
        .collection('study_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return StudySession.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  // Get students by IDs (for displaying group members)
  static Future<List<Student>> getStudentsByIds(List<String> studentIds) async {
    try {
      if (studentIds.isEmpty) return [];

      final futures = studentIds
          .map((id) => _firestore.collection('students').doc(id).get());

      final docs = await Future.wait(futures);

      return docs
          .where((doc) => doc.exists)
          .map((doc) => Student.fromJson({...doc.data()!, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting students by IDs: $e');
      return [];
    }
  }

  // Apply for leave
  static Future<String?> applyForLeave({
    required String reason,
    required DateTime leaveDate,
    required LeaveType type,
    String? documentUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final application = LeaveApplication(
        id: '', // Will be set by Firestore
        studentId: currentUser.uid,
        reason: reason,
        leaveDate: leaveDate,
        type: type,
        documentUrl: documentUrl,
        appliedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('leave_applications')
          .add(application.toJson());

      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      print('Error applying for leave: $e');
      return null;
    }
  }

  // Get user's leave applications
  static Future<List<LeaveApplication>> getUserLeaveApplications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final query = await _firestore
          .collection('leave_applications')
          .where('studentId', isEqualTo: currentUser.uid)
          .get();

      final applications = query.docs
          .map(
              (doc) => LeaveApplication.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Sort locally to avoid Firebase index requirement
      applications.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

      return applications;
    } catch (e) {
      print('Error getting leave applications: $e');
      return [];
    }
  }

  // Check if leave can be applied for a specific date
  static bool canApplyLeave(DateTime leaveDate, LeaveType type) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(leaveDate.year, leaveDate.month, leaveDate.day);

    switch (type) {
      case LeaveType.preDL:
        // Pre-DL: Can apply anytime before the leave date, but not on the same day
        return targetDate.isAfter(today);

      case LeaveType.postDL:
        // Post-DL: Can apply 1-2 days after the leave date
        final daysSinceLeave = today.difference(targetDate).inDays;
        return daysSinceLeave >= 1 && daysSinceLeave <= 2;
    }
  }

  // Check if all group members are ready for study session
  static Future<bool> areAllMembersReady(String sessionId) async {
    try {
      final sessionDoc =
          await _firestore.collection('study_sessions').doc(sessionId).get();

      if (!sessionDoc.exists) return false;

      final session =
          StudySession.fromJson({...sessionDoc.data()!, 'id': sessionDoc.id});
      final readiness = session.memberReadiness;
      final members = session.memberReadiness.keys;

      // Check if all members have marked themselves as ready
      for (String memberId in members) {
        if (readiness[memberId] != true) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error checking member readiness: $e');
      return false;
    }
  }

  // Get current user's active buddy group
  static Future<BuddyGroup?> getCurrentUserGroup() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final query = await _firestore
          .collection('buddy_groups')
          .where('memberIds', arrayContains: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      return BuddyGroup.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      print('Error getting current user group: $e');
      return null;
    }
  }
}
