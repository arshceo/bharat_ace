// lib/screens/home/home_screen.dart

import 'package:bharat_ace/common/routes.dart';
import 'package:bharat_ace/core/models/ai_spark_theme.dart';
import 'package:bharat_ace/core/services/study_plan_service.dart';
import 'package:bharat_ace/screens/exam_succeed/exam_succeed_screen.dart';
import 'package:bharat_ace/screens/notification_screen.dart';
import 'package:bharat_ace/screens/analytics/study_analytics_screen.dart';
import 'package:bharat_ace/screens/career/career_dream_palace_screen.dart';
import 'package:bharat_ace/screens/career/career_path_visualization_screen.dart';
import 'package:bharat_ace/core/theme/app_theme.dart';
import 'package:bharat_ace/screens/smaterial/key_notes_screen.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';
import 'package:bharat_ace/core/providers/settings_providers.dart' as settings;
import 'dark_mode_utils.dart';
import 'package:bharat_ace/widgets/home_screen_widgets/ai_chat_widget.dart';
import 'package:bharat_ace/widgets/home_screen_widgets/animated_sun_display.dart';
import 'package:bharat_ace/widgets/home_screen_widgets/book_magic_theme_display.dart';
import 'package:bharat_ace/widgets/home_screen_widgets/moon_theme_display.dart';
import 'package:bharat_ace/widgets/home_screen_widgets/rocket_theme_display.dart';
import 'package:bharat_ace/widgets/home_screen_widgets/thinking_cap_theme_display.dart';
import 'package:bharat_ace/widgets/screen_timer_display.dart';
import 'package:bharat_ace/widgets/timer_widget.dart';
import 'package:bharat_ace/widgets/discipline_system.dart';
import 'package:bharat_ace/widgets/discipline_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animate_do/animate_do.dart';

// --- Import ACTUAL providers and models ---
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:bharat_ace/core/models/study_task_model.dart';
import 'package:bharat_ace/core/providers/feature_toggle_provider.dart';

// --- Import NEWLY separated models and providers ---
import 'package:bharat_ace/core/models/daily_feed_item.dart';
import 'package:bharat_ace/core/providers/home_providers.dart';
import 'package:bharat_ace/core/providers/student_details_listener.dart';

// --- Import Navigation Targets ---
import 'package:bharat_ace/screens/smaterial/chapter_landing_screen.dart';
import 'package:bharat_ace/screens/courses/course_screen.dart';

import 'package:bharat_ace/widgets/study_session_manager.dart';

import '../../core/theme/app_colors.dart';

// --- Import Widgets ---

class HomeScreen2 extends ConsumerWidget {
  const HomeScreen2({super.key});

  IconData _getIconForContext(String context) {
    switch (context.toLowerCase()) {
      case 'science':
        return Icons.science_outlined;
      case 'math':
        return Icons.calculate_outlined;
      case 'physics':
        return Icons.thermostat_outlined; // Or Icons.bolt_outlined
      case 'chemistry':
        return Icons.biotech_outlined; // Or Icons.science_rounded
      case 'biology':
        return Icons.eco_outlined; // Or Icons.emoji_nature_outlined
      case 'history':
        return Icons.history_edu_outlined;
      case 'geography':
        return Icons.public_outlined;
      case 'english':
        return Icons.translate_outlined; // Or Icons.menu_book_outlined
      case 'computer science':
        return Icons.computer_outlined;
      default:
        return Icons.book_outlined;
    }
  }

