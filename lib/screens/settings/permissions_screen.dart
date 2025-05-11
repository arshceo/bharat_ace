import 'dart:io'; // Import for Platform.isAndroid check
import 'dart:async';
import 'package:animate_do/animate_do.dart' show FadeIn, FadeInDown;
import 'package:bharat_ace/core/providers/tempTasksCompleteProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for PlatformException and MethodChannel
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'; // For standard permissions like Notifications

// --- Providers to track Permission Status ---
// Status for standard permissions
final notificationPermissionProvider =
    StateProvider.autoDispose<PermissionStatus>(
        (ref) => PermissionStatus.denied,
        name: 'notificationPermissionProvider');
// Status for special Android permissions (checked via Platform Channel)
final usageStatsPermissionProvider = StateProvider.autoDispose<bool>(
    (ref) => false,
    name: 'usageStatsPermissionProvider');
final overlayPermissionProvider = StateProvider.autoDispose<bool>(
    (ref) => false,
    name: 'overlayPermissionProvider');
final deviceAdminPermissionProvider = StateProvider.autoDispose<bool>(
    (ref) => false,
    name: 'deviceAdminPermissionProvider');
final exactAlarmPermissionProvider = StateProvider.autoDispose<bool>(
    (ref) => false,
    name: 'exactAlarmPermissionProvider'); // Android 12+

// --- Platform Channel Setup ---
// Use the same consistent channel name as defined in MainActivity.kt
const MethodChannel _platformPermissionsChannel =
    MethodChannel('com.bharatace.app/permissions');

const MethodChannel _disciplineChannel =
    MethodChannel('com.bharatace.app/discipline');

const EventChannel _disciplineEventsChannel =
    EventChannel('com.bharatace.app/discipline_events');

// Method names matching the native implementation
const String _checkUsageStatsMethod = 'checkUsageStatsPermission';
const String _requestUsageStatsMethod =
    'requestUsageStatsPermission'; // Opens Settings
const String _checkOverlayMethod = 'checkOverlayPermission';
const String _requestOverlayMethod =
    'requestOverlayPermission'; // Opens Settings
const String _checkDeviceAdminMethod = 'checkDeviceAdminActive';
const String _requestDeviceAdminMethod =
    'requestDeviceAdminActivation'; // Opens Activation screen
const String _checkExactAlarmMethod =
    'checkExactAlarmPermission'; // Android 12+
const String _requestExactAlarmMethod =
    'requestExactAlarmPermission'; // Opens Settings (Android 12+)
const String _scheduleTestAlarmMethod = 'scheduleTestAlarm';
const String _updatePermissionStatusMethod = 'updatePermissionStatus';

final distractionLimitProvider =
    StateProvider<Duration>((ref) => const Duration(minutes: 30));
final distractionUsedProvider = StateProvider<Duration>((ref) => Duration.zero);
final tasksCompleteProvider =
    StateProvider<bool>((ref) => false); // Tracks status received from service
