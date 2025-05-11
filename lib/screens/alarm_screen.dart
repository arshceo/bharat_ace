// lib/screens/alarm_screen.dart (New File)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/common/routes.dart'; // To navigate home

// Define channel and method name constants (match MainActivity.kt)
const MethodChannel _platformPermissionsChannel =
    MethodChannel('com.bharatace.app/permissions');
const String _stopAlarmSoundMethod = 'stopAlarmSound';
const String _dismissAlarmMethod = 'dismissAlarm';
const String _snoozeAlarmMethod = 'snoozeAlarm';

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  Future<void> _dismissAlarm(BuildContext context) async {
    print("AlarmScreen: Calling native dismissAlarm...");
    try {
      await _platformPermissionsChannel.invokeMethod(_dismissAlarmMethod);
      // Navigation happens natively now when service stops and launches MainActivity
      // Or we can still navigate here if needed. Let's keep it for clarity.
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.main_layout_nav, (route) => false);
      }
    } catch (e) {
      print("AlarmScreen: Generic error stopping alarm: $e");
    }
  }

  Future<void> _snoozeAlarm(BuildContext context) async {
    print("AlarmScreen: Calling native snoozeAlarm...");
    try {
      await _platformPermissionsChannel.invokeMethod(_snoozeAlarmMethod);
      // Optionally provide user feedback
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Alarm snoozed for 30 seconds."),
          duration: Duration(seconds: 2)));
      // Optionally update snooze count display if state is passed back from native (more complex)
    } catch (e) {
      print("Error invoking snoozeAlarm: $e"); /* Show error */
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Basic Dark Theme Colors (replace with AppTheme later)
    const Color darkBg = Color(0xFF12121F);
    const Color textPrimary = Color(0xFFEAEAEA);
    const Color primaryPurple = Color(0xFF8A2BE2);

    return Scaffold(
      backgroundColor: darkBg
          .withOpacity(0.9), // Semi-transparent background? Or solid color
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.alarm_on_rounded,
                    size: 80, color: Colors.redAccent.shade100),
                const SizedBox(height: 30),
                Text(
                  "Time for Your Tasks!", /* ... style ... */
                ),
                const SizedBox(height: 15),
                Text(
                  "Please complete your remaining BharatAce missions for today.", /* ... style ... */
                ),
                const SizedBox(height: 40),
                // --- Add Snooze Button ---
                TextButton.icon(
                  // Use TextButton for less emphasis than main action
                  icon: const Icon(Icons.snooze_rounded),
                  label: const Text("Snooze (30s)"),
                  onPressed: () => _snoozeAlarm(context),
                  // TODO: Disable if snooze count reaches 0 (needs state from service)
                ),
                const SizedBox(height: 20),
                // --- Dismiss Button ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: const Text("Start Learning Now"),
                  style: ElevatedButton.styleFrom(/* ... style ... */),
                  onPressed: () =>
                      _dismissAlarm(context), // Calls dismiss method
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