  // --- Copied from HomeScreen2 (modern greeting/stats UI) ---
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(studentDetailsFetcher); // Initialize listener
    return DisciplineWrapper(
      screenName: 'Home',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: FadeIn(
            child: Text(
              'BharatAce',
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
          centerTitle: false,
          actions: [
            const StudySessionTimer(),
            EmergencyBreakButton(),
            const SizedBox(width: AppTheme.spaceXS),
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              color: HomeScreenTheme.getTextColor(context),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudyAnalyticsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: AppTheme.spaceXS),
            // Notifications icon - only show when extra features are enabled
            Consumer(
              builder: (context, ref, child) {
                final extraFeaturesEnabled = ref.watch(featureToggleProvider);
                return extraFeaturesEnabled
                    ? IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: AppTheme.gray700,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
            const SizedBox(width: AppTheme.spaceXS),
          ],
        ),
        body: RefreshIndicator(
          backgroundColor: HomeScreenTheme.getCardColor(context),
          color: AppTheme.primary,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(studentDetailsNotifierProvider);
            ref.invalidate(todaysPersonalizedTasksProvider);
            ref.invalidate(currentStudentsOnlineProvider);
            ref.invalidate(homeLeaderboardProvider);
            ref.invalidate(dailyAiFeedProvider);
            await ref
                .read(studentDetailsNotifierProvider.notifier)
                .fetchStudentDetails();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingSection(
                    context, ref.watch(studentDetailsProvider)),
                const SizedBox(height: AppTheme.spaceLG),
                _buildQuickStatsSection(ref.watch(studentDetailsProvider)),
                const SizedBox(height: AppTheme.space2XL),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                  child: _buildEnhancedDailyAiSection(context, ref),
                ),
                const SizedBox(height: AppTheme.space2XL),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                  child: _buildEnhancedStatsGrid(context, ref),
                ),
                const SizedBox(height: AppTheme.space2XL),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                  child: _buildStudySessionSection(context, ref),
                ),
                const SizedBox(height: AppTheme.space2XL),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                  child: _buildEnhancedExperimentSection(context, ref),
                ),
                const SizedBox(height: AppTheme.space2XL),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                  child: _buildEnhancedQuickActions(context, ref),
                ),
                const SizedBox(height: AppTheme.space3XL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(
      BuildContext context, AsyncValue<StudentModel?> student) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: student.when(
        data: (studentData) => FadeInUp(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Icon(
                  _getTimeIcon(),
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()},',
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.gray600,
                      ),
                    ),
                    Text(
                      studentData?.name ?? 'Student',
                      style: AppTheme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.gray900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => _buildGreetingShimmer(),
        error: (error, stack) => _buildGreetingError(),
      ),
    );
  }

  Widget _buildQuickStatsSection(AsyncValue<StudentModel?> student) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: student.when(
        data: (studentData) => FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: BoxDecoration(
              color: AppTheme.darkBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: AppTheme.gray200),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spaceXS),
                    Builder(builder: (context) {
                      return Text(
                        'Your Progress',
                        style: AppTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.gray900,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceLG),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'XP',
                        '${studentData?.xp ?? 0}',
                        Icons.star_rounded,
                        AppTheme.warning,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.gray200,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Level',
                        '${_calculateLevel(studentData?.xp ?? 0)}',
                        Icons.emoji_events_rounded,
                        AppTheme.primary,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.gray200,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Streak',
                        '${studentData?.dailyStreak ?? 0} days',
                        Icons.local_fire_department_rounded,
                        AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        loading: () => _buildStatsShimmer(),
        error: (error, stack) => Container(),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          value,
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTheme.textTheme.bodySmall,
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      return Icons.wb_sunny_outlined;
    } else {
      return Icons.nights_stay_rounded;
    }
  }

  int _calculateLevel(int xp) {
    // Use the same logic as the backup file for level calculation if needed
    return (xp / 1000).floor() + 1;
  }

  Widget _buildGreetingShimmer() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.gray200,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.gray200,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.gray200,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      height: 120,
    );
  }

  Widget _buildGreetingError() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Icon(
            Icons.error_outline,
            color: AppTheme.error,
            size: 24,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Day,',
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.gray600,
                ),
              ),
              Text(
                'Student',
                style: AppTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Removed animated/professional background for a clean white look.

  void _showAiFeedDetailsDialog(
      BuildContext context, WidgetRef ref, DailyFeedItem item) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            item.title,
            style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Text(
              item.content,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Got it!",
                  style: TextStyle(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Acknowledged: ${item.title}",
                        style: TextStyle(color: AppColors.darkBg)),
                    backgroundColor: AppColors.accentCyan,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(10),
                  ),
                );
              },
            ),
            TextButton(
              child: Text("Want to know more",
                  style: TextStyle(
                      color: AppColors.accentPink,
                      fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close this dialog first
                _showAiChatBottomSheet(context, ref, item);
              },
            ),
          ],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        );
      },
    );
  }
// In HomeScreen2.dart

