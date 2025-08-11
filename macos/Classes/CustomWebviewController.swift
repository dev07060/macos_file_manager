import Cocoa
import FlutterMacOS
import WebKit

class CustomWebviewController: NSObject {
    private let webviewId: Int64
    private var webView: WKWebView?
    private weak var methodChannel: FlutterMethodChannel?
    
    init(webviewId: Int64, methodChannel: FlutterMethodChannel? = nil) {
        self.webviewId = webviewId
        self.methodChannel = methodChannel
        super.init()
        setupWebView()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        
        // Enable JavaScript
        configuration.preferences.javaScriptEnabled = true
        
        // Enable developer extras for debugging
        if #available(macOS 13.3, *) {
            configuration.preferences.isElementFullscreenEnabled = true
        }
        
        // Configure website data store for better performance
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        // Configure user content controller for JavaScript communication
        let userContentController = WKUserContentController()
        
        // Add script message handler for Flutter communication
        userContentController.add(self, name: "flutterWebview")
        
        // Inject JavaScript bridge initialization script
        let bridgeInitScript = WKUserScript(
            source: getBridgeInitializationScript(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(bridgeInitScript)
        
        configuration.userContentController = userContentController
        
        // Configure process pool for better resource management
        configuration.processPool = WKProcessPool()
        
        // Enable media playback
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Create the webview with proper frame
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: configuration)
        webView?.navigationDelegate = self
        webView?.uiDelegate = self
        
        // Configure webview properties
        webView?.allowsBackForwardNavigationGestures = true
        webView?.allowsMagnification = true
        webView?.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        
        // Set up auto-layout constraints if needed
        webView?.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func loadUrl(url: String, completion: @escaping (Bool, String?) -> Void) {
        guard let webView = webView else {
            completion(false, "WebView not initialized")
            return
        }
        
        // Validate and normalize URL
        var urlString = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add protocol if missing
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") && !urlString.hasPrefix("file://") {
            urlString = "https://" + urlString
        }
        
        // Special handling for Google.com to ensure reliable loading
        if urlString.contains("google.com") && !urlString.contains("www.") {
            urlString = urlString.replacingOccurrences(of: "://google.com", with: "://www.google.com")
        }
        
        guard let url = URL(string: urlString) else {
            completion(false, "Invalid URL format: \(urlString)")
            return
        }
        
        // Create request with proper headers for better compatibility
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 30.0
        
        // Add headers for better compatibility with Google.com
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
        // Load the request
        webView.load(request)
        completion(true, nil)
    }
    
    func goBack() -> Bool {
        guard let webView = webView else { return false }
        
        if webView.canGoBack {
            webView.goBack()
            return true
        }
        return false
    }
    
    func goForward() -> Bool {
        guard let webView = webView else { return false }
        
        if webView.canGoForward {
            webView.goForward()
            return true
        }
        return false
    }
    
    func reload() {
        webView?.reload()
    }
    
