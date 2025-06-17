// --- android/app/src/main/kotlin/com/your_package_name/MainActivity.kt (COMPLETE & CORRECTED) ---
package com.example.bharat_ace // *** REPLACE with your actual package name ***

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.os.Bundle
import android.os.Handler // Already present, but ensure Looper is too
import android.os.Looper
import android.os.Build
import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import androidx.core.content.ContextCompat
import android.content.ComponentName
import android.app.AlarmManager
import androidx.annotation.RequiresApi
import android.util.Log
import android.os.UserManager  //UserManager Import
import android.widget.Toast
import android.app.PendingIntent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification // For VISIBILITY_PUBLIC
import android.app.usage.UsageStatsManager // Import UsageStatsManager
import android.content.BroadcastReceiver // Import for listening to service broadcasts
import android.content.IntentFilter // Import for listening to service broadcasts
import com.example.bharat_ace.AlarmReceiver // Import receiver
import com.example.bharat_ace.DisciplineService // Import service
import com.example.bharat_ace.AppDeviceAdminReceiver // Import device admin receiver
import java.util.HashMap // For passing map to intent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity: FlutterActivity() {
    // Define Channel Names
    private val PERMISSIONS_CHANNEL = "com.bharatace.app/permissions"
    private val DISCIPLINE_CHANNEL = "com.bharatace.app/discipline"
    private val LIFECYCLE_CHANNEL = "com.bharatace.app/lifecycle"
    private val DISCIPLINE_EVENTS_CHANNEL = "com.bharatace.app/discipline_events"
    private val mainActivityHandler = Handler(Looper.getMainLooper())    // Member variable for Device Admin Component Name
    private lateinit var compName: ComponentName
    private lateinit var devicePolicyManager: DevicePolicyManager
    private val appsToBlock = listOf(
        "com.google.android.youtube",
        "com.instagram.android",
        "in.swiggy.android",
        "com.zomato.com",
        "com.facebook.katana",
        "com.twitter.android",
        "com.netflix.mediaclient",
        "com.snapchat.android",
        "com.spotify.music",
        "com.amazon.music",
        "com.spotify.premium",
        "com.reddit.frontpage",
        "com.pinterest",
        "com.quora.android",
        "com.linkedin.android",
        "com.tiktok",
        // ... add more app package names
    )

    // Member variable to store initial route from alarm intent
    private var initialRoute: String? = null

    // For EventChannel (Native -> Flutter for DisciplineService status)
    private var disciplineEventSink: EventChannel.EventSink? = null
    private var disciplineStatusReceiver: BroadcastReceiver? = null

    // Member variable for UsageStatsManager
    private var usageStatsManager: UsageStatsManager? = null


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "onCreate called.")
        handleIntent(intent) // Check if launched from alarm

        // Initialize UsageStatsManager here
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager?
        if (usageStatsManager == null) { Log.e("MainActivity", "Failed to get UsageStatsManager in onCreate!")}
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        // Initialize ComponentName BEFORE using it
        compName = ComponentName(this, AppDeviceAdminReceiver::class.java)

        // Create notification channels on startup
        AlarmReceiver.createNotificationChannelIfNeeded(this)
        DisciplineService.createNotificationChannelIfNeeded(this)

        // Register BroadcastReceiver to get updates from DisciplineService
        registerDisciplineStatusUpdateReceiver()

    }

    override fun onDestroy() {
        unregisterDisciplineStatusUpdateReceiver() // Unregister receiver
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d("MainActivity", "onNewIntent called.")
        handleIntent(intent)
    }

    // Processes the launch/new intent to see if it came from the alarm
    private fun handleIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("alarm_triggered", false) == true) {
            Log.d("MainActivity", "Launched from Alarm Intent (handleIntent).")
            initialRoute = intent.getStringExtra("navigate_to")
            Log.d("MainActivity", "Stored initialRoute: $initialRoute")
        } else {
            initialRoute = null
            Log.d("MainActivity", "Not launched from Alarm Intent (handleIntent).")
        }
    }

    // --- Flutter Engine Configuration ---
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("MainActivity", "configureFlutterEngine called.")
        // compName is already initialized in onCreate
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.bharatace/app_control") 
            channel.setMethodCallHandler { call, result ->
            if (call.method == "enableAppBlocking") {
                if (devicePolicyManager.isAdminActive(compName)) { // Check if device admin is active
                    // Block apps here
                    setAppRestrictions(true) // Enable restrictions
                    result.success(true)
                } else {
                    activateDeviceAdmin() // Request device admin activation
                    result.success(null) // Or an appropriate result indicating pending activation
                }
            } else if (call.method == "disableAppBlocking") {
                setAppRestrictions(false) // Disable restrictions
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
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
                    val intent = Intent(this, AlarmReceiver::class.java)
                    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) { PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE } else { PendingIntent.FLAG_UPDATE_CURRENT }
                    val pendingIntent = PendingIntent.getBroadcast(this, 1, intent, flags)
                    try { alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent); Log.d("MainActivity", "Scheduled test alarm OK"); result.success(true) }
                    catch (e: Exception) { Log.e("MainActivity", "Error scheduling alarm", e); result.error("ALARM_ERROR", "Failed to schedule alarm: ${e.message}", e.stackTraceToString()) }
                }
                // --- Commands targeting Service (e.g., Alarm or Discipline) ---
                "stopAlarmSound", "dismissAlarm" -> {
                    Log.d("MainActivity", "Req ${call.method} -> Sending DISMISS Action to DisciplineService.")
                    val serviceIntent = Intent(this, DisciplineService::class.java)
                    serviceIntent.action = DisciplineService.ACTION_DISMISS
                    try { startService(serviceIntent); result.success(null) }
                    catch (e: Exception) { result.error("SERVICE_ERROR", "Failed dismiss command", e.message) }
                }
                else -> result.notImplemented()
            }
        } // End Permissions Channel

        // --- Discipline Service Channel Handler (Flutter -> Native) ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DISCIPLINE_CHANNEL).setMethodCallHandler { call, result ->
           Log.d("MainActivity", "[DISCIPLINE_CHANNEL] Call received: ${call.method}")
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
                    catch (e: Exception) { Log.e("MainActivity", "Error starting DisciplineService", e); result.error("SERVICE_ERROR", "Failed start service", e.message)}
                }
                "stopDisciplineService" -> {
                    serviceIntent.action = DisciplineService.ACTION_STOP_SERVICE
                    try { startService(serviceIntent); result.success(true) }
                    catch (e: Exception) { Log.e("MainActivity", "Error sending stop action", e); result.error("SERVICE_ERROR", "Failed to stop service", e.message)}
                }
                "updateDisciplineSettings" -> {
                    val settings = call.arguments as? Map<*, *>
                    serviceIntent.action = DisciplineService.ACTION_UPDATE_SETTINGS
                    if (settings != null) { _passSettingsToIntent(serviceIntent, settings) }
                        try { startService(serviceIntent); result.success(true) }
                        catch (e: Exception) { Log.e("MainActivity", "Error sending update settings", e); result.error("SERVICE_ERROR", "Failed update settings", e.message)}
                }
                "setTasksCompleteStatus" -> {
                        val isComplete = call.argument<Boolean>("isComplete") ?: false
                        serviceIntent.action = if(isComplete) DisciplineService.ACTION_TASKS_COMPLETE else DisciplineService.ACTION_TASKS_INCOMPLETE
                        try { startService(serviceIntent); result.success(true) }
                        catch (e: Exception) { Log.e("MainActivity", "Error sending task status", e); result.error("SERVICE_ERROR", "Failed set task status", e.message)}
                }
                "resetDailyUsage" -> {
                        serviceIntent.action = DisciplineService.ACTION_RESET_USAGE
                        try { startService(serviceIntent); result.success(null) }
                        catch (e: Exception) { Log.e("MainActivity", "Error sending reset usage", e); result.error("SERVICE_ERROR", "Failed reset usage", e.message)}
                }
                // *** ADDED Handler for updateServicePermissionStatus ***
                "updateServicePermissionStatus" -> {
                    val args = call.arguments as? Map<*, *>
                    Log.d("MainActivity", "[Native DISCIPLINE] Received 'updateServicePermissionStatus' from Flutter: $args")
                    if (args != null) {
                        val usageGranted = args["usageStatsGranted"] as? Boolean
                        val overlayGranted = args["overlayGranted"] as? Boolean // Example if you add more
                        val broadcastIntent = Intent(DisciplineService.ACTION_PERMISSION_STATUS_UPDATE)
                        if (usageGranted != null) {
                             broadcastIntent.putExtra("usageStatsGranted", usageGranted)
                             Log.d("MainActivity", "[Native DISCIPLINE] Broadcasting usageStatsGranted=$usageGranted")
                        }
                        if (overlayGranted != null) { // Example for another permission
                            broadcastIntent.putExtra("overlayGranted", overlayGranted)
                             Log.d("MainActivity", "[Native DISCIPLINE] Broadcasting overlayGranted=$overlayGranted")
                        }
                        broadcastIntent.`package` = packageName // Target broadcast to own app
                        try {
                           sendBroadcast(broadcastIntent)
                           result.success(null)
                        } catch (e: Exception) {
                           Log.e("MainActivity", "Error sending permission status broadcast", e)
                           result.error("BROADCAST_ERROR", "Failed to send status broadcast", e.message)
                        }
                    } else {
                        Log.w("MainActivity", "[Native DISCIPLINE] No arguments for 'updateServicePermissionStatus'")
                        result.error("INVALID_ARGS", "No args for perm update", null)
                    }
                }
                // *** END ADDED Handler ***
               else -> { Log.w("MainActivity", "Method '${call.method}' not impl on $DISCIPLINE_CHANNEL."); result.notImplemented() }
           }
        } // End Discipline Channel

        // --- Lifecycle Channel Handler (Flutter -> Native) ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIFECYCLE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) { "getLaunchRoute" -> { result.success(initialRoute) } else -> result.notImplemented() }
        } // End Lifecycle Channel

        // --- Event Channel Setup (Native -> Flutter for DisciplineService status) ---
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, DISCIPLINE_EVENTS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d("MainActivity", "[EventChannel] Flutter listener for Discipline Events attached.")
                    disciplineEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    Log.d("MainActivity", "[EventChannel] Flutter listener for Discipline Events cancelled.")
                    disciplineEventSink = null
                }
            }
        ) // End Event Channel
    } // End configureFlutterEngine
    // Make sure this function is inside the MainActivity class
    private fun activateDeviceAdmin() {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName)
        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Please enable this permission to block distracting apps during study sessions.")
        try {
            startActivityForResult(intent, 100) // or any appropriate request code
        } catch (e: Exception) { // Handle exceptions (e.g., if no activity can handle the intent)
            Toast.makeText(this, "Error activating device admin.", Toast.LENGTH_SHORT).show()
            e.printStackTrace() // Print the exception for debugging
        }
    }
    private fun setAppRestrictions(enable: Boolean) {
        if (devicePolicyManager.isAdminActive(compName)) { // (1) Check admin status - OPEN BRACE FOR THIS IF
            Log.d("AppBlocking", "Device Admin IS active.")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) { // (2) App restrictions available from API 24 - OPEN BRACE
                CoroutineScope(Dispatchers.IO).launch {
                    var changesMade = false 
                    var allSuccessful = true
                    if (enable) {
                        Log.d("AppBlocking", "Enabling restrictions...")
                        for (packageName in appsToBlock) {
                            Log.d("AppBlocking", "Attempting to block $packageName...")
                        // Original logic had a duplicated call here, I'll use the one in try/catch
                        // devicePolicyManager.setApplicationHidden(compName, packageName, true)
                        // changesMade = true 
                            try {
                                val result = devicePolicyManager.setApplicationHidden(compName, packageName, true)
                                Log.d("AppBlocking", "Result of blocking $packageName: $result")
                                changesMade = true // Mark if successful
                            } catch (e: SecurityException) {
                                Log.e("AppBlocking", "Error blocking $packageName: ${e.message}")
                                allSuccessful = false
                                changesMade = true // Attempt was made
                            } catch (e: Exception) {
                                Log.e("AppBlocking", "Generic error blocking $packageName: ${e.message}")
                                allSuccessful = false
                                changesMade = true // Attempt was made
                            }
                        }
                        Log.d("AppBlocking", "Finished enabling restrictions.")
                        mainActivityHandler.post {
                            if (changesMade && allSuccessful && appsToBlock.isNotEmpty()) {
                                Toast.makeText(this@MainActivity, "App hiding enabled for selected apps.", Toast.LENGTH_SHORT).show()
                            } else if (changesMade && !allSuccessful) {
                                Toast.makeText(this@MainActivity, "Attempted to enable app hiding. Some apps may have failed. Check logs.", Toast.LENGTH_LONG).show()
                            } else if (!changesMade && appsToBlock.isNotEmpty()) {
                                Toast.makeText(this@MainActivity, "App hiding not enabled (no changes made or all failed). Check logs.", Toast.LENGTH_LONG).show()
                            } else if (appsToBlock.isEmpty()) {
                                Toast.makeText(this@MainActivity, "No apps selected for hiding.", Toast.LENGTH_SHORT).show()
                            }
                        }
                    } else { // This 'else' is for 'if (enable)'
                        Log.d("AppBlocking", "Disabling restrictions...")
                        for (packageName in appsToBlock) {
                            try {
                                devicePolicyManager.setApplicationHidden(compName, packageName, false)
                                changesMade = true
                            } catch (e: Exception) {
                                Log.e("AppBlocking", "Error unhiding $packageName: ${e.message}")
                                allSuccessful = false
                                changesMade = true
                            }
                        }
                        // Add a summary Toast for disabling completion
                        mainActivityHandler.post {
                            if (changesMade && allSuccessful && appsToBlock.isNotEmpty()) {
                                Toast.makeText(this@MainActivity, "App hiding disabled for selected apps.", Toast.LENGTH_SHORT).show()
                            } else if (changesMade && !allSuccessful) {
                                Toast.makeText(this@MainActivity, "Attempted to disable app hiding. Some apps may have failed. Check logs.", Toast.LENGTH_LONG).show()
                            } else if (!changesMade && appsToBlock.isNotEmpty()) {
                                Toast.makeText(this@MainActivity, "App hiding not disabled (no changes made or all failed). Check logs.", Toast.LENGTH_LONG).show()
                            } else if (appsToBlock.isEmpty()) {
                                Toast.makeText(this@MainActivity, "No apps were previously hidden.", Toast.LENGTH_SHORT).show()
                            }
                        }
                    }
                } // Closes CoroutineScope.launch
            } else { // (2) This 'else' is for 'if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)' - OPEN BRACE
                mainActivityHandler.post {
                    Toast.makeText(this@MainActivity, "App hiding (via Device Admin) not fully supported on this Android version.", Toast.LENGTH_LONG).show()
                }
            } // (2) - CLOSE BRACE for 'else for SDK_INT'
        } else { // (1) Device admin not active - THIS IS THE 'else' FOR 'if (devicePolicyManager.isAdminActive(compName))' - OPEN BRACE
            Log.w("AppBlocking", "Device Admin is NOT active. Cannot set app restrictions.")
            mainActivityHandler.post {
                Toast.makeText(this@MainActivity, "Device Admin not active. Please enable it first.", Toast.LENGTH_LONG).show()
            }
        } // (1) - CLOSE BRACE for 'else for isAdminActive'
    } // Closes setAppRestrictions method

    // --- Helper to pass settings map safely ---
    private fun _passSettingsToIntent(intent: Intent, settings: Map<*, *>) {
        Log.d("MainActivity", "[PASS SETTINGS] Raw Settings Map from Flutter: $settings")
        intent.putStringArrayListExtra("blockedApps", ArrayList(settings["blockedApps"] as? List<String> ?: listOf()))
        intent.putExtra("limitMinutes", settings["limitMinutes"] as? Int ?: 30)
        intent.putExtra("block", settings["block"] as? Boolean ?: true)
        intent.putExtra("isActive", settings["isActive"] as? Boolean ?: true)
        Log.d("MainActivity", "[PASS SETTINGS] Putting blockedApps: ${intent.getStringArrayListExtra("blockedApps")}, Limit: ${intent.getIntExtra("limitMinutes", -1)}")
    }

    // --- BroadcastReceiver for Service Updates (To forward to Flutter) ---
    private fun registerDisciplineStatusUpdateReceiver() {
        if (disciplineStatusReceiver == null) {
            Log.d("MainActivity", "Registering DisciplineStatusUpdateReceiver...")
            disciplineStatusReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                        Log.d("MainActivity", "[BroadcastReceiver] Received status update from Service: ${intent?.action}")
                        if (intent?.action == DisciplineService.ACTION_STATUS_UPDATE_BROADCAST) {
                            val cumulativeMillis = intent.getLongExtra("cumulativeMillis", 0L) // Default to 0L
                            val limitMillis = intent.getLongExtra("limitMillis", 30 * 60 * 1000L) // Default to 30 min
                            val tasksDone = intent.getBooleanExtra("tasksComplete", false)
                            val isBlockingActive = intent.getBooleanExtra("isBlocking", false)
                            val currentForegroundApp = intent.getStringExtra("currentForegroundApp") ?: "" // Get foreground app
                            val statusMap = mapOf(
                                "cumulativeMillis" to cumulativeMillis, "limitMillis" to limitMillis,
                                "tasksComplete" to tasksDone, "isBlocking" to isBlockingActive,
                                "currentForegroundApp" to currentForegroundApp
                            )
                            Log.d("MainActivity", "[BroadcastReceiver] Forwarding status to Flutter: $statusMap")
                            try { disciplineEventSink?.success(statusMap) }
                            catch (e: Exception) { Log.e("MainActivity", "Error sending status to Flutter EventChannel", e) }
                        }
                    }
                }
            val intentFilter = IntentFilter(DisciplineService.ACTION_STATUS_UPDATE_BROADCAST)
            // Use ContextCompat for registering broadcast receiver
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ContextCompat.registerReceiver(this, disciplineStatusReceiver!!, intentFilter, ContextCompat.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("UnspecifiedRegisterReceiverFlag") // Suppress for older versions
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

    // --- Native Helper Methods for Permissions ---
    private fun hasUsageStatsPermission(): Boolean {
        if (usageStatsManager == null) { Log.e("MainActivity", "UsageStatsManager is null in check!"); return false }
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager? ?: return false
        val mode = if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) { appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)} else { @Suppress("DEPRECATION") appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)}
        val granted = mode == AppOpsManager.MODE_ALLOWED
        Log.d("MainActivity", "Usage Stats Permission Check Result: $granted (Mode: $mode)")
        return granted
    }
    private fun openUsageAccessSettings() { try { startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)) } catch (e: Exception) { Log.e("MainActivity", "Err Usage Settings", e); openAppSettingsFallback() } }
    private fun hasOverlayPermission(): Boolean { return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.canDrawOverlays(this) else true }
    private fun openOverlaySettings() { if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) { try { startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))) } catch (e: Exception) { Log.e("MainActivity", "Err Overlay Settings", e); openAppSettingsFallback() } } }
    private fun isDeviceAdminActive(): Boolean { val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager?; return dpm?.isAdminActive(compName) ?: false }
    private fun requestDeviceAdminActivation() { try { val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply { putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName); putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Enable admin for app control features.") }; startActivity(intent) } catch (e: Exception) { Log.e("MainActivity", "Err Device Admin Activation", e); Toast.makeText(this, "Could not open Device Admin.", Toast.LENGTH_SHORT).show() } }
    @RequiresApi(Build.VERSION_CODES.S) private fun hasExactAlarmPermission(): Boolean { val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager?; return am?.canScheduleExactAlarms() ?: false }
    private fun openExactAlarmSettings() { if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { try { startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply{ data = Uri.parse("package:$packageName")}) } catch (e: Exception) { Log.e("MainActivity", "Err Exact Alarm Settings", e); openAppSettingsFallback() } } }
    private fun openAppSettingsFallback() { try { val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply { data = Uri.fromParts("package", packageName, null) }; startActivity(intent) } catch (e: Exception) { Log.e("MainActivity", "Err App Settings", e); Toast.makeText(this, "Could not open App Settings.", Toast.LENGTH_SHORT).show() } }

} // End MainActivity