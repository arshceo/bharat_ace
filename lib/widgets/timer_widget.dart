// lib/widgets/timer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';

// Provider for current screen timer
final currentScreenTimerProvider =
    StateNotifierProvider<CurrentScreenTimerNotifier, Duration>((ref) {
  return CurrentScreenTimerNotifier();
});

class CurrentScreenTimerNotifier extends StateNotifier<Duration> {
  CurrentScreenTimerNotifier() : super(Duration.zero);

  DateTime? _startTime;
  String? _currentScreen;

  void startTimer(String screenName) {
    if (_currentScreen != screenName) {
      _stopCurrentTimer();
      _currentScreen = screenName;
      _startTime = DateTime.now();
      AppTimerManager.startScreenTimer(screenName);
      _updateTimer();
    }
  }

  void _stopCurrentTimer() {
    if (_currentScreen != null) {
      AppTimerManager.stopScreenTimer(_currentScreen!);
    }
    _startTime = null;
    _currentScreen = null;
  }

  void _updateTimer() {
    if (_startTime != null && _currentScreen != null) {
      state = AppTimerManager.getScreenTime(_currentScreen!);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _startTime != null) {
          _updateTimer();
        }
      });
    }
  }

  @override
  void dispose() {
    _stopCurrentTimer();
    super.dispose();
  }
}

class TimerAppBarWidget extends ConsumerWidget {
  final String screenName;

  const TimerAppBarWidget({
    super.key,
    required this.screenName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start timer when widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenTimerProvider.notifier).startTimer(screenName);
    });

    final currentTime = ref.watch(currentScreenTimerProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceXS,
        vertical: AppTheme.space2XS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXS),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: AppTheme.primary,
          ),
          const SizedBox(width: AppTheme.space2XS),
          Text(
            _formatDuration(currentTime),
            style: AppTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

class SessionTimerWidget extends ConsumerWidget {
  const SessionTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceXS,
        vertical: AppTheme.space2XS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXS),
        border: Border.all(
          color: AppTheme.success.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 14,
            color: AppTheme.success,
          ),
          const SizedBox(width: AppTheme.space2XS),
          Text(
            _formatDuration(AppTimerManager.getSessionTime()),
            style: AppTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.success,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
}
