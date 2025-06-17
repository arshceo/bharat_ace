import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScreenTimeState {
  final String? currentScreenName;
  final Duration currentScreenElapsedTime;
  final Map<String, Duration> screenTimeLog; // To store total time per screen

  ScreenTimeState({
    this.currentScreenName,
    this.currentScreenElapsedTime = Duration.zero,
    this.screenTimeLog = const {},
  });

  ScreenTimeState copyWith({
    String? currentScreenName,
    Duration? currentScreenElapsedTime,
    Map<String, Duration>? screenTimeLog,
    bool resetCurrentScreenName = false,
  }) {
    return ScreenTimeState(
      currentScreenName: resetCurrentScreenName
          ? null
          : currentScreenName ?? this.currentScreenName,
      currentScreenElapsedTime:
          currentScreenElapsedTime ?? this.currentScreenElapsedTime,
      screenTimeLog: screenTimeLog ?? this.screenTimeLog,
    );
  }
}

class ScreenTimeTrackerNotifier extends StateNotifier<ScreenTimeState>
    with WidgetsBindingObserver {
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  String? _activeScreenRouteName; // Internally tracks the current route name

  ScreenTimeTrackerNotifier() : super(ScreenTimeState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    super.didChangeAppLifecycleState(lifecycleState);
    if (_activeScreenRouteName == null && !_stopwatch.isRunning) return;

    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.detached) {
      _pauseTracking();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      _resumeTracking();
    }
  }

  void _pauseTracking() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
      // print("ScreenTimeTracker: Paused for $_activeScreenRouteName");
    }
  }

  void _resumeTracking() {
    if (_activeScreenRouteName != null && !_stopwatch.isRunning) {
      _stopwatch.start();
      _startPeriodicUpdates();
      // print("ScreenTimeTracker: Resumed for $_activeScreenRouteName");
    }
  }

  void screenChanged(String? newScreenRouteName) {
    // print("ScreenTimeTracker: screenChanged. Old: $_activeScreenRouteName, New: $newScreenRouteName");

    Map<String, Duration> updatedLog = Map.from(state.screenTimeLog);

    // 1. Finalize and log time for the PREVIOUS screen (if any)
    if (_activeScreenRouteName != null) {
      _stopwatch.stop();
      _timer?.cancel(); // Stop UI updates for the old screen's timer

      final Duration elapsedOnOldScreen = _stopwatch.elapsed;
      final Duration previousTotalTimeForOldScreen =
          updatedLog[_activeScreenRouteName!] ?? Duration.zero;
      updatedLog[_activeScreenRouteName!] =
          previousTotalTimeForOldScreen + elapsedOnOldScreen;
      // print("ScreenTimeTracker: Logged $_activeScreenRouteName: $elapsedOnOldScreen (total ${updatedLog[_activeScreenRouteName!]})");
    }

    _activeScreenRouteName =
        newScreenRouteName; // Update the internal current screen

    // 2. Handle the NEW screen
    if (newScreenRouteName != null) {
      _stopwatch.reset();
      _stopwatch.start();
      _startPeriodicUpdates(); // Start UI updates for the new screen's timer
      state = state.copyWith(
        currentScreenName: newScreenRouteName,
        currentScreenElapsedTime:
            Duration.zero, // Timer for new screen starts at 0
        screenTimeLog: updatedLog, // Persist the updated log
      );
      // print("ScreenTimeTracker: Now tracking $newScreenRouteName");
    } else {
      // No new screen is active (e.g. app exit or unnamed route)
      _stopwatch.stop();
      _stopwatch.reset();
      _timer?.cancel();
      state = state.copyWith(
        resetCurrentScreenName: true, // Sets currentScreenName to null
        currentScreenElapsedTime: Duration.zero,
        screenTimeLog: updatedLog, // Persist any final log entry
      );
      // print("ScreenTimeTracker: No active screen. Tracking fully stopped.");
    }
  }

  void _startPeriodicUpdates() {
    _timer?.cancel();
    if (_activeScreenRouteName != null && _stopwatch.isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_stopwatch.isRunning) {
          // Check again, might have been paused by lifecycle
          state = state.copyWith(currentScreenElapsedTime: _stopwatch.elapsed);
        } else {
          timer.cancel(); // Stop this periodic timer if stopwatch isn't running
        }
      });
    }
  }

  // For debugging or other UI elements if needed
  Duration getTotalTimeForScreen(String screenName) {
    return state.screenTimeLog[screenName] ?? Duration.zero;
  }
}

final screenTimeTrackerProvider =
    StateNotifierProvider<ScreenTimeTrackerNotifier, ScreenTimeState>((ref) {
  return ScreenTimeTrackerNotifier();
});
