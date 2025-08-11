import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:macos_file_manager/model/webview/js_message.dart';
import 'package:macos_file_manager/webview/platform/webview_platform_interface.dart';

/// JavaScript bridge for bidirectional communication between Flutter and webview.
///
/// This class handles JavaScript injection, message passing, and error handling
/// for webview communication.
class JSBridge {
  final WebviewPlatformInterface _platform;
  final StreamController<JSMessage> _messageController = StreamController<JSMessage>.broadcast();
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  int _messageIdCounter = 0;

  /// Stream of messages received from JavaScript.
  Stream<JSMessage> get messageStream => _messageController.stream;

  JSBridge(this._platform);

  /// Initializes the JavaScript bridge by injecting the communication script.
  Future<void> initialize() async {
    try {
      await _injectBridgeScript();
      developer.log('JavaScript bridge initialized successfully', name: 'JSBridge');
    } catch (e) {
      developer.log('Failed to initialize JavaScript bridge: $e', name: 'JSBridge', level: 1000);
      rethrow;
    }
  }

  /// Injects the JavaScript bridge script into the webview.
  Future<void> _injectBridgeScript() async {
    const bridgeScript = '''
      (function() {
        // Prevent multiple injections
        if (window.flutterBridge) {
          return;
        }

        // Create the Flutter bridge object
        window.flutterBridge = {
          // Send message to Flutter
          sendMessage: function(type, data, id) {
            try {
              const message = {
                type: type || 'message',
                data: data || {},
                id: id || null,
                timestamp: new Date().toISOString()
              };
              
              // Use WKScriptMessageHandler to send message to native code
              if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.flutterWebview) {
                window.webkit.messageHandlers.flutterWebview.postMessage(message);
              } else {
                console.warn('Flutter webview message handler not available');
              }
            } catch (error) {
              console.error('Error sending message to Flutter:', error);
            }
          },

          // Handle messages from Flutter
          handleMessage: function(message) {
            try {
              const event = new CustomEvent('flutterMessage', { detail: message });
              window.dispatchEvent(event);
              
              // Also call the global handler if it exists
              if (typeof window.flutter_webview_message_handler === 'function') {
                window.flutter_webview_message_handler(message);
              }
            } catch (error) {
              console.error('Error handling Flutter message:', error);
            }
          },

          // Request-response pattern
          sendRequest: function(type, data) {
            return new Promise(function(resolve, reject) {
              const requestId = 'req_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
              
              // Store the promise resolvers
              window.flutterBridge._pendingRequests = window.flutterBridge._pendingRequests || {};
              window.flutterBridge._pendingRequests[requestId] = { resolve: resolve, reject: reject };
              
              // Send the request
              window.flutterBridge.sendMessage(type, data, requestId);
              
              // Set timeout for the request
              setTimeout(function() {
                if (window.flutterBridge._pendingRequests[requestId]) {
                  delete window.flutterBridge._pendingRequests[requestId];
                  reject(new Error('Request timeout'));
                }
              }, 30000); // 30 second timeout
            });
          },

          // Handle responses from Flutter
          handleResponse: function(message) {
            if (message.id && window.flutterBridge._pendingRequests && window.flutterBridge._pendingRequests[message.id]) {
              const request = window.flutterBridge._pendingRequests[message.id];
              delete window.flutterBridge._pendingRequests[message.id];
              
              if (message.type === 'response') {
                request.resolve(message.data);
              } else if (message.type === 'error') {
                request.reject(new Error(message.data.message || 'Unknown error'));
              }
            }
          }
        };

        // Set up global message handler for backward compatibility
        window.flutter_webview_message_handler = function(message) {
          if (message.id && (message.type === 'response' || message.type === 'error')) {
            window.flutterBridge.handleResponse(message);
          } else {
            window.flutterBridge.handleMessage(message);
          }
        };

        // Log successful initialization
        console.log('Flutter webview bridge initialized');
        
        // Send initialization message to Flutter
        window.flutterBridge.sendMessage('bridge_ready', { ready: true });
      })();
    ''';

    await _platform.executeJavaScript(bridgeScript);
  }

  /// Sends a message to JavaScript.
  Future<void> sendMessage(JSMessage message) async {
    try {
      await _platform.sendMessageToJS(message);
      developer.log('Sent message to JavaScript: ${message.type}', name: 'JSBridge');
    } catch (e) {
      developer.log('Failed to send message to JavaScript: $e', name: 'JSBridge', level: 1000);
      rethrow;
    }
  }

  /// Sends a request to JavaScript and waits for a response.
  Future<T> sendRequest<T>(
    String type,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final requestId = _generateMessageId();
    final completer = Completer<T>();

    _pendingRequests[requestId] = completer;

    // Set up timeout
    Timer(timeout, () {
      if (_pendingRequests.containsKey(requestId)) {
        _pendingRequests.remove(requestId);
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Request timeout', timeout));
        }
      }
    });

