import 'package:bharat_ace/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Keep for potential date formatting later
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For 'ms' extension
import 'package:animate_do/animate_do.dart'; // For animations

// --- Import ACTUAL providers and models --- (Ensure paths are correct)
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/providers/study_plan_provider.dart'; // Real daily task provider
import 'package:bharat_ace/core/models/study_task_model.dart'; // Real task model

// --- Import Navigation Targets --- (Ensure path is correct)
import 'package:bharat_ace/screens/smaterial/chapter_landing_screen.dart';

// --- Listener Provider (Should be defined elsewhere, e.g., student_details_provider.dart) ---
// Ensure this provider is defined and imported correctly
final studentDetailsFetcher = Provider<void>((ref) {
  print("ℹ️ Initializing studentDetailsFetcher listener.");
  ref.listen<AsyncValue<User?>>(authStateProvider,
      (previousAuthState, currentAuthState) {
    final notifier = ref.read(studentDetailsProvider.notifier);
    final User? currentUser = currentAuthState.valueOrNull;
    if (currentUser != null) {
      final StudentModel? currentStudentData = ref.read(studentDetailsProvider);
      if (currentStudentData == null ||
          currentStudentData.id != currentUser.uid) {
        notifier.fetchStudentDetails();
      }
    } else {
      notifier.clearStudentDetails();
    }
  });
}, name: 'studentDetailsFetcher');
// ----------------------------------------

// --- Main Home Screen Widget ---
class HomeScreen2 extends ConsumerWidget {
  const HomeScreen2({super.key});

