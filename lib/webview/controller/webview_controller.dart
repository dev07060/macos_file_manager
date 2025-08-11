import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:macos_file_manager/model/webview/js_message.dart';
import 'package:macos_file_manager/model/webview/webview_config.dart';
import 'package:macos_file_manager/model/webview/webview_state.dart';
import 'package:macos_file_manager/webview/bridge/js_bridge.dart';
import 'package:macos_file_manager/webview/platform/webview_platform_interface.dart';
import 'package:macos_file_manager/webview/utils/performance_optimizer.dart';

/// Controller that abstracts webview operations.
///
/// This controller provides a consistent API for webview operations
/// regardless of the underlying platform implementation. It handles
/// error recovery, state synchronization, and provides reactive
/// updates through streams.
class WebviewController implements WebviewCallbacks {
  WebviewController(this._platformInterface, {WebviewConfig? config}) : _config = config ?? const WebviewConfig() {
    _platformInterface.setCallbacks(this);
    _jsBridge = JSBridge(_platformInterface);
    _initializeState();
    _setupJSBridge();

    // Initialize performance optimizer (only if not already initialized)
    WebviewPerformanceOptimizer.initialize();
  }

  final WebviewPlatformInterface _platformInterface;
  final WebviewConfig _config;
  late final JSBridge _jsBridge;

  /// Gets the platform interface for advanced usage
  WebviewPlatformInterface get platformInterface => _platformInterface;

  // State management
  WebviewState _currentState = const WebviewState();
  final StreamController<WebviewState> _stateController = StreamController<WebviewState>.broadcast();
  final StreamController<JSMessage> _jsMessageController = StreamController<JSMessage>.broadcast();
  final StreamController<WebviewError> _errorController = StreamController<WebviewError>.broadcast();

  // Getters for reactive streams
  Stream<WebviewState> get stateStream => _stateController.stream;
  Stream<JSMessage> get jsMessageStream => _jsMessageController.stream;
  Stream<WebviewError> get errorStream => _errorController.stream;
  WebviewState get currentState => _currentState;

  bool _isInitialized = false;
  bool _isDisposed = false;

  void _initializeState() {
    _currentState = WebviewState(
      currentUrl: _config.initialUrl,
      isLoading: false,
      canGoBack: false,
      canGoForward: false,
      error: null,
      navigationHistory: [],
    );
  }

  void _setupJSBridge() {
    // Forward JavaScript messages from bridge to controller stream
    _jsBridge.messageStream.listen(
      (message) => _jsMessageController.add(message),
      onError:
          (error) => _handleError(
            WebviewError(type: WebviewErrorType.javascriptError, message: 'JavaScript bridge error: $error'),
          ),
    );
  }

  /// Initializes the webview with the provided configuration.
  Future<void> initialize() async {
    if (_isDisposed) {
      throw WebviewError(type: WebviewErrorType.initializationError, message: 'Cannot initialize disposed controller');
    }

    if (_isInitialized) {
      return;
    }

    try {
      await _platformInterface.initialize(_config.toJson());
      _isInitialized = true;

      // Initialize JavaScript bridge
      await _jsBridge.initialize();

      // Load initial URL if provided and auto-loading is enabled
      if (_config.initialUrl.isNotEmpty && _config.autoLoadInitialUrl) {
        await _loadInitialUrl();
      }
    } catch (e) {
      final error =
          e is WebviewError
              ? e
              : WebviewError(type: WebviewErrorType.initializationError, message: 'Failed to initialize webview: $e');
      _handleError(error);
      rethrow;
    }
  }

