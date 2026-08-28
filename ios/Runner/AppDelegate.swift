import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(name: "com.soluro.app/clipboard", binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "ClipboardPlugin").messenger())

    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "copyImage" {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["path"] as? String,
              let image = UIImage(contentsOfFile: imagePath) else {
          result(false)
          return
        }
        UIPasteboard.general.image = image
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
  }
}
