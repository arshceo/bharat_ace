package com.example.bharat_ace // replace with your package name

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast // Example for showing status

class AppDeviceAdminReceiver : DeviceAdminReceiver() {
    private val TAG = "AppDeviceAdminReceiver"

    // Simple way to show user feedback, you might replace this with channel calls
    private fun showToast(context: Context, msg: String) {
        // Toast.makeText(context, msg, Toast.LENGTH_SHORT).show() // Commented out to avoid context issues if used improperly
        Log.d(TAG, msg) // Log instead of Toast for background safety
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        showToast(context, "BharatAce Device Admin Enabled.")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        showToast(context, "BharatAce Device Admin Disabled.")
    }

     override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // Optional: Provide a custom message when user tries to disable admin
        return "Disabling administrator may prevent discipline features from working correctly."
    }

    // Add other overrides as needed for specific policies
}