  /// Loads the initial URL with proper error handling and timeout.
  Future<void> _loadInitialUrl() async {
    try {
      // Set loading state
      _updateState(_currentState.copyWith(isLoading: true, error: null));

      // Load URL with timeout
      await loadUrl(_config.initialUrl).timeout(
        Duration(seconds: _config.initialLoadTimeoutSeconds),
        onTimeout: () {
          throw WebviewError(
            type: WebviewErrorType.networkError,
            message: 'Initial URL loading timed out after ${_config.initialLoadTimeoutSeconds} seconds',
          );
        },
      );
    } catch (e) {
      // Handle initial URL loading error but don't fail initialization
      final error =
          e is WebviewError
              ? e
              : WebviewError(
                type: WebviewErrorType.navigationError,
                message: 'Failed to load initial URL (${_config.initialUrl}): $e',
              );

      _handleError(error);

      // Update state to show error but keep webview initialized
      _updateState(
        _currentState.copyWith(isLoading: false, error: 'Failed to load ${_config.initialUrl}: ${error.message}'),
      );

      // For Google.com specifically, try alternative URLs if the main one fails
      if (_config.initialUrl.contains('google.com')) {
        await _tryAlternativeGoogleUrls();
      }
    }
  }

  /// Tries alternative Google URLs if the main one fails (for better reliability).
  Future<void> _tryAlternativeGoogleUrls() async {
    final alternativeUrls = ['https://google.com', 'https://www.google.com/search?q=test', 'https://google.com/search'];

    for (final url in alternativeUrls) {
      if (url == _config.initialUrl) continue; // Skip the one that already failed

      try {
        await loadUrl(url).timeout(Duration(seconds: _config.initialLoadTimeoutSeconds ~/ 2));
        // If successful, break out of the loop
        break;
      } catch (e) {
        // Continue to next alternative URL
        continue;
      }
    }
  }

  /// Loads the specified URL in the webview.
  Future<void> loadUrl(String url) async {
    try {
      _validateInitialized();
      _validateUrl(url);

      // Performance optimization: validate URL
      if (!WebviewPerformanceOptimizer.isUrlOptimized(url)) {
        throw WebviewError(type: WebviewErrorType.navigationError, message: 'URL failed performance validation: $url');
      }

      _updateState(_currentState.copyWith(isLoading: true, error: null));

      // Cache URL metadata for performance
      WebviewPerformanceOptimizer.cacheUrlMetadata(url);

      await _platformInterface.loadUrl(url);
    } catch (e) {
      final error =
          e is WebviewError
              ? e
              : WebviewError(type: WebviewErrorType.navigationError, message: 'Failed to load URL: $e');

      // Update state with error
      _updateState(_currentState.copyWith(isLoading: false, error: _formatNavigationError(error)));

      _handleError(error);
      rethrow;
    }
  }

  /// Navigates back in the webview history.
  Future<void> goBack() async {
    await _executeWithErrorHandling(() async {
      _validateInitialized();

      final canGoBack = await _platformInterface.canGoBack();
      if (!canGoBack) {
        throw WebviewError(
          type: WebviewErrorType.navigationError,
          message: 'Cannot navigate back - no history available',
        );
      }

      await _platformInterface.goBack();
    }, 'goBack');
  }

  /// Navigates forward in the webview history.
  Future<void> goForward() async {
    await _executeWithErrorHandling(() async {
      _validateInitialized();

      final canGoForward = await _platformInterface.canGoForward();
      if (!canGoForward) {
        throw WebviewError(
          type: WebviewErrorType.navigationError,
          message: 'Cannot navigate forward - no forward history available',
        );
      }

      await _platformInterface.goForward();
    }, 'goForward');
  }

  /// Reloads the current page.
  Future<void> reload() async {
    await _executeWithErrorHandling(() async {
      _validateInitialized();

      _updateState(_currentState.copyWith(isLoading: true, error: null));

      await _platformInterface.reload();
    }, 'reload');
  }

  /// Executes JavaScript code in the webview.
  Future<String?> executeJavaScript(String script) async {
    return await _executeWithErrorHandling<String?>(() async {
      _validateInitialized();

      if (script.trim().isEmpty) {
        throw WebviewError(type: WebviewErrorType.javascriptError, message: 'JavaScript script cannot be empty');
      }

      return await _platformInterface.executeJavaScript(script);
    }, 'executeJavaScript');
  }

  /// Sends a message to JavaScript context.
  Future<void> sendMessageToJS(JSMessage message) async {
    await _executeWithErrorHandling(() async {
      _validateInitialized();
      await _jsBridge.sendMessage(message);
    }, 'sendMessageToJS');
  }

