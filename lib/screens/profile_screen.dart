// import 'dart:io';

// import 'package:bharat_ace/core/theme/app_theme.dart';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';

// import 'package:bharat_ace/core/models/student_model.dart';
// import 'package:bharat_ace/core/providers/student_details_provider.dart';
// import '../widgets/profile_menu_widget.dart';

// // --- Local ProfileAchievement Model ---
// class ProfileAchievement {
//   final String id;
//   final String title;
//   final IconData icon;
//   final Color color;
//   final DateTime dateAchieved;

//   ProfileAchievement({
//     required this.id,
//     required this.title,
//     required this.icon,
//     required this.color,
//     required this.dateAchieved,
//   });
// }

// // --- userAchievementsProvider ---
// final userAchievementsProvider =
//     FutureProvider<List<ProfileAchievement>>((ref) async {
//   await Future.delayed(const Duration(milliseconds: 800));
//   return [
//     ProfileAchievement(
//         id: 'a1',
//         title: 'Math Champion',
//         icon: Icons.calculate_rounded,
//         color: AppTheme.primary,
//         dateAchieved: DateTime.now().subtract(const Duration(days: 5))),
//     ProfileAchievement(
//         id: 'a2',
//         title: 'Science Explorer',
//         icon: Icons.science_rounded,
//         color: AppTheme.secondary,
//         dateAchieved: DateTime.now().subtract(const Duration(days: 12))),
//     ProfileAchievement(
//         id: 'a3',
//         title: '7-Day Streak!',
//         icon: Icons.local_fire_department_rounded,
//         color: AppTheme.warning,
//         dateAchieved: DateTime.now().subtract(const Duration(days: 2))),
//     ProfileAchievement(
//         id: 'a4',
//         title: 'Perfect Score',
//         icon: Icons.star_rounded,
//         color: AppTheme.success,
//         dateAchieved: DateTime.now().subtract(const Duration(days: 20))),
//   ];
// });

// class ProfileScreen extends ConsumerStatefulWidget {
//   final String? userId;

//   const ProfileScreen({super.key, this.userId});

//   @override
//   ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends ConsumerState<ProfileScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Map<String, dynamic> _calculateLevel(int xp) {
//     const int baseXpPerLevel = 1000;
//     int level = (xp / baseXpPerLevel).floor() + 1;
//     int xpInCurrentLevel = xp % baseXpPerLevel;
//     double progressToNextLevel = xpInCurrentLevel / baseXpPerLevel;

//     return {
//       'level': level,
//       'progressToNextLevel': progressToNextLevel,
//       'xpInCurrentLevel': xpInCurrentLevel,
//       'xpForNextLevel': baseXpPerLevel - xpInCurrentLevel,
//     };
//   }