    try {
      final message = JSMessage(type: type, data: data, id: requestId, timestamp: DateTime.now());

      await sendMessage(message);
      return await completer.future;
    } catch (e) {
      _pendingRequests.remove(requestId);
      rethrow;
    }
  }

  /// Handles incoming messages from JavaScript.
  void handleIncomingMessage(JSMessage message) {
    try {
      developer.log('Received message from JavaScript: ${message.type}', name: 'JSBridge');

      // Handle responses to pending requests
      if (message.id != null && _pendingRequests.containsKey(message.id)) {
        final completer = _pendingRequests.remove(message.id!);

        if (message.type == 'response') {
          completer?.complete(message.data);
        } else if (message.type == 'error') {
          final errorMessage = message.data['message'] as String? ?? 'Unknown JavaScript error';
          completer?.completeError(JSBridgeError(errorMessage, message.data));
        }
        return;
      }

      // Handle regular messages
      _messageController.add(message);
    } catch (e) {
      developer.log('Error handling incoming message: $e', name: 'JSBridge', level: 1000);
    }
  }

  /// Executes JavaScript code and returns the result.
  Future<T?> executeJavaScript<T>(String script) async {
    final startTime = DateTime.now();

    try {
      final result = await _platform.executeJavaScript(script);

      // Log successful execution
      final duration = DateTime.now().difference(startTime);
      developer.log('JavaScript execution took ${duration.inMilliseconds}ms', name: 'JSBridge');

      developer.log('Executed JavaScript successfully', name: 'JSBridge');

      if (result == null) return null;

      // Try to parse JSON result if it's a string
      if ((result.startsWith('{') || result.startsWith('['))) {
        try {
          return jsonDecode(result) as T;
        } catch (_) {
          return result as T;
        }
      }

      return result as T;
    } catch (e) {
      // Log execution error
      developer.log('Failed to execute JavaScript: $e', name: 'JSBridge', level: 1000);
      throw JSBridgeError('JavaScript execution failed: $e');
    }
  }

  /// Injects a JavaScript function into the webview.
  Future<void> injectFunction(String functionName, String functionBody) async {
    final script = '''
      window.$functionName = $functionBody;
    ''';

    await executeJavaScript(script);
    developer.log('Injected JavaScript function: $functionName', name: 'JSBridge');
  }

  /// Calls a JavaScript function with arguments.
  Future<T?> callFunction<T>(String functionName, [List<dynamic>? args]) async {
    final argsJson = args != null ? jsonEncode(args) : '[]';
    final script = '''
      (function() {
        try {
          const args = $argsJson;
          const result = window.$functionName.apply(window, args);
          return JSON.stringify(result);
        } catch (error) {
          throw new Error('Function call failed: ' + error.message);
        }
      })();
    ''';

    return await executeJavaScript<T>(script);
  }

  /// Evaluates a JavaScript expression and returns the result.
  Future<T?> evaluateExpression<T>(String expression) async {
    final script = '''
      (function() {
        try {
          const result = $expression;
          return JSON.stringify(result);
        } catch (error) {
          throw new Error('Expression evaluation failed: ' + error.message);
        }
      })();
    ''';

    return await executeJavaScript<T>(script);
  }

  /// Adds a JavaScript event listener.
  Future<void> addEventListener(String eventType, String handlerFunction) async {
    final script = '''
      document.addEventListener('$eventType', $handlerFunction);
    ''';

    await executeJavaScript(script);
    developer.log('Added JavaScript event listener: $eventType', name: 'JSBridge');
  }

  /// Removes a JavaScript event listener.
  Future<void> removeEventListener(String eventType, String handlerFunction) async {
    final script = '''
      document.removeEventListener('$eventType', $handlerFunction);
    ''';

    await executeJavaScript(script);
    developer.log('Removed JavaScript event listener: $eventType', name: 'JSBridge');
  }

  /// Generates a unique message ID.
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${_messageIdCounter++}';
  }

  /// Disposes of the bridge and cleans up resources.
  void dispose() {
    _messageController.close();

    // Complete any pending requests with errors
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(JSBridgeError('Bridge disposed'));
      }
    }
    _pendingRequests.clear();

    developer.log('JavaScript bridge disposed', name: 'JSBridge');
  }
}

/// Exception thrown by the JavaScript bridge.
class JSBridgeError implements Exception {
  final String message;
  final Map<String, dynamic>? details;

  const JSBridgeError(this.message, [this.details]);

  @override
  String toString() => 'JSBridgeError: $message';
}

/// Timeout exception for JavaScript requests.
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: ${timeout.inSeconds}s)';
}