  /// Sends a request to JavaScript and waits for a response.
  Future<T> sendJSRequest<T>(
    String type,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return await _executeWithErrorHandling(() async {
          _validateInitialized();
          return await _jsBridge.sendRequest<T>(type, data, timeout: timeout);
        }, 'sendJSRequest')
        as T;
  }

  /// Injects JavaScript code into the webview.
  Future<void> injectJavaScript(String script) async {
    await _executeWithErrorHandling(() async {
      _validateInitialized();
      await _platformInterface.injectJavaScript(script);
    }, 'injectJavaScript');
  }

  /// Injects a JavaScript function into the webview.
  Future<void> injectJSFunction(String functionName, String functionBody) async {
    await _executeWithErrorHandling(() async {
      _validateInitialized();
      await _jsBridge.injectFunction(functionName, functionBody);
    }, 'injectJSFunction');
  }

  /// Calls a JavaScript function with arguments.
  Future<T?> callJSFunction<T>(String functionName, [List<dynamic>? args]) async {
    return await _executeWithErrorHandling<T?>(() async {
      _validateInitialized();
      return await _jsBridge.callFunction<T>(functionName, args);
    }, 'callJSFunction');
  }

  /// Evaluates a JavaScript expression and returns the result.
  Future<T?> evaluateJSExpression<T>(String expression) async {
    return await _executeWithErrorHandling<T?>(() async {
      _validateInitialized();
      return await _jsBridge.evaluateExpression<T>(expression);
    }, 'evaluateJSExpression');
  }

  /// Adds a JavaScript event listener.
  Future<void> addJSEventListener(String eventType, String handlerFunction) async {
    await _executeWithErrorHandling(() async {
      _validateInitialized();
      await _jsBridge.addEventListener(eventType, handlerFunction);
    }, 'addJSEventListener');
  }

  /// Removes a JavaScript event listener.
  Future<void> removeJSEventListener(String eventType, String handlerFunction) async {
    await _executeWithErrorHandling(() async {
      _validateInitialized();
      await _jsBridge.removeEventListener(eventType, handlerFunction);
    }, 'removeJSEventListener');
  }

  /// Sets up a listener for JavaScript messages.
  ///
  /// This method is deprecated in favor of using [jsMessageStream].
  @Deprecated('Use jsMessageStream instead')
  void setJSMessageListener(Function(JSMessage) listener) {
    jsMessageStream.listen(listener);
  }

  /// Checks if the webview can navigate back.
  Future<bool> canGoBack() async {
    return await _executeWithErrorHandling(() async {
          _validateInitialized();
          return await _platformInterface.canGoBack();
        }, 'canGoBack') ??
        false;
  }

  /// Checks if the webview can navigate forward.
  Future<bool> canGoForward() async {
    return await _executeWithErrorHandling(() async {
          _validateInitialized();
          return await _platformInterface.canGoForward();
        }, 'canGoForward') ??
        false;
  }

  /// Gets the current URL.
  Future<String?> getCurrentUrl() async {
    return await _executeWithErrorHandling<String?>(() async {
      _validateInitialized();
      return await _platformInterface.getCurrentUrl();
    }, 'getCurrentUrl');
  }

  /// Gets the current loading state.
  Future<bool> isLoading() async {
    return await _executeWithErrorHandling(() async {
          _validateInitialized();
          return await _platformInterface.isLoading();
        }, 'isLoading') ??
        false;
  }

  /// Gets the current page title.
  Future<String?> getTitle() async {
    return await _executeWithErrorHandling<String?>(() async {
      _validateInitialized();
      return await _platformInterface.getTitle();
    }, 'getTitle');
  }

  /// Disposes of the webview resources.
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;

