// lib/widgets/study_session_topic_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/models/study_task_model.dart';
import 'study_session_manager.dart';
import 'discipline_system.dart';
import 'ai_quiz_system.dart';
import 'engaging_study_content_widget.dart';

class StudySessionTopicScreen extends ConsumerStatefulWidget {
  final StudyTask task;
  final int sessionIndex;
  final int totalTasks;

  const StudySessionTopicScreen({
    super.key,
    required this.task,
    required this.sessionIndex,
    required this.totalTasks,
  });

  @override
  ConsumerState<StudySessionTopicScreen> createState() =>
      _StudySessionTopicScreenState();
}

class _StudySessionTopicScreenState
    extends ConsumerState<StudySessionTopicScreen> {
  bool _breakDialogShown = false;

  @override
  void initState() {
    super.initState();
    // Start monitoring for break intervals
    _startBreakMonitoring();
  }

  void _startBreakMonitoring() {
    // Check for break dialog every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _checkForBreakDialog();
        _startBreakMonitoring();
      }
    });
  }

  void _checkForBreakDialog() {
    final sessionNotifier = ref.read(studySessionProvider.notifier);
    if (sessionNotifier.shouldShowBreakDialog() && !_breakDialogShown) {
      _showBreakDialog();
    }
  }

  void _showBreakDialog() {
    if (_breakDialogShown) return;

    setState(() {
      _breakDialogShown = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BreakReminderDialog(
        accumulatedBreakTime:
            Duration.zero, // Can be enhanced to show actual accumulated time
        onTakeBreak: () {
          Navigator.of(context).pop();
          ref.read(studySessionProvider.notifier).takeBreak();
          _showBreakModeDialog();
        },
        onSkipBreak: () {
          Navigator.of(context).pop();
          ref.read(studySessionProvider.notifier).skipBreak();
          setState(() {
            _breakDialogShown = false;
          });
        },
      ),
    );
  }

  void _showBreakModeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Break Time!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_cafe,
              size: 48,
              color: AppTheme.primary,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Take a 5-minute break to recharge.\nYou\'ve been studying hard!',
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(studySessionProvider.notifier).endBreak();
              setState(() {
                _breakDialogShown = false;
              });
            },
            child: Text('Back to Study'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during study session
        _showExitWarning();
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppTheme.white,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              color: Colors.black, // dark black background
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Timer icon only
                      const Icon(Icons.timer, color: Colors.amber),

                      // Center: Study Session title + subtitle
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Study Session',
                              style: AppTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.amber,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Task ${widget.sessionIndex + 1} of ${widget.totalTasks}',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade200,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right: Close button
                      IconButton(
                        onPressed: () => _showExitWarning(),
                        icon: const Icon(Icons.close, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: EngagingStudyContentWidget(
            task: widget.task,
            onContentCompleted: _completeTask,
          ),
        ),
      ),
    );
  }

  void _completeTask() {
    // First, start the AI quiz before marking task as complete
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIQuizScreen(
          task: widget.task,
          onQuizPassed: () {
            // Quiz passed, now complete the task
            Navigator.pop(context); // Close quiz screen
            _actuallyCompleteTask();
          },
          onQuizFailed: () {
            // Quiz failed, go back to topic content to review
            Navigator.pop(context); // Close quiz screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Please review the material and try the quiz again.'),
                backgroundColor: AppTheme.error,
              ),
            );
          },
        ),
      ),
    );
  }

  void _actuallyCompleteTask() {
    ref.read(studySessionProvider.notifier).completeCurrentTask();
    final sessionState = ref.read(studySessionProvider);

    if (sessionState.isCompleted) {
      // Show completion dialog and navigate back to home
      _showCompletionDialog();
    } else {
      // Navigate to next task
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudySessionTopicScreen(
            task: sessionState.currentTask!,
            sessionIndex: sessionState.currentTaskIndex,
            totalTasks: sessionState.tasks.length,
          ),
        ),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                size: 48,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Text(
              'Congratulations!',
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'You have successfully completed your study session! Great job staying focused.',
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray600,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            _buildSessionStats(),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate back to home screen (pop all study session screens)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                ),
              ),
              child: Text(
                'Continue Learning',
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStats() {
    final sessionState = ref.read(studySessionProvider);
    final duration = sessionState.sessionStartTime != null
        ? DateTime.now().difference(sessionState.sessionStartTime!)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Tasks Completed',
            '${sessionState.tasks.length}',
            Icons.task_alt,
          ),
          _buildStatItem(
            'Study Time',
            _formatDuration(duration),
            Icons.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primary,
          size: 24,
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          value,
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.gray900,
          ),
        ),
        Text(
          label,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.gray600,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _showExitWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Text(
          'Exit Study Session?',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Leaving now will end your study session. Your progress will be saved, but you won\'t complete all planned tasks.',
          style: AppTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continue Studying'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(studySessionProvider.notifier).endSession();
              Navigator.of(context).pop(); // Return to home
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('End Session'),
          ),
        ],
      ),
    );
  }
}
