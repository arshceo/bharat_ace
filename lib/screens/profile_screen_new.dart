import 'dart:io';

import 'package:bharat_ace/core/providers/user_profile_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';

// --- Local ProfileAchievement Model ---
class ProfileAchievement {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final DateTime dateAchieved;

  ProfileAchievement({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.dateAchieved,
  });
}

// --- userAchievementsProvider ---
final userAchievementsProvider =
    FutureProvider<List<ProfileAchievement>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return [
    ProfileAchievement(
        id: 'a1',
        title: 'Math Whiz',
        icon: Icons.calculate_rounded,
        color: ProfileScreen.accentCyan,
        dateAchieved: DateTime.now().subtract(const Duration(days: 5))),
    ProfileAchievement(
        id: 'a2',
        title: 'Science Explorer',
        icon: Icons.science_rounded,
        color: ProfileScreen.accentPink,
        dateAchieved: DateTime.now().subtract(const Duration(days: 12))),
    ProfileAchievement(
        id: 'a3',
        title: '7-Day Streak!',
        icon: Icons.local_fire_department_rounded,
        color: Colors.orangeAccent,
        dateAchieved: DateTime.now().subtract(const Duration(days: 2))),
    ProfileAchievement(
        id: 'a4',
        title: 'Perfect Score: Quiz 1',
        icon: Icons.star_rounded,
        color: ProfileScreen.goldStar,
        dateAchieved: DateTime.now().subtract(const Duration(days: 20))),
  ];
});

class ProfileScreen extends ConsumerStatefulWidget {
  final String?
      userId; // Optional userId parameter to view other users' profiles

  const ProfileScreen({super.key, this.userId});

  static const Color darkBg = Color(0xFF12121F);
  static const Color primaryPurple = Color(0xFF7E57C2);
  static const Color accentCyan = Color(0xFF29B6F6);
  static const Color accentPink = Color(0xFFEC407A);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color surfaceLight = Color(0xFF2A2A3A);
  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color goldStar = Color(0xFFFFD700);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // Reduced from 3 tabs to 2
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _calculateLevel(int xp) {
    const int baseXpPerLevel = 1000;
    int level = (xp / baseXpPerLevel).floor() + 1;
    int xpInCurrentLevel = xp % baseXpPerLevel;
    double progressToNextLevel = xpInCurrentLevel / baseXpPerLevel;

    return {
      'level': level,
      'progressToNextLevel': progressToNextLevel,
      'xpInCurrentLevel': xpInCurrentLevel,
      'xpForNextLevel': baseXpPerLevel - xpInCurrentLevel,
    };
  }

  Future<void> _handleProfileImageUpdate() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: ProfileScreen.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update Profile Picture',
              style: TextStyle(
                color: ProfileScreen.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      await _uploadProfileImage(File(image.path));
                    }
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      await _uploadProfileImage(File(image.path));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ProfileScreen.surfaceLight,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: ProfileScreen.accentCyan.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: ProfileScreen.accentCyan, size: 40),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: ProfileScreen.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: ProfileScreen.surfaceDark,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ProfileScreen.accentCyan),
              const SizedBox(height: 16),
              Text(
                'Uploading profile image...',
                style: TextStyle(color: ProfileScreen.textPrimary),
              ),
            ],
          ),
        ),
      );

      // Upload image using the provider
      await ref.read(profileImageUploadProvider(imageFile).future);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile image updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileScreen.darkBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildProfileHeader(),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAchievementsTab(),
                  _buildStatsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final student = ref.watch(studentDetailsProvider);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ProfileScreen.primaryPurple.withOpacity(0.8),
              ProfileScreen.accentCyan.withOpacity(0.6),
            ],
          ),
        ),
        child: student.when(
          data: (studentData) => _buildProfileContent(studentData),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading profile',
              style: TextStyle(color: ProfileScreen.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(Student student) {
    final levelData = _calculateLevel(student.xp);

    return Column(
      children: [
        // Profile Picture with edit button
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: ProfileScreen.surfaceLight,
                backgroundImage: student.profileImageUrl != null
                    ? NetworkImage(student.profileImageUrl!)
                    : null,
                child: student.profileImageUrl == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: ProfileScreen.textSecondary,
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _handleProfileImageUpdate,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ProfileScreen.accentCyan,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Name and Username
        Text(
          student.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '@${student.username}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),

        // Level Progress
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${levelData['level']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${student.xp} XP',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              CircularPercentIndicator(
                radius: 40.0,
                lineWidth: 8.0,
                percent: levelData['progressToNextLevel'],
                center: Text(
                  '${(levelData['progressToNextLevel'] * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                progressColor: ProfileScreen.goldStar,
                backgroundColor: Colors.white.withOpacity(0.2),
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(height: 10),
              Text(
                '${levelData['xpForNextLevel']} XP to next level',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: ProfileScreen.surfaceDark,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: ProfileScreen.accentCyan,
          borderRadius: BorderRadius.circular(25),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: ProfileScreen.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Achievements'),
          Tab(text: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final achievements = ref.watch(userAchievementsProvider);

    return achievements.when(
      data: (achievementList) => achievementList.isEmpty
          ? _buildEmptyState('No achievements yet', Icons.emoji_events)
          : Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: achievementList.length,
                itemBuilder: (context, index) {
                  final achievement = achievementList[index];
                  return _buildAchievementCard(achievement);
                },
              ),
            ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: ProfileScreen.accentCyan),
      ),
      error: (error, stack) => _buildEmptyState(
        'Error loading achievements',
        Icons.error_outline,
      ),
    );
  }

  Widget _buildAchievementCard(ProfileAchievement achievement) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              achievement.color.withOpacity(0.8),
              achievement.color.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: achievement.color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              achievement.icon,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(achievement.dateAchieved),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final student = ref.watch(studentDetailsProvider);

    return student.when(
      data: (studentData) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatCard(
              'Total XP',
              '${studentData.xp}',
              Icons.star,
              ProfileScreen.goldStar,
            ),
            const SizedBox(height: 15),
            _buildStatCard(
              'Current Level',
              '${_calculateLevel(studentData.xp)['level']}',
              Icons.trending_up,
              ProfileScreen.accentCyan,
            ),
            const SizedBox(height: 15),
            _buildStatCard(
              'Study Streak',
              '7 days', // This could be dynamic based on your data
              Icons.local_fire_department,
              Colors.orangeAccent,
            ),
            const SizedBox(height: 15),
            _buildStatCard(
              'Subjects',
              '${studentData.selectedSubjects?.length ?? 0}',
              Icons.book,
              ProfileScreen.accentPink,
            ),
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: ProfileScreen.accentCyan),
      ),
      error: (error, stack) => _buildEmptyState(
        'Error loading stats',
        Icons.error_outline,
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ProfileScreen.surfaceLight,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: ProfileScreen.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: TextStyle(
                      color: ProfileScreen.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: ProfileScreen.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: ProfileScreen.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
