import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:macos_file_manager/model/webview/js_message.dart';
import 'package:macos_file_manager/webview/bridge/js_bridge.dart';
import 'package:macos_file_manager/webview/platform/webview_platform_interface.dart';

class MockWebviewPlatform extends WebviewPlatformInterface {
  final List<String> executedScripts = [];
  final List<JSMessage> sentMessages = [];
  String? lastExecutedScript;
  dynamic scriptResult;
  bool shouldThrowError = false;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  @override
  void setCallbacks(WebviewCallbacks callbacks) {}

  @override
  Future<void> loadUrl(String url) async {}

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}

  @override
  Future<void> reload() async {}

  @override
  Future<String?> executeJavaScript(String script) async {
    if (shouldThrowError) {
      throw Exception('JavaScript execution failed');
    }

    executedScripts.add(script);
    lastExecutedScript = script;

    if (scriptResult != null) {
      return scriptResult is String ? scriptResult : jsonEncode(scriptResult);
    }

    return null;
  }

  @override
  Future<void> sendMessageToJS(JSMessage message) async {
    if (shouldThrowError) {
      throw Exception('Message sending failed');
    }

    sentMessages.add(message);
  }

  @override
  Future<void> injectJavaScript(String script) async {
    if (shouldThrowError) {
      throw Exception('JavaScript injection failed');
    }

    executedScripts.add(script);
    lastExecutedScript = script;
  }

  @override
  void setJSMessageListener(Function(JSMessage) listener) {}

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<String?> getCurrentUrl() async => null;

  @override
  Future<bool> isLoading() async => false;

  @override
  Future<String?> getTitle() async => null;

  @override
  Future<void> dispose() async {}
}