//   Future<void> _handleProfileImageUpdate() async {
//     HapticFeedback.mediumImpact();
//     final ImagePicker picker = ImagePicker();

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: AppTheme.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius:
//             BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(AppTheme.space2XL),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Drag handle
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: AppTheme.gray300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: AppTheme.spaceLG),
//             Text(
//               'Update Profile Picture',
//               style: AppTheme.textTheme.headlineSmall,
//             ),
//             const SizedBox(height: AppTheme.spaceMD),
//             Text(
//               'Choose how you\'d like to update your profile picture',
//               style: AppTheme.textTheme.bodyMedium,
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: AppTheme.space2XL),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildImageSourceOption(
//                     icon: Icons.camera_alt_rounded,
//                     label: 'Camera',
//                     onTap: () async {
//                       Navigator.pop(context);
//                       final XFile? image = await picker.pickImage(
//                         source: ImageSource.camera,
//                         imageQuality: 80,
//                       );
//                       if (image != null) {
//                         await _uploadProfileImage(File(image.path));
//                       }
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: AppTheme.spaceMD),
//                 Expanded(
//                   child: _buildImageSourceOption(
//                     icon: Icons.photo_library_rounded,
//                     label: 'Gallery',
//                     onTap: () async {
//                       Navigator.pop(context);
//                       final XFile? image = await picker.pickImage(
//                         source: ImageSource.gallery,
//                         imageQuality: 80,
//                       );
//                       if (image != null) {
//                         await _uploadProfileImage(File(image.path));
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: AppTheme.spaceMD),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImageSourceOption({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: AppTheme.gray50,
//       borderRadius: BorderRadius.circular(AppTheme.radiusLG),
//       child: InkWell(
//         onTap: () {
//           HapticFeedback.lightImpact();
//           onTap();
//         },
//         borderRadius: BorderRadius.circular(AppTheme.radiusLG),
//         child: Container(
//           padding: const EdgeInsets.all(AppTheme.spaceLG),
//           child: Column(
//             children: [
//               Icon(icon, size: 32, color: AppTheme.primary),
//               const SizedBox(height: AppTheme.spaceXS),
//               Text(
//                 label,
//                 style: AppTheme.textTheme.bodyMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _uploadProfileImage(File imageFile) async {
//     try {
//       // Show loading dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => AlertDialog(
//           backgroundColor: AppTheme.white,
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: AppTheme.spaceMD),
//               Text('Uploading profile picture...',
//                   style: AppTheme.textTheme.bodyMedium),
//             ],
//           ),
//         ),
//       );

//       // TODO: Implement actual image upload to Supabase/Firebase
//       // For now, just simulate a delay
//       await Future.delayed(const Duration(seconds: 2));

//       Navigator.of(context).pop(); // Close loading dialog

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Profile picture updated successfully!'),
//           backgroundColor: AppTheme.success,
//         ),
//       );

//       // Refresh the profile data
//       // ignore: unused_result
//       ref.refresh(studentDetailsProvider);
//     } catch (e) {
//       Navigator.of(context).pop(); // Close loading dialog

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to upload image: $e'),
//           backgroundColor: AppTheme.error,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final student = ref.watch(studentDetailsProvider);

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: student.when(
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, stack) => Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.error_outline, size: 64, color: AppTheme.error),
//               const SizedBox(height: AppTheme.spaceMD),
//               Text(
//                 'Error loading profile',
//                 style: AppTheme.textTheme.titleLarge?.copyWith(
//                   color: AppTheme.error,
//                 ),
//               ),
//               const SizedBox(height: AppTheme.spaceMD),
//               ElevatedButton(
//                 onPressed: () => ref.refresh(studentDetailsProvider),
//                 child: const Text('Retry'),
//               ),
//             ],
//           ),
//         ),
//         data: (studentData) => _buildProfileContent(studentData),
//       ),
//     );
//   }

//   Widget _buildProfileContent(StudentModel? student) {
//     if (student == null) {
//       return const Center(
//         child: Text('No student data available'),
//       );
//     }

//     final levelData = _calculateLevel(student.xp);

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(AppTheme.spaceLG),
//       child: Column(
//         children: [
//           // Profile Header
//           _buildProfileHeader(student, levelData),

//           const SizedBox(height: AppTheme.spaceLG),

//           // Menu Options including Leave Application
//           const ProfileMenuWidget(),

//           const SizedBox(height: AppTheme.spaceLG),

//           // Quick Stats
//           _buildQuickStats(student),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileHeader(
//       StudentModel student, Map<String, dynamic> levelData) {
//     return Builder(
//       builder: (context) {
//         final isDark = Theme.of(context).brightness == Brightness.dark;
//         return Container(
//           padding: const EdgeInsets.all(AppTheme.spaceLG),
//           margin: const EdgeInsets.only(top: 16.0),
//           decoration: BoxDecoration(
//             color: isDark ? AppTheme.darkCard : AppTheme.white,
//             borderRadius: BorderRadius.circular(AppTheme.radiusLG),
//             boxShadow: isDark
//               ? [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ]
//               : AppTheme.cardShadow,
//             border: Border.all(
//               color: isDark ? AppTheme.darkBorder : Colors.transparent,
//               width: isDark ? 1 : 0,
//             ),
//           ),
//           child: Column(
//         children: [
//           // Profile Picture
//           GestureDetector(
//             onTap: () async => await _handleProfileImageUpdate(),
//             child: CircleAvatar(
//               radius: 50,
//               backgroundColor: AppTheme.primary.withOpacity(0.1),
//               backgroundImage: student.avatar.isNotEmpty
//                   ? NetworkImage(student.avatar)
//                   : null,
//               child: student.avatar.isEmpty
//                   ? Icon(
//                       Icons.person,
//                       size: 50,
//                       color: AppTheme.primary,
//                     )
//                   : null,
//             ),
//           ),

