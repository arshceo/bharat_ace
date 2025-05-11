// --- android/app/src/main/kotlin/com/your_package_name/AlarmForegroundService.kt ---
package com.example.bharat_ace // Replace with your package name

import android.app.*
import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.graphics.PixelFormat
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.*
import android.provider.Settings
import android.util.Log
import android.view.*
import android.widget.Button
import android.widget.TextView
import android.widget.Toast // *** ADDED IMPORT ***
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.bharat_ace.R
import java.util.Timer
import java.util.TimerTask
import kotlin.concurrent.schedule

class AlarmForegroundService : Service(), AudioManager.OnAudioFocusChangeListener {

    companion object {
        private const val TAG = "AlarmForegroundService"
        const val CHANNEL_ID = "BHARATACE_ALARM_CHANNEL" // Ensure consistent ID
        private const val NOTIFICATION_ID_SERVICE = 567
        private const val WAKELOCK_TAG = "$TAG::ServiceWakeLock"
        const val ACTION_SNOOZE = "com.bharatace.app.ACTION_SNOOZE" // Action for Snooze Intent
        const val ACTION_DISMISS = "com.bharatace.app.ACTION_DISMISS" // Action for Dismiss Intent
        // Ensure AppRoutes exists or replace "/alarm" and "/main_nav" with actual strings
        // object AppRoutes { const val alarm = "/alarm"; const val main_layout_nav = "/main_nav"; }
    }

    // --- Service Instance Variables ---
    private var mediaPlayer: MediaPlayer? = null
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioManager: AudioManager? = null
    private var originalAlarmVolume: Int = -1
    private var snoozeCount = 3 // Max snoozes allowed
    private var snoozeTimer: Timer? = null // Use java.util.Timer
    private var isSnoozed = false
    private val handler = Handler(Looper.getMainLooper()) // Handler for UI updates from background threads if needed

    // --- Service Lifecycle Methods ---
    override fun onBind(intent: Intent?): IBinder? = null // Not a bound service

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Foreground Service Created.")
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        // Notification channel should be created reliably on app start (e.g., in MainActivity or Application class)
         AlarmReceiver.createNotificationChannelIfNeeded(this) // Call static helper to ensure
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand received. Action: ${intent?.action}")

        // Handle explicit actions first
        when (intent?.action) {
            ACTION_SNOOZE -> {
                handleSnoozeCommand() // Handle snooze internally
                return START_STICKY // Keep service running
            }
            ACTION_DISMISS -> {
                handleDismissCommand() // Handle dismiss internally
                return START_NOT_STICKY // Stop service after dismiss
            }
        }

        // --- Normal Service Start Logic ---
        val serviceNotification = buildForegroundNotification()
        try {
           startForeground(NOTIFICATION_ID_SERVICE, serviceNotification)
           Log.d(TAG, "Service started in foreground.")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service. Maybe missing permission?", e)
            // If foreground fails, can't reliably run. Stop self?
            stopSelfCleanup()
            return START_NOT_STICKY
        }

        acquireWakeLock()
        val taskInfo = intent?.getStringExtra("task_details") // Get passed task info
        showOverlay(taskInfo) // Show overlay UI
        startAlarmSoundAndMonitorVolume() // Start sound

