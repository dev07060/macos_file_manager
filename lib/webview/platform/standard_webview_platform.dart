import 'package:flutter/foundation.dart';
import 'package:macos_file_manager/model/webview/js_message.dart';
import 'package:webview_flutter/webview_flutter.dart' as wf;

import 'webview_platform_interface.dart';

/// Standard webview platform implementation using webview_flutter package.
///
/// This implementation uses the official webview_flutter package which provides
/// native webview support for macOS through WKWebView.
class StandardWebviewPlatform extends WebviewPlatformInterface {
  wf.WebViewController? _controller;
  WebviewCallbacks? _callbacks;
  bool _isInitialized = false;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    try {
      // Create the webview controller
      _controller = wf.WebViewController();

      // Configure the controller
      await _controller!.setJavaScriptMode(wf.JavaScriptMode.unrestricted);
      // Note: setBackgroundColor is not supported on macOS, so we skip it

      // Set up navigation delegate
      await _controller!.setNavigationDelegate(
        wf.NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            _callbacks?.onPageStarted(url);
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            _callbacks?.onPageFinished(url);
            // Use a small delay to ensure the page is fully loaded
            Future.delayed(const Duration(milliseconds: 100), () {
              _updateNavigationState();
            });
          },
          onWebResourceError: (wf.WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
            _callbacks?.onPageError(
              WebviewError(
                type: WebviewErrorType.networkError,
                message: error.description,
                code: error.errorCode.toString() ?? 'unknown',
              ),
            );
          },
          onNavigationRequest: (wf.NavigationRequest request) {
            debugPrint('Navigation request: ${request.url}');
            // Allow all navigation requests
            return wf.NavigationDecision.navigate;
          },
        ),
      );

      _isInitialized = true;
    } catch (e) {
      throw WebviewError(type: WebviewErrorType.initializationError, message: 'Failed to initialize webview: $e');
    }
  }

  @override
  Future<void> loadUrl(String url) async {
    _validateInitialized();

    try {
      await _controller!.loadRequest(Uri.parse(url));
    } catch (e) {
      throw WebviewError(type: WebviewErrorType.navigationError, message: 'Failed to load URL: $e');
    }
  }

  @override
  Future<void> goBack() async {
    _validateInitialized();

    if (await _controller!.canGoBack()) {
      await _controller!.goBack();
      await _updateNavigationState();
    }
  }

  @override
  Future<void> goForward() async {
    _validateInitialized();

    if (await _controller!.canGoForward()) {
      await _controller!.goForward();
      await _updateNavigationState();
    }
  }

  @override
  Future<void> reload() async {
    _validateInitialized();
    await _controller!.reload();
  }

  @override
  Future<String?> executeJavaScript(String script) async {
    _validateInitialized();

    try {
      final result = await _controller!.runJavaScriptReturningResult(script);
      return result.toString();
    } catch (e) {
      // Log the error but don't throw to prevent crashes
      debugPrint('JavaScript execution failed: $e');
      return null;
    }
  }

  @override
  Future<void> injectJavaScript(String script) async {
    _validateInitialized();

    try {
      await _controller!.runJavaScript(script);
    } catch (e) {
      // Log the error but don't throw to prevent crashes
      debugPrint('JavaScript injection failed: $e');
    }
  }

  @override
  Future<bool> canGoBack() async {
    _validateInitialized();
    return await _controller!.canGoBack();
  }

  @override
  Future<bool> canGoForward() async {
    _validateInitialized();
    return await _controller!.canGoForward();
  }

  @override
  Future<String?> getCurrentUrl() async {
    _validateInitialized();
    return await _controller!.currentUrl();
  }

  @override
  Future<String?> getTitle() async {
    _validateInitialized();
    return await _controller!.getTitle();
  }

  @override
  Future<bool> isLoading() async {
    _validateInitialized();
    // webview_flutter doesn't provide a direct isLoading method
    // We'll track this through navigation callbacks
    return false;
  }

  @override
  Future<void> sendMessageToJS(JSMessage message) async {
    _validateInitialized();

    try {
      final messageJson = message.toJson().toString().replaceAll("'", '"');
      final script = '''
        if (window.flutter_webview_bridge) {
          window.flutter_webview_bridge.onMessage($messageJson);
        }
      ''';
      await _controller!.runJavaScript(script);
    } catch (e) {
      throw WebviewError(type: WebviewErrorType.javascriptError, message: 'Failed to send message to JS: $e');
    }
  }

  @override
  void setCallbacks(WebviewCallbacks callbacks) {
    _callbacks = callbacks;
  }

  @override
  void setJSMessageListener(Function(JSMessage) listener) {
    // For the standard webview implementation, we'll handle JS messages
    // through the JavaScript bridge setup in the controller
    // This method is kept for interface compatibility
  }

  @override
  Future<void> dispose() async {
    _callbacks = null;
    _controller = null;
    _isInitialized = false;
  }

  /// Gets the underlying WebViewController for widget integration
  wf.WebViewController? get controller => _controller;

  void _validateInitialized() {
    if (!_isInitialized || _controller == null) {
      throw WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }
  }

  Future<void> _updateNavigationState() async {
    if (_callbacks != null && _controller != null) {
      try {
        final canGoBack = await _controller!.canGoBack();
        final canGoForward = await _controller!.canGoForward();
        _callbacks!.onNavigationStateChanged(canGoBack, canGoForward);
      } catch (e) {
        // Ignore navigation state update errors to prevent crashes
        debugPrint('Navigation state update failed: $e');
      }
    }
  }
}
