import Flutter
import FirebaseCore
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("APPDELEGATE: didFinishLaunching start")
    if FirebaseApp.app() == nil {
      if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
        FirebaseApp.configure()
        NSLog("APPDELEGATE: Firebase configured from GoogleService-Info.plist")
      } else {
        NSLog("APPDELEGATE: GoogleService-Info.plist missing, relying on Dart Firebase options")
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    NSLog("APPDELEGATE: plugins registered")
    let result = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    NSLog("APPDELEGATE: didFinishLaunching end = %@", String(result))
    return result
  }
}