// Helper function to show the exam date input dialog
  Future<void> _showExamDateDialog(BuildContext context, WidgetRef ref) async {
    DateTime? selectedFinalExamDate;
    DateTime? selectedMstDate;

    // Get current student details to pre-fill dates if they exist
    final student = ref.read(studentDetailsProvider).valueOrNull;
    if (student != null) {
      selectedFinalExamDate = student.examDate;
      selectedMstDate = student.mstDate; // If you added mstDate to StudentModel
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // User can dismiss by tapping outside
      builder: (BuildContext dialogContext) {
        // Use a StatefulWidget for the dialog content if you need to manage local state for date pickers
        // For simplicity here, we'll manage it directly, but StatefulWidget is cleaner for complex dialogs.
        // Let's use a simple StatefulBuilder for this example.
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: Text('Set Your Exam Dates',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Help us create your personalized study plan!',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),

                  // MST Date Picker
                  Text('Mid-Semester Test (MST) Date (Optional):',
                      style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.8))),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.calendar_today,
                        color: AppColors.accentPink.withOpacity(0.8)),
                    label: Text(
                      selectedMstDate == null
                          ? 'Select MST Date'
                          : 'MST: ${selectedMstDate!.day}/${selectedMstDate!.month}/${selectedMstDate!.year}',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedMstDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365 * 2)), // 2 years out
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              // Or your app's dark theme
                              colorScheme: ColorScheme.dark(
                                primary: AppColors.accentPink,
                                onPrimary: Colors.white,
                                surface: AppColors.surfaceDark,
                                onSurface: AppColors.textPrimary,
                              ),
                              dialogBackgroundColor: AppColors.darkBg,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != selectedMstDate) {
                        setStateDialog(() {
                          selectedMstDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Final Exam Date Picker
                  Text('Final Exam Date (Required):',
                      style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.8))),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.calendar_today,
                        color: AppColors.accentCyan.withOpacity(0.8)),
                    label: Text(
                      selectedFinalExamDate == null
                          ? 'Select Final Exam Date'
                          : 'Final: ${selectedFinalExamDate!.day}/${selectedFinalExamDate!.month}/${selectedFinalExamDate!.year}',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedFinalExamDate ??
                            DateTime.now().add(const Duration(days: 120)),
                        firstDate: DateTime.now().add(const Duration(
                            days: 7)), // Exam should be at least a week away
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              // Or your app's dark theme
                              colorScheme: ColorScheme.dark(
                                primary: AppColors.accentCyan,
                                onPrimary: Colors.white,
                                surface: AppColors.surfaceDark,
                                onSurface: AppColors.textPrimary,
                              ),
                              dialogBackgroundColor: AppColors.darkBg,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != selectedFinalExamDate) {
                        setStateDialog(() {
                          selectedFinalExamDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple),
                child: const Text('Save Dates',
                    style: TextStyle(color: Colors.white)),
                onPressed: () {
                  if (selectedFinalExamDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a final exam date.'),
                          backgroundColor: Colors.redAccent),
                    );
                    return;
                  }
                  // Update student details in Firestore
                  ref
                      .read(studentDetailsNotifierProvider.notifier)
                      .updateStudentExamDates(
                        finalExamDate: selectedFinalExamDate,
                        mstDate: selectedMstDate, // Pass MST date as well
                      );
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Exam dates updated! Your plan will refresh shortly.'),
                        backgroundColor: AppColors.completedGreen),
                  );
                  // The todaysPersonalizedTasksProvider will auto-refresh because studentDetailsProvider changes.
                },
              ),
            ],
          );
        });
      },
    );
  }

  void _showAiChatBottomSheet(
      BuildContext context, WidgetRef ref, DailyFeedItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return AiChatWidget(item: item);
      },
    );
  }

  Widget _buildEnhancedHeaderSliver(
      BuildContext context, WidgetRef ref, Size size) {
    final AsyncValue<StudentModel?> studentAsync =
        ref.watch(studentDetailsProvider);
    final StudentModel? student = studentAsync.valueOrNull;
    final bool isLoading = studentAsync is AsyncLoading || student == null;
    final TextTheme textTheme = Theme.of(context).textTheme;

    int currentLevel = 1;
    double levelProgress = 0.0;
    if (student != null) {
      const int xpPerLevelBase = 500;
      const double levelMultiplier = 1.2;

      currentLevel = 1;
      int xpForNextLevel = xpPerLevelBase;
      int cumulativeXpForPreviousLevels = 0;
      while (student.xp >= cumulativeXpForPreviousLevels + xpForNextLevel) {
        cumulativeXpForPreviousLevels += xpForNextLevel;
        currentLevel++;
        xpForNextLevel =
            (xpPerLevelBase * (currentLevel - 1) * levelMultiplier).toInt();
        xpForNextLevel = (xpForNextLevel > 0) ? xpForNextLevel : xpPerLevelBase;
      }

      int xpIntoCurrentLevel = student.xp - cumulativeXpForPreviousLevels;
      levelProgress = (xpForNextLevel > 0)
          ? (xpIntoCurrentLevel.toDouble() / xpForNextLevel.toDouble())
              .clamp(0.0, 1.0)
          : 1.0;
    }

    final int studentCoins = student?.coins ?? 0;
    final int studentStreak = student?.dailyStreak ?? 0;

    return SliverAppBar(
      expandedHeight: 200.0,
      floating: true,
      pinned: true,
      snap: true,
      elevation: 0,
      backgroundColor: AppTheme.white,
      foregroundColor: AppTheme.gray900,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: isLoading
          ? null
          : FadeIn(
              duration: 400.ms,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.auto_awesome,
                            size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Welcome back!",
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.gray600,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              "${student.name.isNotEmpty ? student.name.split(' ').first : 'Learner'}",
                              style: AppTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.gray900,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
      actions: [
        const ScreenTimerDisplay(),
        _buildIconButton(
          icon: Icons.notifications_none_rounded,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationScreen()),
          ),
          hasNotification: true,
        ),
        _buildIconButton(
          icon: Icons.logout_rounded,
          onPressed: () async {
            HapticFeedback.lightImpact();
            await ref.read(authServiceProvider).signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.authChecker, (route) => false);
            }
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.6, 1.0],
              colors: [
                AppTheme.primary.withOpacity(0.03),
                AppTheme.white.withOpacity(0.9),
                AppTheme.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 20),
              child: isLoading
                  ? _buildEnhancedHeaderLoading()
                  : FadeInUp(
                      duration: 500.ms,
                      child: _buildResponsiveHeaderContent(
                        context,
                        student,
                        currentLevel,
                        levelProgress,
                        studentCoins,
                        studentStreak,
                        textTheme,
                        size,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveHeaderContent(
    BuildContext context,
    StudentModel student,
    int currentLevel,
    double levelProgress,
    int coins,
    int streak,
    TextTheme textTheme,
    Size screenSize,
  ) {
    // Responsive breakpoints
    final bool isSmallScreen = screenSize.width < 360;
    final bool isMediumScreen = screenSize.width < 400;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          constraints: BoxConstraints(
            maxHeight: 100, // Prevent overflow
          ),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.white,
                AppTheme.gray50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.gray200,
              width: 1,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Avatar with progress ring - Responsive sizing
              SizedBox(
                width: isSmallScreen ? 50 : (isMediumScreen ? 60 : 70),
                height: isSmallScreen ? 50 : (isMediumScreen ? 60 : 70),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress ring with proper sizing
                    CircularPercentIndicator(
                      radius:
                          isSmallScreen ? 22.0 : (isMediumScreen ? 27.0 : 32.0),
                      lineWidth: 2.5,
                      percent: levelProgress,
                      animation: true,
                      animationDuration: 1500,
                      backgroundColor: AppTheme.gray200,
                      progressColor: AppTheme.primary,
                      circularStrokeCap: CircularStrokeCap.round,
                      center: CircleAvatar(
                        radius: isSmallScreen ? 18 : (isMediumScreen ? 23 : 28),
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name[0].toUpperCase()
                              : '🌟',
                          style: TextStyle(
                            fontSize:
                                isSmallScreen ? 16 : (isMediumScreen ? 20 : 24),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Level badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.warning,
                              AppTheme.warning.withOpacity(0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.warning.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          'L$currentLevel',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 8 : 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: isSmallScreen ? 8 : 12),

              // Content - Flexible and responsive
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // XP display
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "${student.xp} XP",
                        style: AppTheme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontSize:
                              isSmallScreen ? 16 : (isMediumScreen ? 18 : 20),
                        ),
                      ),
                    ),
                    // Level info
                    Text(
                      "Level $currentLevel Explorer",
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.gray600,
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 10 : 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Stats chips - Responsive layout
                    if (!isSmallScreen)
                      Row(
                        children: [
                          Flexible(
                            child: _buildCompactStatChip(
                              icon: Icons.local_fire_department_rounded,
                              value: "$streak",
                              color: streak > 0
                                  ? AppTheme.warning
                                  : AppTheme.gray600,
                              isAnimated: streak > 0,
                              isSmall: isMediumScreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: _buildCompactStatChip(
                              icon: Icons.monetization_on_rounded,
                              value: "$coins",
                              color: AppTheme.warning,
                              isSmall: isMediumScreen,
                            ),
                          ),
                        ],
                      )
                    else
                      // For very small screens, show minimally
                      Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 12,
                              color: streak > 0
                                  ? AppTheme.warning
                                  : AppTheme.gray600),
                          const SizedBox(width: 2),
                          Text("$streak",
                              style: TextStyle(
                                  fontSize: 10, color: AppTheme.warning)),
                          const SizedBox(width: 8),
                          Icon(Icons.monetization_on_rounded,
                              size: 12, color: AppTheme.warning),
                          const SizedBox(width: 2),
                          Text("$coins",
                              style: TextStyle(
                                  fontSize: 10, color: AppTheme.warning)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStatChip({
    required IconData icon,
    required String value,
    required Color color,
    bool isAnimated = false,
    bool isSmall = false,
  }) {
    Widget iconWidget = Icon(
      icon,
      size: isSmall ? 10 : 12,
      color: color,
    );

    if (isAnimated) {
      iconWidget = iconWidget
          .animate(onPlay: (controller) => controller.repeat())
          .scaleXY(begin: 0.8, end: 1.2, duration: 1000.ms)
          .then()
          .scaleXY(begin: 1.2, end: 0.8, duration: 1000.ms);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 4 : 6,
        vertical: isSmall ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 8 : 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool hasNotification = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.gray200,
                width: 1,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: IconButton(
              icon: Icon(icon, size: 18, color: AppTheme.gray700),
              onPressed: onPressed,
              splashRadius: 20,
              padding: EdgeInsets.zero,
            ),
          ),
          if (hasNotification)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.error.withOpacity(0.5),
                      blurRadius: 3,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scaleXY(begin: 0.8, end: 1.2, duration: 1000.ms)
                  .then()
                  .scaleXY(begin: 1.2, end: 0.8, duration: 1000.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeaderLoading() {
    return Row(
      children: [
        _buildShimmerAvatar(40),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildShimmerText(180, 24),
              const SizedBox(height: 8),
              _buildShimmerText(120, 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDailyAiSection(BuildContext context, WidgetRef ref) {
    final dailyFeedAsync = ref.watch(dailyAiFeedProvider);
    final AiSparkThemeType currentTheme = getDailyTheme();

    Widget buildDisplayWidget(DailyFeedItem item) {
      VoidCallback onTapCallback =
          () => _showAiFeedDetailsDialog(context, ref, item);

      Widget themeWidget;
      switch (currentTheme) {
        case AiSparkThemeType.sun:
          themeWidget =
              AnimatedSunDisplay(dailyFeedItem: item, onTap: onTapCallback);
          break;
        case AiSparkThemeType.moon:
          themeWidget =
              MoonThemeDisplay(dailyFeedItem: item, onTap: onTapCallback);
          break;
        case AiSparkThemeType.thinkingCap:
          themeWidget = ThinkingCapThemeDisplay(
              dailyFeedItem: item, onTap: onTapCallback);
          break;
        case AiSparkThemeType.rocket:
          themeWidget =
              RocketThemeDisplay(dailyFeedItem: item, onTap: onTapCallback);
          break;
        case AiSparkThemeType.bookMagic:
          themeWidget =
              BookMagicThemeDisplay(dailyFeedItem: item, onTap: onTapCallback);
          break;
        default:
          themeWidget =
              BookMagicThemeDisplay(dailyFeedItem: item, onTap: onTapCallback);
      }

      // Enhanced wrapper with professional card styling
      return Builder(builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.gray200,
              width: 1,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.gray900.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTapCallback,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              child: themeWidget,
            ),
          ),
        );
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 24,
                color: AppTheme.darkBg,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(begin: -0.1, end: 0.1, duration: 2000.ms)
                .then()
                .rotate(begin: 0.1, end: -0.1, duration: 2000.ms),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Spark",
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: HomeScreenTheme.getTextColor(context),
                    ),
                  ),
                  Text(
                    "Your personalized daily insight",
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: HomeScreenTheme.getTextColor(context,
                          secondary: true),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: HomeScreenTheme.getAccentBackgroundColor(
                    context, AppTheme.success),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.success.withOpacity(0.5)
                      : AppTheme.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scaleXY(begin: 0.5, end: 1.5, duration: 1000.ms)
                      .then()
                      .scaleXY(begin: 1.5, end: 0.5, duration: 1000.ms),
                  const SizedBox(width: 8),
                  Text(
                    "Live",
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        dailyFeedAsync.when(
          data: (item) => buildDisplayWidget(item),
          loading: () => _buildEnhancedShimmerCard(height: 280),
          error: (e, s) => _buildEnhancedErrorCard(
            context,
            "AI Spark is taking a short break",
            "We're working on bringing you fresh insights",
            () => ref.invalidate(dailyAiFeedProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatsGrid(BuildContext context, WidgetRef ref) {
    final studentsOnlineAsync = ref.watch(currentStudentsOnlineProvider);
    final leaderboardAsync = ref.watch(homeLeaderboardProvider);
    final textTheme = AppTheme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceXS),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(
                Icons.trending_up_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Text(
              "Community Pulse",
              style: AppTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: HomeScreenTheme.getTextColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLG),
        Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.gray200,
                width: 1,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppTheme.gray900.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Row(
              children: [
                // Online Students
                Expanded(
                  child: studentsOnlineAsync.when(
                    data: (count) => _buildStatCard(
                      icon: Icons.group_work_rounded,
                      title: "$count",
                      subtitle: "Scholars\nOnline",
                      color: AppTheme.success,
                      isMainStat: true,
                    ),
                    loading: () => _buildStatCardLoading(),
                    error: (e, s) => _buildStatCard(
                      icon: Icons.error_outline_rounded,
                      title: "—",
                      subtitle: "Unavailable",
                      color: AppTheme.error,
                    ),
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 80,
                  margin:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                  color: AppTheme.gray200,
                ),

                // Leaderboard
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceXS),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSM),
                            ),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: AppTheme.warning,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceXS),
                          Text(
                            "Top Achievers",
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.gray900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceMD),
                      leaderboardAsync.when(
                        data: (users) {
                          if (users.isEmpty) {
                            return _buildEmptyLeaderboard(textTheme);
                          }
                          return Column(
                            children: users
                                .take(3)
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) => _buildLeaderboardItem(
                                      entry.key + 1,
                                      entry.value,
                                      textTheme,
                                    ))
                                .toList(),
                          );
                        },
                        loading: () => _buildLeaderboardLoading(),
                        error: (e, s) =>
                            _buildEmptyLeaderboard(textTheme, isError: true),
                      ),
                      const SizedBox(height: AppTheme.spaceMD),
                      // View All Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/leaderboard');
                          },
                          icon: Icon(
                            Icons.leaderboard_rounded,
                            size: 16,
                            color: AppTheme.white,
                          ),
                          label: Text(
                            'View Full Leaderboard',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spaceXS),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSM),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        })
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isMainStat = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Make column take minimum space
      children: [
        Container(
          padding: const EdgeInsets.all(12), // Reduced padding from 16 to 12
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon,
              color: color, size: isMainStat ? 28 : 24), // Reduced sizes
        ),
        const SizedBox(height: 8), // Reduced from 12 to 8
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: TextStyle(
              fontSize: isMainStat ? 24 : 20, // Reduced from 28/24 to 24/20
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2), // Reduced from 4 to 2
        Builder(
          builder: (context) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12, // Reduced from 13 to 12
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkTextPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCardLoading() {
    return Column(
      children: [
        _buildShimmerAvatar(32),
        const SizedBox(height: 12),
        _buildShimmerText(60, 28),
        const SizedBox(height: 4),
        _buildShimmerText(80, 13),
      ],
    );
  }

  Widget _buildLeaderboardItem(
      int position, dynamic user, TextTheme textTheme) {
    Color positionColor = position == 1
        ? AppColors.goldStar
        : position == 2
            ? Colors.grey.shade400
            : Colors.orange.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: positionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: positionColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: positionColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "$position",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Builder(builder: (context) {
              return Text(
                user.name,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkTextPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${user.xp} XP",
              style: TextStyle(
                color: AppColors.accentCyan,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLeaderboard(TextTheme textTheme, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isError ? Colors.redAccent : AppColors.accentCyan)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isError ? Colors.redAccent : AppColors.accentCyan)
              .withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Builder(builder: (context) {
          return Text(
            isError ? "Leaderboard unavailable" : "Be the first to shine! ✨",
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkTextPrimary
                  : AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          );
        }),
      ),
    );
  }

  Widget _buildLeaderboardLoading() {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _buildShimmerAvatar(12),
              const SizedBox(width: 12),
              Expanded(child: _buildShimmerText(100, 14)),
              _buildShimmerText(50, 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudySessionSection(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<StudyTask>> tasksAsync =
        ref.watch(todaysPersonalizedTasksProvider);

    return tasksAsync.when(
      data: (tasks) => StudySessionButton(tasks: tasks),
      loading: () => _buildSessionLoading(),
      error: (e, s) => _buildEnhancedErrorCard(
        context,
        "Study Session Unavailable",
        "We're preparing your personalized study plan",
        () => ref.invalidate(todaysPersonalizedTasksProvider),
      ),
    );
  }

  Widget _buildSessionLoading() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.gray300,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.gray300,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.gray300,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMissionsSection(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<StudyTask>> tasksAsync =
        ref.watch(todaysPersonalizedTasksProvider);
    final TextTheme textTheme = AppTheme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceXS),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(
                Icons.track_changes_rounded,
                size: 20,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Missions",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray900,
                    ),
                  ),
                  Text(
                    "Your personalized learning path",
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceXS,
                vertical: AppTheme.space2XS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                border: Border.all(
                  color: AppTheme.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: AppTheme.space2XS),
                  Text(
                    "AI Curated",
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLG),
        tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return _buildEnhancedEmptyMissions(context);
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) => FadeInUp(
                delay: (index * 100).ms,
                duration: 500.ms,
                child: _buildEnhancedMissionCard(
                    context, ref, tasks[index], index),
              ),
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            );
          },
          loading: () => _buildMissionsLoading(),
          error: (e, s) => _buildEnhancedErrorCard(
            context,
            "Mission Control is Offline",
            "We're recalibrating your learning missions",
            () => ref.invalidate(todaysPersonalizedTasksProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedMissionCard(
    BuildContext context,
    WidgetRef ref,
    StudyTask task,
    int index,
  ) {
    final TextTheme textTheme = AppTheme.textTheme;
    final double progress = task.progress ?? (task.id.hashCode % 100 / 100.0);
    final bool isCompleted = progress >= 0.99;

    // Color scheme based on task type
    Color primaryColor = _getTaskColor(task.type);

    return ProfessionalCard(
      onTap: () {
        HapticFeedback.lightImpact();
        _handleMissionTap(context, ref, task);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceXS),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Icon(
                  _getIconForContext(task.subject),
                  color: primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppTheme.spaceXS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.subject.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _getTaskTypeLabel(task.type),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // XP Reward Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceXS,
                  vertical: AppTheme.space2XS,
                ),
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.success : primaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted ? Icons.check_rounded : Icons.star_rounded,
                      size: 12,
                      color: AppTheme.white,
                    ),
                    const SizedBox(width: AppTheme.space2XS),
                    Text(
                      isCompleted ? "DONE" : "+${task.xpReward} XP",
                      style: TextStyle(
                        color: AppTheme.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),

          // Mission Title
          Text(
            task.title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.gray900,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              decorationColor: AppTheme.gray500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),

          // Progress Bar and Time
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Progress",
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.gray600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: textTheme.bodySmall?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.gray200,
                        borderRadius: BorderRadius.circular(AppTheme.space2XS),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isCompleted ? AppTheme.success : primaryColor,
                            borderRadius:
                                BorderRadius.circular(AppTheme.space2XS),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceLG),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceXS,
                  vertical: AppTheme.space2XS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(color: AppTheme.gray200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppTheme.gray600,
                    ),
                    const SizedBox(width: AppTheme.space2XS),
                    Text(
                      "${task.estimatedTimeMinutes} min",
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.gray600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTaskColor(TaskType type) {
    switch (type) {
      case TaskType.studyChapter:
        return AppTheme.info;
      case TaskType.revision:
        return AppTheme.secondary;
      case TaskType.test:
        return AppTheme.warning;
      case TaskType.quiz:
        return AppTheme.success;
      case TaskType.config:
        return AppTheme.primary;
      default:
        return AppTheme.info;
    }
  }

  String _getTaskTypeLabel(TaskType type) {
    switch (type) {
      case TaskType.studyChapter:
        return "Study Session";
      case TaskType.revision:
        return "Quick Review";
      case TaskType.test:
        return "Practice Test";
      case TaskType.quiz:
        return "Quick Quiz";
      case TaskType.config:
        return "Setup Task";
      default:
        return "Learning Task";
    }
  }

  void _handleMissionTap(BuildContext context, WidgetRef ref, StudyTask task) {
    if (task.id == 'set-exam-date-task') {
      _showExamDateDialog(context, ref);
    } else if (task.type == TaskType.studyChapter ||
        task.type == TaskType.studyTopic ||
        task.type == TaskType.revision) {
      _navigateToTask(context, task);
    } else if (task.type == TaskType.config &&
        task.id != 'set-exam-date-task') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Configuration: ${task.title}"),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    } else if (task.type == TaskType.test || task.type == TaskType.quiz) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Starting ${_getTaskTypeLabel(task.type)}: ${task.title}"),
          backgroundColor: _getTaskColor(task.type),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Opening: ${task.title}"),
          backgroundColor: AppTheme.info,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  Widget _buildEnhancedEmptyMissions(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.completedGreen.withOpacity(0.1),
            AppColors.completedGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.completedGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.completedGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration_rounded,
              size: 48,
              color: AppColors.completedGreen,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scaleXY(begin: 0.9, end: 1.1, duration: 2000.ms)
              .then()
              .scaleXY(begin: 1.1, end: 0.9, duration: 2000.ms),
          const SizedBox(height: 20),
          Text(
            "Mission Complete! 🎉",
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.completedGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up! Check back tomorrow for new learning adventures.",
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsLoading() {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildEnhancedShimmerCard(height: 140),
        ),
      ),
    );
  }

  Widget _buildMissionCard(
      BuildContext context, WidgetRef ref, StudyTask task) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double progress = task.progress ?? (task.id.hashCode % 100 / 100.0);
    final bool isCompleted = progress >= 0.99;

    return Card(
      elevation: isCompleted ? 2 : 4,
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isCompleted
            ? BorderSide(
                color: AppColors.completedGreen.withOpacity(0.5), width: 1)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // In HomeScreen2.dart, inside _buildMissionCard method:
        onTap: () {
          if (task.id == 'set-exam-date-task') {
            _showExamDateDialog(context, ref);
          } else if (task.type == TaskType.studyChapter ||
              task.type == TaskType.studyTopic || // If you use studyTopic
              task.type == TaskType.revision) {
            _navigateToTask(
                context, task); // <<< --- CALL YOUR NAVIGATION METHOD
          } else if (task.type == TaskType.config &&
              task.id != 'set-exam-date-task') {
            // Handle other specific config tasks if they exist and have actions
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Configuration task: ${task.title}")),
            );
          } else if (task.type == TaskType.test || task.type == TaskType.quiz) {
            // TODO: Implement navigation to Test/Quiz screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("Navigate to Test/Quiz for: ${task.title}")),
            );
          } else {
            // Fallback for any other unhandled task types
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Action pending for task: ${task.title}")),
            );
          }
        },
        borderRadius: BorderRadius.circular(18),
        splashColor:
            (isCompleted ? AppColors.completedGreen : AppColors.accentCyan)
                .withOpacity(0.2),
        highlightColor:
            (isCompleted ? AppColors.completedGreen : AppColors.accentCyan)
                .withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isCompleted) ...[
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.completedGreen, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("Completed!",
                          style: textTheme.titleSmall?.copyWith(
                              color: AppColors.completedGreen,
                              fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    Icon(_getIconForContext(task.subject),
                        color: AppColors.primaryPurple, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(task.subject,
                            style: textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500))),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isCompleted
                              ? AppColors.completedGreen
                              : AppColors.accentCyan)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("+${task.xpReward} XP",
                        style: textTheme.bodySmall?.copyWith(
                            color: isCompleted
                                ? AppColors.completedGreen
                                : AppColors.accentCyan,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(task.title,
                  style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppColors.textPrimary.withOpacity(0.6)
                          : AppColors.textPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.textSecondary,
                      decorationThickness: 1.5,
                      height: 1.35)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: LinearPercentIndicator(
                      percent: progress,
                      lineHeight: 9.0,
                      backgroundColor: AppColors.darkBg.withOpacity(0.8),
                      progressColor: isCompleted
                          ? AppColors.completedGreen
                          : AppColors.accentCyan,
                      barRadius: const Radius.circular(4.5),
                      animation: true,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.timer_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text("${task.estimatedTimeMinutes} min",
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedExperimentSection(BuildContext context, WidgetRef ref) {
    // Check if extra features are enabled - if not, don't show this section
    final extraFeaturesEnabled = ref.watch(featureToggleProvider);
    if (!extraFeaturesEnabled) {
      return const SizedBox
          .shrink(); // Return empty widget when features are disabled
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final bool isMediumScreen = screenSize.width < 400;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                AppColors.accentPink.withOpacity(0.12),
                AppColors.primaryPurple.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.accentPink.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPink.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to experiment submission
              },
              borderRadius: BorderRadius.circular(24),
              splashColor: AppColors.accentPink.withOpacity(0.15),
              highlightColor: AppColors.accentPink.withOpacity(0.08),
              child: Padding(
                padding: EdgeInsets.all(
                    isSmallScreen ? 16 : (isMediumScreen ? 20 : 24)),
                child: screenSize.width < 380
                    ? _buildCompactExperimentLayout(textTheme, isSmallScreen)
                    : _buildFullExperimentLayout(
                        textTheme, isSmallScreen, isMediumScreen),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactExperimentLayout(
      TextTheme textTheme, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with icon and title
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentPink, AppColors.primaryPurple],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPink.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.science_rounded,
                size: isSmallScreen ? 20 : 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Science Lab",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                  Text(
                    "Share Your Experiments",
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.accentPink,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Compact description
        Text(
          "Share your discoveries! Upload experiments, earn badges, and inspire others.",
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
            fontSize: isSmallScreen ? 11 : 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 16),

        // Compact benefits
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCompactBenefit("🏆", "Badges", isSmallScreen),
            _buildCompactBenefit("⭐", "Fame", isSmallScreen),
            _buildCompactBenefit("🎁", "Rewards", isSmallScreen),
          ],
        ),

        const SizedBox(height: 16),

        // Compact CTA button
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentPink, AppColors.primaryPurple],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPink.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: Icon(Icons.rocket_launch_rounded,
                  size: isSmallScreen ? 16 : 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Share Discovery",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 10 : 12,
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to experiment submission
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullExperimentLayout(
      TextTheme textTheme, bool isSmallScreen, bool isMediumScreen) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMediumScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentPink, AppColors.primaryPurple],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPink.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.science_rounded,
                      size: isMediumScreen ? 22 : 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Science Lab",
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: isMediumScreen ? 16 : 18,
                            ),
                          ),
                        ),
                        Text(
                          "Share Your Experiments",
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.accentPink,
                            fontWeight: FontWeight.w600,
                            fontSize: isMediumScreen ? 12 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: isMediumScreen ? 14 : 18),

              // Description
              Text(
                "Got an experiment kit? Showcase your scientific discoveries! Upload videos, earn exclusive badges, and inspire fellow scientists.",
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  fontSize: isMediumScreen ? 12 : 13,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: isMediumScreen ? 16 : 20),

              // Benefits row
              Row(
                children: [
                  Flexible(
                      child: _buildBenefit("🏆", "Badges", isMediumScreen)),
                  const SizedBox(width: 12),
                  Flexible(child: _buildBenefit("⭐", "Fame", isMediumScreen)),
                  const SizedBox(width: 12),
                  Flexible(
                      child: _buildBenefit("🎁", "Rewards", isMediumScreen)),
                ],
              ),

              SizedBox(height: isMediumScreen ? 16 : 20),

              // CTA Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentPink, AppColors.primaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPink.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.rocket_launch_rounded,
                      size: isMediumScreen ? 18 : 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Share Your Discovery",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMediumScreen ? 13 : 15,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMediumScreen ? 18 : 22,
                      vertical: isMediumScreen ? 12 : 14,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // TODO: Navigate to experiment submission
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBenefit(String emoji, String label, bool isSmall) {
    return Column(
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: isSmall ? 16 : 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 9 : 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefit(String emoji, String label, bool isMedium) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMedium ? 8 : 10,
        vertical: isMedium ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentPink.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: isMedium ? 14 : 16),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMedium ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accentPink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickActions(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentOrange, AppColors.goldStar],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.explore_rounded, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Text(
              "Quick Actions",
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
          childAspectRatio: 0.9,
          children: [
            // Only show the specified options as per requirements
            _buildEnhancedActionCard(
              context,
              "Exam Tips",
              Icons.lightbulb_outline_rounded,
              AppColors.accentCyan,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExamSucceedScreen(),
                  ),
                );
              },
              description: "Scoring strategies",
            ),
            _buildEnhancedActionCard(
              context,
              "Career Feed",
              Icons.timeline_rounded,
              AppColors.accentPink,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CareerPathVisualizationScreen(),
                  ),
                );
              },
              description: "Explore your future pathway",
            ),
            _buildEnhancedActionCard(
              context,
              "Study Plan",
              Icons.calendar_today_outlined,
              AppColors.accentGreen,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CourseScreen(),
                  ),
                );
              },
              description: "Your complete roadmap",
            ),
            _buildEnhancedActionCard(
              context,
              "Key Notes",
              Icons.note_alt_rounded,
              AppColors.accentOrange,
              () {
                // Use Consumer to access providers in a widget function
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Consumer(
                      builder: (context, ref, child) {
                        // Access saved key notes from provider
                        final savedKeyNotes = ref.watch(keyNotesProvider);

                        return KeyNotesScreen(
                          // Pass the actual saved key notes
                          initialKeyNotes: savedKeyNotes,
                          // More descriptive title for the all notes view
                          chapterTitle: 'All Saved Notes',
                          fontFamily: 'Inter',
                          fontSizeMultiplier: 1.0,
                        );
                      },
                    ),
                  ),
                );
              },
              description: "Essential concepts",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? description,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(
                0.15), // Use the action color for better visibility
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.textSecondary.withOpacity(0.6),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced helper methods
  Widget _buildEnhancedShimmerCard({required double height, double? width}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceDark.withOpacity(0.8),
            AppColors.surfaceLight.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: AppColors.surfaceLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceDark,
        highlightColor: AppColors.surfaceLight.withOpacity(0.6),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedErrorCard(
    BuildContext context,
    String title,
    String message,
    VoidCallback onRetry,
  ) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.redAccent.withOpacity(0.15),
            Colors.redAccent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 32,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.redAccent.shade100,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh_rounded, size: 20),
            label: Text("Try Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              onRetry();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String message,
      IconData icon, Color color) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      color: AppColors.surfaceLight.withOpacity(0.8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1.3)),
                  const SizedBox(height: 6),
                  Text(message,
                      style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.9),
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(
      {required double height, double? width, double borderRadius = 12}) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: AppColors.surfaceLight.withOpacity(0.8),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildShimmerText(double width, double height,
      {double borderRadius = 4}) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: AppColors.surfaceLight.withOpacity(0.8),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(borderRadius)),
        margin: const EdgeInsets.symmetric(vertical: 2.5),
      ),
    );
  }

  Widget _buildShimmerAvatar(double radius) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: AppColors.surfaceLight.withOpacity(0.8),
      child:
          CircleAvatar(radius: radius, backgroundColor: AppColors.surfaceDark),
    );
  }

  Widget _buildErrorCard(
      BuildContext context, String message, VoidCallback onRetry) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      color: Colors.redAccent.withOpacity(0.2),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.redAccent.withOpacity(0.3),
        highlightColor: Colors.redAccent.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 34),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message,
                        style: textTheme.titleSmall?.copyWith(
                            color: Colors.redAccent.shade100,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Tap to retry",
                        style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.9))),
                  ],
                ),
              ),
              Icon(Icons.refresh_rounded,
                  color: AppColors.textSecondary.withOpacity(0.7), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTask(BuildContext context, StudyTask task) {
    final String? targetChapterId = task.chapter;
    // final String? firstTopicId = task.topic?.split(',').firstWhere((id) => id.isNotEmpty, orElse: () => null); // If you use initialTopicId

    if (targetChapterId != null && targetChapterId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChapterLandingScreen(
            subjectName: task.subject, // This is task.subject (the subjectId)
            chapterId: targetChapterId,
            // initialTopicId: firstTopicId, // Pass if ChapterLandingScreen uses it
          ),
        ),
      ).then((_) {
        // Optional: Invalidate providers if progress might have changed and you want immediate refresh
        // ProviderScope.containerOf(context).invalidate(todaysPersonalizedTasksProvider);
        // ProviderScope.containerOf(context).invalidate(studentSubjectProgressProvider(task.subject));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Task details for 'task.title}' are not specific enough to navigate."),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ));
    }
  }
}
