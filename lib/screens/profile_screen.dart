import 'dart:io'; // Make sure this is imported

// Updated imports for models and enums
import 'package:bharat_ace/core/models/content_type_enum.dart';
import 'package:bharat_ace/core/models/profile_content_item_model.dart';
import 'package:bharat_ace/screens/upload_creation_screen.dart'; // For navigation
// Import for UploadCreationScreen to invalidate provider (already in upload_creation_screen.dart)
// No need for alias here if UploadCreationScreen is the only thing used from this file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';

// --- Local ProfileAchievement Model (remains as it's specific to profile screen and not part of content upload) ---
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

// --- End of Local ProfileAchievement Model ---
// --- Updated userCreationsProvider ---
final userCreationsProvider =
    StreamProvider.autoDispose<List<ProfileContentItem>>((ref) {
  final studentAsyncValue = ref.watch(studentDetailsProvider);
  final student = studentAsyncValue.valueOrNull;

  if (student == null) {
    return Stream.value([]);
  }

  final firestore = FirebaseFirestore.instance;
  final query = firestore
      .collection('userCreations')
      .where('userId', isEqualTo: student.id)
      .orderBy('timestamp', descending: true); // THIS IS THE QUERY

  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      // Use the new ProfileContentItem.fromFirestore factory
      return ProfileContentItem.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  });
});

// --- userAchievementsProvider (remains as is, uses local ProfileAchievement) ---
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

