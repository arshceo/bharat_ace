// --- android/app/src/main/kotlin/com/your_package_name/DisciplineService.kt ---
package com.example.bharat_ace // Replace with your package name

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver // Import for the permission receiver
import android.content.IntentFilter  
import android.content.pm.ServiceInfo
import android.os.*
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.bharat_ace.R // Import R class
import java.util.Calendar
import java.util.*
import kotlin.collections.ArrayList

class DisciplineService : Service() {

    companion object {
        private const val TAG = "DisciplineService"
        const val CHANNEL_ID = "BHARATACE_DISCIPLINE_CHANNEL"
        private const val NOTIFICATION_ID_SERVICE = 789
        private const val WAKELOCK_TAG = "$TAG::ServiceWakeLock"
        // Actions
        const val ACTION_START_MONITORING = "com.bharatace.app.ACTION_START"
        const val ACTION_STOP_SERVICE = "com.bharatace.app.ACTION_STOP_SERVICE"
        const val ACTION_UPDATE_SETTINGS = "com.bharatace.app.ACTION_UPDATE_SETTINGS"
        const val ACTION_TASKS_COMPLETE = "com.bharatace.app.ACTION_TASKS_COMPLETE"
        const val ACTION_TASKS_INCOMPLETE = "com.bharatace.app.ACTION_TASKS_INCOMPLETE"
        const val ACTION_DISMISS = "com.bharatace.app.ACTION_DISMISS"        
        const val ACTION_RESET_USAGE = "com.bharatace.app.ACTION_RESET_USAGE"
        const val ACTION_PERMISSION_STATUS_UPDATE = "com.bharatace.app.PERMISSIONS_UPDATED" // Received from MainActivity
        const val ACTION_STATUS_UPDATE_BROADCAST = "com.bharatace.app.ACTION_STATUS_UPDATE" // Sent TO MainActivity

        fun createNotificationChannelIfNeeded(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val name = "BharatAce Focus Service"
                val descriptionText = "Monitors app usage for discipline features."
                val importance = NotificationManager.IMPORTANCE_LOW // Less intrusive for service
                val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                    description = descriptionText
                    setShowBadge(false) // Usually false for persistent service notifications
                }
                val notificationManager: NotificationManager? = ContextCompat.getSystemService(context, NotificationManager::class.java)
                if (notificationManager?.getNotificationChannel(CHANNEL_ID) == null) {
                    try {
                        notificationManager?.createNotificationChannel(channel)
                        Log.d(TAG, "Discipline Notification channel created: $CHANNEL_ID")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to create discipline notification channel", e)
                    }
                }
            }
        }
    } // End Companion Object


    // --- Service Instance Variables ---
    @Volatile private var wakeLock: PowerManager.WakeLock? = null
    @Volatile private var isServiceRunning = false
    private val serviceHandler = Handler(Looper.getMainLooper())
    private var usageStatsManager: UsageStatsManager? = null

    // Settings (Defaults, updated via Intent)
    @Volatile private var isActive = true
    @Volatile private var blockAfterLimit = true
    @Volatile private var totalDistractionLimitMillis: Long = 30 * 60 * 1000L // Default 30 mins
    @Volatile private var distractingApps = listOf<String>()
    @Volatile private var tasksComplete = false // Updated via Intent

    // Permission States (Updated via Intent/Broadcast)
    @Volatile private var _hasUsagePermission = false
    @Volatile private var _hasOverlayPermission = false // For launching BlockingOverlayActivity

    // Usage Tracking
    @Volatile private var cumulativeDistractionTimeMillis: Long = 0L
    @Volatile private var lastUsageCheckTimestamp: Long = System.currentTimeMillis()
    private val checkIntervalMillis: Long = 15 * 1000L // Check every 15 seconds
    @Volatile private var currentlyForegroundAppPkg: String? = null

    // SharedPreferences for persistence
    private val sharedPrefs by lazy { getSharedPreferences("DisciplinePrefs", Context.MODE_PRIVATE) }
    private val TODAY_DATE_KEY = "usageTrackDate"
    private val CUMULATIVE_TIME_KEY = "cumulativeDistractionMs"
    // private val TASKS_COMPLETE_KEY = "tasksComplete" // Optional: persist tasksComplete flag

    // BroadcastReceiver for internal permission updates
    private var permissionUpdateReceiver: BroadcastReceiver? = null

    // --- Lifecycle Methods ---
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Discipline Service Created.")
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager?
        if (usageStatsManager == null) { Log.e(TAG, "Failed to get UsageStatsManager!") }
        createNotificationChannelIfNeeded(this)
        registerPermissionUpdateReceiver()
        loadCumulativeTime() // Load persisted time and check for daily reset
        Log.d(TAG, "Initial loaded cumulative time: ${cumulativeDistractionTimeMillis / 1000}s")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START_MONITORING // Default to start if no action
        Log.d(TAG, "onStartCommand received. Action: $action")

        // Update internal states from intent extras FIRST
        _updatePermissionsFromIntent(intent) // Reads initialUsageStatsGranted, initialOverlayGranted
        _updateSettingsFromIntent(intent)    // Reads blockedApps, limitMinutes, block, isActive

        when (action) {
            ACTION_STOP_SERVICE -> { stopSelfCleanup(); return START_NOT_STICKY }
            ACTION_DISMISS -> { handleDismissCommand(); return START_NOT_STICKY }            
            ACTION_TASKS_COMPLETE -> {
                tasksComplete = true; Log.d(TAG, "Tasks marked complete via Intent.");
                // Persist tasksComplete status (e.g., in SharedPreferences)
                // sharedPrefs.edit().putBoolean(TASKS_COMPLETE_KEY, true).apply()
                checkUsageAndApplyRules(); return START_STICKY
            }
            ACTION_TASKS_INCOMPLETE -> {
                tasksComplete = false; Log.d(TAG, "Tasks marked incomplete via Intent.");
                // sharedPrefs.edit().putBoolean(TASKS_COMPLETE_KEY, false).apply()
                checkUsageAndApplyRules(); return START_STICKY
            }
            ACTION_RESET_USAGE -> {
                Log.i(TAG, "Resetting cumulative usage time via Intent...");
                cumulativeDistractionTimeMillis = 0L;
                saveCumulativeTime(); // Persist the reset
                sendStatusUpdateBroadcast();
                checkUsageAndApplyRules();
                return START_STICKY
            }
            // ACTION_START_MONITORING and ACTION_UPDATE_SETTINGS are handled by _updateSettingsFromIntent
            // and the subsequent !isServiceRunning check
        }

        // Start foreground service and periodic checks only if not already running
        if (!isServiceRunning && isActive) { // Only start if discipline is active
            isServiceRunning = true
            val serviceNotification = buildForegroundNotification()
            try {
                startForeground(NOTIFICATION_ID_SERVICE, serviceNotification)
                Log.d(TAG, "Discipline Service started in foreground.")
            } catch (e: Exception) {
                Log.e(TAG, "Error starting foreground service: ${e.message}", e)
                stopSelfCleanup()
                return START_NOT_STICKY
            }
            acquireWakeLock()
            serviceHandler.removeCallbacks(usageCheckRunnable) // Ensure no duplicates
            serviceHandler.post(usageCheckRunnable) // Start checks immediately
        } else if (isServiceRunning && !isActive) {
            Log.i(TAG, "Discipline is inactive. Stopping service.")
            stopSelfCleanup() // Stop if settings make it inactive
        }

        return START_STICKY // Try to restart if killed by system
    }

    override fun onDestroy() {
        Log.d(TAG, "Discipline Service Destroyed.")
        unregisterPermissionUpdateReceiver()
        stopSelfCleanup() // Ensure all resources are released
        super.onDestroy()
    }

    // --- Helper Methods ---
    private fun _updatePermissionsFromIntent(intent: Intent?) {
        if (intent == null) return
        // Only update if the specific extras are present
        if (intent.hasExtra("initialUsageStatsGranted")) {
            _hasUsagePermission = intent.getBooleanExtra("initialUsageStatsGranted", _hasUsagePermission)
        }
        if (intent.hasExtra("initialOverlayGranted")) {
            _hasOverlayPermission = intent.getBooleanExtra("initialOverlayGranted", _hasOverlayPermission)
        }
        Log.d(TAG, "Internal permissions potentially updated from Intent: Usage=$_hasUsagePermission, Overlay=$_hasOverlayPermission")
    }

    private fun _updateSettingsFromIntent(intent: Intent?) {
        if (intent == null) return
        Log.d(TAG, "Updating settings from Intent...")

        // Log all extras for debugging
        intent.extras?.let { bundle ->
            Log.d(TAG, "Intent Extras Bundle for settings:")
            bundle.keySet().forEach { key -> Log.d(TAG, "  Key: $key, Value: ${bundle.get(key)}") }
        }

        // Use safe extraction with defaults, only update if key exists
        if (intent.hasExtra("blockedApps")) distractingApps = intent.getStringArrayListExtra("blockedApps") ?: distractingApps
        if (intent.hasExtra("limitMinutes")) totalDistractionLimitMillis = (intent.getIntExtra("limitMinutes", (totalDistractionLimitMillis / 60000).toInt()) * 60000L)
        if (intent.hasExtra("block")) blockAfterLimit = intent.getBooleanExtra("block", blockAfterLimit)
        if (intent.hasExtra("isActive")) isActive = intent.getBooleanExtra("isActive", isActive)

        Log.i(TAG, "SETTINGS UPDATED -> Active: $isActive, Block: $blockAfterLimit, Limit(ms): $totalDistractionLimitMillis, Apps: [${distractingApps.joinToString()}]")

        if (!isActive && isServiceRunning) { // If settings make it inactive, stop
            stopSelfCleanup()
        } else if (isActive && isServiceRunning) {
            checkUsageAndApplyRules() // Re-check rules with new settings
        }
    }

    private fun registerPermissionUpdateReceiver() {
        if (permissionUpdateReceiver == null) {
            Log.i(TAG, "Attempting to register PermissionUpdateReceiver...")
            permissionUpdateReceiver = object : BroadcastReceiver() {
                override fun onReceive(p0: Context?, p1: Intent?) {
                    val context = p0 ?: return
                    val intent = p1 ?: return
                    Log.d(TAG, ">>> BR onReceive. Action: ${intent.action}")
                    if (intent.action == ACTION_PERMISSION_STATUS_UPDATE) {
                        val receivedStatus = intent.getBooleanExtra("usageStatsGranted", _hasUsagePermission)
                        Log.d(TAG, ">>> BR Received $ACTION_PERMISSION_STATUS_UPDATE. Before: $_hasUsagePermission. Intent: $receivedStatus")
                        if (_hasUsagePermission != receivedStatus) {
                            _hasUsagePermission = receivedStatus
                            Log.i(TAG, ">>> _hasUsagePermission updated TO: $_hasUsagePermission via Broadcast")
                            if (_hasUsagePermission) { checkUsageAndApplyRules() } else { /* Maybe stop launching overlay? */ }
                        }
                    }
                }
            }
            val intentFilter = IntentFilter(ACTION_PERMISSION_STATUS_UPDATE)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { ContextCompat.registerReceiver(applicationContext, permissionUpdateReceiver!!, intentFilter, ContextCompat.RECEIVER_NOT_EXPORTED) }
                else { @Suppress("UnspecifiedRegisterReceiverFlag") applicationContext.registerReceiver(permissionUpdateReceiver, intentFilter) }
                Log.i(TAG, "PermissionUpdateReceiver REGISTERED.")
            } catch (e: Exception) { Log.e(TAG, "FAILED to register PermissionUpdateReceiver!", e); permissionUpdateReceiver = null }
        }
    }

    private fun unregisterPermissionUpdateReceiver() {
        if (permissionUpdateReceiver != null) {
            Log.i(TAG, "Attempting to unregister PermissionUpdateReceiver...")
            try {
                applicationContext.unregisterReceiver(permissionUpdateReceiver) // Use applicationContext
                Log.i(TAG, "PermissionUpdateReceiver UNREGISTERED successfully.")
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering PermissionUpdateReceiver", e)
            } finally {
                 permissionUpdateReceiver = null
            }
        }
    }
    // --- End BroadcastReceiver ---

    // --- Core Logic ---
    private fun scheduleUsageCheck() {
        if (!isServiceRunning || !isActive) return // Don't schedule if not running or inactive
        serviceHandler.removeCallbacks(usageCheckRunnable)
        serviceHandler.postDelayed(usageCheckRunnable, checkIntervalMillis)
    }

    private val usageCheckRunnable = Runnable {
        if (!isServiceRunning || !isActive) return@Runnable
        Log.d(TAG, "Running periodic usage check...")
        checkUsageAndApplyRules()
        scheduleUsageCheck() // Reschedule only if service still should run
    }

    private fun checkUsageAndApplyRules() {
        if (!isActive) { Log.i(TAG, "checkUsageAndApplyRules: Service inactive, skipping checks."); return }
        if (usageStatsManager == null) { Log.e(TAG, "checkUsageAndApplyRules: UsageStatsManager is null!"); return }
        if (!_hasUsagePermission) { Log.w(TAG, "checkUsageAndApplyRules: Usage Stats permission NOT granted (internal flag: $_hasUsagePermission)."); return }

        val currentTime = System.currentTimeMillis()
        val calendar = Calendar.getInstance().apply { timeInMillis = currentTime; set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0) }
        val startOfDayMillis = calendar.timeInMillis

        var currentDayTotalDistractionMillis = 0L
        try {
            val stats = usageStatsManager!!.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startOfDayMillis, currentTime)
            if (stats != null && stats.isNotEmpty()) {
                for (usageStats in stats) {
                    if (distractingApps.any { it.equals(usageStats.packageName, ignoreCase = true) }) {
                        currentDayTotalDistractionMillis += usageStats.totalTimeInForeground
                    }
                }
            }
            if (cumulativeDistractionTimeMillis != currentDayTotalDistractionMillis) {
                Log.i(TAG, "Updating Cumulative Distraction Time: ${cumulativeDistractionTimeMillis/1000}s -> ${currentDayTotalDistractionMillis/1000}s")
                cumulativeDistractionTimeMillis = currentDayTotalDistractionMillis
                saveCumulativeTime()
            }
        } catch (e: Exception) { Log.e(TAG, "Error querying DAILY usage stats", e) }

        // Determine Current Foreground App
        var latestFgAppThisInterval: String? = null
        try {
            val recentStartTime = currentTime - (checkIntervalMillis + 5000L) // Look back a bit more
            val events = usageStatsManager!!.queryEvents(recentStartTime, currentTime)
            var lastMoveToFgEvent: UsageEvents.Event? = null
            // Iterate to find the *absolute last* MOVE_TO_FOREGROUND event in the window
            while (events.hasNextEvent()) { val event = UsageEvents.Event(); events.getNextEvent(event); if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) { lastMoveToFgEvent = event } }
            latestFgAppThisInterval = lastMoveToFgEvent?.packageName

            // Only update if it's different and not null (to avoid clearing it if no FG event found in short window)
            if (latestFgAppThisInterval != null && currentlyForegroundAppPkg != latestFgAppThisInterval) {
                Log.i(TAG, "Current FG app updated from '$currentlyForegroundAppPkg' to '$latestFgAppThisInterval'")
                currentlyForegroundAppPkg = latestFgAppThisInterval
            } else if (latestFgAppThisInterval == null && currentlyForegroundAppPkg != null){
                 // If no FG events in window, need a way to confirm if app truly went background
                 // This is complex; for now, we'll keep the last known FG app until another moves to FG
                 Log.d(TAG, "No recent FG event, keeping last known FG: $currentlyForegroundAppPkg")
            }
        } catch (e: Exception) { Log.e(TAG, "Error querying RECENT usage events for foreground app", e) }

        // --- Apply Rules ---
        val limitReached = cumulativeDistractionTimeMillis >= totalDistractionLimitMillis
        val shouldBlock = isActive && limitReached && !tasksComplete && blockAfterLimit
        val isDistractingAppCurrentlyForeground = currentlyForegroundAppPkg != null && distractingApps.any { it.equals(currentlyForegroundAppPkg, ignoreCase = true) }

        Log.d(TAG, "Check Results: ShouldBlock=$shouldBlock, CurrentFG=$currentlyForegroundAppPkg, IsDistracting=$isDistractingAppCurrentlyForeground, CumulativeTime=${cumulativeDistractionTimeMillis/1000}s of ${totalDistractionLimitMillis/1000}s")

        sendStatusUpdateBroadcast() // Send current status to Flutter

        if (shouldBlock && isDistractingAppCurrentlyForeground) {
            Log.w(TAG, "Block condition met AND distracting app ($currentlyForegroundAppPkg) is foreground. Launching BlockingOverlayActivity.")
            launchBlockingActivity("Daily app limit reached!")
        }
    } 

    private fun hasOverlayPermission(): Boolean { return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.canDrawOverlays(this) else true }

    private fun launchBlockingActivity(message: String) {
        if (!hasOverlayPermission()) { Log.e(TAG,"Cannot launch blocking activity - Overlay permission missing!"); return }
         Log.d(TAG, "Attempting to launch BlockingOverlayActivity.")
         try {
             val overlayIntent = Intent(this, BlockingOverlayActivity::class.java).apply {
                 addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                 putExtra("message", message)
             }
             startActivity(overlayIntent)
         } catch (e: Exception) { Log.e(TAG, "Error starting BlockingOverlayActivity", e) }
    }

    // Called by ACTION_DISMISS (e.g., when BlockingOverlayActivity is explicitly closed by user)
    private fun handleDismissCommand() {
        Log.d(TAG, "Dismiss command received. Service will stop itself.")
        // This assumes the user wants to stop the service if they dismiss the blocker this way
        // OR it means the service should just note the overlay is gone and continue monitoring.
        // For now, let's make it stop the service.
        stopSelfCleanup()
    }

    // --- Service Cleanup ---
    private fun stopSelfCleanup() {
        Log.d(TAG, "Service initiating self-cleanup...")
        serviceHandler.removeCallbacks(usageCheckRunnable)
        isServiceRunning = false
        releaseWakeLock()
        saveCumulativeTime() // Save final time
        stopForeground(true) // true = remove notification
        stopSelf()
    }

     // --- Build Foreground Notification ---
    private fun buildForegroundNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) { PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE } else { PendingIntent.FLAG_UPDATE_CURRENT }
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, flags)
        val smallIconResId = R.mipmap.ic_launcher // Ensure this exists
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BharatAce Focus Active").setContentText("Monitoring app usage...").setSmallIcon(smallIconResId)
            .setContentIntent(pendingIntent).setPriority(NotificationCompat.PRIORITY_LOW).setOngoing(true).build()
   }

    // --- WakeLock Management ---
    private fun acquireWakeLock() {
        if (wakeLock == null) {
           val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager?
           wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG)
           wakeLock?.setReferenceCounted(false)
        }
        if (wakeLock?.isHeld == false) { wakeLock?.acquire(10*60*1000L); Log.d(TAG, "Service WakeLock acquired.") }
    }

    private fun releaseWakeLock() {
        if (wakeLock?.isHeld == true) {
            try {
                wakeLock?.release()
                Log.d(TAG, "Service WakeLock released.") // Log moved after successful release
            } catch (e: Exception) {
                Log.e(TAG, "Error releasing WakeLock", e)
            }
        }
        // Always nullify after attempting release or if not held
        wakeLock = null
        Log.d(TAG, "WakeLock reference nullified.")
    }

   // --- SharedPreferences Load/Save ---
    private fun loadCumulativeTime() {
        val todayStr = android.text.format.DateFormat.format("yyyy-MM-dd", java.util.Date()) as String
        val lastTrackDate = sharedPrefs.getString(TODAY_DATE_KEY, "")
        if (lastTrackDate != todayStr) {
            Log.i(TAG,"New day detected. Resetting cumulative distraction time.")
            cumulativeDistractionTimeMillis = 0L
            sharedPrefs.edit().putLong(CUMULATIVE_TIME_KEY, 0L).putString(TODAY_DATE_KEY, todayStr).apply()
        } else {
            cumulativeDistractionTimeMillis = sharedPrefs.getLong(CUMULATIVE_TIME_KEY, 0L)
            Log.d(TAG, "Loaded cumulative time for today: ${cumulativeDistractionTimeMillis / 1000}s")
        }
        lastUsageCheckTimestamp = System.currentTimeMillis() // Reset last check time on load
    }

    // Save cumulative time
    private fun saveCumulativeTime() {
        sharedPrefs.edit().putLong(CUMULATIVE_TIME_KEY, cumulativeDistractionTimeMillis).apply()
        // Log.v(TAG,"Saved cumulative time: ${cumulativeDistractionTimeMillis/1000}s") // Verbose log
    }

    private fun sendStatusUpdateBroadcast() {
        Log.v(TAG,"Sending status update broadcast")
        val intent = Intent(ACTION_STATUS_UPDATE_BROADCAST).apply {
            putExtra("cumulativeMillis", cumulativeDistractionTimeMillis)
            putExtra("limitMillis", totalDistractionLimitMillis)
            putExtra("tasksComplete", tasksComplete)
            val limitReached = cumulativeDistractionTimeMillis >= totalDistractionLimitMillis
            val shouldActuallyBlock = isActive && limitReached && !tasksComplete && blockAfterLimit
            putExtra("isBlocking", shouldActuallyBlock)
            putExtra("currentForegroundApp", currentlyForegroundAppPkg ?: "")
             `package` = packageName
        }
        try { sendBroadcast(intent) }
        catch (e: Exception) { Log.e(TAG, "Error sending status broadcast", e) }
    }

} // End DisciplineService












