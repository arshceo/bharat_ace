import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharat_ace/core/models/student_model.dart';

// Provider for fetching any user's profile by ID
class UserProfileNotifier extends StateNotifier<AsyncValue<StudentModel?>> {
  UserProfileNotifier(this.userId) : super(const AsyncValue.loading()) {
    _fetchUserProfile();
  }

  final String userId;
  final supabaseClient = Supabase.instance.client;

  Future<void> _fetchUserProfile() async {
    try {
      final response = await supabaseClient
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      final student = StudentModel.fromJson({
        'id': response['id'],
        'username': response['username'] ?? 'Unknown',
        'name': response['name'] ?? 'Unknown User',
        'email': response['email'] ?? '',
        'phone': response['phone'] ?? '',
        'school': response['school'] ?? '',
        'board': response['board'] ?? '',
        'grade': response['grade'] ?? '',
        'enrolledSubjects': response['enrolled_subjects'] ?? [],
        'createdAt': Timestamp.fromDate(DateTime.parse(
            response['created_at'] ?? DateTime.now().toIso8601String())),
        'lastActive': Timestamp.fromDate(DateTime.parse(
            response['last_active'] ?? DateTime.now().toIso8601String())),
        'xp': response['xp'] ?? 0,
        'coins': response['coins'] ?? 0,
        'dailyStreak': response['daily_streak'] ?? 0,
        'isPremium': response['is_premium'] ?? false,
        'avatar': response['avatar'] ?? '',
        'deviceInfo': {},
        'contributionsCount': response['contributions_count'] ?? 0,
        'studyBuddiesCount': response['study_buddies_count'] ?? 0,
        'lastXpEarnedDate': null,
      });

      state = AsyncValue.data(student);
    } catch (e) {
      print('Error fetching user profile: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _fetchUserProfile();
  }
}

// Provider factory for user profiles
final userProfileProvider = StateNotifierProvider.family<UserProfileNotifier,
    AsyncValue<StudentModel?>, String>((ref, userId) {
  return UserProfileNotifier(userId);
});

// Provider for user's creations by user ID
final userCreationsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return Stream.fromFuture(Future.delayed(const Duration(milliseconds: 500)))
      .asyncExpand((_) async* {
    try {
      final supabaseClient = Supabase.instance.client;
      final response = await supabaseClient
          .from('user_creations')
          .select('*')
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      yield response;
    } catch (e) {
      print('Error fetching user creations: $e');
      yield <Map<String, dynamic>>[];
    }
  });
});
