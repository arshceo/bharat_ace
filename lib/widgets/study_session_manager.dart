// lib/widgets/study_session_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/theme/app_theme.dart';
import '../core/models/study_task_model.dart';
import '../core/models/buddy_group_model.dart';
import '../core/services/buddy_group_service.dart';
import 'professional_card.dart' as widgets;
import 'study_session_topic_screen.dart';
import '../screens/buddy_group/buddy_group_creation_screen.dart';
import 'add_buddy_bottom_sheet.dart';

// Study Session State
class StudySessionState {
  final bool isActive;
  final List<StudyTask> tasks;
  final int currentTaskIndex;
  final DateTime? sessionStartTime;
  final Duration totalStudyTime;
  final bool isOnBreak;
  final DateTime? lastBreakCheck;
  final int breaksTaken;
  final bool isCompleted;

  const StudySessionState({
    this.isActive = false,
    this.tasks = const [],
    this.currentTaskIndex = 0,
    this.sessionStartTime,
    this.totalStudyTime = Duration.zero,
    this.isOnBreak = false,
    this.lastBreakCheck,
    this.breaksTaken = 0,
    this.isCompleted = false,
  });

  StudySessionState copyWith({
    bool? isActive,
    List<StudyTask>? tasks,
    int? currentTaskIndex,
    DateTime? sessionStartTime,
    Duration? totalStudyTime,
    bool? isOnBreak,
    DateTime? lastBreakCheck,
    int? breaksTaken,
    bool? isCompleted,
  }) {
    return StudySessionState(
      isActive: isActive ?? this.isActive,
      tasks: tasks ?? this.tasks,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      totalStudyTime: totalStudyTime ?? this.totalStudyTime,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      lastBreakCheck: lastBreakCheck ?? this.lastBreakCheck,
      breaksTaken: breaksTaken ?? this.breaksTaken,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  StudyTask? get currentTask =>
      tasks.isNotEmpty && currentTaskIndex < tasks.length
          ? tasks[currentTaskIndex]
          : null;

  bool get hasMoreTasks => currentTaskIndex < tasks.length - 1;

  bool get isSessionCompleted => currentTaskIndex >= tasks.length;
}

// Study Session Provider
final studySessionProvider =
    StateNotifierProvider<StudySessionNotifier, StudySessionState>((ref) {
  return StudySessionNotifier();
});

class StudySessionNotifier extends StateNotifier<StudySessionState> {
  StudySessionNotifier() : super(const StudySessionState());

  void startSession(List<StudyTask> tasks) {
    if (tasks.isEmpty) return;

    state = StudySessionState(
      isActive: true,
      tasks: tasks,
      currentTaskIndex: 0,
      sessionStartTime: DateTime.now(),
    );

    // Enable app blocking
    _enableAppBlocking();

    // Start break monitoring
    _startBreakMonitoring();
  }

  void _startBreakMonitoring() {
    _checkBreakInterval();
  }

  void _checkBreakInterval() {
    if (!state.isActive || state.sessionStartTime == null || state.isOnBreak)
      return;

    final elapsed = DateTime.now().difference(state.sessionStartTime!);
    final lastBreakElapsed = state.lastBreakCheck != null
        ? DateTime.now().difference(state.lastBreakCheck!)
        : elapsed;

    // Show break dialog every 25 minutes
    if (lastBreakElapsed.inMinutes >= 25) {
      // This will be handled by the UI layer through a callback
      print('Break interval reached: ${lastBreakElapsed.inMinutes} minutes');
    }

    // Continue checking every minute
    Future.delayed(const Duration(minutes: 1), () {
      if (state.isActive && !state.isOnBreak) {
        _checkBreakInterval();
      }
    });
  }

  bool shouldShowBreakDialog() {
    if (!state.isActive || state.sessionStartTime == null || state.isOnBreak)
      return false;

    final lastBreakElapsed = state.lastBreakCheck != null
        ? DateTime.now().difference(state.lastBreakCheck!)
        : DateTime.now().difference(state.sessionStartTime!);

    return lastBreakElapsed.inMinutes >= 25;
  }

  void takeBreak() {
    state = state.copyWith(
      isOnBreak: true,
      lastBreakCheck: DateTime.now(),
      breaksTaken: state.breaksTaken + 1,
    );
  }

  void skipBreak() {
    state = state.copyWith(
      lastBreakCheck: DateTime.now(),
    );
  }

  void endBreak() {
    state = state.copyWith(isOnBreak: false);
  }

  void completeCurrentTask() {
    if (state.currentTask == null) return;

    if (state.hasMoreTasks) {
      state = state.copyWith(currentTaskIndex: state.currentTaskIndex + 1);
    } else {
      _completeSession();
    }
  }

  void _completeSession() {
    final sessionDuration = state.sessionStartTime != null
        ? DateTime.now().difference(state.sessionStartTime!)
        : Duration.zero;

    state = state.copyWith(
      isActive: false,
      isCompleted: true,
      totalStudyTime: sessionDuration,
    );

    // Disable app blocking
    _disableAppBlocking();

    // Save session data
    _saveSessionData(sessionDuration);
  }

  void pauseSession() {
    state = state.copyWith(isOnBreak: true);
  }

  void resumeSession() {
    state = state.copyWith(isOnBreak: false);
  }

  void endSession() {
    final sessionDuration = state.sessionStartTime != null
        ? DateTime.now().difference(state.sessionStartTime!)
        : Duration.zero;

    state = const StudySessionState();
    _disableAppBlocking();
    _saveSessionData(sessionDuration);
  }

  void _enableAppBlocking() {
    // Platform channel call to enable app blocking and start discipline service
    try {
      const platform = MethodChannel('com.bharatace.app/discipline');

      // Start discipline service with strict settings
      platform.invokeMethod('startDisciplineService', {
        'usageStatsGranted': true,
        'overlayGranted': true,
        'deviceAdminGranted': true,
        'strictMode': true, // Enable strict mode to prevent any app switching
        'blockAllApps': true, // Block all apps except our study app
        'emergencyOnly': false, // No emergency mode during study
      });

      print('Discipline service started for study session');
    } catch (e) {
      print('Error enabling strict app blocking: $e');
      // Show error to user that study session cannot start without proper permissions
      throw Exception(
          'Cannot start study session without proper permissions. Please grant all required permissions first.');
    }
  }

  void _disableAppBlocking() {
    // Platform channel call to disable app blocking and stop discipline service
    try {
      const platform = MethodChannel('com.bharatace.app/discipline');
      platform.invokeMethod('stopDisciplineService');
      print('Discipline service stopped');
    } catch (e) {
      print('Error disabling app blocking: $e');
    }
  }

  void _saveSessionData(Duration duration) {
    // Save to local storage for daily analytics
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    print('Session completed on $dateKey in ${duration.inMinutes} minutes');

    // TODO: Implement actual data saving to SharedPreferences or database
    // Example structure:
    // {
    //   "date": "2024-01-15",
    //   "totalStudyTime": 65, // minutes
    //   "sessionsCompleted": 1,
    //   "tasksCompleted": 3,
    //   "breaksTaken": 2
    // }

    _saveToLocalStorage(dateKey, duration);
  }

  Future<void> _saveToLocalStorage(String dateKey, Duration duration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getString('study_analytics_$dateKey');

      Map<String, dynamic> dayData = existingData != null
          ? jsonDecode(existingData)
          : {
              'date': dateKey,
              'totalStudyTime': 0,
              'sessionsCompleted': 0,
              'tasksCompleted': 0,
              'breaksTaken': 0,
            };

      // Update the analytics data
      dayData['totalStudyTime'] =
          (dayData['totalStudyTime'] ?? 0) + duration.inMinutes;
      dayData['sessionsCompleted'] = (dayData['sessionsCompleted'] ?? 0) + 1;
      dayData['tasksCompleted'] =
          (dayData['tasksCompleted'] ?? 0) + state.tasks.length;
      dayData['breaksTaken'] =
          (dayData['breaksTaken'] ?? 0) + state.breaksTaken;

      await prefs.setString('study_analytics_$dateKey', jsonEncode(dayData));

      // Also maintain a list of all analytics dates for easy retrieval
      final datesList = prefs.getStringList('study_analytics_dates') ?? [];
      if (!datesList.contains(dateKey)) {
        datesList.add(dateKey);
        await prefs.setStringList('study_analytics_dates', datesList);
      }

      print(
          'Analytics saved for $dateKey: ${duration.inMinutes} minutes, ${state.tasks.length} tasks, ${state.breaksTaken} breaks');
    } catch (e) {
      print('Error saving analytics: $e');
    }
  }

  // Method to retrieve analytics for a specific date
  Future<Map<String, dynamic>?> getAnalyticsForDate(String dateKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('study_analytics_$dateKey');
      return data != null ? jsonDecode(data) : null;
    } catch (e) {
      print('Error retrieving analytics: $e');
      return null;
    }
  }