// --- Updated userBookmarksProvider (uses new ProfileContentItem and ContentType) ---
final userBookmarksProvider =
    FutureProvider.autoDispose<List<ProfileContentItem>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 1000));
  final student = ref.watch(studentDetailsProvider).valueOrNull;
  final String currentUserId = student?.id ?? 'dummyUser';

  return [
    ProfileContentItem(
        id: 'b1',
        thumbnailUrl: 'https://picsum.photos/seed/bookmark1/200/300',
        downloadUrl: 'https://picsum.photos/seed/bookmark1/600/900',
        title: 'Saved Geometry Video',
        type: ContentType.video,
        userId: currentUserId,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        views: 120,
        likes: 15),
    ProfileContentItem(
        id: 'b2',
        thumbnailUrl: 'https://picsum.photos/seed/bookmark2/200/300',
        downloadUrl: 'https://picsum.photos/seed/bookmark2/600/900',
        title: 'Important History Article',
        type: ContentType.image,
        userId: currentUserId,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        views: 250,
        likes: 30),
  ];
});
// ---------------------------------------------------

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _calculateLevel(int xp) {
    int currentLevel = 1;
    double levelProgress = 0.0;
    const int xpPerLevelBase = 500;
    const double levelMultiplier = 1.2;
    int xpForNextLevel = xpPerLevelBase;
    int cumulativeXp = 0;
    while (xp >= cumulativeXp + xpForNextLevel) {
      cumulativeXp += xpForNextLevel;
      currentLevel++;
      xpForNextLevel =
          (xpPerLevelBase * (currentLevel - 1) * levelMultiplier).toInt() +
              xpPerLevelBase;
    }
    int xpInCurrentLevel = xp - cumulativeXp;
    int totalXpNeededForThisLevel = xpForNextLevel;
    levelProgress = (totalXpNeededForThisLevel > 0)
        ? (xpInCurrentLevel / totalXpNeededForThisLevel).clamp(0.0, 1.0)
        : 1.0;
    return {'level': currentLevel, 'progress': levelProgress};
  }

  // --- Updated _pickAndUpload method to match UploadCreationScreen constructor ---
  Future<void> _pickAndUpload(ContentType type) async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile;

    try {
      if (type == ContentType.image) {
        pickedFile = await picker.pickImage(
            source: ImageSource.gallery, imageQuality: 70);
      } else if (type == ContentType.video) {
        pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      }

      if (pickedFile != null) {
        File fileToUpload =
            File(pickedFile.path); // Create File object from XFile path

        // NAVIGATE to UploadCreationScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UploadCreationScreen(
              pickedFile: pickedFile!, // Pass XFile
              type: type, // Pass ContentType
              file: fileToUpload, // Pass the created File object
            ),
          ),
        );
      } else {
        print('No file selected.');
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentDetailsProvider);
    final TextTheme textTheme = Theme.of(context).textTheme.apply(
          bodyColor: ProfileScreen.textPrimary,
          displayColor: ProfileScreen.textPrimary,
        );

    return Scaffold(
      backgroundColor: ProfileScreen.darkBg,
      appBar: AppBar(
        backgroundColor: ProfileScreen.surfaceDark,
        elevation: 1,
        centerTitle: true,
        title: studentAsync.when(
          data: (student) => Text(
            student?.username ?? student?.name.split(' ').first ?? 'Profile',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          loading: () => const SizedBox.shrink(),
          error: (e, s) => Text('Profile',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28),
            tooltip: "Menu / Settings",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Navigate to Settings Screen")));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return const Center(child: Text("Student data not found."));
          }
          final levelData = _calculateLevel(student.xp);
          final int currentLevel = levelData['level'];
          final double levelProgress = levelData['progress'];

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildProfileHeader(context, student, currentLevel,
                              levelProgress, textTheme)
                          .animate()
                          .fadeIn(duration: 300.ms),
                      _buildActionButtons(context, textTheme)
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 300.ms),
                      _buildKeyAchievementsSection(context, textTheme)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 300.ms),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: ProfileScreen.accentCyan,
                  labelColor: ProfileScreen.accentCyan,
                  unselectedLabelColor: ProfileScreen.textSecondary,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on_rounded), text: "Creations"),
                    Tab(icon: Icon(Icons.insights_rounded), text: "Progress"),
                    Tab(
                        icon: Icon(Icons.bookmark_border_rounded),
                        text: "Bookmarks"),
                  ],
                ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCreationsTab(context, ref)
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms),
                      _buildProgressTab(context, ref, student, textTheme)
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms),
                      _buildBookmarksTab(context, ref)
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
            child:
                CircularProgressIndicator(color: ProfileScreen.primaryPurple)),
        error: (e, s) =>
            Center(child: Text("Error loading profile: ${e.toString()}")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: ProfileScreen.surfaceDark,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "Create New",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: ProfileScreen.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.image_outlined,
                          color: ProfileScreen.accentCyan),
                      title: const Text('Upload Image',
                          style: TextStyle(color: ProfileScreen.textPrimary)),
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUpload(ContentType.image);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.video_collection_outlined,
                          color: ProfileScreen.accentPink),
                      title: const Text('Upload Video',
                          style: TextStyle(color: ProfileScreen.textPrimary)),
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUpload(ContentType.video);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
        backgroundColor: ProfileScreen.accentPink,
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        label: const Text("Create",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      )
          .animate()
          .scale(delay: 600.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }

  ImageProvider? _getAvatarImageProvider(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return NetworkImage(avatarPath);
    } else if (avatarPath.startsWith('assets/')) {
      // Or any other prefix you use for local assets
      return AssetImage(avatarPath);
    }
    // If it's just a file name like 'female_avatar.png' and you store them in 'assets/avatars/'
    // you might do: return AssetImage('assets/avatars/$avatarPath');
    // However, it's better if student.avatar stores the full asset path like 'assets/avatars/female_avatar.png'
    print(
        "Warning: Avatar path '$avatarPath' is not a recognized network or asset path.");
    return null; // Fallback or handle as an error
  }

  Widget _buildProfileHeader(BuildContext context, StudentModel student,
      int currentLevel, double levelProgress, TextTheme textTheme) {
    final ImageProvider? avatarImage =
        _getAvatarImageProvider(student.avatar); // Use the helper

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularPercentIndicator(
                  radius: 45.0,
                  lineWidth: 5.0,
                  percent: levelProgress,
                  animation: true,
                  center: CircleAvatar(
                    radius: 38,
                    backgroundColor:
                        ProfileScreen.primaryPurple.withOpacity(0.8),
                    backgroundImage: avatarImage, // USE THE DETERMINED PROVIDER
                    child: avatarImage ==
                            null // Show text fallback only if no image
                        ? Text(
                            student.name.isNotEmpty
                                ? student.name[0].toUpperCase()
                                : "🌟",
                            style: const TextStyle(
                                fontSize: 38,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )
                        : null, // No child if backgroundImage is set
                  ),
                  progressColor: ProfileScreen.accentCyan,
                  backgroundColor: ProfileScreen.surfaceLight.withOpacity(0.6),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCounter("Creations", student.contributionsCount,
                        textTheme), // Removed ?? 0 as student.contributionsCount is not nullable
                    _buildStatCounter("Buddies", student.studyBuddiesCount,
                        textTheme), // Same here
                    _buildStatCounter("XP", student.xp, textTheme),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(student.name,
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (student.bio != null && student.bio!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(student.bio!,
                style: textTheme.bodyMedium
                    ?.copyWith(color: ProfileScreen.textSecondary)),
          ],
          if (student.studyGoal != null && student.studyGoal!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text("🎯 Goal: ${student.studyGoal!}",
                style: textTheme.bodyMedium?.copyWith(
                    color: ProfileScreen.accentCyan,
                    fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 4),
          Text("Level $currentLevel  |  🔥 ${student.dailyStreak} Day Streak",
              style: textTheme.bodyMedium?.copyWith(
                  color: ProfileScreen.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatCounter(String label, int count, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            count
                .toString(), // Assuming count is non-nullable based on provided StudentModel
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: textTheme.bodySmall
                ?.copyWith(color: ProfileScreen.textSecondary)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Navigate to Edit Profile Screen")));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ProfileScreen.textPrimary,
                side: const BorderSide(color: ProfileScreen.surfaceLight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Edit Profile"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Share Profile Action")));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ProfileScreen.textPrimary,
                side: const BorderSide(color: ProfileScreen.surfaceLight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Share Profile"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyAchievementsSection(
      BuildContext context, TextTheme textTheme) {
    final achievementsAsync = ref.watch(userAchievementsProvider);

    return achievementsAsync.when(
      data: (achievements) {
        if (achievements.isEmpty) return const SizedBox.shrink();
        final pinnedAchievements = achievements.take(5).toList();

        return Container(
          height: 141,
          padding: const EdgeInsets.only(top: 12, left: 16, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Key Achievements",
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pinnedAchievements.length,
                  itemBuilder: (context, index) {
                    final achievement = pinnedAchievements[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: 12.0,
                      ),
                      child: FadeInLeft(
                        delay: (index * 100).ms,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  achievement.color.withOpacity(0.2),
                              child: Icon(achievement.icon,
                                  color: achievement.color, size: 24),
                            ),
                            const SizedBox(height: 1),
                            SizedBox(
                              width: 60,
                              child: Text(
                                achievement.title,
                                style: textTheme.labelSmall?.copyWith(
                                    color: ProfileScreen.textSecondary),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: ProfileScreen.primaryPurple))),
      ),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildCreationsTab(BuildContext context, WidgetRef ref) {
    final creationsAsync = ref.watch(userCreationsProvider);

    return creationsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload_outlined,
                    size: 60, color: ProfileScreen.textSecondary),
                const SizedBox(height: 16),
                const Text("No creations yet.",
                    style: TextStyle(
                        color: ProfileScreen.textSecondary, fontSize: 16)),
                const SizedBox(height: 8),
                const Text("Tap '+' to share your first study material!",
                    style: TextStyle(color: ProfileScreen.textSecondary)),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1 / 1.2,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            IconData typeIcon;
            switch (item.type) {
              case ContentType.image:
                typeIcon = Icons.image_outlined;
                break;
              case ContentType.video:
                typeIcon = Icons.movie_creation_rounded;
                break;
            }
            return Card(
              color: ProfileScreen.surfaceLight,
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("View ${item.title}")));
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: item.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              item.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image_rounded,
                                      size: 40,
                                      color: ProfileScreen.textSecondary),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                    child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                        color: ProfileScreen.accentCyan));
                              },
                            )
                          : const Icon(Icons.image_not_supported_rounded,
                              size: 40, color: ProfileScreen.textSecondary),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(typeIcon, color: Colors.white, size: 16),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        color: Colors.black.withOpacity(0.6),
                        child: Text(
                          item.title,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: ProfileScreen.primaryPurple)),
      error: (e, s) =>
          Center(child: Text("Error loading creations: ${e.toString()}")),
    );
  }

  Widget _buildProgressTab(BuildContext context, WidgetRef ref,
      StudentModel student, TextTheme textTheme) {
    final achievementsAsync = ref.watch(userAchievementsProvider);

    final weeklyXP = [120.0, 180.0, 150.0, 220.0, 190.0, 250.0, 170.0];
    final subjectMastery = {'Physics': 0.75, 'Math': 0.60, 'Chemistry': 0.85};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Recent Achievements",
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          achievementsAsync.when(
            data: (achievements) {
              if (achievements.isEmpty) {
                return const Text("No achievements yet. Keep learning!",
                    style: TextStyle(color: ProfileScreen.textSecondary));
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final ach = achievements[index];
                  return Card(
                    color: ProfileScreen.surfaceLight,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: ach.color.withOpacity(0.2),
                          child: Icon(ach.icon, color: ach.color)),
                      title: Text(ach.title,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          "Achieved: ${ach.dateAchieved.day}/${ach.dateAchieved.month}/${ach.dateAchieved.year}",
                          style: textTheme.labelSmall
                              ?.copyWith(color: ProfileScreen.textSecondary)),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: ProfileScreen.primaryPurple)),
            error: (e, s) => Text("Could not load achievements.",
                style: TextStyle(color: Colors.red.shade300)),
          ),
          const SizedBox(height: 24),
          Text("Weekly XP Gain",
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 150,
            decoration: BoxDecoration(
                color: ProfileScreen.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ProfileScreen.surfaceDark)),
            child: const Center(
                child: Text("XP Chart (e.g., using 'fl_chart')",
                    style: TextStyle(color: ProfileScreen.textSecondary))),
          ),
          const SizedBox(height: 24),
          Text("Subject Mastery",
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...subjectMastery.entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: textTheme.titleSmall),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: entry.value,
                          backgroundColor: ProfileScreen.surfaceDark,
                          color: ProfileScreen.accentCyan,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(userBookmarksProvider);
    return bookmarksAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bookmark_add_outlined,
                    size: 60, color: ProfileScreen.textSecondary),
                const SizedBox(height: 16),
                const Text("No bookmarks yet.",
                    style: TextStyle(
                        color: ProfileScreen.textSecondary, fontSize: 16)),
                const SizedBox(height: 8),
                const Text("Save important content for later!",
                    style: TextStyle(color: ProfileScreen.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            IconData typeIcon;
            switch (item.type) {
              case ContentType.image:
                typeIcon = Icons.description_rounded;
                break;
              case ContentType.video:
                typeIcon = Icons.videocam_rounded;
                break;
            }
            return Card(
              color: ProfileScreen.surfaceLight,
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: SizedBox(
                  width: 60,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            item.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Icon(typeIcon,
                                color: ProfileScreen.textSecondary),
                          )
                        : Icon(typeIcon, color: ProfileScreen.textSecondary),
                  ),
                ),
                title: Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(item.type.name.toString(),
                    style: const TextStyle(
                        color: ProfileScreen.textSecondary, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new_rounded,
                      color: ProfileScreen.accentCyan),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Open bookmarked ${item.title}")));
                  },
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Open bookmarked ${item.title}")));
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: ProfileScreen.primaryPurple)),
      error: (e, s) =>
          Center(child: Text("Error loading bookmarks: ${e.toString()}")),
    );
  }
}
