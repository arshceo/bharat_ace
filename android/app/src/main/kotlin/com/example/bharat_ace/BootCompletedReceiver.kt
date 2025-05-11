package com.example.bharat_ace // Replace with your package name

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

class BootCompletedReceiver : BroadcastReceiver() {
    private val TAG = "BootReceiver"

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null) return
        // Check for boot completed action
        if (Intent.ACTION_BOOT_COMPLETED == intent?.action || Intent.ACTION_LOCKED_BOOT_COMPLETED == intent?.action || "android.intent.action.QUICKBOOT_POWERON" == intent?.action) {
            Log.d(TAG, ">>> BOOT COMPLETED Received <<< Starting DisciplineService...")

            val serviceIntent = Intent(context, DisciplineService::class.java)
            try {
                // Use startForegroundService for reliability
                ContextCompat.startForegroundService(context, serviceIntent)
                Log.d(TAG, "DisciplineService start command issued on boot.")
            } catch (e: Exception) {
                // This might fail if app is in stopped state after install before first launch
                // or due to background restrictions on some devices after boot.
                Log.e(TAG, "Error starting DisciplineService on boot", e)
            }
        }
    }
}