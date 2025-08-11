import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:macos_file_manager/model/webview/js_message.dart';

import 'webview_platform_interface.dart';

class CustomWebviewPlatform extends WebviewPlatformInterface {
  static const MethodChannel _channel = MethodChannel('custom_webview_plugin');

  int? _webviewId;
  WebviewCallbacks? _callbacks;

  CustomWebviewPlatform() {
    _channel.setMethodCallHandler(handleMethodCall);
  }

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    try {
      _webviewId = await _channel.invokeMethod<int>('createWebview');
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  void setCallbacks(WebviewCallbacks callbacks) {
    _callbacks = callbacks;
  }

  @override
  Future<void> loadUrl(String url) async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      await _channel.invokeMethod('loadUrl', {'webviewId': _webviewId, 'url': url});
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<bool> canGoBack() async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      return await _channel.invokeMethod<bool>('canGoBack', {'webviewId': _webviewId}) ?? false;
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<bool> canGoForward() async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      return await _channel.invokeMethod<bool>('canGoForward', {'webviewId': _webviewId}) ?? false;
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<void> goBack() async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      await _channel.invokeMethod('goBack', {'webviewId': _webviewId});
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<void> goForward() async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      await _channel.invokeMethod('goForward', {'webviewId': _webviewId});
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<void> reload() async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      await _channel.invokeMethod('reload', {'webviewId': _webviewId});
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<String?> executeJavaScript(String script) async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      final result = await _channel.invokeMethod<String>('evaluateJavaScript', {
        'webviewId': _webviewId,
        'script': script,
      });
      return result;
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<void> sendMessageToJS(JSMessage message) async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      await _channel.invokeMethod('sendMessageToJS', {'webviewId': _webviewId, 'message': message.toJson()});
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<String?> getCurrentUrl() async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      return await _channel.invokeMethod<String>('getCurrentUrl', {'webviewId': _webviewId});
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<bool> isLoading() async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      return await _channel.invokeMethod<bool>('isLoading', {'webviewId': _webviewId}) ?? false;
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<String?> getTitle() async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      return await _channel.invokeMethod<String>('getTitle', {'webviewId': _webviewId});
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<void> injectJavaScript(String script) async {
    if (_webviewId == null) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Webview not initialized');
    }

    try {
      await _channel.invokeMethod('injectJavaScript', {'webviewId': _webviewId, 'script': script});
    } on PlatformException catch (e) {
      throw WebviewError.fromPlatformException(e);
    }
  }

  @override
  Future<void> dispose() async {
    if (_webviewId != null) {
      try {
        await _channel.invokeMethod('disposeWebview', {'webviewId': _webviewId});
        _webviewId = null;
        _callbacks = null;
      } on PlatformException catch (e) {
        throw WebviewError.fromPlatformException(e);
      }
    }
  }

  @override
  @Deprecated('Use WebviewCallbacks.onJSMessage instead')
  void setJSMessageListener(Function(JSMessage) listener) {
    // This method is deprecated, callbacks should be used instead
  }

  @visibleForTesting
  Future<void> handleMethodCall(MethodCall call) async {
    if (_callbacks == null) return;

    try {
      switch (call.method) {
        case 'onPageStarted':
          final args = call.arguments as Map<String, dynamic>;
          final url = args['url'] as String? ?? '';
          _callbacks!.onPageStarted(url);
          break;

        case 'onPageFinished':
          final args = call.arguments as Map<String, dynamic>;
          final url = args['url'] as String? ?? '';
          _callbacks!.onPageFinished(url);
          break;

        case 'onPageError':
          final args = call.arguments as Map<String, dynamic>;
          final error = WebviewError(
            type: WebviewErrorType.networkError,
            message: args['error'] as String? ?? 'Unknown error',
            code: args['code']?.toString(),
            details: args,
          );
          _callbacks!.onPageError(error);
          break;

        case 'onNavigationStateChanged':
          final args = call.arguments as Map<String, dynamic>;
          final canGoBack = args['canGoBack'] as bool? ?? false;
          final canGoForward = args['canGoForward'] as bool? ?? false;
          _callbacks!.onNavigationStateChanged(canGoBack, canGoForward);
          break;

        case 'onJavaScriptMessage':
          final args = call.arguments as Map<String, dynamic>;
          final messageData = args['message'];
          final message = JSMessage(type: 'message', data: messageData as Map<String, dynamic>? ?? {});
          _callbacks!.onJSMessage(message);
          break;

        case 'onNavigationStarted':
          final args = call.arguments as Map<String, dynamic>;
          final url = args['url'] as String? ?? '';
          final type = args['type'] as String? ?? 'unknown';

          // Notify about navigation start with type information
          _callbacks!.onPageStarted(url);
          break;

        default:
          print('Unhandled method call: ${call.method}');
      }
    } catch (e) {
      print('Error handling method call ${call.method}: $e');
    }
  }
}
