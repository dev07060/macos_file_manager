import Cocoa
import FlutterMacOS
import WebKit

public class CustomWebviewPlugin: NSObject, FlutterPlugin {
    private var webviewInstances: [Int64: CustomWebviewController] = [:]
    private var nextWebviewId: Int64 = 0
    private var methodChannel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "custom_webview_plugin",
            binaryMessenger: registrar.messenger
        )
        let instance = CustomWebviewPlugin()
        instance.methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "createWebview":
            createWebview(call: call, result: result)
        case "loadUrl":
            loadUrl(call: call, result: result)
        case "goBack":
            goBack(call: call, result: result)
        case "goForward":
            goForward(call: call, result: result)
        case "reload":
            reload(call: call, result: result)
        case "evaluateJavaScript":
            evaluateJavaScript(call: call, result: result)
        case "getCurrentUrl":
            getCurrentUrl(call: call, result: result)
        case "getTitle":
            getTitle(call: call, result: result)
        case "isLoading":
            isLoading(call: call, result: result)
        case "canGoBack":
            canGoBack(call: call, result: result)
        case "canGoForward":
            canGoForward(call: call, result: result)
        case "sendMessageToJS":
            sendMessageToJS(call: call, result: result)
        case "injectJavaScript":
            injectJavaScript(call: call, result: result)
        case "disposeWebview":
            disposeWebview(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func createWebview(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let webviewId = nextWebviewId
        nextWebviewId += 1
        
        let controller = CustomWebviewController(webviewId: webviewId, methodChannel: methodChannel)
        webviewInstances[webviewId] = controller
        
        result(webviewId)
    }
    
    private func loadUrl(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let url = args["url"] as? String,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        controller.loadUrl(url: url) { success, error in
            if success {
                result(nil)
            } else {
                result(FlutterError(code: "LOAD_ERROR", message: error, details: nil))
            }
        }
    }
    
    private func goBack(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let canGoBack = controller.goBack()
        result(canGoBack)
    }
    
    private func goForward(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let canGoForward = controller.goForward()
        result(canGoForward)
    }
    
    private func reload(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        controller.reload()
        result(nil)
    }
    
    private func evaluateJavaScript(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let script = args["script"] as? String,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        controller.evaluateJavaScript(script: script) { jsResult, error in
            if let error = error {
                result(FlutterError(code: "JS_ERROR", message: error, details: nil))
            } else {
                result(jsResult)
            }
        }
    }
    
    private func getCurrentUrl(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let currentUrl = controller.getCurrentUrl()
        result(currentUrl)
    }
    
    private func getTitle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let title = controller.getTitle()
        result(title)
    }
    
    private func isLoading(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let loading = controller.isLoading()
        result(loading)
    }
    
    private func canGoBack(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let canGoBack = controller.canGoBack()
        result(canGoBack)
    }
    
    private func canGoForward(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let canGoForward = controller.canGoForward()
        result(canGoForward)
    }
    
    private func sendMessageToJS(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let message = args["message"] as? [String: Any],
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        controller.sendMessageToJS(message: message) { success, error in
            if success {
                result(nil)
            } else {
                result(FlutterError(code: "MESSAGE_ERROR", message: error, details: nil))
            }
        }
    }
    
    private func injectJavaScript(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64,
              let script = args["script"] as? String,
              let controller = webviewInstances[webviewId] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        controller.injectJavaScript(script: script) { success, error in
            if success {
                result(nil)
            } else {
                result(FlutterError(code: "INJECTION_ERROR", message: error, details: nil))
            }
        }
    }
    
    private func disposeWebview(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let webviewId = args["webviewId"] as? Int64 else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        if let controller = webviewInstances[webviewId] {
            controller.dispose()
            webviewInstances.removeValue(forKey: webviewId)
        }
        
        result(nil)
    }
}