final isBlockingActiveProvider =
    StateProvider<bool>((ref) => false); // Tracks status received from service

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _isChecking = false; // To show loading indicator during checks

  bool _currentUsageStatus = false;
  bool _currentOverlayStatus = false;
  bool _currentAdminStatus = false;
  bool _currentAlarmStatus = false;

  StreamSubscription? _eventSubscription; // To listen to native events

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure context is available safely after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Double check mounted status
        _checkAllPermissions();
        _listenToDisciplineEvents();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel(); // Cancel listener
    super.dispose();
  }

  void _listenToDisciplineEvents() {
    _eventSubscription = _disciplineEventsChannel
        .receiveBroadcastStream()
        .listen((dynamic event) {
      print("[Flutter PermissionsScreen] Received Event: $event");
      if (event is Map) {
        // Update Riverpod state providers based on event data
        final Map<Object?, Object?> data = event; // Cast to Map
        if (mounted) {
          // Check mounted before updating state
          ref.read(distractionLimitProvider.notifier).state = Duration(
              milliseconds:
                  (data['limitMillis'] as int? ?? 1800000)); // Default 30 min
          ref.read(distractionUsedProvider.notifier).state =
              Duration(milliseconds: (data['cumulativeMillis'] as int? ?? 0));
          ref.read(tasksCompleteProvider.notifier).state =
              data['tasksComplete'] as bool? ?? false;
          ref.read(isBlockingActiveProvider.notifier).state =
              data['isBlocking'] as bool? ?? false;
        }
      }
    }, onError: (dynamic error) {
      print("[Flutter PermissionsScreen] Error receiving event: $error");
    }, onDone: () {
      print("[Flutter PermissionsScreen] Discipline event stream closed.");
    });
    print("[Flutter PermissionsScreen] Subscribed to Discipline Events.");
  }

  Future<void> _resetUsageTime() async {
    print("Requesting usage time reset...");
    try {
      // Need a new platform channel method for this
      await _disciplineChannel.invokeMethod('resetDailyUsage');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Daily usage time reset.")));
      }
      // Optionally trigger a re-check to update UI immediately
      // ref.read(disciplineControllerProvider..).forceCheck(); // If controller exists
      // Or wait for next periodic update from service event channel
    } catch (e) {
      print("Error resetting usage: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error resetting time: $e"),
            backgroundColor: Colors.red));
      }
    }
  }

  // --- Check All Permissions ---
  Future<void> _checkAllPermissions() async {
    if (!mounted) return;
    setState(() => _isChecking = true);
    print("Checking all permissions...");

    // Notifications (Standard)
    final notif = await Permission.notification.status;
    if (mounted) {
      ref.read(notificationPermissionProvider.notifier).state = notif;
    }

    if (Platform.isAndroid) {
      // Check special permissions and store results locally
      _currentUsageStatus = await _invokeBoolMethod(_checkUsageStatsMethod);
      _currentOverlayStatus = await _invokeBoolMethod(_checkOverlayMethod);
      _currentAdminStatus = await _invokeBoolMethod(_checkDeviceAdminMethod);
      _currentAlarmStatus = await _invokeBoolMethod(
          _checkExactAlarmMethod); // TODO: Version check

      if (mounted) {
        // Update Riverpod providers for UI display
        ref.read(usageStatsPermissionProvider.notifier).state =
            _currentUsageStatus;
        ref.read(overlayPermissionProvider.notifier).state =
            _currentOverlayStatus;
        ref.read(deviceAdminPermissionProvider.notifier).state =
            _currentAdminStatus;
        ref.read(exactAlarmPermissionProvider.notifier).state =
            _currentAlarmStatus;
      }
    }
    print(
        "Permission check complete. Usage=$_currentUsageStatus, Overlay=$_currentOverlayStatus, Admin=$_currentAdminStatus, Alarm=$_currentAlarmStatus");
    if (mounted) setState(() => _isChecking = false);
  }

  // --- Method Channel Invocation Helpers ---
  Future<bool> _invokeBoolMethod(String methodName) async {
    if (!Platform.isAndroid) return false;
    print("Invoking native method (bool): $methodName");
    try {
      final bool? result =
          await _platformPermissionsChannel.invokeMethod<bool>(methodName);
      print("Native method '$methodName' returned: $result");
      return result ?? false;
    } on PlatformException catch (e) {
      print("PlatformException invoking $methodName: ${e.message}");
      return false;
    } catch (e) {
      print("Error invoking $methodName: $e");
      return false;
    }
  }

  Future<void> _invokeVoidMethod(String methodName,
      [Map<String, dynamic>? args]) async {
    if (!Platform.isAndroid) return;
    print("Invoking native method (void): $methodName");
    try {
      await _platformPermissionsChannel.invokeMethod(methodName, args);
    } on PlatformException catch (e) {
      print("PlatformException invoking $methodName: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error opening settings: ${e.message}"),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    } catch (e) {
      print("Error invoking $methodName: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Could not perform action: $e"),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    }
  }

  // --- Helper to send permission status to service ---

  // Future<void> _sendPermissionStatusToService(
  //   BuildContext context, {
  //   bool? usageGranted,
  //   bool? overlayGranted,
  //   bool? adminActive,
  //   bool? exactAlarmGranted,
  //   // Add other permissions here if the service needs to know their status
  // }) async {
  //   // Only proceed if running on Android
  //   if (!Platform.isAndroid) {
  //     print("PermissionsScreen: Skipping sending status, not on Android.");
  //     return;
  //   }
  //   // Build the arguments map dynamically based on provided statuses
  //   final args = <String, bool?>{};
  //   if (usageGranted != null) args['usageStatsGranted'] = usageGranted;
  //   if (overlayGranted != null) args['overlayGranted'] = overlayGranted;
  //   if (adminActive != null) {
  //     args['adminActive'] = adminActive; // Example key name
  //   }
  //   if (exactAlarmGranted != null) {
  //     args['exactAlarmGranted'] = exactAlarmGranted; // Example key name
  //   }
  //   // Don't send if no relevant status was provided
  //   if (args.isEmpty) {
  //     print(
  //         "PermissionsScreen: No relevant permission status provided to send.");
  //     return;
  //   }
  //   print(
  //       "PermissionsScreen: Sending permission status update to native channel '${_disciplineChannel.name}' method 'updateServicePermissionStatus': $args");
  //   try {
  //     // Invoke the method on the platform channel defined in MainActivity.kt
  //     await _disciplineChannel.invokeMethod(
  //         'updateServicePermissionStatus', args);
  //     print("PermissionsScreen: Status update SENT to native successfully.");
  //   } on PlatformException catch (e) {
  //     // Handle potential errors if the method doesn't exist on the native side
  //     // or if the native code throws an error.
  //     print(
  //         "PermissionsScreen: PlatformException sending permission status update: ${e.code} - ${e.message}");
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //           content: Text(
  //               "Error communicating service status: ${e.message ?? 'Unknown platform error'}"),
  //           backgroundColor: Theme.of(context).colorScheme.error));
  //     }
  //   } catch (e) {
  //     // Handle any other unexpected errors during the platform channel call
  //     print(
  //         "PermissionsScreen: Generic error sending permission status update: $e");
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //           content: Text("Error updating background service: ${e.toString()}"),
  //           backgroundColor: Theme.of(context).colorScheme.error));
  //     }
  //   }
  // }

  // --- Individual Permission Checkers & Requesters ---

  Future<void> _startServiceWithPermissions() async {
    print("Starting Discipline Service...");
    // Prepare settings AND current permission status to send
    Map<String, dynamic> serviceArgs = {
      // Example Settings (Fetch from provider/state later)
      "blockedApps": ["com.instagram.android", "app.phantom"],
      "limitMinutes": 25, // Low limit for testing
      "block": true,
      "isActive": true,
      // Pass CURRENT permission statuses
      "usageStatsGranted": _currentUsageStatus,
      "overlayGranted": _currentOverlayStatus,
      "adminActive": _currentAdminStatus,
      // Pass others if service needs them
    };
    try {
      await _disciplineChannel.invokeMethod(
          'startDisciplineService', serviceArgs);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Discipline Service Started (or ensured running)")));
      }
    } catch (e) {
      print("Error starting service: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error starting service: $e"),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _stopService() async {
    print("Stopping Discipline Service...");
    try {
      await _disciplineChannel.invokeMethod('stopDisciplineService');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Discipline Service Stopped")));
      }
    } catch (e) {
      print("Error stopping service: $e");
    }
  }

  // 1. Notifications (Standard using permission_handler)
  Future<void> _checkNotificationPermission() async {
    if (!mounted) return;
    final status = await Permission.notification.status;
    print("Notification Check: Status = ${status.name}");
    if (mounted) {
      ref.read(notificationPermissionProvider.notifier).state = status;
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (!mounted) return;
    final status = await Permission.notification.request();
    if (mounted) {
      ref.read(notificationPermissionProvider.notifier).state = status;
    }
    _showSnackbarResult("Notification", status.toString());
  }

  // 2. Usage Stats (Uses Platform Channel)
  Future<void> _checkUsageStatsPermission() async {
    if (!mounted || !Platform.isAndroid) return;
    print(
        "[Flutter PermissionsScreen] Calling native '$_checkUsageStatsMethod'...");
    final bool granted =
        await _invokeBoolMethod(_checkUsageStatsMethod); // Call native CHECK
    print(
        "[Flutter PermissionsScreen] Native '$_checkUsageStatsMethod' returned: $granted");
    if (mounted) {
      ref.read(usageStatsPermissionProvider.notifier).state = granted;
      // *** Send the checked status to the service ***
      // await _sendPermissionStatusToService(context,
      //     usageGranted: granted); // Ensure context is available
    }
  }

  Future<void> _requestUsageStatsPermission() async {
    if (!mounted || !Platform.isAndroid) return;
    await _invokeVoidMethod(_requestUsageStatsMethod); // Opens settings
    _showInfoDialog("Usage Stats Access", "..."); // Guide user
    await Future.delayed(
        const Duration(seconds: 3)); // Give time to return/grant
    await _checkUsageStatsPermission();
  }

  // 3. Overlay (Uses Platform Channel)
  Future<void> _checkOverlayPermission() async {
    if (!mounted || !Platform.isAndroid) return;
    final bool granted = await _invokeBoolMethod(_checkOverlayMethod);
    if (mounted) ref.read(overlayPermissionProvider.notifier).state = granted;
  }

  Future<void> _requestOverlayPermission() async {
    if (!mounted || !Platform.isAndroid) return;
    print("Requesting Overlay via platform channel...");
    await _invokeVoidMethod(
        _requestOverlayMethod); // Native code opens settings
    _showInfoDialog("Display Over Other Apps",
        "Please find BharatAce in the list and enable 'Display over other apps'. You may need to tap 'Re-Check Permissions' after returning.");
    await Future.delayed(const Duration(seconds: 1));
    _checkOverlayPermission();
  }

  // 4. Device Administrator (Uses Platform Channel)
  Future<void> _checkDeviceAdminPermission() async {
    if (!mounted || !Platform.isAndroid) return;
    final bool granted = await _invokeBoolMethod(_checkDeviceAdminMethod);
    if (mounted) {
      ref.read(deviceAdminPermissionProvider.notifier).state = granted;
    }
  }

  Future<void> _requestDeviceAdminPermission() async {
    if (!mounted || !Platform.isAndroid) return;
    print("Requesting Device Admin via platform channel...");
    _showInfoDialog("Device Administrator Activation",
        "App control features require Device Administrator rights. Please activate BharatAce on the next screen. This allows the app to help manage focus time but does NOT grant access to wipe data (unless specifically requested in policies - which we haven't here).");
    await Future.delayed(
        const Duration(milliseconds: 500)); // Allow user to read dialog
    await _invokeVoidMethod(
        _requestDeviceAdminMethod); // Native code launches activation screen
    // Re-check status after user returns from the system screen
    await Future.delayed(const Duration(seconds: 2));
    _checkDeviceAdminPermission();
  }

  // 5. Schedule Exact Alarm (Uses Platform Channel)
  Future<void> _checkExactAlarmPermission() async {
    if (!mounted || !Platform.isAndroid) return;
    // Note: Native check should handle API level >= 31 (Android 12)
    final bool granted = await _invokeBoolMethod(_checkExactAlarmMethod);
    if (mounted) {
      ref.read(exactAlarmPermissionProvider.notifier).state = granted;
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    if (!mounted || !Platform.isAndroid) return;
    print("Requesting Exact Alarm via platform channel...");
    _showInfoDialog("Alarms & Reminders Permission",
        "Urgent task reminders require permission to schedule exact alarms (Android 12+). Please allow this in the upcoming settings screen.");
    await Future.delayed(const Duration(milliseconds: 500));
    await _invokeVoidMethod(
        _requestExactAlarmMethod); // Native code opens settings
    await Future.delayed(const Duration(seconds: 2));
    _checkExactAlarmPermission();
  }

  // --- Helper to show snackbar result ---
  void _showSnackbarResult(String permissionName, String statusString) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$permissionName Permission: $statusString"),
        duration: const Duration(seconds: 2)));
  }

  // --- Helper to show info dialog before opening settings ---
  Future<void> _showInfoDialog(String title, String content) async {
    if (!mounted) return;
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"))
              ],
            ));
  }

  // *** NEW: Function to trigger the test alarm ***
  Future<void> _triggerTestAlarm() async {
    int delaySeconds = 10; // Trigger after 10 seconds
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("Attempting to schedule alarm in $delaySeconds seconds..."),
        duration: const Duration(seconds: 3)));
    // Call the native method via platform channel, passing arguments
    await _invokeVoidMethod(
        _scheduleTestAlarmMethod, {'triggerSeconds': delaySeconds});
  }

  @override
  Widget build(BuildContext context) {
    // Watch the providers
    final notifStatus = ref.watch(notificationPermissionProvider);
    final usageStatus = ref.watch(usageStatsPermissionProvider);
    final overlayStatus = ref.watch(overlayPermissionProvider);
    final adminStatus = ref.watch(deviceAdminPermissionProvider);
    final alarmStatus = ref.watch(exactAlarmPermissionProvider);

    final limit = ref.watch(distractionLimitProvider);
    final used = ref.watch(distractionUsedProvider);
    final tasksDone =
        ref.watch(tasksCompleteProvider); // Use this from service event
    final isBlocked =
        ref.watch(isBlockingActiveProvider); // Use this from service event
    final Duration remaining = limit > used ? limit - used : Duration.zero;

    // Only show Android-specific permissions on Android
    final bool isAndroid = Platform.isAndroid;

    return Scaffold(
      appBar: AppBar(title: const Text("Required Permissions")),
      body: RefreshIndicator(
        onRefresh: _checkAllPermissions,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (_isChecking) // Show loading indicator at top while checking
              const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Center(child: LinearProgressIndicator())),
            FadeInDown(
              child: Card(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text("Distraction Time Status",
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Text("Limit: ${_formatDuration(limit)}"),
                      Text("Used Today: ${_formatDuration(used)}"),
                      Text("Remaining: ${_formatDuration(remaining)}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: remaining > Duration.zero
                                  ? Colors.greenAccent
                                  : Colors.redAccent)),
                      const SizedBox(height: 5),
                      Text("Tasks Complete: ${tasksDone ? 'Yes' : 'No'}"),
                      Text(
                          "App Blocking Active: ${isBlocked ? 'Yes' : 'No'}"), // Show block status
                      const SizedBox(height: 10),
                      ElevatedButton(
                          onPressed: _resetUsageTime,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade800),
                          child: const Text("Reset Daily Time (DEV)"))
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
                "BharatAce needs certain permissions for reminders and discipline features. Please grant them for the best experience.",
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),

            // --- Permission Tiles ---
            _buildPermissionTile(
                context: context,
                title: "Notifications",
                subtitle: "For reminders and alerts.",
                isGranted: notifStatus == PermissionStatus.granted,
                onRequest: _requestNotificationPermission,
                statusText: notifStatus.name),
            if (isAndroid) ...[
              const Divider(),
              _buildPermissionTile(
                  context: context,
                  title: "Usage Stats Access",
                  subtitle: "Needed for app usage limits.",
                  isGranted: usageStatus,
                  onRequest: _requestUsageStatsPermission,
                  statusText: usageStatus ? "Enabled" : "Disabled",
                  isSpecial: true),
              const Divider(),
              _buildPermissionTile(
                  context: context,
                  title: "Display Over Other Apps",
                  subtitle: "Needed for focus/blocking screens.",
                  isGranted: overlayStatus,
                  onRequest: _requestOverlayPermission,
                  statusText: overlayStatus ? "Allowed" : "Not Allowed",
                  isSpecial: true),
              const Divider(),
              _buildPermissionTile(
                  context: context,
                  title: "Device Administrator",
                  subtitle: "Required for app control features.",
                  isGranted: adminStatus,
                  onRequest: _requestDeviceAdminPermission,
                  statusText: adminStatus ? "Active" : "Inactive",
                  isSpecial: true),
              const Divider(),
              // TODO: Conditionally show Exact Alarm based on Android version >= 12 (API 31)
              // This requires getting the Android SDK version, e.g., using `device_info_plus` package
              _buildPermissionTile(
                  context: context,
                  title: "Alarms & Reminders (Android 12+)",
                  subtitle: "Needed for urgent, non-dismissible alarms.",
                  isGranted: alarmStatus,
                  onRequest: _requestExactAlarmPermission,
                  statusText: alarmStatus ? "Allowed" : "Not Allowed",
                  isSpecial: true),
              const Divider(),
            ],

            const SizedBox(height: 30),
            Center(
                child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Re-Check All Permissions"),
              onPressed: _isChecking ? null : _checkAllPermissions,
            )), // Disable button while checking
            const SizedBox(height: 10),
            // *** ADD TEST ALARM BUTTON ***
            if (isAndroid) ...[
              // Only show on Android
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.alarm_add),
                  label: const Text("Schedule Test Alarm (10s)"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700),
                  // Only enable if exact alarm permission seems granted (based on provider)
                  onPressed: alarmStatus ? _triggerTestAlarm : null,
                ),
              ),
              if (!alarmStatus)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    "(Enable 'Alarms & Reminders' permission first)",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ),
              ElevatedButton(
                onPressed: _startServiceWithPermissions,
                child: Text("Start Discipline Service (DEV)"),
              ),
              ElevatedButton(
                onPressed: _stopService,
                child: Text("Stop Discipline Service (DEV)"),
              ),
              // Temporary Toggle for Task Completion
              SwitchListTile(
                title: const Text("Simulate Tasks Complete"),
                value: ref.watch(
                    tempTasksCompleteProvider), // Need a temp state provider
                onChanged: (isComplete) async {
                  ref.read(tempTasksCompleteProvider.notifier).state =
                      isComplete;
                  try {
                    await _disciplineChannel.invokeMethod(
                        'setTasksCompleteStatus', {'isComplete': isComplete});
                  } catch (e) {
                    print("Error setting task status: $e");
                  }
                },
              ),
            ],
            // *** END TEST ALARM BUTTON ***
            if (isAndroid)
              const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Note: Some permissions require enabling them manually in your phone's Settings screen.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  )),
          ],
        ),
      ),
    );
  }

  // Helper to format Duration
  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    // return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds"; // HH:MM:SS
    return "$twoDigitMinutes min $twoDigitSeconds sec"; // MM:SS
  }

  // --- Helper Widget for Permission Tile ---
  Widget _buildPermissionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onRequest,
    required String statusText,
    bool isSpecial = false,
  }) {
    return ListTile(
      leading: FadeIn(
          // Add animation
          child: Icon(
              isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isGranted ? Colors.green.shade400 : Colors.orange.shade600,
              size: 28)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600)), // Slightly dimmer subtitle
      trailing: ElevatedButton(
        onPressed: isGranted ? null : onRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: isGranted
              ? Colors.grey.shade300
              : Theme.of(context).colorScheme.primary,
          foregroundColor: isGranted
              ? Colors.black54
              : Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          textStyle: const TextStyle(fontSize: 12),
          minimumSize: const Size(80, 34), // Set min size
        ),
        child:
            Text(isGranted ? "GRANTED" : (isSpecial ? "Settings" : "Request")),
      ),
    );
  }
} // End of _PermissionsScreenState