    func evaluateJavaScript(script: String, completion: @escaping (Any?, String?) -> Void) {
        guard let webView = webView else {
            completion(nil, "WebView not initialized")
            return
        }
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                completion(nil, error.localizedDescription)
            } else {
                completion(result, nil)
            }
        }
    }
    
    func getCurrentUrl() -> String? {
        return webView?.url?.absoluteString
    }
    
    func getTitle() -> String? {
        return webView?.title
    }
    
    func isLoading() -> Bool {
        return webView?.isLoading ?? false
    }
    
    func canGoBack() -> Bool {
        return webView?.canGoBack ?? false
    }
    
    func canGoForward() -> Bool {
        return webView?.canGoForward ?? false
    }
    
    func sendMessageToJS(message: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        guard let webView = webView else {
            completion(false, "WebView not initialized")
            return
        }
        
        // Convert message to JSON string
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            
            // Create JavaScript code to send message using the bridge
            let script = """
                (function() {
                    try {
                        const message = \(jsonString);
                        if (window.flutterBridge && window.flutterBridge.handleMessage) {
                            window.flutterBridge.handleMessage(message);
                        } else if (window.flutter_webview_message_handler) {
                            window.flutter_webview_message_handler(message);
                        } else {
                            console.log('Flutter message (no handler):', message);
                        }
                        return true;
                    } catch (error) {
                        console.error('Error handling Flutter message:', error);
                        return false;
                    }
                })();
            """
            
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, "Failed to serialize message: \(error.localizedDescription)")
        }
    }
    
    private func getBridgeInitializationScript() -> String {
        return """
            (function() {
                // Prevent multiple injections
                if (window.flutterBridgeNative) {
                    return;
                }
                
                // Mark that native bridge is available
                window.flutterBridgeNative = true;
                
                // Enhanced error handling and logging
                window.flutterBridgeLog = function(message, level) {
                    const logLevel = level || 'info';
                    const timestamp = new Date().toISOString();
                    console[logLevel]('[FlutterBridge ' + timestamp + ']', message);
                };
                
                // Enhanced message validation
                window.flutterBridgeValidateMessage = function(message) {
                    if (!message || typeof message !== 'object') {
                        return { valid: false, error: 'Message must be an object' };
                    }
                    
                    if (!message.type || typeof message.type !== 'string') {
                        return { valid: false, error: 'Message must have a string type' };
                    }
                    
                    if (!message.data || typeof message.data !== 'object') {
                        return { valid: false, error: 'Message must have a data object' };
                    }
                    
                    return { valid: true };
                };
                
                // Debug mode detection
                window.flutterBridgeDebug = window.location.hostname === 'localhost' || 
                                           window.location.hostname === '127.0.0.1' ||
                                           window.location.search.includes('debug=true');
                
                if (window.flutterBridgeDebug) {
                    window.flutterBridgeLog('Flutter bridge native initialization script loaded', 'info');
                }
            })();
        """
    }
    
    func injectJavaScript(script: String, completion: @escaping (Bool, String?) -> Void) {
        guard let webView = webView else {
            completion(false, "WebView not initialized")
            return
        }
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    
    func getWebView() -> WKWebView? {
        return webView
    }
    
    func dispose() {
        guard let webView = webView else { return }
        
        // Stop any ongoing navigation
        webView.stopLoading()
        
        // Clear delegates
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        
        // Remove script message handlers
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "flutterWebview")
        
        // Clear website data if needed
        let dataStore = webView.configuration.websiteDataStore
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) { }
        
        // Remove from superview
        webView.removeFromSuperview()
        
        // Clear reference
        self.webView = nil
        
        print("WebView \(webviewId) disposed successfully")
    }
    
    private func sendMessageToFlutter(method: String, arguments: [String: Any]?) {
        guard let methodChannel = methodChannel else {
            print("WebView Event (no channel): \(method), Args: \(arguments ?? [:])")
            return
        }
        
        // Send the message to Flutter on the main thread
        DispatchQueue.main.async {
            methodChannel.invokeMethod(method, arguments: arguments)
        }
    }
}