  // Method to get all analytics dates
  Future<List<String>> getAllAnalyticsDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('study_analytics_dates') ?? [];
    } catch (e) {
      print('Error retrieving analytics dates: $e');
      return [];
    }
  }

  // Method to get total study time for the current week
  Future<int> getWeeklyStudyTime() async {
    try {
      final now = DateTime.now();
      int totalMinutes = 0;

      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final analytics = await getAnalyticsForDate(dateKey);
        if (analytics != null) {
          totalMinutes += (analytics['totalStudyTime'] as int? ?? 0);
        }
      }

      return totalMinutes;
    } catch (e) {
      print('Error calculating weekly study time: $e');
      return 0;
    }
  }
}

// Study Session Timer Widget
class StudySessionTimer extends ConsumerWidget {
  const StudySessionTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(studySessionProvider);

    if (!sessionState.isActive || sessionState.sessionStartTime == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final elapsed =
            DateTime.now().difference(sessionState.sessionStartTime!);

        return Container(
          margin: const EdgeInsets.all(AppTheme.spaceMD),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMD,
            vertical: AppTheme.spaceXS,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                _formatDuration(elapsed),
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Text(
                'Task ${sessionState.currentTaskIndex + 1}/${sessionState.tasks.length}',
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }
}

// Study Session Button Widget
class StudySessionButton extends ConsumerStatefulWidget {
  final List<StudyTask> tasks;

  const StudySessionButton({
    super.key,
    required this.tasks,
  });

  @override
  ConsumerState<StudySessionButton> createState() => _StudySessionButtonState();
}

class _StudySessionButtonState extends ConsumerState<StudySessionButton> {
  bool _showTasks = false;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(studySessionProvider);

    if (sessionState.isActive) {
      return _buildActiveSession();
    }

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
                Icons.play_circle_outline,
                size: 20,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Builder(builder: (context) {
                return Text(
                  "Study Session",
                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.gray900,
                  ),
                );
              }),
            ),
            IconButton(
              onPressed: () => setState(() => _showTasks = !_showTasks),
              icon: Builder(builder: (context) {
                return Icon(
                  _showTasks
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.gray600,
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLG),
        if (_showTasks) ...[
          _buildTasksList(),
          const SizedBox(height: AppTheme.spaceLG),
        ],
        _buildBuddyGroupButton(),
        const SizedBox(height: AppTheme.spaceMD),
        _buildStartButton(),
      ],
    );
  }

