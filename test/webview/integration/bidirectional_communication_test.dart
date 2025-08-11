import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:macos_file_manager/model/webview/js_message.dart';
import 'package:macos_file_manager/webview/bridge/js_bridge.dart';
import 'package:macos_file_manager/webview/controller/webview_controller.dart';
import 'package:macos_file_manager/webview/platform/webview_platform_interface.dart';

class MockBidirectionalPlatform extends WebviewPlatformInterface {
  final List<String> executedScripts = [];
  final List<JSMessage> sentMessages = [];
  final StreamController<JSMessage> _incomingMessages = StreamController<JSMessage>.broadcast();

  WebviewCallbacks? _callbacks;
  bool _isInitialized = false;
  bool shouldThrowError = false;

  // Simulate JavaScript execution results
  final Map<String, dynamic> _jsResults = {};

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _isInitialized = true;
  }

  @override
  void setCallbacks(WebviewCallbacks callbacks) {
    _callbacks = callbacks;
  }

  @override
  Future<void> loadUrl(String url) async {
    _callbacks?.onPageStarted(url);
    await Future.delayed(Duration(milliseconds: 10));
    _callbacks?.onPageFinished(url);
  }

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

    // Simulate bridge initialization
    if (script.contains('window.flutterBridge')) {
      // Simulate successful bridge initialization
      await Future.delayed(Duration(milliseconds: 5));
      simulateJSMessage(JSMessage(type: 'bridge_ready', data: {'ready': true}, timestamp: DateTime.now()));
      return 'true';
    }

    // Simulate function calls
    if (script.contains('testFunction.apply')) {
      return 'function executed';
    }

    // Simulate expression evaluation
    if (script.contains('document.title')) {
      return 'Test Page';
    }

    // Return stored results or default
    final result = _jsResults[script];
    if (result != null) {
      return result is String ? result : jsonEncode(result);
    }

    return 'null';
  }

  @override
  Future<void> sendMessageToJS(JSMessage message) async {
    sentMessages.add(message);

    // Simulate JavaScript processing the message
    await Future.delayed(Duration(milliseconds: 5));

    // Simulate response for request messages
    if (message.id != null && message.type != 'response' && message.type != 'error') {
      final response = JSMessage(
        type: 'response',
        data: {'echo': message.data, 'processed': true},
        id: message.id,
        timestamp: DateTime.now(),
      );
      simulateJSMessage(response);
    }
  }

  @override
  Future<void> injectJavaScript(String script) async {
    executedScripts.add(script);
  }

  @override
  void setJSMessageListener(Function(JSMessage) listener) {}

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<String?> getCurrentUrl() async => 'https://example.com';

  @override
  Future<bool> isLoading() async => false;

  @override
  Future<String?> getTitle() async => 'Test Page';

  @override
  Future<void> dispose() async {
    await _incomingMessages.close();
  }

  // Helper method to simulate JavaScript messages
  void simulateJSMessage(JSMessage message) {
    _callbacks?.onJSMessage(message);
  }

  // Helper method to simulate user interactions in JavaScript
  void simulateUserAction(String action, Map<String, dynamic> data) {
    final message = JSMessage(type: action, data: data, timestamp: DateTime.now());
    simulateJSMessage(message);
  }

  // Helper method to simulate JavaScript errors
  void simulateJSError(String error, {String? messageId}) {
    final message = JSMessage(
      type: 'error',
      data: {'message': error, 'source': 'javascript'},
      id: messageId,
      timestamp: DateTime.now(),
    );
    simulateJSMessage(message);
  }
}