//           const SizedBox(height: AppTheme.spaceMD),

//           // Name and Username
//           Builder(
//             builder: (context) {
//               final isDark = Theme.of(context).brightness == Brightness.dark;
//               return Text(
//                 student.name,
//                 style: AppTheme.textTheme.displaySmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? AppTheme.darkTextPrimary : AppTheme.gray900,
//                 ),
//                 textAlign: TextAlign.center,
//               );
//             }
//           ),

//           const SizedBox(height: AppTheme.spaceXS),

//           Builder(
//             builder: (context) {
//               final isDark = Theme.of(context).brightness == Brightness.dark;
//               return Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: AppTheme.spaceMD,
//                   vertical: AppTheme.spaceXS,
//                 ),
//                 decoration: BoxDecoration(
//                   color: isDark ? AppTheme.darkCard.withOpacity(0.6) : AppTheme.gray100,
//                   borderRadius: BorderRadius.circular(AppTheme.radiusSM),
//                   border: isDark ? Border.all(color: AppTheme.darkBorder, width: 1) : null,
//                 ),
//                 child: Text(
//                   '@${student.username}',
//                   style: AppTheme.textTheme.bodyMedium?.copyWith(
//                     color: isDark ? AppTheme.darkTextSecondary : AppTheme.gray600,
//                   ),
//                 ),
//               );
//             }
//           ),

//           const SizedBox(height: AppTheme.spaceLG),

//         // Level Progress
//         _buildLevelProgress(levelData),
//       ],
//     ),
//   );
// }

// Widget _buildLevelProgress(Map<String, dynamic> levelData) {
//   return Builder(
//     builder: (context) {
//       final isDark = Theme.of(context).brightness == Brightness.dark;
//       return Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Level ${levelData['level']}',
//                 style: AppTheme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? AppTheme.darkTextPrimary : AppTheme.gray900,
//                 ),
//               ),
//               Text(
//                 '${levelData['xpInCurrentLevel']} / 1000 XP',
//                 style: AppTheme.textTheme.bodyMedium?.copyWith(
//                   color: isDark ? AppTheme.darkTextSecondary : AppTheme.gray600,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: AppTheme.spaceXS),
//           LinearProgressIndicator(
//             value: levelData['progressToNextLevel'],
//             backgroundColor: isDark ? AppTheme.gray700 : AppTheme.gray200,
//             valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
//           ),
//         ],
//       );
//     },
//   );
// }

// Future<void> _handleProfileImageUpdate() async {
//     HapticFeedback.mediumImpact();
//     final ImagePicker picker = ImagePicker();

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: AppTheme.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius:
//             BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(AppTheme.space2XL),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Drag handle
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: AppTheme.gray300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: AppTheme.spaceLG),
//             Text(
//               'Update Profile Picture',
//               style: AppTheme.textTheme.headlineSmall,
//             ),
//             const SizedBox(height: AppTheme.spaceMD),
//             Text(
//               'Choose how you\'d like to update your profile picture',
//               style: AppTheme.textTheme.bodyMedium,
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: AppTheme.space2XL),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildImageSourceOption(
//                     icon: Icons.camera_alt_rounded,
//                     label: 'Camera',
//                     onTap: () async {
//                       Navigator.pop(context);
//                       final XFile? image = await picker.pickImage(
//                         source: ImageSource.camera,
//                         imageQuality: 80,
//                       );
//                       if (image != null) {
//                         await _uploadProfileImage(File(image.path));
//                       }
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: AppTheme.spaceMD),
//                 Expanded(
//                   child: _buildImageSourceOption(
//                     icon: Icons.photo_library_rounded,
//                     label: 'Gallery',
//                     onTap: () async {
//                       Navigator.pop(context);
//                       final XFile? image = await picker.pickImage(
//                         source: ImageSource.gallery,
//                         imageQuality: 80,
//                       );
//                       if (image != null) {
//                         await _uploadProfileImage(File(image.path));
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: AppTheme.spaceMD),
//           ],
//         ),
//       ),
//     );
//   },