    try {
      if (_isInitialized) {
        _jsBridge.dispose();
        await _platformInterface.dispose();
      }

      // Note: Don't dispose performance optimizer here as it's shared across controllers
      // It will be disposed when the app shuts down or explicitly called
    } catch (e) {
      // Log error but don't throw during disposal
      _handleError(WebviewError(type: WebviewErrorType.platformError, message: 'Error during disposal: $e'));
    } finally {
      await _stateController.close();
      await _jsMessageController.close();
      await _errorController.close();
    }
  }

  // WebviewCallbacks implementation
  @override
  void onNavigationStateChanged(bool canGoBack, bool canGoForward) {
    _updateState(_currentState.copyWith(canGoBack: canGoBack, canGoForward: canGoForward));
  }

  @override
  void onPageStarted(String url) {
    // Validate URL before processing
    if (url.isEmpty) return;

    debugPrint('Page started loading: $url');

    final updatedHistory = List<String>.from(_currentState.navigationHistory);

    // Only add to history if it's a new URL (not just a reload)
    if (updatedHistory.isEmpty || updatedHistory.last != url) {
      updatedHistory.add(url);
    }

    // Optimize navigation history for performance
    final optimizedHistory = WebviewPerformanceOptimizer.optimizeNavigationHistory(updatedHistory);

    _updateState(
      _currentState.copyWith(currentUrl: url, isLoading: true, error: null, navigationHistory: optimizedHistory),
    );
  }

  @override
  void onPageFinished(String url) {
    // Validate URL before processing
    if (url.isEmpty) return;

    debugPrint('Page finished loading: $url');
    _updateState(_currentState.copyWith(currentUrl: url, isLoading: false, error: null));
  }

  @override
  void onPageError(WebviewError error) {
    // Enhanced error handling with more context
    final errorMessage = _formatNavigationError(error);

    _updateState(_currentState.copyWith(isLoading: false, error: errorMessage));

    _handleError(error);
  }

  @override
  void onJSMessage(JSMessage message) {
    // Forward message to JavaScript bridge for processing
    _jsBridge.handleIncomingMessage(message);
  }

  /// Formats navigation errors with user-friendly messages
  String _formatNavigationError(WebviewError error) {
    switch (error.type) {
      case WebviewErrorType.networkError:
        if (error.message.contains('NSURLErrorDomain')) {
          if (error.code == '-1009') {
            return 'No internet connection available';
          } else if (error.code == '-1001') {
            return 'Request timed out';
          } else if (error.code == '-1003') {
            return 'Server not found';
          }
        }
        return 'Network error: Unable to load page';

      case WebviewErrorType.navigationError:
        return 'Navigation failed: ${error.message}';

      case WebviewErrorType.javascriptError:
        return 'Page error: ${error.message}';

      case WebviewErrorType.platformError:
        return 'System error: ${error.message}';

      case WebviewErrorType.initializationError:
        return 'Initialization error: ${error.message}';

      default:
        return error.message;
    }
  }

  // Private helper methods
  void _validateInitialized() {
    if (_isDisposed) {
      throw WebviewError(type: WebviewErrorType.platformError, message: 'Controller has been disposed');
    }

    if (!_isInitialized) {
      throw WebviewError(
        type: WebviewErrorType.initializationError,
        message: 'Controller not initialized. Call initialize() first.',
      );
    }
  }

  void _validateUrl(String url) {
    if (url.trim().isEmpty) {
      throw WebviewError(type: WebviewErrorType.navigationError, message: 'URL cannot be empty');
    }

    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https'))) {
      throw WebviewError(type: WebviewErrorType.navigationError, message: 'Invalid URL format: $url');
    }
  }

  void _updateState(WebviewState newState) {
    if (_isDisposed) return;

    _currentState = newState;
    _stateController.add(newState);
  }

  void _handleError(WebviewError error) {
    if (_isDisposed) return;

    _errorController.add(error);
  }

  Future<T?> _executeWithErrorHandling<T>(Future<T> Function() operation, String operationName) async {
    try {
      return await operation();
    } catch (e) {
      final error =
          e is WebviewError
              ? e
              : WebviewError(type: WebviewErrorType.platformError, message: 'Error in $operationName: $e');
      _handleError(error);
      rethrow;
    }
  }
}
