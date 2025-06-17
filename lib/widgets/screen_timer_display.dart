import 'package:bharat_ace/screens/alarm_screen.dart' as HomeScreen2;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/services/screen_time_tracker_service.dart'; // Adjust path

class ScreenTimerDisplay extends ConsumerWidget {
  const ScreenTimerDisplay({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenTimeState = ref.watch(screenTimeTrackerProvider);

    // You can choose to display 00:00 or hide if no screen is active
    if (screenTimeState.currentScreenName == null &&
        screenTimeState.currentScreenElapsedTime == Duration.zero) {
      // return const SizedBox.shrink(); // Option to hide
      return const Padding(
        // Option to show 00:00
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined,
                size: 18, color: HomeScreen2.textSecondary),
            SizedBox(width: 4),
            Text("00:00"),
          ],
        ),
      );
    }

    // For debugging which screen is being tracked:
    // print("TimerDisplay: Screen: ${screenTimeState.currentScreenName}, Time: ${screenTimeState.currentScreenElapsedTime}");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined,
              size: 18, color: HomeScreen2.textSecondary), // Using your color
          const SizedBox(width: 4),
          Text(
            _formatDuration(screenTimeState.currentScreenElapsedTime),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: HomeScreen2.textSecondary),
          ),
          // Optional: Display current screen name for debugging
          // Text(" (${screenTimeState.currentScreenName?.split('/').last ?? 'N/A'})", style: TextStyle(fontSize: 10, color: HomeScreen2.textSecondary.withOpacity(0.7))),
        ],
      ),
    );
  }
}