  Widget _buildActiveSession() {
    final sessionState = ref.watch(studySessionProvider);

    return widgets.ProfessionalCard(
      color: AppTheme.white,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.timer,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Session Active',
                      style: AppTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.gray900,
                      ),
                    ),
                    Text(
                      'Task ${sessionState.currentTaskIndex + 1} of ${sessionState.tasks.length}',
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEndSessionDialog(),
                  icon: Icon(Icons.stop, size: 18),
                  label: Text('End Session'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToCurrentTask(),
                  icon: Icon(Icons.arrow_forward, size: 18),
                  label: Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) {
          final task = widget.tasks[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spaceXS),
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: AppTheme.gray50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray900,
                        ),
                      ),
                      Text(
                        task.subject.toUpperCase(),
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.gray500,
                ),
                const SizedBox(width: AppTheme.space2XS),
                Text(
                  '${task.estimatedTimeMinutes}m',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.gray600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBuddyGroupButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showBuddyGroupCreation(),
        icon: Icon(Icons.group_add, size: 20),
        label: Builder(builder: (context) {
          return Text(
            'Make Your Buddy Group',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.primary,
            ),
          );
        }),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: BorderSide(color: AppTheme.primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
        ),
      ),
    );
  }

  void _showBuddyGroupCreation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddBuddyBottomSheet(
          onOptionSelected: (option) {
            // Handle different sharing options if needed
            if (option != 'maybe_later') {
              // Start a study session after sharing
              Future.delayed(const Duration(seconds: 1), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Invitation sent! Waiting for your buddy to join.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    final sessionState = ref.watch(studySessionProvider);

    if (sessionState.isCompleted) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppTheme.success),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppTheme.success, size: 24),
              const SizedBox(width: AppTheme.spaceMD),
              Text(
                'Completed Study Session',
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.tasks.isEmpty ? null : () => _startStudySession(),
        icon: Icon(Icons.play_arrow, size: 20),
        label: Text(
          'Start Study Session',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.white,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
        ),
      ),
    );
  }

  void _startStudySession() {
    // Check for buddy group first
    _checkBuddyGroupSession();
  }

  Future<void> _checkBuddyGroupSession() async {
    try {
      final buddyGroup = await BuddyGroupService.getCurrentUserGroup();

      if (buddyGroup != null) {
        // User has a buddy group, check if session can start
        _showGroupSessionDialog(buddyGroup);
      } else {
        // No buddy group, start individual session
        _showIndividualSessionDialog();
      }
    } catch (e) {
      print('Error checking buddy group: $e');
      _showIndividualSessionDialog();
    }
  }

  void _showGroupSessionDialog(BuddyGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Text(
          'Buddy Group Study Session',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'re part of "${group.name}" group!',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Group study sessions start when all buddies are live. This ensures everyone studies together!',
              style: AppTheme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              children: [
                Icon(Icons.group, color: AppTheme.primary, size: 18),
                const SizedBox(width: AppTheme.spaceXS),
                Text(
                  '${group.memberIds.length} members',
                  style: AppTheme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGroupSession(group);
            },
            child: Text('Join Group Session'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showIndividualSessionDialog();
            },
            child: Text('Study Alone'),
          ),
        ],
      ),
    );
  }

  void _showIndividualSessionDialog() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Text(
          'Start Study Session?',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will start a focused study session with:',
              style: AppTheme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              children: [
                Icon(Icons.lock, color: AppTheme.warning, size: 18),
                const SizedBox(width: AppTheme.spaceXS),
                Expanded(
                  child: Text(
                    'App blocking to prevent distractions',
                    style: AppTheme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Row(
              children: [
                Icon(Icons.timer, color: AppTheme.info, size: 18),
                const SizedBox(width: AppTheme.spaceXS),
                Expanded(
                  child: Text(
                    'Break reminders every 25 minutes',
                    style: AppTheme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.success, size: 18),
                const SizedBox(width: AppTheme.spaceXS),
                Expanded(
                  child: Text(
                    'Study time tracking',
                    style: AppTheme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(studySessionProvider.notifier)
                  .startSession(widget.tasks);
              _navigateToCurrentTask();
            },
            child: Text('Start'),
          ),
        ],
      ),
    );
  }

  Future<void> _startGroupSession(BuddyGroup group) async {
    try {
      // Extract task IDs from study tasks
      final taskIds = widget.tasks.map((task) => task.id).toList();

      // Create a group study session
      final success = await BuddyGroupService.startGroupStudySession(
        groupId: group.id,
        taskIds: taskIds,
      );

      if (success) {
        // For now, we'll simulate session ID - in a real app, you'd get it from the service
        const sessionId = 'temp_session_id';

        // Mark current user as ready
        await BuddyGroupService.markUserReady(sessionId);

        // Show waiting dialog
        _showWaitingForBuddiesDialog(sessionId);
      } else {
        // Failed to create session, fall back to individual
        _showError(
            'Failed to start group session. Starting individual session.');
        _showIndividualSessionDialog();
      }
    } catch (e) {
      print('Error starting group session: $e');
      _showError('Error starting group session. Starting individual session.');
      _showIndividualSessionDialog();
    }
  }

  void _showWaitingForBuddiesDialog(String sessionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Row(
          children: [
            Icon(Icons.group, color: AppTheme.primary),
            const SizedBox(width: AppTheme.spaceXS),
            Text('Waiting for Buddies'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Waiting for all group members to be ready...',
              style: AppTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Session will start automatically when everyone is ready!',
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Cancel group session and start individual
              _showIndividualSessionDialog();
            },
            child: Text('Study Alone Instead'),
          ),
        ],
      ),
    );

    // Listen for session readiness
    _listenForGroupSessionStart(sessionId);
  }

  void _listenForGroupSessionStart(String sessionId) {
    BuddyGroupService.listenToStudySession(sessionId).listen((session) async {
      if (session != null) {
        final allReady = await BuddyGroupService.areAllMembersReady(sessionId);

        if (allReady) {
          // Close waiting dialog and start session
          Navigator.of(context).pop();

          // Start the actual study session
          ref.read(studySessionProvider.notifier).startSession(widget.tasks);
          _navigateToCurrentTask();

          _showSuccess('Group study session started! 🎉');
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _navigateToCurrentTask() {
    final sessionState = ref.read(studySessionProvider);
    final currentTask = sessionState.currentTask;

    if (currentTask == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudySessionTopicScreen(
          task: currentTask,
          sessionIndex: sessionState.currentTaskIndex,
          totalTasks: sessionState.tasks.length,
        ),
      ),
    );
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Text('End Study Session?'),
        content: Text(
            'Are you sure you want to end your study session? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continue Studying'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(studySessionProvider.notifier).endSession();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('End Session'),
          ),
        ],
      ),
    );
  }
}