//   Widget _buildImageSourceOption({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: AppTheme.gray50,
//       borderRadius: BorderRadius.circular(AppTheme.radiusLG),
//       child: InkWell(
//         onTap: () {
//           HapticFeedback.lightImpact();
//           onTap();
//         },
//         borderRadius: BorderRadius.circular(AppTheme.radiusLG),
//         child: Container(
//           padding: const EdgeInsets.all(AppTheme.spaceLG),
//           child: Column(
//             children: [
//               Icon(icon, size: 32, color: AppTheme.primary),
//               const SizedBox(height: AppTheme.spaceXS),
//               Text(
//                 label,
//                 style: AppTheme.textTheme.bodyMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _uploadProfileImage(File imageFile) async {
//     try {
//       // Show loading dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => AlertDialog(
//           backgroundColor: AppTheme.white,
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: AppTheme.spaceMD),
//               Text('Uploading profile picture...',
//                   style: AppTheme.textTheme.bodyMedium),
//             ],
//           ),
//         ),
//       );

//       // TODO: Implement actual image upload to Supabase/Firebase
//       // For now, just simulate a delay
//       await Future.delayed(const Duration(seconds: 2));

//       Navigator.of(context).pop(); // Close loading dialog

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Profile picture updated successfully!'),
//           backgroundColor: AppTheme.success,
//         ),
//       );

//       // Refresh the profile data
//       // ignore: unused_result
//       ref.refresh(studentDetailsProvider);
//     } catch (e) {
//       Navigator.of(context).pop(); // Close loading dialog

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to upload image: $e'),
//           backgroundColor: AppTheme.error,
//         ),
//       );
//     }
//   }

//   Widget _buildQuickStats(StudentModel student) {
//     return Builder(
//       builder: (context) {
//         final isDark = Theme.of(context).brightness == Brightness.dark;
//         return Container(
//           padding: const EdgeInsets.all(AppTheme.spaceLG),
//           decoration: BoxDecoration(
//             color: isDark ? AppTheme.darkCard : AppTheme.white,
//             borderRadius: BorderRadius.circular(AppTheme.radiusLG),
//             boxShadow: isDark
//                 ? [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ]
//                 : AppTheme.cardShadow,
//             border: Border.all(
//               color: isDark ? AppTheme.darkBorder : Colors.transparent,
//               width: isDark ? 1 : 0,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Quick Stats',
//                 style: AppTheme.textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? AppTheme.darkTextPrimary : AppTheme.gray900,
//                 ),
//               ),
//               const SizedBox(height: AppTheme.spaceMD),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildStatCard(
//                       title: 'XP',
//                       value: student.xp.toString(),
//                       icon: Icons.emoji_events,
//                       color: AppTheme.primary,
//                     ),
//                   ),
//                   const SizedBox(width: AppTheme.spaceMD),
//                   Expanded(
//                     child: _buildStatCard(
//                       title: 'Streak',
//                       value: '7', // Replace with actual streak data
//                       icon: Icons.local_fire_department,
//                       color: AppTheme.warning,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildStatCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Builder(
//       builder: (context) {
//         final isDark = Theme.of(context).brightness == Brightness.dark;
//         return Container(
//           padding: const EdgeInsets.all(AppTheme.spaceMD),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(AppTheme.radiusMD),
//             border: isDark ? Border.all(color: color.withOpacity(0.3), width: 1) : null,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Icon(icon, color: color, size: 24),
//               const SizedBox(height: AppTheme.spaceXS),
//               Text(
//                 value,
//                 style: AppTheme.textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? AppTheme.darkTextPrimary : AppTheme.gray900,
//                 ),
//               ),
//               Text(
//                 title,
//                 style: AppTheme.textTheme.bodySmall?.copyWith(
//                   color: isDark ? AppTheme.darkTextSecondary : AppTheme.gray600,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
