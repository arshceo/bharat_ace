// --- android/app/src/main/kotlin/com/your_package_name/AlarmReceiver.kt ---
package com.example.bharat_ace // Replace with your actual package name

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri // Needed for URI parsing
import android.os.Build
import android.os.PowerManager
import android.provider.Settings // Needed for Notification Channel settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.bharat_ace.R // Import R class for drawable resource

class AlarmReceiver : BroadcastReceiver() {

    // Companion object only holds constants and static helpers if needed
    companion object {
        private const val TAG = "AlarmReceiver"
        private const val WAKELOCK_TAG = "$TAG::ReceiverWakeLock"
        const val CHANNEL_ID = "BHARATACE_ALARM_CHANNEL" // Make public if needed by Service/MainActivity
        private const val NOTIFICATION_ID_FULLSCREEN = 1235

         // --- Helper to Create Notification Channel ---
         // This *can* be static, call it from MainActivity/Application on startup
         fun createNotificationChannelIfNeeded(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val name = "BharatAce Alarms"
                val descriptionText = "Urgent study task reminders"
                val importance = NotificationManager.IMPORTANCE_HIGH
                val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                    description = descriptionText
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 600, 200, 600, 200, 600)
                    setBypassDnd(true)
                    // *** FIX: Use correct visibility constant ***
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC // From android.app.Notification
                }
                val notificationManager: NotificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (notificationManager.getNotificationChannel(CHANNEL_ID) == null) {
                    notificationManager.createNotificationChannel(channel)
                    Log.d(TAG, "Notification channel created: $CHANNEL_ID")
                }
            }
         }

          // Static helper to trigger the full-screen notification (can be called by Service too)
         fun triggerFullScreenNotification(context: Context) {
            createNotificationChannelIfNeeded(context)

            val mainActivityIntent = Intent(context, MainActivity::class.java).apply {
                 flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                 putExtra("navigate_to", AppRoutes.alarm) // Using Kotlin object now
                 putExtra("alarm_triggered", true)
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val fullScreenPendingIntent = PendingIntent.getActivity(context, 1, mainActivityIntent, flags)
            val smallIconResId = R.mipmap.ic_launcher

            val notificationBuilder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(smallIconResId)
                .setContentTitle("BharatAce: Focus Time!")
                .setContentText("Your scheduled study reminder.")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC) // Use Compat version
                .setContentIntent(fullScreenPendingIntent)
                .setFullScreenIntent(fullScreenPendingIntent, true)

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID_FULLSCREEN, notificationBuilder.build())
            Log.d(TAG, "Full-Screen Notification posted with ID $NOTIFICATION_ID_FULLSCREEN.")
        }

    } // End Companion Object

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null) { Log.e(TAG, "Context is null in onReceive."); return }
        Log.d(TAG, ">>> ALARM RECEIVED! Starting AlarmForegroundService... <<<")

        // Acquire temporary WakeLock
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager?
        val wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG)
        var wakeLockAcquired = false
        try {
            wakeLock?.setReferenceCounted(false)
            wakeLock?.acquire(10 * 1000L)
            wakeLockAcquired = true
            Log.d(TAG, "Receiver WakeLock acquired.")

            // Start the Foreground Service
            val serviceIntent = Intent(context, AlarmForegroundService::class.java)
            Log.d(TAG,"Attempting to start AlarmForegroundService...")
            ContextCompat.startForegroundService(context, serviceIntent) // Handles O+ automatically
            Log.d(TAG,"AlarmForegroundService start command issued.")

            // Trigger Full-Screen Notification
             triggerFullScreenNotification(context) // Call static helper

        } catch (e: Exception) { Log.e(TAG, "Error during AlarmReceiver onReceive", e) }
        finally { // Release the receiver's WakeLock
            if (wakeLockAcquired && wakeLock?.isHeld == true) { try { wakeLock.release(); Log.d(TAG, "Receiver WakeLock released.") } catch (e: Exception) { Log.e(TAG, "Error releasing Receiver WakeLock", e) } }
        }
    } // End onReceive
} // End AlarmReceiver

// Placeholder for AppRoutes used in triggerFullScreenNotification
// In real native code, you might pass this string via the initial alarm intent
// or have a shared constants file.
object AppRoutes {
    const val alarm = "/alarm";
    const val main_layout_nav = "/main_nav";
}