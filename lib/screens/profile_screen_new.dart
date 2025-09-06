import 'dart:io';

import 'package:bharat_ace/core/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import '../widgets/profile_menu_widget.dart';

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
        title: 'Math Champion',
        icon: Icons.calculate_rounded,
        color: AppTheme.primary,
        dateAchieved: DateTime.now().subtract(const Duration(days: 5))),
    ProfileAchievement(
        id: 'a2',
        title: 'Science Explorer',
        icon: Icons.science_rounded,
        color: AppTheme.secondary,
        dateAchieved: DateTime.now().subtract(const Duration(days: 12))),
    ProfileAchievement(
        id: 'a3',
        title: '7-Day Streak!',
        icon: Icons.local_fire_department_rounded,
        color: AppTheme.warning,
        dateAchieved: DateTime.now().subtract(const Duration(days: 2))),
    ProfileAchievement(
        id: 'a4',
        title: 'Perfect Score',
        icon: Icons.star_rounded,
        color: AppTheme.success,
        dateAchieved: DateTime.now().subtract(const Duration(days: 20))),
  ];
});

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _calculateLevel(int xp) {
    const int xpPerLevel = 1000;
    final int level = (xp / xpPerLevel).floor() + 1;
    final int xpForCurrentLevel = xp % xpPerLevel;
    final double progress = xpForCurrentLevel / xpPerLevel;

    return {
      'level': level,
      'xp': xp,
      'xpForCurrentLevel': xpForCurrentLevel,
      'progress': progress,
      'nextLevel': level + 1,
      'xpRequired': xpPerLevel,
    };
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(studentDetailsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: student.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                'Error loading profile',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              ElevatedButton(
                onPressed: () => ref.refresh(studentDetailsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (studentData) => _buildProfileContent(studentData),
      ),
    );
  }

  Widget _buildProfileContent(StudentModel? student) {
    if (student == null) {
      return const Center(
        child: Text('No student data available'),
      );
    }

    final levelData = _calculateLevel(student.xp);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(student, levelData),

          const SizedBox(height: AppTheme.spaceLG),

          // Menu Options including Leave Application
          const ProfileMenuWidget(),

          const SizedBox(height: AppTheme.spaceLG),

          // Quick Stats
          _buildQuickStats(student),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      StudentModel student, Map<String, dynamic> levelData) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          margin: const EdgeInsets.only(top: 16.0),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : AppTheme.cardShadow,
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : Colors.transparent,
              width: isDark ? 1 : 0,
            ),
          ),
          child: Column(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: _handleProfileImageUpdate,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: student.avatar.isNotEmpty
                      ? NetworkImage(student.avatar)
                      : null,
                  child: student.avatar.isEmpty
                      ? Text(
                          student.name.isNotEmpty
                              ? student.name[0].toUpperCase()
                              : 'S',
                          style: AppTheme.textTheme.headlineLarge?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: AppTheme.spaceMD),

              // Name & Username
              Builder(builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceXS),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBg.withOpacity(0.5)
                        : AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Text(
                    student.username,
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.gray600,
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                student.name,
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.gray900,
                ),
              ),

              const SizedBox(height: AppTheme.spaceMD),

              // Level Progress
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${levelData['level']}',
                        style: AppTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        '${levelData['xpForCurrentLevel']}/${levelData['xpRequired']} XP',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  LinearProgressIndicator(
                    value: levelData['progress'],
                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(StudentModel student) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : AppTheme.cardShadow,
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : Colors.transparent,
              width: isDark ? 1 : 0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Stats',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.gray900,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatCard(
                      icon: Icons.school,
                      label: 'Class',
                      value: student.grade,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: _buildQuickStatCard(
                      icon: Icons.business,
                      label: 'Board',
                      value: student.board,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatCard(
                      icon: Icons.location_on,
                      label: 'School',
                      value: student.school,
                      color: AppTheme.info,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: _buildQuickStatCard(
                      icon: Icons.monetization_on,
                      label: 'Coins',
                      value: '${student.coins}',
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            label,
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.gray600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            value,
            style: AppTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _handleProfileImageUpdate() async {
    HapticFeedback.mediumImpact();
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkCard
          : AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLG)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: AppTheme.gray300,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Update Profile Picture',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.gray900,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Camera Option
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    await _uploadProfileImage(File(image.path));
                  }
                },
                child: _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: AppTheme.primary,
                ),
              ),
              // Gallery Option
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    await _uploadProfileImage(File(image.path));
                  }
                },
                child: _buildImageSourceOption(
                  icon: Icons.photo,
                  label: 'Gallery',
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
        ],
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          label,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.gray800,
          ),
        ),
      ],
    );
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: AppTheme.spaceMD),
              Text("Updating profile picture..."),
            ],
          ),
        ),
      );

      // TODO: Implement actual image upload to Supabase/Firebase
      // For now, just simulate a delay
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture updated successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );

      // Refresh the profile data
      // ignore: unused_result
      ref.refresh(studentDetailsProvider);
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
