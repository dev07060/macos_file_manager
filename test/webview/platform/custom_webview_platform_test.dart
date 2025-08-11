import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_file_manager/model/webview/js_message.dart';
import 'package:macos_file_manager/webview/platform/custom_webview_platform.dart';
import 'package:macos_file_manager/webview/platform/webview_platform_interface.dart';

class MockWebviewCallbacks implements WebviewCallbacks {
  final List<String> events = [];
  String? lastUrl;
  bool? lastCanGoBack;
  bool? lastCanGoForward;
  WebviewError? lastError;
  JSMessage? lastMessage;

  @override
  void onNavigationStateChanged(bool canGoBack, bool canGoForward) {
    events.add('onNavigationStateChanged');
    lastCanGoBack = canGoBack;
    lastCanGoForward = canGoForward;
  }

  @override
  void onPageStarted(String url) {
    events.add('onPageStarted');
    lastUrl = url;
  }

  @override
  void onPageFinished(String url) {
    events.add('onPageFinished');
    lastUrl = url;
  }

  @override
  void onPageError(WebviewError error) {
    events.add('onPageError');
    lastError = error;
  }

  @override
  void onJSMessage(JSMessage message) {
    events.add('onJSMessage');
    lastMessage = message;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomWebviewPlatform', () {
    late CustomWebviewPlatform platform;
    late MockWebviewCallbacks mockCallbacks;
    late List<MethodCall> methodCalls;

    setUp(() {
      platform = CustomWebviewPlatform();
      mockCallbacks = MockWebviewCallbacks();
      methodCalls = [];

      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('custom_webview_plugin'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          switch (methodCall.method) {
            case 'createWebview':
              return 1; // Return webview ID
            case 'loadUrl':
            case 'goBack':
            case 'goForward':
            case 'reload':
            case 'evaluateJavaScript':
            case 'sendMessageToJS':
            case 'disposeWebview':
              return null;
            case 'getCurrentUrl':
              return 'https://example.com';
            case 'getTitle':
              return 'Test Page';
            case 'isLoading':
              return false;
            case 'canGoBack':
              return true;
            case 'canGoForward':
              return false;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('custom_webview_plugin'),
        null,
      );
    });

    test('should initialize webview and return webview ID', () async {
      await platform.initialize({});

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'createWebview');
    });

    test('should load URL with proper arguments', () async {
      await platform.initialize({});
      await platform.loadUrl('https://example.com');

      expect(methodCalls.length, 2);
      expect(methodCalls[1].method, 'loadUrl');
      expect(methodCalls[1].arguments['webviewId'], 1);
      expect(methodCalls[1].arguments['url'], 'https://example.com');
    });

    test('should handle navigation methods', () async {
      await platform.initialize({});

      await platform.goBack();
      await platform.goForward();
      await platform.reload();

      expect(methodCalls.any((call) => call.method == 'goBack'), true);
      expect(methodCalls.any((call) => call.method == 'goForward'), true);
      expect(methodCalls.any((call) => call.method == 'reload'), true);
    });

    test('should execute JavaScript', () async {
      await platform.initialize({});

      final result = await platform.executeJavaScript('console.log("test")');

      expect(methodCalls.any((call) => call.method == 'evaluateJavaScript'), true);
      final jsCall = methodCalls.firstWhere((call) => call.method == 'evaluateJavaScript');
      expect(jsCall.arguments['script'], 'console.log("test")');
    });

    test('should send message to JavaScript', () async {
      await platform.initialize({});

      final message = JSMessage(type: 'test', data: {'key': 'value'});
      await platform.sendMessageToJS(message);

      expect(methodCalls.any((call) => call.method == 'sendMessageToJS'), true);
      final msgCall = methodCalls.firstWhere((call) => call.method == 'sendMessageToJS');
      expect(msgCall.arguments['message'], message.toJson());
    });

    test('should handle callbacks from native', () async {
      platform.setCallbacks(mockCallbacks);

      // Simulate native callbacks
      await platform.handleMethodCall(
        const MethodCall('onPageStarted', {'webviewId': 1, 'url': 'https://example.com'}),
      );

      await platform.handleMethodCall(
        const MethodCall('onPageFinished', {'webviewId': 1, 'url': 'https://example.com'}),
      );

      await platform.handleMethodCall(
        const MethodCall('onNavigationStateChanged', {'webviewId': 1, 'canGoBack': true, 'canGoForward': false}),
      );

      expect(mockCallbacks.events, contains('onPageStarted'));
      expect(mockCallbacks.events, contains('onPageFinished'));
      expect(mockCallbacks.events, contains('onNavigationStateChanged'));
      expect(mockCallbacks.lastUrl, 'https://example.com');
      expect(mockCallbacks.lastCanGoBack, true);
      expect(mockCallbacks.lastCanGoForward, false);
    });

    test('should handle error callbacks', () async {
      platform.setCallbacks(mockCallbacks);

      await platform.handleMethodCall(
        const MethodCall('onPageError', {'webviewId': 1, 'error': 'Network error', 'code': '404'}),
      );

      expect(mockCallbacks.events, contains('onPageError'));
      expect(mockCallbacks.lastError?.message, 'Network error');
      expect(mockCallbacks.lastError?.code, '404');
    });

    test('should dispose webview properly', () async {
      await platform.initialize({});
      await platform.dispose();

      expect(methodCalls.any((call) => call.method == 'disposeWebview'), true);
    });

    test('should throw error when webview not initialized', () async {
      expect(() => platform.loadUrl('https://example.com'), throwsA(isA<WebviewError>()));
    });
  });
}
