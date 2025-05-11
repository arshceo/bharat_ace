// --- android/app/src/main/kotlin/com/your_package_name/MainActivity.kt (COMPLETE & CORRECTED) ---
package com.example.bharat_ace // *** REPLACE with your actual package name ***

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel // Import for EventChannel
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import androidx.core.content.ContextCompat
import android.content.ComponentName
import android.app.AlarmManager
import androidx.annotation.RequiresApi
import android.util.Log
import android.widget.Toast
import android.app.PendingIntent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification
import android.app.usage.UsageStatsManager // Import UsageStatsManager
import android.content.BroadcastReceiver // Import for listening to service broadcasts
import android.content.IntentFilter // Import for listening to service broadcasts
import com.example.bharat_ace.AlarmReceiver
import com.example.bharat_ace.DisciplineService
import com.example.bharat_ace.AppDeviceAdminReceiver
import java.util.HashMap

class MainActivity: FlutterActivity() {
    // Define Channel Names
    private val PERMISSIONS_CHANNEL = "com.bharatace.app/permissions"
    private val DISCIPLINE_CHANNEL = "com.bharatace.app/discipline"
    private val LIFECYCLE_CHANNEL = "com.bharatace.app/lifecycle"
    private val DISCIPLINE_EVENTS_CHANNEL = "com.bharatace.app/discipline_events"

    // Member variable for Device Admin Component Name
    private lateinit var deviceAdminReceiverComponent: ComponentName

    private val ALARM_CHANNEL_ID = AlarmReceiver.CHANNEL_ID // Use constant from AlarmReceiver

