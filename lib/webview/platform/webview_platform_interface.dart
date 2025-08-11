import 'package:flutter/services.dart';
import 'package:macos_file_manager/model/webview/js_message.dart';

/// Method channel constants for webview communication.
class WebviewMethodChannelConstants {
  static const String channelName = 'com.macos_file_manager/webview';

  // Navigation methods
  static const String loadUrl = 'loadUrl';
  static const String goBack = 'goBack';
  static const String goForward = 'goForward';
  static const String reload = 'reload';
  static const String canGoBack = 'canGoBack';
  static const String canGoForward = 'canGoForward';
  static const String getCurrentUrl = 'getCurrentUrl';

  // JavaScript methods
  static const String executeJavaScript = 'executeJavaScript';
  static const String sendMessageToJS = 'sendMessageToJS';
  static const String injectJavaScript = 'injectJavaScript';

  // Lifecycle methods
  static const String initialize = 'initialize';
  static const String dispose = 'dispose';

  // Callback methods (from native to Flutter)
  static const String onNavigationStateChanged = 'onNavigationStateChanged';
  static const String onPageStarted = 'onPageStarted';
  static const String onPageFinished = 'onPageFinished';
  static const String onPageError = 'onPageError';
  static const String onJSMessage = 'onJSMessage';
}

/// Error types for webview operations.
enum WebviewErrorType {
  networkError,
  javascriptError,
  platformError,
  navigationError,
  initializationError,
  communicationError,
}

/// Webview error class with detailed error information.
class WebviewError implements Exception {
  const WebviewError({required this.type, required this.message, this.code, this.details, this.stackTrace});

  final WebviewErrorType type;
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'WebviewError(type: $type, message: $message, code: $code)';
  }

  /// Creates a WebviewError from a platform exception.
  factory WebviewError.fromPlatformException(PlatformException e) {
    WebviewErrorType type;
    switch (e.code) {
      case 'NETWORK_ERROR':
        type = WebviewErrorType.networkError;
        break;
      case 'JAVASCRIPT_ERROR':
        type = WebviewErrorType.javascriptError;
        break;
      case 'NAVIGATION_ERROR':
        type = WebviewErrorType.navigationError;
        break;
      case 'INITIALIZATION_ERROR':
        type = WebviewErrorType.initializationError;
        break;
      case 'COMMUNICATION_ERROR':
        type = WebviewErrorType.communicationError;
        break;
      default:
        type = WebviewErrorType.platformError;
    }

    return WebviewError(
      type: type,
      message: e.message ?? 'Unknown platform error',
      code: e.code,
      details: e.details as Map<String, dynamic>?,
    );
  }
}

/// Callback interface for webview events.
abstract class WebviewCallbacks {
  /// Called when navigation state changes (can go back/forward).
  void onNavigationStateChanged(bool canGoBack, bool canGoForward);

  /// Called when a page starts loading.
  void onPageStarted(String url);

  /// Called when a page finishes loading.
  void onPageFinished(String url);

  /// Called when a page loading error occurs.
  void onPageError(WebviewError error);

  /// Called when a JavaScript message is received.
  void onJSMessage(JSMessage message);
}

/// Abstract interface for platform-specific webview implementations.
///
/// This interface defines the contract that platform-specific webview
/// implementations must follow, enabling consistent behavior across
/// different platforms and webview technologies.
abstract class WebviewPlatformInterface {
  /// Initializes the webview with the given configuration.
  Future<void> initialize(Map<String, dynamic> config);

  /// Sets the callback handler for webview events.
  void setCallbacks(WebviewCallbacks callbacks);

  /// Loads the specified URL in the webview.
  ///
  /// Throws [WebviewError] if the URL is invalid or loading fails.
  Future<void> loadUrl(String url);

  /// Navigates back in the webview history.
  ///
  /// Throws [WebviewError] if navigation is not possible.
  Future<void> goBack();

  /// Navigates forward in the webview history.
  ///
  /// Throws [WebviewError] if navigation is not possible.
  Future<void> goForward();

  /// Reloads the current page.
  ///
  /// Throws [WebviewError] if reload fails.
  Future<void> reload();

  /// Executes JavaScript code in the webview.
  ///
  /// Returns the result of the JavaScript execution as a string,
  /// or null if no result is available.
  ///
  /// Throws [WebviewError] if JavaScript execution fails.
  Future<String?> executeJavaScript(String script);

  /// Sends a message to JavaScript context.
  ///
  /// Throws [WebviewError] if message sending fails.
  Future<void> sendMessageToJS(JSMessage message);

  /// Injects JavaScript code into the webview.
  ///
  /// This method injects JavaScript code that will be executed
  /// in the webview context. Unlike [executeJavaScript], this
  /// method is designed for injecting persistent code like
  /// bridge scripts or event handlers.
  ///
  /// Throws [WebviewError] if injection fails.
  Future<void> injectJavaScript(String script);

  /// Sets up a listener for JavaScript messages.
  ///
  /// This method is deprecated in favor of using [WebviewCallbacks.onJSMessage].
  @Deprecated('Use WebviewCallbacks.onJSMessage instead')
  void setJSMessageListener(Function(JSMessage) listener);

  /// Checks if the webview can navigate back.
  Future<bool> canGoBack();

  /// Checks if the webview can navigate forward.
  Future<bool> canGoForward();

  /// Gets the current URL.
  Future<String?> getCurrentUrl();

  /// Gets the current loading state.
  Future<bool> isLoading();

  /// Gets the current page title.
  Future<String?> getTitle();

  /// Disposes of the webview resources.
  Future<void> dispose();
}
