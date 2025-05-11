// --- android/app/src/main/kotlin/com/your_package_name/DisciplineService.kt ---
package com.example.bharat_ace // Replace with your package name

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver // Import for the permission receiver
import android.content.IntentFilter    // Import for the permission receiver
import android.os.*
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.bharat_ace.R // Import R class
import java.util.Calendar

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
        const val ACTION_DISMISS = "com.bharatace.app.ACTION_DISMISS" // For overlay activity to notify service
        const val ACTION_RESET_USAGE = "com.bharatace.app.ACTION_RESET_USAGE"
        const val ACTION_PERMISSION_STATUS_UPDATE = "com.bharatace.app.PERMISSIONS_UPDATED" // Broadcast from MainActivity
        const val ACTION_STATUS_UPDATE_BROADCAST = "com.bharatace.app.ACTION_STATUS_UPDATE" // Broadcast to MainActivity/Flutter

        fun createNotificationChannelIfNeeded(context: Context) {
             if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                 val name = "BharatAce Focus Service"; val descriptionText = "Monitors app usage."; val importance = NotificationManager.IMPORTANCE_LOW
                 val channel = NotificationChannel(CHANNEL_ID, name, importance).apply { description = descriptionText; setShowBadge(false) }
                 val nm: NotificationManager? = ContextCompat.getSystemService(context, NotificationManager::class.java)
                 if (nm?.getNotificationChannel(CHANNEL_ID) == null) { try { nm?.createNotificationChannel(channel); Log.d(TAG, "Discipline Channel created: $CHANNEL_ID") } catch(e: Exception) { Log.e(TAG, "Failed to create channel", e)}}
             }
         }
    }

    // --- Service Instance Variables ---
    @Volatile private var wakeLock: PowerManager.WakeLock? = null
    @Volatile private var isServiceRunning = false
    private val serviceHandler = Handler(Looper.getMainLooper())
    private var usageStatsManager: UsageStatsManager? = null
    @Volatile private var isActive = true
    @Volatile private var blockAfterLimit = true
    @Volatile private var totalDistractionLimitMillis: Long = 30 * 60 * 1000L
    @Volatile private var distractingApps = listOf<String>()
    @Volatile private var tasksComplete = false
    @Volatile private var _hasUsagePermission = false // Updated by broadcast from MainActivity
    @Volatile private var _hasOverlayPermission = false // Also updated by broadcast from MainActivity
    @Volatile private var cumulativeDistractionTimeMillis: Long = 0
    @Volatile private var lastUsageCheckTimestamp: Long = System.currentTimeMillis()
    private val checkIntervalMillis: Long = 15 * 1000L // Check interval
    @Volatile private var currentlyForegroundAppPkg: String? = null
    private var permissionUpdateReceiver: BroadcastReceiver? = null


    private val sharedPrefs by lazy { getSharedPreferences("DisciplinePrefs", Context.MODE_PRIVATE) }
    private val TODAY_DATE_KEY = "usageTrackDate"
    private val CUMULATIVE_TIME_KEY = "cumulativeDistractionMs"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Discipline Service Created.")
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager?
        createNotificationChannelIfNeeded(this)
        registerPermissionUpdateReceiver() // Register to receive permission status updates
        loadCumulativeTime()
        Log.d(TAG, "Initial loaded time: ${cumulativeDistractionTimeMillis / 1000}s")
    }

    private fun _updatePermissionsFromIntent(intent: Intent?) { // From MainActivity when starting service
        if (intent == null) return
        _hasUsagePermission = intent.getBooleanExtra("initialUsageStatsGranted", _hasUsagePermission)
        _hasOverlayPermission = intent.getBooleanExtra("initialOverlayGranted", _hasOverlayPermission)
        Log.d(TAG, "Internal permissions updated from START Intent: Usage=$_hasUsagePermission, Overlay=$_hasOverlayPermission")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START_MONITORING
        Log.d(TAG, "onStartCommand received. Action: $action")

        // Always update permissions and settings from the intent if they are passed
        // This handles initial start and updates
        _updatePermissionsFromIntent(intent)
        _updateSettingsFromIntent(intent) // Ensure this also updates internal vars

        when (action) {
            ACTION_STOP_SERVICE -> { stopSelfCleanup(); return START_NOT_STICKY }
            ACTION_DISMISS -> { Log.d(TAG,"Dismiss Action received (likely overlay closed)"); stopSelfCleanup(); return START_NOT_STICKY } // Assume stop service
            ACTION_TASKS_COMPLETE -> { tasksComplete = true; Log.d(TAG, "Tasks complete."); checkUsageAndApplyRules(); return START_STICKY }
            ACTION_TASKS_INCOMPLETE -> { tasksComplete = false; Log.d(TAG, "Tasks incomplete."); checkUsageAndApplyRules(); return START_STICKY }
            ACTION_RESET_USAGE -> {
                 Log.i(TAG, "Resetting cumulative usage time..."); cumulativeDistractionTimeMillis = 0L; saveCumulativeTime();
                 sendStatusUpdateBroadcast(); checkUsageAndApplyRules(); return START_STICKY
            }
            // ACTION_UPDATE_SETTINGS handled by _updateSettingsFromIntent above
            // ACTION_PERMISSION_STATUS_UPDATE is handled by BroadcastReceiver now
        }

        if (!isServiceRunning && (action == ACTION_START_MONITORING || action == ACTION_UPDATE_SETTINGS)) {
            isServiceRunning = true
            val serviceNotification = buildForegroundNotification()
            try { startForeground(NOTIFICATION_ID_SERVICE, serviceNotification); Log.d(TAG, "Discipline Service started in foreground.") }
            catch (e: Exception) { Log.e(TAG, "Error starting foreground.", e); stopSelfCleanup(); return START_NOT_STICKY }
            acquireWakeLock()
            serviceHandler.removeCallbacks(usageCheckRunnable) // Ensure no duplicates
            serviceHandler.post(usageCheckRunnable) // Start checks
        }
        return START_STICKY
    }

    private fun _updateSettingsFromIntent(intent: Intent?) {
        if (intent == null) return
        Log.d(TAG, "Updating settings from Intent...")

    // Log ALL extras found in the intent for debugging
    // val bundle = intent.extras
    // if (bundle != null) {
    //     Log.d(TAG, "Intent Extras Bundle:")
    //     for (key in bundle.keySet()) {
    //         Log.d(TAG, "  Key: $key, Value: ${bundle.get(key)}")
    //     }
    // } else {
    //      Log.w(TAG, "Intent Extras Bundle is NULL.")
    // }

    // Attempt to extract and assign, log result
    val receivedBlockedApps = intent.getStringArrayListExtra("blockedApps")
    if (receivedBlockedApps != null) {
         Log.i(TAG, "Received 'blockedApps' extra: [${receivedBlockedApps.joinToString()}]")
         distractingApps = receivedBlockedApps // Assign the received list
    } else {
         Log.w(TAG, "'blockedApps' extra not found or not a StringArrayList. Keeping current: [${distractingApps.joinToString()}]")
         // Don't use ?: distractingApps here, handle null explicitly to see if extraction failed
    }

    // Use safe extraction with defaults
    // distractingApps = intent.getStringArrayListExtra("blockedApps") ?: distractingApps // <<< Log this
    totalDistractionLimitMillis = (intent.getIntExtra("limitMinutes", (totalDistractionLimitMillis / 60000).toInt()) * 60000L)
    blockAfterLimit = intent.getBooleanExtra("block", blockAfterLimit)
    isActive = intent.getBooleanExtra("isActive", isActive)
    // *** ADD DETAILED LOG ***
    Log.i(TAG, "SETTINGS UPDATED -> Active: $isActive, Block: $blockAfterLimit, Limit(ms): $totalDistractionLimitMillis, Apps Variable: [${distractingApps.joinToString()}]")

    if (!isActive) { stopSelfCleanup() }
         else { checkUsageAndApplyRules() } // Re-check rules after updating
    }


    override fun onDestroy() {
        Log.d(TAG, "Discipline Service Destroyed.")
        unregisterPermissionUpdateReceiver() // Unregister receiver
        stopSelfCleanup()
        super.onDestroy()
    }

    // --- BroadcastReceiver for Permission Updates ---
    private fun registerPermissionUpdateReceiver() {
        if (permissionUpdateReceiver == null) {
            Log.i(TAG, "Attempting to register PermissionUpdateReceiver...")
            permissionUpdateReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    Log.d(TAG, ">>> BroadcastReceiver onReceive CALLED. Action: ${intent?.action}")
                    if (context == null || intent == null) { return }
                    if (intent.action == ACTION_PERMISSION_STATUS_UPDATE) { // Match action string
                        val receivedStatus = intent.getBooleanExtra("usageStatsGranted", _hasUsagePermission)
                        Log.d(TAG, ">>> BR Received $ACTION_PERMISSION_STATUS_UPDATE. Before: $_hasUsagePermission. Intent: $receivedStatus")
                        if (_hasUsagePermission != receivedStatus) {
                            _hasUsagePermission = receivedStatus
                            Log.i(TAG, ">>> _hasUsagePermission updated TO: $_hasUsagePermission via Broadcast")
                            if(_hasUsagePermission) { checkUsageAndApplyRules() } else { removeBlockingActivityIfShown() }
                        } else { Log.d(TAG, "BR: Perm status unchanged ($_hasUsagePermission).") }
                    }
                }
            }
            val intentFilter = IntentFilter(ACTION_PERMISSION_STATUS_UPDATE) // Use correct action
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { ContextCompat.registerReceiver( applicationContext, permissionUpdateReceiver, intentFilter, ContextCompat.RECEIVER_NOT_EXPORTED )}
                else { applicationContext.registerReceiver(permissionUpdateReceiver, intentFilter) }
                Log.i(TAG, "PermissionUpdateReceiver REGISTERED successfully.")
            } catch (e: Exception) { Log.e(TAG, "!!! FAILED to register PermissionUpdateReceiver !!!", e); permissionUpdateReceiver = null }
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
        if (!isServiceRunning) return
        serviceHandler.removeCallbacks(usageCheckRunnable) // Prevent duplicates
        serviceHandler.postDelayed(usageCheckRunnable, checkIntervalMillis)
    }

    private val usageCheckRunnable = Runnable {
        if (!isServiceRunning) return@Runnable
        Log.d(TAG, "Running periodic usage check...")
        checkUsageAndApplyRules() // Perform the check
        scheduleUsageCheck() // Reschedule itself
    }

    private fun checkUsageAndApplyRules() {
        if (!isActive || usageStatsManager == null || !_hasUsagePermission) {
            Log.w(TAG, "Cannot check usage: Active=$isActive Mgr=${usageStatsManager != null} Perm=$_hasUsagePermission");
            // If permission was revoked, and an overlay activity *might* be shown (though unlikely if service just restarted)
            // it would be the activity's job to close itself if it can detect this.
            // For now, the service will just stop *launching new* blocking activities.
            return
        }

        val currentTime = System.currentTimeMillis()
        val calendar = Calendar.getInstance(); calendar.set(Calendar.HOUR_OF_DAY, 0); /* ... */
        val startOfDayMillis = calendar.timeInMillis

        // 1. Calculate Cumulative Time for Distracting Apps Today
        var currentDayTotalDistractionMillis = 0L // Calculate fresh for today
        try {
            val stats = usageStatsManager!!.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startOfDayMillis, currentTime)
            if (stats != null) {
                for (usageStats in stats) {
                    if (distractingApps.any { it.equals(usageStats.packageName, ignoreCase = true) }) { // Case insensitive check
                        currentDayTotalDistractionMillis += usageStats.totalTimeInForeground
                    }
                }
            }
            // Update and persist the official cumulative time
            if (cumulativeDistractionTimeMillis != currentDayTotalDistractionMillis) {
                Log.i(TAG, "Updating Cumulative Distraction Time: ${cumulativeDistractionTimeMillis/1000}s -> ${currentDayTotalDistractionMillis/1000}s")
                cumulativeDistractionTimeMillis = currentDayTotalDistractionMillis
                saveCumulativeTime()
            }
        } catch(e: Exception) { Log.e(TAG, "Error querying DAILY usage stats", e) }

        // 2. Determine Current Foreground App (More Robustly)
        var latestFgAppFromEvents: String? = null
        try {
            // Query events in a recent window (e.g., last (interval + buffer) seconds)
            val recentStartTime = currentTime - (checkIntervalMillis + 5000L) // Look back a bit more
            val events = usageStatsManager!!.queryEvents(recentStartTime, currentTime)
            var lastMoveToFgEvent: UsageEvents.Event? = null

            while (events.hasNextEvent()) {
                val event = UsageEvents.Event()
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    lastMoveToFgEvent = event
                } else if (event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                    // If the app that just went to background was our last known foreground app,
                    // it's no longer foreground.
                    if (lastMoveToFgEvent?.packageName == event.packageName) {
                        lastMoveToFgEvent = null // Invalidate it
                    }
                }
            }
            latestFgAppFromEvents = lastMoveToFgEvent?.packageName

            // Update the persistent currentlyForegroundAppPkg only if it changed
            if (currentlyForegroundAppPkg != latestFgAppFromEvents) {
                Log.i(TAG, "Current FG app changed from '$currentlyForegroundAppPkg' to '$latestFgAppFromEvents'")
                currentlyForegroundAppPkg = latestFgAppFromEvents
            }

        } catch (e: Exception) { Log.e(TAG, "Error querying RECENT usage events for foreground app", e) }

        // --- Apply Rules ---
        val limitReached = cumulativeDistractionTimeMillis >= totalDistractionLimitMillis
        val shouldBlock = isActive && limitReached && !tasksComplete && blockAfterLimit
        val isCurrentAppDistracting = currentlyForegroundAppPkg != null && distractingApps.any { it.equals(currentlyForegroundAppPkg, ignoreCase = true) }

        Log.d(TAG, "Check Results: ShouldBlock=$shouldBlock, CurrentFG=$currentlyForegroundAppPkg, IsDistracting=$isDistractingAppCurrentlyForeground, CumulativeTime=${cumulativeDistractionTimeMillis/1000}s of ${totalDistractionLimitMillis/1000}s")
        sendStatusUpdateBroadcast() // Send current status to Flutter

         if (shouldBlock && isDistractingAppCurrentlyForeground) {
             // The BlockingOverlayActivity should ideally check if it's already visible
             // to avoid launching multiple instances, though singleTask launchMode helps.
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
        Log.d(TAG, "Discipline Service initiating self-cleanup...")
        serviceHandler.removeCallbacks(usageCheckRunnable)
        isServiceRunning = false
        // No overlayView to remove directly from here
        releaseWakeLock()
        saveCumulativeTime()
        stopForeground(true)
        stopSelf()
    }

     // --- Build Foreground Notification ---
    private fun buildForegroundNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) { PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE } else { PendingIntent.FLAG_UPDATE_CURRENT }
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, flags)
        val smallIconResId = R.mipmap.ic_launcher // Or R.drawable.ic_launcher
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

   // Helper for removing overlay if permission is revoked
   private fun removeBlockingActivityIfShown() {
        // Since we launch an Activity, we can't directly "remove" it like a WindowManager view.
        // The Activity should close itself if its reason for being shown is no longer valid.
        // For now, if usage permission is revoked, the service will stop launching it.
        // If an instance is already shown, it will remain until the user closes it or its internal logic closes it.
        Log.d(TAG, "Block condition changed. New blocking activities won't be launched if not needed.")
   }


} // End DisciplineService