void main() {
  group('JSBridge', () {
    late MockWebviewPlatform mockPlatform;
    late JSBridge jsBridge;

    setUp(() {
      mockPlatform = MockWebviewPlatform();
      jsBridge = JSBridge(mockPlatform);
    });

    tearDown(() {
      jsBridge.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await jsBridge.initialize();

        expect(mockPlatform.executedScripts, hasLength(1));
        expect(mockPlatform.lastExecutedScript, contains('window.flutterBridge'));
        expect(mockPlatform.lastExecutedScript, contains('sendMessage'));
        expect(mockPlatform.lastExecutedScript, contains('handleMessage'));
      });

      test('should handle initialization errors', () async {
        mockPlatform.shouldThrowError = true;

        expect(() => jsBridge.initialize(), throwsException);
      });
    });

    group('Message Sending', () {
      setUp(() async {
        await jsBridge.initialize();
        mockPlatform.executedScripts.clear();
        mockPlatform.sentMessages.clear();
      });

      test('should send message to JavaScript', () async {
        final message = JSMessage(type: 'test', data: {'key': 'value'}, id: 'test-id', timestamp: DateTime.now());

        await jsBridge.sendMessage(message);

        expect(mockPlatform.sentMessages, hasLength(1));
        expect(mockPlatform.sentMessages.first.type, equals('test'));
        expect(mockPlatform.sentMessages.first.data['key'], equals('value'));
      });

      test('should handle message sending errors', () async {
        mockPlatform.shouldThrowError = true;

        final message = JSMessage(type: 'test', data: {});

        expect(() => jsBridge.sendMessage(message), throwsException);
      });
    });

    group('JavaScript Execution', () {
      setUp(() async {
        await jsBridge.initialize();
        mockPlatform.executedScripts.clear();
      });

      test('should execute JavaScript and return result', () async {
        mockPlatform.scriptResult = 'test result';

        final result = await jsBridge.executeJavaScript<String>('console.log("test")');

        expect(result, equals('test result'));
        expect(mockPlatform.executedScripts, hasLength(1));
      });

      test('should parse JSON results', () async {
        mockPlatform.scriptResult = '{"key": "value"}';

        final result = await jsBridge.executeJavaScript<Map<String, dynamic>>('getObject()');

        expect(result, isA<Map<String, dynamic>>());
        expect(result?['key'], equals('value'));
      });

      test('should handle execution errors', () async {
        mockPlatform.shouldThrowError = true;

        expect(() => jsBridge.executeJavaScript('throw new Error("test")'), throwsA(isA<JSBridgeError>()));
      });
    });

    group('Function Injection and Calling', () {
      setUp(() async {
        await jsBridge.initialize();
        mockPlatform.executedScripts.clear();
      });

      test('should inject JavaScript function', () async {
        await jsBridge.injectFunction('testFunction', 'function() { return "test"; }');

        expect(mockPlatform.executedScripts, hasLength(1));
        expect(mockPlatform.lastExecutedScript, contains('window.testFunction'));
      });

      test('should call JavaScript function with arguments', () async {
        mockPlatform.scriptResult = 'function result';

        final result = await jsBridge.callFunction<String>('testFunction', ['arg1', 'arg2']);

        expect(result, equals('function result'));
        expect(mockPlatform.lastExecutedScript, contains('testFunction.apply'));
        expect(mockPlatform.lastExecutedScript, contains('["arg1","arg2"]'));
      });

      test('should evaluate JavaScript expressions', () async {
        mockPlatform.scriptResult = 42;

        final result = await jsBridge.evaluateExpression<int>('21 + 21');

        expect(result, equals(42));
        expect(mockPlatform.lastExecutedScript, contains('21 + 21'));
      });
    });

    group('Event Listeners', () {
      setUp(() async {
        await jsBridge.initialize();
        mockPlatform.executedScripts.clear();
      });

      test('should add event listener', () async {
        await jsBridge.addEventListener('click', 'function(e) { console.log(e); }');

        expect(mockPlatform.executedScripts, hasLength(1));
        expect(mockPlatform.lastExecutedScript, contains('addEventListener'));
        expect(mockPlatform.lastExecutedScript, contains('click'));
      });

      test('should remove event listener', () async {
        await jsBridge.removeEventListener('click', 'clickHandler');

        expect(mockPlatform.executedScripts, hasLength(1));
        expect(mockPlatform.lastExecutedScript, contains('removeEventListener'));
        expect(mockPlatform.lastExecutedScript, contains('click'));
      });
    });

    group('Request-Response Pattern', () {
      setUp(() async {
        await jsBridge.initialize();
        mockPlatform.executedScripts.clear();
        mockPlatform.sentMessages.clear();
      });

      test('should send request and handle response', () async {
        // Start the request
        final requestFuture = jsBridge.sendRequest<Map<String, dynamic>>('getData', {'param': 'value'});

        // Verify request was sent
        await Future.delayed(Duration(milliseconds: 10)); // Allow async operations to complete
        expect(mockPlatform.sentMessages, hasLength(1));

        final sentMessage = mockPlatform.sentMessages.first;
        expect(sentMessage.type, equals('getData'));
        expect(sentMessage.data['param'], equals('value'));
        expect(sentMessage.id, isNotNull);

        // Simulate response
        final responseMessage = JSMessage(
          type: 'response',
          data: {'result': 'response data'},
          id: sentMessage.id,
          timestamp: DateTime.now(),
        );

        jsBridge.handleIncomingMessage(responseMessage);

        // Verify response is received
        final result = await requestFuture;
        expect(result, equals({'result': 'response data'}));
      });

      test('should handle request timeout', () async {
        expect(
          () => jsBridge.sendRequest('getData', {}, timeout: Duration(milliseconds: 10)),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should handle error responses', () async {
        // Start the request
        final requestFuture = jsBridge.sendRequest<String>('getData', {});

        // Wait for request to be sent
        await Future.delayed(Duration.zero);
        final sentMessage = mockPlatform.sentMessages.first;

        // Simulate error response
        final errorMessage = JSMessage(
          type: 'error',
          data: {'message': 'Request failed'},
          id: sentMessage.id,
          timestamp: DateTime.now(),
        );

        jsBridge.handleIncomingMessage(errorMessage);

        // Verify error is thrown
        expect(() => requestFuture, throwsA(isA<Error>()));
      });
    });

    group('Message Handling', () {
      setUp(() async {
        await jsBridge.initialize();
      });

      test('should forward regular messages to stream', () async {
        final receivedMessages = <JSMessage>[];
        jsBridge.messageStream.listen(receivedMessages.add);

        final message = JSMessage(
          type: 'notification',
          data: {'content': 'test notification'},
          timestamp: DateTime.now(),
        );

        jsBridge.handleIncomingMessage(message);

        await Future.delayed(Duration.zero); // Allow stream to process
        expect(receivedMessages, hasLength(1));
        expect(receivedMessages.first.type, equals('notification'));
      });

      test('should handle malformed messages gracefully', () async {
        expect(() => jsBridge.handleIncomingMessage(JSMessage(type: '', data: {})), returnsNormally);
      });
    });

    group('Disposal', () {
      test('should dispose resources properly', () async {
        await jsBridge.initialize();

        // Start a request that will be cancelled
        final requestFuture = jsBridge.sendRequest('test', {});

        jsBridge.dispose();

        // Verify pending requests are cancelled
        expect(() => requestFuture, throwsA(isA<JSBridgeError>()));
      });
    });
  });
}