        return START_STICKY // Try to restart if killed
    }

    override fun onDestroy() {
        Log.d(TAG, "Foreground Service Destroyed.")
        stopSelfCleanup() // Ensure all resources are released
        super.onDestroy()
    }

     // --- Audio Focus Change Listener ---
    override fun onAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS -> {
                Log.w(TAG, "Audio focus lost permanently. Stopping sound.")
                // *** FIX: Call correct method ***
                stopAndReleasePlayer()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                Log.w(TAG, "Audio focus lost temporarily. Stopping sound.")
                // *** FIX: Call correct method ***
                stopAndReleasePlayer()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                Log.w(TAG, "Audio focus lost temporarily (can duck). Stopping sound.")
                // *** FIX: Call correct method ***
                stopAndReleasePlayer()
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                 Log.d(TAG, "Audio focus gained.")
                 // Restart only if not snoozed and player is null/stopped
                if (!isSnoozed && mediaPlayer == null) { // Check if null (means it was released)
                   Log.d(TAG,"Audio focus gained: Restarting sound.")
                   startAlarmSoundAndMonitorVolume()
                 } else if (!isSnoozed && mediaPlayer?.isPlaying == false) {
                     Log.d(TAG,"Audio focus gained: Resuming sound.")
                     try { mediaPlayer?.start() } catch (e: Exception) { Log.e(TAG, "Error resuming mediaplayer", e)}
                 }
            }
        }
    }


    // --- Foreground Notification ---
    private fun buildForegroundNotification(): Notification {
         val notificationIntent = Intent(this, MainActivity::class.java)
         val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
         return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BharatAce Alarm Active")
            .setContentText("Study reminder is active.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    // --- WakeLock Management ---
    private fun acquireWakeLock() {
         if (wakeLock == null) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager?
            wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG)
            wakeLock?.setReferenceCounted(false)
         }
         if (wakeLock?.isHeld == false) {
            wakeLock?.acquire(10*60*1000L) // Hold for up to 10 mins max (should be released sooner)
            Log.d(TAG, "Service WakeLock acquired.")
         }
    }
    private fun releaseWakeLock() {
        if (wakeLock?.isHeld == true) {
           try { wakeLock?.release() } catch (e: Exception) { Log.e(TAG, "Wakelock release error", e)}
            Log.d(TAG, "Service WakeLock released.")
        }
        wakeLock = null
    }

    // --- Overlay Management ---
     private fun showOverlay(taskInfo: String?) {
        if (overlayView != null || windowManager == null) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Log.e(TAG, "Cannot show overlay: Permission denied.")
            return
        }

        val inflater = LayoutInflater.from(this)
        overlayView = inflater.inflate(R.layout.alarm_overlay, null) // Use correct R class import

        // --- Window Manager Layout Params ---
        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT, overlayType,
            // Adjusted flags: Allow touch events within the overlay, keep screen on
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.CENTER

        // --- Setup Buttons and Text ---
        try {
            val snoozeButton = overlayView?.findViewById<Button>(R.id.snooze_button)
            val dismissButton = overlayView?.findViewById<Button>(R.id.dismiss_button)
            val taskInfoText = overlayView?.findViewById<TextView>(R.id.alarm_task_info)
            val snoozeCountText = overlayView?.findViewById<TextView>(R.id.snooze_count_text)

            taskInfoText?.text = taskInfo ?: "Time to focus on your BharatAce tasks!"
            updateSnoozeCountText(snoozeCountText) // Initial update

            snoozeButton?.setOnClickListener { handleSnoozeCommand() } // Trigger internal command
            dismissButton?.setOnClickListener { handleDismissCommand() } // Trigger internal command

            windowManager?.addView(overlayView, params)
            Log.d(TAG, "Overlay view added.")
        } catch (e: Exception) { Log.e(TAG, "Error setting up or adding overlay view", e) }
    }

    private fun removeOverlay() {
        if (overlayView != null && windowManager != null) {
            try { windowManager?.removeView(overlayView) }
            catch (e: Exception) { Log.e(TAG, "Error removing overlay view", e) }
            finally { overlayView = null; Log.d(TAG, "Overlay view removed.") }
        }
    }

    // --- Sound & Volume Management ---
     private fun startAlarmSoundAndMonitorVolume() {
        if (mediaPlayer?.isPlaying == true) { Log.w(TAG, "Sound already playing."); return }
        stopAndReleasePlayer() // Clean up previous instance

        if (audioManager == null) { Log.e(TAG, "AudioManager null, cannot play sound."); stopSelfCleanup(); return }

        try {
            // Set Max Volume (Best effort)
            originalAlarmVolume = audioManager!!.getStreamVolume(AudioManager.STREAM_ALARM)
            val maxVolume = audioManager!!.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            try { audioManager!!.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0) }
            catch (se: SecurityException) { Log.e(TAG, "MODIFY_AUDIO_SETTINGS permission likely missing.", se)}
            Log.d(TAG, "Set alarm volume attempt to MAX ($maxVolume). Original was $originalAlarmVolume")

            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            if (alarmUri != null) {
                // Request audio focus
                 val focusRequestResult = audioManager!!.requestAudioFocus(this, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN) // Request focus and pass listener

                 if (focusRequestResult == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                     Log.d(TAG, "Audio focus granted.")
                     mediaPlayer = MediaPlayer().apply {
                         setDataSource(applicationContext, alarmUri)
                         setAudioStreamType(AudioManager.STREAM_ALARM)
                         isLooping = true
                         prepare()
                         start()
                         Log.d(TAG, "MediaPlayer playback started by service (looping).")
                         setOnErrorListener { _, _, _ -> Log.e(TAG, "MediaPlayer Error"); stopSelfCleanup(); true }
                     }
                     // registerVolumeObserver() // Deferring volume observer - too unreliable
                 } else {
                      Log.e(TAG, "Audio focus not granted. Cannot play alarm sound reliably.");
                      // Consider stopping service or just showing notification without sound
                       stopSelfCleanup() // Stop if focus fails
                 }
            } else { Log.e(TAG, "Could not get alarm URI."); stopSelfCleanup() }
        } catch (e: Exception) { Log.e(TAG, "Error setting volume or playing sound", e); stopSelfCleanup() }
    }

    private fun stopAndReleasePlayer() {
          if (mediaPlayer?.isPlaying == true) { try { mediaPlayer?.stop() } catch (e: Exception) {} }
          try { mediaPlayer?.release() } catch (e: Exception) {}
          mediaPlayer = null
          audioManager?.abandonAudioFocus(this) // Abandon focus using the listener
          Log.d(TAG,"Stopped and released MediaPlayer instance.")
     }

    private fun restoreOriginalVolume() {
       if (originalAlarmVolume != -1 && audioManager != null) {
           Log.d(TAG, "Attempting to restore original alarm volume to $originalAlarmVolume")
           try {
               val maxVolume = audioManager!!.getStreamMaxVolume(AudioManager.STREAM_ALARM)
               val volumeToSet = originalAlarmVolume.coerceIn(0, maxVolume)
               audioManager!!.setStreamVolume(AudioManager.STREAM_ALARM, volumeToSet, 0)
           } catch (e: Exception) { Log.e(TAG, "Error restoring volume", e) }
           finally { originalAlarmVolume = -1 }
       }
    }

    // --- Command Handlers ---
    private fun handleSnoozeCommand() {
        Log.d(TAG, "Snooze command received in service.")
        if (isSnoozed) { Log.w(TAG,"Already snoozed."); return }
        if (snoozeCount > 0) {
            isSnoozed = true
            snoozeCount--
            updateSnoozeCountText(overlayView?.findViewById(R.id.snooze_count_text))
            stopAndReleasePlayer() // Stop sound and release audio focus
            snoozeTimer?.cancel()
            snoozeTimer = Timer()
            snoozeTimer?.schedule(30 * 1000L) {
                if (!isSnoozed) return@schedule
                Log.d(TAG, "Snooze finished. Restarting alarm.")
                handler.post { isSnoozed = false; startAlarmSoundAndMonitorVolume() }
            }
        } else { Log.d(TAG, "No snoozes left."); Toast.makeText(this, "No snoozes left!", Toast.LENGTH_SHORT).show() }
    }

    private fun handleDismissCommand() {
        Log.d(TAG, "Dismiss command received in service.")
        // --- Launch MainActivity AFTER cleanup ---
        stopSelfCleanup() // Stop service, sound, overlay first

        try {
             val mainActivityIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                // *** FIX: Use literal string for route name ***
                putExtra("navigate_to", "/main_nav") // Or your actual route string
             }
             startActivity(mainActivityIntent)
         } catch (e: Exception) { Log.e(TAG, "Error starting MainActivity on dismiss", e) }
    }

    private fun updateSnoozeCountText(snoozeCountTextView: TextView?) {
         if (snoozeCountTextView == null) return
         handler.post { // Ensure UI update is on main thread
             snoozeCountTextView.text = "Snoozes left: $snoozeCount"
             overlayView?.findViewById<Button>(R.id.snooze_button)?.isEnabled = snoozeCount > 0
         }
    }

     // Central cleanup method
    private fun stopSelfCleanup() {
        Log.d(TAG, "Service initiating self-cleanup...")
        snoozeTimer?.cancel(); snoozeTimer = null
        isSnoozed = false
        // unregisterVolumeObserver() // Removed volume observer
        stopAndReleasePlayer() // Stop sound and release audio focus
        removeOverlay()
        restoreOriginalVolume()
        releaseWakeLock()
        stopForeground(true) // Remove foreground notification
        stopSelf()           // Stop the service
    }

} // End AlarmForegroundService