    // Member variable to store initial route from alarm intent
    private var initialRoute: String? = null
    private var disciplineEventSink: EventChannel.EventSink? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d("MainActivity", "onNewIntent called.")
        // Handle intent if app is already running and launched again (e.g., from notification)
        handleIntent(intent)
        // Optional: If Flutter needs to react immediately to this new intent while running
        // you might need another platform channel call here to notify Flutter.
    }

    // Processes the launch/new intent to see if it came from the alarm
    private fun handleIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("alarm_triggered", false) == true) {
             Log.d("MainActivity", "Launched from Alarm Intent (handleIntent).")
             // Store the target route from the intent's extra
             initialRoute = intent.getStringExtra("navigate_to") // Fetch the route path
             Log.d("MainActivity", "Stored initialRoute: $initialRoute")
         } else {
             // Clear initial route if not launched from alarm
             initialRoute = null
             Log.d("MainActivity", "Not launched from Alarm Intent (handleIntent).")
         }
     }

     private var usageStatsManager: UsageStatsManager? = null
     
     override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "onCreate called.")
        handleIntent(intent) // Check if launched from alarm

        // Initialize UsageStatsManager here
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager?
        if (usageStatsManager == null) { Log.e("MainActivity", "Failed to get UsageStatsManager in onCreate!")}

        // Initialize ComponentName BEFORE using it in permission checks if they happen early
        deviceAdminReceiverComponent = ComponentName(this.applicationContext, AppDeviceAdminReceiver::class.java)

        // Create notification channels on startup
        AlarmReceiver.createNotificationChannelIfNeeded(this)
        DisciplineService.createNotificationChannelIfNeeded(this)

        // Register BroadcastReceiver to get updates from DisciplineService
        registerDisciplineStatusUpdateReceiver()
    }

    // --- Flutter Engine Configuration ---
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("MainActivity", "configureFlutterEngine called.")

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, DISCIPLINE_EVENTS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d("MainActivity", "Flutter listener started for Discipline Events.")
                    disciplineEventSink = events // Store sink to send events
                }

                override fun onCancel(arguments: Any?) {
                     Log.d("MainActivity", "Flutter listener cancelled for Discipline Events.")
                    disciplineEventSink = null // Clear sink
                }
            }
        )

        // Initialize ComponentName using the application context
        deviceAdminReceiverComponent = ComponentName(this.applicationContext, AppDeviceAdminReceiver::class.java)

        // --- Permissions/Alarm Channel Handler ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            Log.d("MainActivity", "Permissions Channel call received: ${call.method}")
            when (call.method) {
                // --- Permission Checks ---
                "checkUsageStatsPermission" -> result.success(hasUsageStatsPermission())
                "checkOverlayPermission" -> result.success(hasOverlayPermission())
                "checkDeviceAdminActive" -> result.success(isDeviceAdminActive())
                "checkExactAlarmPermission" -> { if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { result.success(hasExactAlarmPermission()) } else { result.success(true) } }
                // --- Permission Requests ---
                "requestUsageStatsPermission" -> { openUsageAccessSettings(); result.success(null) }
                "requestOverlayPermission" -> { openOverlaySettings(); result.success(null) }
                "requestDeviceAdminActivation" -> { requestDeviceAdminActivation(); result.success(null) }
                "requestExactAlarmPermission" -> { openExactAlarmSettings(); result.success(null) }
                // --- Test Alarm Scheduling ---
                 "scheduleTestAlarm" -> {
                     val triggerSeconds = call.argument<Int>("triggerSeconds") ?: 10
                     val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager?
                     if (alarmManager == null) { result.error("SERVICE_ERROR", "AlarmManager not available.", null); return@setMethodCallHandler }
                     if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) { result.error("PERMISSION_DENIED", "Exact Alarm permission denied.", null); return@setMethodCallHandler }
                     val triggerAtMillis = System.currentTimeMillis() + triggerSeconds * 1000L
                     val intent = Intent(this, AlarmReceiver::class.java) // Target the Receiver
                     val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) { PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE } else { PendingIntent.FLAG_UPDATE_CURRENT }
                     val pendingIntent = PendingIntent.getBroadcast(this, 1, intent, flags) // Use unique request code
                     try { alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent); Log.d("MainActivity", "Scheduled test alarm OK"); result.success(true) }
                     catch (e: Exception) { Log.e("MainActivity", "Error scheduling alarm", e); result.error("ALARM_ERROR", "Failed to schedule alarm: ${e.message}", e.stackTraceToString()) }
                 }

                // --- Commands now target DisciplineService ---
                "stopAlarmSound", "dismissAlarm" -> {
                    Log.d("MainActivity", "Req ${call.method} -> Sending DISMISS Action.")
                    val serviceIntent = Intent(this, DisciplineService::class.java)
                    serviceIntent.action = DisciplineService.ACTION_DISMISS // Use constant
                    try { startService(serviceIntent); result.success(null) } catch (e: Exception) { result.error("SERVICE_ERROR", "Failed dismiss command", e.message) }
                }
                //  "snoozeAlarm" -> {
                //     Log.d("MainActivity", "Req ${call.method} -> Sending SNOOZE Action.")
                //       val serviceIntent = Intent(this, DisciplineService::class.java)
                //       serviceIntent.action = DisciplineService.ACTION_SNOOZE // Use constant
                //       try { startService(serviceIntent); result.success(null) } catch (e: Exception) { result.error("SERVICE_ERROR", "Failed snooze command", e.message) }
                //  }
                else -> { Log.w("MainActivity", "Method '${call.method}' not implemented on $PERMISSIONS_CHANNEL."); result.notImplemented() }
            }
        } // End Permissions Channel

        // --- Discipline Service Channel Handler ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DISCIPLINE_CHANNEL).setMethodCallHandler { call, result ->
           val serviceIntent = Intent(this, DisciplineService::class.java)
           when(call.method) {
                "startDisciplineService" -> {
                   val args = call.arguments as? Map<*, *>
                   if (args != null) {
                       _passSettingsToIntent(serviceIntent, args)
                       serviceIntent.putExtra("initialUsageStatsGranted", args["usageStatsGranted"] as? Boolean ?: false)
                       serviceIntent.putExtra("initialOverlayGranted", args["overlayGranted"] as? Boolean ?: false)
                   }
                   try { ContextCompat.startForegroundService(this, serviceIntent); result.success(true) }
                   catch (e: Exception) { result.error("SERVICE_ERROR", "Failed start service", e.message)}
               }
                "stopDisciplineService" -> { serviceIntent.action = DisciplineService.ACTION_STOP_SERVICE; try { startService(serviceIntent); result.success(true) } catch (e: Exception) { result.error("SERVICE_ERROR", "Failed stop", e.message)}}
                "updateDisciplineSettings" -> { val settings = call.arguments as? Map<*, *>; serviceIntent.action = DisciplineService.ACTION_UPDATE_SETTINGS; if (settings != null) { _passSettingsToIntent(serviceIntent, settings) }; try { startService(serviceIntent); result.success(true) } catch (e: Exception) { result.error("SERVICE_ERROR", "Failed update settings", e.message)}}
                "setTasksCompleteStatus" -> { val isComplete = call.argument<Boolean>("isComplete") ?: false; serviceIntent.action = if(isComplete) DisciplineService.ACTION_TASKS_COMPLETE else DisciplineService.ACTION_TASKS_INCOMPLETE; try { startService(serviceIntent); result.success(true) } catch (e: Exception) { result.error("SERVICE_ERROR", "Failed set task status", e.message)}}
                "resetDailyUsage" -> { serviceIntent.action = DisciplineService.ACTION_RESET_USAGE; try { startService(serviceIntent); result.success(null) } catch (e: Exception) { result.error("SERVICE_ERROR", "Failed reset usage", e.message)}}
                else -> { Log.w("MainActivity", "Method '${call.method}' not impl on $DISCIPLINE_CHANNEL."); result.notImplemented() }
           }
        }
    } // End Discipline Channel

        // --- Lifecycle Channel Handler ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIFECYCLE_CHANNEL).setMethodCallHandler { call, result ->
             when (call.method) {
                "getLaunchRoute" -> { result.success(initialRoute) }
                else -> result.notImplemented()
             }
        } // End Lifecycle Channel

    } // End configureFlutterEngine

    // --- BroadcastReceiver for Service Updates (To forward to Flutter) ---
    private fun registerDisciplineStatusUpdateReceiver() {
        if (disciplineStatusReceiver == null) {
             Log.d("MainActivity", "Registering DisciplineStatusUpdateReceiver...")
            disciplineStatusReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                     Log.d("MainActivity", "[BroadcastReceiver] Received status update from Service: ${intent?.action}")
                    if (intent?.action == DisciplineService.ACTION_STATUS_UPDATE_BROADCAST) {
                        val cumulativeMillis = intent.getLongExtra("cumulativeMillis", -1L)
                        val limitMillis = intent.getLongExtra("limitMillis", -1L)
                        val tasksDone = intent.getBooleanExtra("tasksComplete", false)
                        val isBlockingActive = intent.getBooleanExtra("isBlocking", false)

                        val statusMap = mapOf( "cumulativeMillis" to cumulativeMillis, "limitMillis" to limitMillis, "tasksComplete" to tasksDone, "isBlocking" to isBlockingActive )
                        Log.d("MainActivity", "[BroadcastReceiver] Forwarding status to Flutter: $statusMap")
                        try { disciplineEventSink?.success(statusMap) }
                        catch (e: Exception) { Log.e("MainActivity", "Error sending status to Flutter EventChannel", e) }
                    }
                }
            }
            val intentFilter = IntentFilter(DisciplineService.ACTION_STATUS_UPDATE_BROADCAST)
            // Use ContextCompat for registering broadcast receiver for modern Android versions
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ContextCompat.registerReceiver(this, disciplineStatusReceiver, intentFilter, ContextCompat.RECEIVER_EXPORTED) // Or RECEIVER_NOT_EXPORTED if appropriate
            } else {
                 registerReceiver(disciplineStatusReceiver, intentFilter)
            }
             Log.d("MainActivity", "DisciplineStatusUpdateReceiver registered.")
        }
    }
    private fun unregisterDisciplineStatusUpdateReceiver() {
         if (disciplineStatusReceiver != null) {
             Log.d("MainActivity", "Unregistering DisciplineStatusUpdateReceiver...")
            try { unregisterReceiver(disciplineStatusReceiver) } catch (e: Exception) { Log.e("MainActivity", "Error unregistering receiver", e)}
            disciplineStatusReceiver = null
         }
    }
    // --- End BroadcastReceiver ---

    // --- Helper to pass settings map safely ---
     private fun _passSettingsToIntent(intent: Intent, settings: Map<*, *>) {
        Log.d("MainActivity", "[PASS SETTINGS] Raw Settings Map from Flutter: $settings") // Log raw map
        // Use safe casting and provide defaults
        val blockedList = ArrayList(settings["blockedApps"] as? List<String> ?: listOf()) // Safe cast
        intent.putStringArrayListExtra("blockedApps", blockedList) // Use the extracted list
        intent.putExtra("limitMinutes", settings["limitMinutes"] as? Int ?: 30)
        intent.putExtra("block", settings["block"] as? Boolean ?: true)
        intent.putExtra("isActive", settings["isActive"] as? Boolean ?: true)
        // Log exactly what's being put into the intent
        Log.d("MainActivity", "[PASS SETTINGS] Putting blockedApps: [${blockedList.joinToString()}]")
        Log.d("MainActivity", "[PASS SETTINGS] Putting limitMinutes: ${settings["limitMinutes"] as? Int ?: 30}")
     }

    // --- Native Helper Methods for Permissions ---
    private fun hasUsageStatsPermission(): Boolean {
        if (usageStatsManager == null) {
            Log.e("MainActivity", "UsageStatsManager is null in check!")
            return false
         }
         val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager? ?: return false
         val mode = if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) { appOpsManager.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)} else { @Suppress("DEPRECATION") appOpsManager.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)}
         val granted = mode == AppOpsManager.MODE_ALLOWED
         Log.d("MainActivity", "Usage Stats Permission Check Result: $granted (Mode: $mode)")
         return granted
    }
    private fun openUsageAccessSettings() { try { startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)) } catch (e: Exception) { Log.e("MainActivity", "Err Usage Settings", e); openAppSettingsFallback() } }
    private fun hasOverlayPermission(): Boolean { return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.canDrawOverlays(this) else true }
    private fun openOverlaySettings() { if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) { try { startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))) } catch (e: Exception) { Log.e("MainActivity", "Err Overlay Settings", e); openAppSettingsFallback() } } }
    private fun isDeviceAdminActive(): Boolean { val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager?; return dpm?.isAdminActive(deviceAdminReceiverComponent) ?: false }
    private fun requestDeviceAdminActivation() { try { val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply { putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, deviceAdminReceiverComponent); putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Enable admin for app control features.") }; startActivity(intent) } catch (e: Exception) { Log.e("MainActivity", "Err Device Admin Activation", e); Toast.makeText(this, "Could not open Device Admin.", Toast.LENGTH_SHORT).show() } }
    @RequiresApi(Build.VERSION_CODES.S) private fun hasExactAlarmPermission(): Boolean { val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager?; return am?.canScheduleExactAlarms() ?: false }
    private fun openExactAlarmSettings() { if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { try { startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply{ data = Uri.parse("package:$packageName")}) } catch (e: Exception) { Log.e("MainActivity", "Err Exact Alarm Settings", e); openAppSettingsFallback() } } }
    private fun openAppSettingsFallback() { try { val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply { data = Uri.fromParts("package", packageName, null) }; startActivity(intent) } catch (e: Exception) { Log.e("MainActivity", "Err App Settings", e); Toast.makeText(this, "Could not open App Settings.", Toast.LENGTH_SHORT).show() } }

} // End MainActivity