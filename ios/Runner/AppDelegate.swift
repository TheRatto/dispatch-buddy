import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Register custom Foundation Models bridge
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let foundationModelsChannel = FlutterMethodChannel(name: "foundation_models",
                                                binaryMessenger: controller.binaryMessenger)
    
    let foundationModelsHandler = FoundationModelsHandler()
    foundationModelsChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      foundationModelsHandler.handleMethodCall(call: call, result: result)
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Handler for Foundation Models method calls
class FoundationModelsHandler {
    private var bridge: Any?
    
    init() {
        if #available(iOS 26.0, *) {
            bridge = FoundationModelsBridge()
        }
    }
    
    func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 26.0, *) {
            guard let bridge = bridge as? FoundationModelsBridge else {
                result(FlutterError(code: "NOT_AVAILABLE", 
                                  message: "Foundation Models not available on this iOS version", 
                                  details: nil))
                return
            }
            handleMethodCallWithBridge(call: call, result: result, bridge: bridge)
        } else {
            result(FlutterError(code: "NOT_AVAILABLE", 
                              message: "Foundation Models not available on this iOS version", 
                              details: nil))
        }
    }
    
    @available(iOS 26.0, *)
    private func handleMethodCallWithBridge(call: FlutterMethodCall, result: @escaping FlutterResult, bridge: FoundationModelsBridge) {
        
        switch call.method {
        case "initialize":
            Task {
                do {
                    try await bridge.initialize()
                    DispatchQueue.main.async {
                        result("Foundation Models initialized successfully")
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "INIT_ERROR", 
                                          message: error.localizedDescription, 
                                          details: nil))
                    }
                }
            }
            
        case "generateBriefing":
            guard let args = call.arguments as? [String: Any],
                  let prompt = args["prompt"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", 
                                  message: "Invalid arguments", 
                                  details: nil))
                return
            }
            
            Task {
                do {
                    let briefing = try await bridge.generateBriefing(prompt: prompt)
                    DispatchQueue.main.async {
                        result(briefing)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "GENERATION_ERROR", 
                                          message: error.localizedDescription, 
                                          details: nil))
                    }
                }
            }
            
        case "checkAvailability":
            let availability = bridge.checkAvailability()
            let resultDict: [String: Any] = [
                "available": availability.isAvailable,
                "osVersion": availability.osVersion,
                "error": availability.errorMessage ?? ""
            ]
            result(resultDict)
            
        case "cancel":
            bridge.cancel()
            result("Operation cancelled")
            
        case "dispose":
            bridge.dispose()
            result("Resources disposed")
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
