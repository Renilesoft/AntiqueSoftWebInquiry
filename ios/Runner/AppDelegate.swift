import UIKit
import Flutter
import Firebase
import FirebaseMessaging        // ← ADD
import UserNotifications        // ← ADD

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FirebaseApp.configure()

    // ── ADD THIS BLOCK ──────────────────────────────────────
    UNUserNotificationCenter.current().delegate = self

    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { _, _ in }
    )

    application.registerForRemoteNotifications()   // ← triggers APNs token generation
    // ────────────────────────────────────────────────────────

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ── ADD THIS ENTIRE FUNCTION ─────────────────────────────
  // Passes the APNs device token to Firebase so FCM token can be generated
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
  }
  // ─────────────────────────────────────────────────────────
}