// MARK: - WKNavigationDelegate
extension CustomWebviewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        sendMessageToFlutter(method: "onPageStarted", arguments: [
            "webviewId": webviewId,
            "url": webView.url?.absoluteString ?? ""
        ])
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // Page has started loading content
        sendMessageToFlutter(method: "onNavigationStateChanged", arguments: [
            "webviewId": webviewId,
            "canGoBack": webView.canGoBack,
            "canGoForward": webView.canGoForward
        ])
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        sendMessageToFlutter(method: "onPageFinished", arguments: [
            "webviewId": webviewId,
            "url": webView.url?.absoluteString ?? "",
            "title": webView.title ?? ""
        ])
        
        // Update navigation state
        sendMessageToFlutter(method: "onNavigationStateChanged", arguments: [
            "webviewId": webviewId,
            "canGoBack": webView.canGoBack,
            "canGoForward": webView.canGoForward
        ])
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        sendMessageToFlutter(method: "onPageError", arguments: [
            "webviewId": webviewId,
            "error": error.localizedDescription,
            "code": nsError.code,
            "domain": nsError.domain
        ])
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        sendMessageToFlutter(method: "onPageError", arguments: [
            "webviewId": webviewId,
            "error": error.localizedDescription,
            "code": nsError.code,
            "domain": nsError.domain
        ])
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Log navigation for debugging
        let navigationTypeString = getNavigationTypeString(navigationAction.navigationType)
        let targetURL = navigationAction.request.url?.absoluteString ?? "unknown"
        
        // Handle different navigation types with enhanced logging
        switch navigationAction.navigationType {
        case .linkActivated:
            // User clicked a link - this is the main case for basic web navigation
            sendMessageToFlutter(method: "onNavigationStarted", arguments: [
                "webviewId": webviewId,
                "url": targetURL,
                "type": "link_clicked"
            ])
            decisionHandler(.allow)
            
        case .formSubmitted, .formResubmitted:
            // Form submission
            sendMessageToFlutter(method: "onNavigationStarted", arguments: [
                "webviewId": webviewId,
                "url": targetURL,
                "type": "form_submitted"
            ])
            decisionHandler(.allow)
            
        case .backForward:
            // Back/forward navigation
            sendMessageToFlutter(method: "onNavigationStarted", arguments: [
                "webviewId": webviewId,
                "url": targetURL,
                "type": "back_forward"
            ])
            decisionHandler(.allow)
            
        case .reload:
            // Page reload
            sendMessageToFlutter(method: "onNavigationStarted", arguments: [
                "webviewId": webviewId,
                "url": targetURL,
                "type": "reload"
            ])
            decisionHandler(.allow)
            
        case .other:
            // Other navigation types (programmatic, etc.)
            sendMessageToFlutter(method: "onNavigationStarted", arguments: [
                "webviewId": webviewId,
                "url": targetURL,
                "type": "other"
            ])
            decisionHandler(.allow)
            
        @unknown default:
            // Future navigation types
            decisionHandler(.allow)
        }
    }
    
    private func getNavigationTypeString(_ type: WKNavigationType) -> String {
        switch type {
        case .linkActivated: return "linkActivated"
        case .formSubmitted: return "formSubmitted"
        case .backForward: return "backForward"
        case .reload: return "reload"
        case .formResubmitted: return "formResubmitted"
        case .other: return "other"
        @unknown default: return "unknown"
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        // Handle response policy - could be used to block certain content types
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        // Handle server redirects
        sendMessageToFlutter(method: "onPageStarted", arguments: [
            "webviewId": webviewId,
            "url": webView.url?.absoluteString ?? ""
        ])
    }
}

// MARK: - WKUIDelegate
extension CustomWebviewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle popup windows by loading in the same webview
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}

// MARK: - WKScriptMessageHandler
extension CustomWebviewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "flutterWebview" {
            // Enhanced JavaScript message handling with validation and error handling
            do {
                var messageData: [String: Any]
                
                // Handle different message body types
                if let dict = message.body as? [String: Any] {
                    messageData = dict
                } else if let string = message.body as? String {
                    // Try to parse as JSON
                    if let data = string.data(using: .utf8),
                       let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        messageData = json
                    } else {
                        // Wrap plain string in a message structure
                        messageData = [
                            "type": "message",
                            "data": ["content": string],
                            "timestamp": ISO8601DateFormatter().string(from: Date())
                        ]
                    }
                } else {
                    // Handle other types by converting to string
                    messageData = [
                        "type": "message",
                        "data": ["content": String(describing: message.body)],
                        "timestamp": ISO8601DateFormatter().string(from: Date())
                    ]
                }
                
                // Add metadata
                messageData["webviewId"] = webviewId
                messageData["source"] = "javascript"
                
                // Validate message structure
                if messageData["type"] == nil {
                    messageData["type"] = "message"
                }
                
                if messageData["data"] == nil {
                    messageData["data"] = [:]
                }
                
                // Send to Flutter
                sendMessageToFlutter(method: "onJavaScriptMessage", arguments: [
                    "webviewId": webviewId,
                    "message": messageData
                ])
                
                // Debug logging
                if let debugMode = messageData["debug"] as? Bool, debugMode {
                    print("WebView \(webviewId) received JS message: \(messageData["type"] ?? "unknown")")
                }
                
            } catch {
                // Handle JSON parsing errors
                let errorMessage: [String: Any] = [
                    "type": "error",
                    "data": [
                        "error": "Failed to parse JavaScript message",
                        "details": error.localizedDescription,
                        "originalMessage": String(describing: message.body)
                    ],
                    "timestamp": ISO8601DateFormatter().string(from: Date()),
                    "webviewId": webviewId,
                    "source": "javascript"
                ]
                
                sendMessageToFlutter(method: "onJavaScriptMessage", arguments: [
                    "webviewId": webviewId,
                    "message": errorMessage
                ])
                
                print("WebView \(webviewId) JS message parsing error: \(error)")
            }
        }
    }
}