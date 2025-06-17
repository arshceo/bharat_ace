import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.example.bharatace/app_control", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        guard let strongSelf = self else { return }  // Ensure self is valid
        if (call.method == "enableAppBlocking") {
            // iOS has extremely limited app blocking capabilities.

            // The best you can do is suggest Guided Access or a system-level focus mode.
            //  Provide instructions or a link to settings.  You cannot programmatically enforce it.

            // ... (Optionally implement other focus-related features)


        } else if (call.method == "disableAppBlocking") {
           // ... (iOS-specific disable logic, if any)

        } else {
             result.notImplemented()
        }

    }) // End channel handler
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}