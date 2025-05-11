package com.example.bharat_ace // Replace with your package name

// import android.app.admin.DevicePolicyManager // *** ADD THIS IMPORT ***
// import android.content.ComponentName       // *** ADD THIS IMPORT ***
import android.content.Context
import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View // Import View
import android.view.Window
import android.widget.Button
import android.widget.TextView
import com.example.bharat_ace.R // Import R class

class BlockingOverlayActivity : Activity() { // Use android.app.Activity for simplicity
    private val TAG = "BlockingOverlayActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate called.")
        // Remove title bar, make fullscreen (optional, theme might handle it)
        // requestWindowFeature(Window.FEATURE_NO_TITLE)
        // window.setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN)

        // Set the transparent theme defined in styles.xml
        setTheme(R.style.Theme_TransparentActivity)

        // Set the content view to your overlay layout
        setContentView(R.layout.blocking_overlay) // Use the SAME layout file

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager?
        // val adminComponent = ComponentName(this, AppDeviceAdminReceiver::class.java) // Your admin receiver
        // if (dpm?.isDeviceOwnerApp(packageName) == true || dpm?.isProfileOwnerApp(packageName) == true || dpm?.isAdminActive(adminComponent) == true) {
        // // Check if lock task is permitted for this app
        // if (dpm.isLockTaskPermitted(packageName)) {
        // Log.i(TAG, "Starting Lock Task Mode...")
        // startLockTask()
        // } else {
        // Log.w(TAG, "Lock Task Mode is not permitted for this package.")
        // // You might need additional setup if not a device/profile owner
        // // Or rely on just disabling back/touch outside
        // }
        // } else {
        //     Log.w(TAG, "Cannot start Lock Task Mode: Not Device/Profile Owner or Active Admin.")
        // }

        // Get message from Intent (passed by the service)
        val message = intent?.getStringExtra("message") ?: "App usage limit reached."
        findViewById<TextView>(R.id.blocking_message)?.text = message

        findViewById<Button>(R.id.close_overlay_button)?.setOnClickListener {
            Log.d(TAG, "Close button clicked -> Finishing Activity & Launching Main App.")
            // --- Launch MainActivity ---
            try {
                 val mainAppIntent = Intent(this, MainActivity::class.java)
                 mainAppIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                 startActivity(mainAppIntent)
            } catch (e: Exception) { Log.e(TAG, "Error launching MainActivity", e) }

            // --- Finish THIS Activity ---
            finish()
            // NOTE: We are NOT sending ACTION_DISMISS to the service here.
            // The service will detect the blocked app is no longer foreground
            // on its next check cycle and will stop trying to launch this overlay.
        }

         // Prevent dismissing by tapping outside or back button (optional but recommended for blocking)
         setFinishOnTouchOutside(false)
    }

    // Override onBackPressed to prevent easily closing the blocker
     override fun onBackPressed() {
        // Currently do nothing to prevent back button dismissal
         Log.d(TAG, "Back button pressed - ignoring for blocking overlay.")
         // Or show a toast: Toast.makeText(this, "Please use the button to proceed.", Toast.LENGTH_SHORT).show()
        // super.onBackPressed() // Don't call super to block back press
     }

    // override fun onPause() {
    //     super.onPause()
    //      // Optional: If the user somehow manages to switch away, bring it back? (Can be annoying)
    //      // Log.d(TAG, "onPause - attempting to bring back to front")
    //      // val bringToFrontIntent = Intent(this, BlockingOverlayActivity::class.java)
    //      // bringToFrontIntent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
    //      // startActivity(bringToFrontIntent)
    // }


    override fun onDestroy() {
        Log.d(TAG, "onDestroy called.")
        super.onDestroy()
    }
}