  // --- Colors (Example - Move to AppTheme) ---
  static const Color darkBg = Color(0xFF12121F);
  static const Color primaryPurple = Color(0xFF8A2BE2);
  static const Color accentCyan = Color(0xFF00FFFF);
  static const Color accentPink = Color(0xFFFF00FF);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color surfaceLight = Color(0xFF2A2A3A);
  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFFAAAAAA);
  // -------------------------------------------

  // --- Helper Method: Icon Mapping ---
  IconData _getIconForContext(String context) {
    switch (context.toLowerCase()) {
      case 'science':
        return Icons.science_outlined;
      case 'math':
        return Icons.calculate_outlined;
      case 'physics':
        return Icons.thermostat_outlined;
      case 'chemistry':
        return Icons.biotech_outlined;
      case 'history':
        return Icons.history_edu_outlined;
      case 'english':
        return Icons.translate_outlined;
      // Add other subjects
      default:
        return Icons.book_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure listener is active & handle potential fallback fetch
    ref.watch(studentDetailsFetcher);
    final authState = ref.watch(authStateProvider);
    final studentDetails = ref.watch(studentDetailsProvider);
    if (authState is AsyncData<User?> &&
        authState.value != null &&
        studentDetails == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(studentDetailsProvider) == null) {
          ref.read(studentDetailsProvider.notifier).fetchStudentDetails();
        }
      });
    }

    final Size size = MediaQuery.of(context).size;
    final ColorScheme colorScheme = Theme.of(context).colorScheme; // Use theme

    return Scaffold(
      backgroundColor: darkBg,
      // extendBody:
      //     true, // Allows body content behind potential bottom nav bar in MainLayout
      body: RefreshIndicator(
        backgroundColor: primaryPurple,
        color: Colors.white,
        onRefresh: () async {
          await Future.wait([
            ref.read(studentDetailsProvider.notifier).fetchStudentDetails(),
            Future.sync(() => ref.invalidate(dailyTaskProvider)),
            // Add invalidations for REAL leaderboard/progress/events providers when implemented
          ]);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeaderSliverV5(context, ref, size), // Header Section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  16, 20, 16, 90), // Main content padding
              sliver: SliverList(
                  delegate: SliverChildListDelegate([
                // Section 1: Daily Missions (Using REAL provider)
                _buildDailyMissionsSectionV5(context, ref),
                const SizedBox(height: 24), // Spacing

                // --- Placeholder for Future Sections ---
                // You can add a simple message or leave empty for now
                // Center(child: Text("More insights coming soon!", style: TextStyle(color: textSecondary))),
                // const SizedBox(height: 24),
              ])),
            ),
          ],
        ),
      ),
      // No Bottom Nav or FAB here - they belong in MainLayout
    );
  }

  // --- Header Sliver ---
  Widget _buildHeaderSliverV5(BuildContext context, WidgetRef ref, Size size) {
    final StudentModel? student = ref.watch(studentDetailsProvider);
    final bool isLoading = student == null;
    final TextTheme textTheme = Theme.of(context)
        .textTheme
        .apply(bodyColor: textPrimary, displayColor: textPrimary);

    int currentLevel = 1;
    double levelProgress = 0.0;
    String levelText = "Lv 1";
    if (!isLoading) {
      const int xpPerLevelBase = 500;
      const double levelMultiplier = 1.2;
      int xpForCurrentLevelStart = 0;
      int xpForNextLevel = xpPerLevelBase;
      int cumulativeXp = 0;
      while (student.xp >= cumulativeXp + xpForNextLevel) {
        cumulativeXp += xpForNextLevel;
        currentLevel++;
        xpForNextLevel =
            (xpPerLevelBase * (currentLevel - 1) * levelMultiplier).toInt() +
                xpPerLevelBase;
      }
      xpForCurrentLevelStart = cumulativeXp;
      int xpInCurrentLevel = student.xp - xpForCurrentLevelStart;
      int totalXpNeededForThisLevel = xpForNextLevel;
      levelProgress = (totalXpNeededForThisLevel > 0)
          ? (xpInCurrentLevel / totalXpNeededForThisLevel).clamp(0.0, 1.0)
          : 1.0;
      levelText = "Lv $currentLevel";
    }

    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      snap: true,
      elevation: 1,
      backgroundColor: darkBg.withOpacity(0.8),
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: isLoading
          ? null
          : FadeIn(
              duration: 300.ms,
              child: Text(
                  "Hi, ${student.name.isNotEmpty ? student.name.split(' ').first : 'Student'}!",
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
      actions: [
        IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: "Notifications",
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Logout",
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.authChecker, (route) => false);
              }
            })
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
            child: Stack(fit: StackFit.expand, children: [
          Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [primaryPurple.withOpacity(0.3), darkBg],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.8]))),
          _buildBackgroundBlobs(size),
          Padding(
              padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: MediaQuery.of(context).padding.top + 15,
                  bottom: 15),
              child: isLoading
                  ? _buildHeaderLoadingState(context)
                  : FadeIn(
                      duration: 400.ms,
                      child: _buildHeaderContent(context, student, currentLevel,
                          levelProgress, textTheme))),
        ])),
      ),
    );
  }

  // --- Helper for Header Loading State ---
  Widget _buildHeaderLoadingState(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      _buildShimmerAvatar(27),
      const SizedBox(width: 14),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            _buildShimmerText(130, 18),
            const SizedBox(height: 6),
            _buildShimmerText(80, 14)
          ])),
    ]);
  }

  // --- Helper for Header Content State ---
  Widget _buildHeaderContent(BuildContext context, StudentModel student,
      int currentLevel, double levelProgress, TextTheme textTheme) {
    const String currentStreak = "15"; // Placeholder
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      SizedBox(
          width: 55,
          height: 55,
          child: CircularPercentIndicator(
              radius: 27.0,
              lineWidth: 3.5,
              percent: levelProgress,
              animation: true,
              animationDuration: 1000,
              center: CircleAvatar(
                  radius: 23,
                  backgroundColor: primaryPurple.withOpacity(0.7),
                  child: Text(
                      student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 22,
                          color: textPrimary,
                          fontWeight: FontWeight.bold))),
              progressColor: accentCyan,
              backgroundColor: surfaceLight.withOpacity(0.5),
              circularStrokeCap: CircularStrokeCap.round)),
      const SizedBox(width: 14),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Text("Welcome back,",
                style: textTheme.bodyMedium?.copyWith(color: textSecondary)),
            Text(
                student.name.isNotEmpty
                    ? student.name.split(' ').first
                    : student.email.split('@').first,
                style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    color: textPrimary),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
            Text("Level $currentLevel",
                style: textTheme.labelMedium
                    ?.copyWith(color: accentCyan, fontWeight: FontWeight.bold)),
          ])),
      const SizedBox(width: 10),
      FadeInRight(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.local_fire_department_rounded,
            color: Colors.orangeAccent.shade100, size: 26),
        Text("$currentStreak Day",
            style: textTheme.labelSmall
                ?.copyWith(color: Colors.orangeAccent.shade100))
      ]))
    ]);
  }

  // --- Background Blobs Helper ---
  Widget _buildBackgroundBlobs(Size size) {
    return Stack(children: [
      Positioned(
          left: -50,
          top: -50,
          child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentPink.withOpacity(0.05), // Reduced opacity
                  boxShadow: [
                    BoxShadow(
                        color: accentPink.withOpacity(0.08),
                        blurRadius: 90,
                        spreadRadius: 60)
                  ]))), // Adjusted shadow
      Positioned(
          right: -60,
          bottom: -40,
          child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentCyan.withOpacity(0.04), // Reduced opacity
                  boxShadow: [
                    BoxShadow(
                        color: accentCyan.withOpacity(0.08),
                        blurRadius: 100,
                        spreadRadius: 70)
                  ]))), // Adjusted shadow
    ]);
  }

  // --- Daily Missions Section ---
  Widget _buildDailyMissionsSectionV5(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<StudyTask>> tasksAsync =
        ref.watch(dailyTaskProvider); // Now expects List<StudyTask>
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Today's Missions",
          style: textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: textPrimary)),
      const SizedBox(height: 12),
      tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return FadeIn(
                child: _buildInfoCard(
                    context,
                    "Mission Complete (for now!)",
                    "No active missions assigned.",
                    Icons.check_circle_outline,
                    Colors.green));
          }
          return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) => FadeInUp(
                  delay: (index * 100).ms,
                  child: _buildMissionCard(
                      context, ref, tasks[index])), // Pass ref
              separatorBuilder: (context, index) => const SizedBox(height: 12));
        },
        loading: () => Column(
            children: List.generate(
                5,
                (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildShimmerCard(height: 130, borderRadius: 16)))),
        error: (e, s) => _buildErrorCard(context, "Failed to load missions",
            () => ref.invalidate(dailyTaskProvider)), // Pass context
      ),
    ]);
  }

  // --- Mission Card Widget ---
  Widget _buildMissionCard(
      BuildContext context, WidgetRef ref, StudyTask task) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    // ** REMOVED watch for completedDailyTaskIdsProvider **
    // final Set<String> completedIds = ref.watch(completedDailyTaskIdsProvider);
    // final bool isCompleted = completedIds.contains(task.id);
    final bool isCompleted = false; // Assume not completed for now

    // Simulate progress (replace later)
    // Keep placeholder progress, or maybe show nothing until completion is tracked?
    final double progress = task.id.hashCode % 100 / 100.0;

    return Card(
      elevation: 4, // Revert elevation
      color: surfaceLight.withOpacity(0.9), // Revert color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToTask(context, task), // Keep navigation
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(_getIconForContext(task.subject),
                    color: accentCyan, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(task.subject,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: textSecondary))),
                // Always show XP for now
                Text("+${task.xpReward} XP",
                    style: textTheme.bodySmall?.copyWith(
                        color: Colors.yellowAccent.shade100,
                        fontWeight: FontWeight.bold))
              ]),
              const SizedBox(height: 10),
              Text(task.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textPrimary, // Always show primary color
                    // decoration: TextDecoration.none // Remove strikethrough
                  )),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: LinearPercentIndicator(
                  percent: progress,
                  lineHeight: 8.0, backgroundColor: darkBg.withOpacity(0.5),
                  progressColor: accentCyan, // Always show accent color
                  barRadius: const Radius.circular(4), animation: true,
                )),
                const SizedBox(width: 10),

                // --- REMOVED Completion Button/Indicator ---
                // Replaced with placeholder or estimated time for now
                Row(
                  // Display estimated time instead of button
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text("${task.estimatedTimeMinutes} min",
                        style: textTheme.labelSmall
                            ?.copyWith(color: textSecondary)),
                  ],
                ),
                // ------------------------------------------
              ])
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (Shimmer, Error, Info) ---
  Widget _buildInfoCard(BuildContext context, String title, String message,
      IconData icon, Color color) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
        color: surfaceLight.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(message,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: textSecondary))
                  ]))
            ])));
  }

  Widget _buildShimmerCard(
      {required double height, double? width, double borderRadius = 15}) {
    return Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
                color: Colors.white /* Placeholder color for shimmer shape */,
                borderRadius: BorderRadius.circular(borderRadius))));
  }

  Widget _buildShimmerText(double width, double height) {
    return Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
            width: width,
            height: height,
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 2)));
  }

  Widget _buildShimmerAvatar(double radius) {
    return Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.1),
        child: CircleAvatar(radius: radius, backgroundColor: Colors.white));
  }

  Widget _buildErrorCard(
      BuildContext context, String message, VoidCallback onRetry,
      {double? height, bool isSmall = false}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
        color: colorScheme.errorContainer.withOpacity(0.7),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(12),
            child: Container(
                height: height,
                padding: EdgeInsets.all(isSmall ? 12 : 16),
                child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                      size: isSmall ? 24 : 30),
                  SizedBox(height: isSmall ? 4 : 8),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onErrorContainer)),
                  SizedBox(height: isSmall ? 2 : 4),
                  Text("Tap to retry",
                      style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500))
                ])))));
  }

  // --- Navigation Helper ---
  void _navigateToTask(BuildContext context, StudyTask task) {
    // Ensure chapterId exists in StudyTask model and is populated by the service
    final String? targetChapterId = task.chapter;

    if (targetChapterId != null && targetChapterId.isNotEmpty) {
      print(
          "Navigating to Chapter Landing for Chapter ID: $targetChapterId, Subject: ${task.subject}");
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChapterLandingScreen(
                  subjectName: task.subject,
                  chapterId: targetChapterId // Use the ID
                  )));
    } else {
      print(
          "Task tapped (${task.title}), but no chapter ID available for navigation.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Cannot navigate: Chapter ID missing."),
          duration: Duration(seconds: 1)));
    }
  }
} // --- End of HomeScreen2 class ---