void main() {
  group('Bidirectional Communication Integration Tests', () {
    late MockBidirectionalPlatform mockPlatform;
    late WebviewController controller;

    setUp(() async {
      mockPlatform = MockBidirectionalPlatform();
      controller = WebviewController(mockPlatform);
      await controller.initialize();

      // Wait for bridge initialization
      await Future.delayed(Duration(milliseconds: 20));
    });

    tearDown(() async {
      await controller.dispose();
    });

    group('Flutter to JavaScript Communication', () {
      test('should send simple message to JavaScript', () async {
        final message = JSMessage(type: 'greeting', data: {'text': 'Hello JavaScript!'}, timestamp: DateTime.now());

        await controller.sendMessageToJS(message);

        expect(mockPlatform.sentMessages, hasLength(1));
        expect(mockPlatform.sentMessages.first.type, equals('greeting'));
        expect(mockPlatform.sentMessages.first.data['text'], equals('Hello JavaScript!'));
      });

      test('should send request and receive response', () async {
        final response = await controller.sendJSRequest<Map<String, dynamic>>('getData', {'query': 'user_info'});

        expect(response['echo']['query'], equals('user_info'));
        expect(response['processed'], isTrue);
      });

      test('should inject and call JavaScript functions', () async {
        // Inject a function
        await controller.injectJSFunction('calculateSum', 'function(a, b) { return a + b; }');

        // Verify function was injected
        expect(mockPlatform.executedScripts.any((script) => script.contains('window.calculateSum')), isTrue);

        // Call the function
        final result = await controller.callJSFunction<String>('calculateSum', [5, 3]);
        expect(result, equals('function executed'));
      });

      test('should evaluate JavaScript expressions', () async {
        mockPlatform
                ._jsResults['(function() { try { const result = document.title; return JSON.stringify(result); } catch (error) { throw new Error(\'Expression evaluation failed: \' + error.message); } })();'] =
            '"Test Page"';

        final result = await controller.evaluateJSExpression<String>('document.title');
        expect(result, equals('Test Page'));
      });

      test('should handle JavaScript execution errors', () async {
        // Configure mock to throw error
        mockPlatform.shouldThrowError = true;

        expect(() => controller.executeJavaScript('throw new Error("test error")'), throwsA(isA<WebviewError>()));

        // Reset error state
        mockPlatform.shouldThrowError = false;
      });
    });

    group('JavaScript to Flutter Communication', () {
      test('should receive messages from JavaScript', () async {
        final receivedMessages = <JSMessage>[];
        controller.jsMessageStream.listen(receivedMessages.add);

        // Simulate JavaScript sending a message
        mockPlatform.simulateUserAction('button_click', {
          'buttonId': 'submit',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        await Future.delayed(Duration(milliseconds: 10));

        expect(receivedMessages, hasLength(1));
        expect(receivedMessages.first.type, equals('button_click'));
        expect(receivedMessages.first.data['buttonId'], equals('submit'));
      });

      test('should handle JavaScript notifications', () async {
        final receivedMessages = <JSMessage>[];
        controller.jsMessageStream.listen(receivedMessages.add);

        // Simulate multiple JavaScript notifications
        mockPlatform.simulateUserAction('page_scroll', {'position': 100});
        mockPlatform.simulateUserAction('form_change', {'field': 'email', 'value': 'test@example.com'});
        mockPlatform.simulateUserAction('modal_open', {'modalId': 'settings'});

        await Future.delayed(Duration(milliseconds: 10));

        expect(receivedMessages, hasLength(3));
        expect(receivedMessages[0].type, equals('page_scroll'));
        expect(receivedMessages[1].type, equals('form_change'));
        expect(receivedMessages[2].type, equals('modal_open'));
      });

      test('should handle JavaScript errors', () async {
        final receivedErrors = <WebviewError>[];
        controller.errorStream.listen(receivedErrors.add);

        // Simulate JavaScript error
        mockPlatform.simulateJSError('Uncaught TypeError: Cannot read property of undefined');

        await Future.delayed(Duration(milliseconds: 10));

        expect(receivedErrors, hasLength(1));
        expect(receivedErrors.first.type, equals(WebviewErrorType.javascriptError));
      });
    });

    group('Request-Response Pattern', () {
      test('should handle multiple concurrent requests', () async {
        final futures = <Future<Map<String, dynamic>>>[];

        // Send multiple concurrent requests
        for (int i = 0; i < 5; i++) {
          futures.add(controller.sendJSRequest<Map<String, dynamic>>('getItem', {'id': i}));
        }

        final results = await Future.wait(futures);

        expect(results, hasLength(5));
        for (int i = 0; i < 5; i++) {
          expect(results[i]['echo']['id'], equals(i));
          expect(results[i]['processed'], isTrue);
        }
      });

      test('should handle request timeout', () async {
        // Mock platform that doesn't respond
        final slowPlatform = MockBidirectionalPlatform();
        final slowController = WebviewController(slowPlatform);
        await slowController.initialize();

        expect(
          () => slowController.sendJSRequest('slowOperation', {}, timeout: Duration(milliseconds: 50)),
          throwsA(isA<TimeoutException>()),
        );

        await slowController.dispose();
      });

      test('should handle request errors', () async {
        final requestFuture = controller.sendJSRequest<Map<String, dynamic>>('errorOperation', {});

        // Wait for request to be sent
        await Future.delayed(Duration(milliseconds: 10));
        final sentMessage = mockPlatform.sentMessages.last;

        // Simulate error response
        mockPlatform.simulateJSError('Operation failed', messageId: sentMessage.id);

        expect(() => requestFuture, throwsA(isA<Exception>()));
      });
    });

    group('Message Serialization and Deserialization', () {
      test('should handle complex data structures', () async {
        final complexData = {
          'user': {
            'id': 123,
            'name': 'John Doe',
            'preferences': {'theme': 'dark', 'notifications': true},
          },
          'items': [
            {'id': 1, 'name': 'Item 1'},
            {'id': 2, 'name': 'Item 2'},
          ],
          'metadata': {'timestamp': DateTime.now().millisecondsSinceEpoch, 'version': '1.0.0'},
        };

        final response = await controller.sendJSRequest<Map<String, dynamic>>('processComplexData', complexData);

        expect(response['echo']['user']['name'], equals('John Doe'));
        expect(response['echo']['items'], hasLength(2));
        expect(response['processed'], isTrue);
      });

      test('should handle special characters and unicode', () async {
        final specialData = {
          'text': 'Hello 世界! 🌍 Special chars: "quotes", \'apostrophes\', <tags>',
          'emoji': '🚀💻🎉',
          'unicode': 'Ñoño café naïve résumé',
        };

        final response = await controller.sendJSRequest<Map<String, dynamic>>('processSpecialChars', specialData);

        expect(response['echo']['text'], contains('世界'));
        expect(response['echo']['emoji'], equals('🚀💻🎉'));
        expect(response['echo']['unicode'], contains('café'));
      });

      test('should handle null and empty values', () async {
        final dataWithNulls = {
          'nullValue': null,
          'emptyString': '',
          'emptyList': <String>[],
          'emptyMap': <String, dynamic>{},
          'zeroNumber': 0,
          'falseBoolean': false,
        };

        final response = await controller.sendJSRequest<Map<String, dynamic>>('processNullValues', dataWithNulls);

        expect(response['echo']['nullValue'], isNull);
        expect(response['echo']['emptyString'], equals(''));
        expect(response['echo']['emptyList'], isEmpty);
        expect(response['echo']['emptyMap'], isEmpty);
        expect(response['echo']['zeroNumber'], equals(0));
        expect(response['echo']['falseBoolean'], isFalse);
      });
    });

    group('Communication Flow and Debugging', () {
      test('should provide debugging information', () async {
        final debugMessages = <JSMessage>[];
        controller.jsMessageStream.listen((message) {
          if (message.type == 'debug' || message.data.containsKey('debug')) {
            debugMessages.add(message);
          }
        });

        // Send a message with debug flag
        await controller.sendMessageToJS(
          JSMessage(type: 'test', data: {'debug': true, 'operation': 'test_debug'}, timestamp: DateTime.now()),
        );

        await Future.delayed(Duration(milliseconds: 10));

        // Verify debug information is available
        expect(mockPlatform.sentMessages.any((msg) => msg.data['debug'] == true), isTrue);
      });

      test('should handle communication errors gracefully', () async {
        final errors = <WebviewError>[];
        controller.errorStream.listen(errors.add);

        // Simulate various error conditions
        mockPlatform.simulateJSError('Network error');
        mockPlatform.simulateJSError('Parse error');
        mockPlatform.simulateJSError('Timeout error');

        await Future.delayed(Duration(milliseconds: 20));

        expect(errors, hasLength(3));
        expect(errors.every((e) => e.type == WebviewErrorType.javascriptError), isTrue);
      });

      test('should maintain message order', () async {
        final receivedMessages = <JSMessage>[];
        controller.jsMessageStream.listen(receivedMessages.add);

        // Send messages in sequence
        for (int i = 0; i < 10; i++) {
          mockPlatform.simulateUserAction('sequence_test', {'order': i});
          await Future.delayed(Duration(milliseconds: 1));
        }

        await Future.delayed(Duration(milliseconds: 20));

        expect(receivedMessages, hasLength(10));
        for (int i = 0; i < 10; i++) {
          expect(receivedMessages[i].data['order'], equals(i));
        }
      });
    });

    group('Performance and Resource Management', () {
      test('should handle high-frequency messages', () async {
        final receivedMessages = <JSMessage>[];
        controller.jsMessageStream.listen(receivedMessages.add);

        // Send many messages quickly
        for (int i = 0; i < 100; i++) {
          mockPlatform.simulateUserAction('high_frequency', {'count': i});
        }

        await Future.delayed(Duration(milliseconds: 50));

        expect(receivedMessages, hasLength(100));
        expect(receivedMessages.last.data['count'], equals(99));
      });

      test('should clean up resources on disposal', () async {
        final testController = WebviewController(MockBidirectionalPlatform());
        await testController.initialize();

        // Verify controller is working
        expect(testController.currentState.isLoading, isFalse);

        // Dispose and verify cleanup
        await testController.dispose();

        // Verify operations fail after disposal
        expect(() => testController.sendMessageToJS(JSMessage(type: 'test', data: {})), throwsA(isA<WebviewError>()));
      });
    });
  });
}
