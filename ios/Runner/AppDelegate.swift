import FirebaseCore
import Flutter
import UIKit
import YandexMapsMobile

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    YMKMapKit.setApiKey("f9754681-7a24-46de-b153-16e51d552998")
    let hasGoogleServiceInfo = Bundle.main.path(
      forResource: "GoogleService-Info",
      ofType: "plist"
    ) != nil
    if hasGoogleServiceInfo && FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
