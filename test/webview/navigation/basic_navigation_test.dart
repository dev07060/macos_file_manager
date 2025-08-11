import 'package:flutter_test/flutter_test.dart';
import 'package:macos_file_manager/model/webview/js_message.dart';
import 'package:macos_file_manager/model/webview/webview_config.dart';
import 'package:macos_file_manager/webview/controller/webview_controller.dart';
import 'package:macos_file_manager/webview/platform/webview_platform_interface.dart';

// Mock platform interface for navigation testing
class MockNavigationPlatform extends WebviewPlatformInterface {
  bool _isInitialized = false;
  String? _currentUrl;
  WebviewCallbacks? _callbacks;
  final List<String> _navigationHistory = [];
  final List<String> _loadedUrls = [];
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _shouldFailNavigation = false;

  // Test configuration
  void setShouldFailNavigation(bool shouldFail) {
    _shouldFailNavigation = shouldFail;
  }

  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);
  List<String> get loadedUrls => List.unmodifiable(_loadedUrls);

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
    if (!_isInitialized) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Platform not initialized');
    }

    if (_shouldFailNavigation) {
      throw WebviewError(type: WebviewErrorType.networkError, message: 'Mock navigation failure for: $url');
    }

    // Simulate navigation
    _currentUrl = url;
    _loadedUrls.add(url);
    _navigationHistory.add(url);

    // Update navigation capabilities
    _canGoBack = _navigationHistory.length > 1;
    _canGoForward = false; // Reset forward capability on new navigation

    // Simulate page loading events
    _callbacks?.onPageStarted(url);
    await Future.delayed(const Duration(milliseconds: 50));
    _callbacks?.onNavigationStateChanged(_canGoBack, _canGoForward);
    await Future.delayed(const Duration(milliseconds: 50));
    _callbacks?.onPageFinished(url);
  }

  @override
  Future<bool> canGoBack() async => _canGoBack;

  @override
  Future<bool> canGoForward() async => _canGoForward;

  @override
  Future<void> goBack() async {
    if (!_canGoBack || _navigationHistory.length <= 1) {
      throw const WebviewError(type: WebviewErrorType.navigationError, message: 'Cannot go back');
    }

    // Remove current URL and go to previous
    _navigationHistory.removeLast();
    final previousUrl = _navigationHistory.last;
    _currentUrl = previousUrl;

    // Update navigation capabilities
    _canGoBack = _navigationHistory.length > 1;
    _canGoForward = true;

    // Simulate navigation events
    _callbacks?.onPageStarted(previousUrl);
    await Future.delayed(const Duration(milliseconds: 50));
    _callbacks?.onNavigationStateChanged(_canGoBack, _canGoForward);
    await Future.delayed(const Duration(milliseconds: 50));
    _callbacks?.onPageFinished(previousUrl);
  }

  @override
  Future<void> goForward() async {
    if (!_canGoForward) {
      throw const WebviewError(type: WebviewErrorType.navigationError, message: 'Cannot go forward');
    }

    // For simplicity, just simulate forward navigation
    _canGoForward = false;
    _callbacks?.onNavigationStateChanged(_canGoBack, _canGoForward);
  }

  @override
  Future<void> reload() async {
    if (_currentUrl != null) {
      await loadUrl(_currentUrl!);
    }
  }

  @override
  Future<String?> executeJavaScript(String script) async => null;

  @override
  Future<void> sendMessageToJS(message) async {}

  @override
  Future<String?> getCurrentUrl() async => _currentUrl;

  @override
  Future<bool> isLoading() async => false;

  @override
  Future<String?> getTitle() async => 'Mock Title';

  @override
  Future<void> injectJavaScript(String script) async {}

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    _currentUrl = null;
    _callbacks = null;
    _navigationHistory.clear();
    _loadedUrls.clear();
  }

  @override
  void setJSMessageListener(Function(JSMessage) listener) {}
}

void main() {
  group('Basic Web Navigation', () {
    late MockNavigationPlatform mockPlatform;
    late WebviewController controller;

    setUp(() {
      mockPlatform = MockNavigationPlatform();
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('should allow clicking links to navigate to new pages', () async {
      const config = WebviewConfig(initialUrl: 'https://www.google.com');
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Simulate clicking a link to navigate to a new page
      await controller.loadUrl('https://www.example.com');

      // Should have navigated to the new URL
      expect(controller.currentState.currentUrl, equals('https://www.example.com'));
      expect(mockPlatform.loadedUrls, contains('https://www.example.com'));
      expect(mockPlatform.navigationHistory, contains('https://www.example.com'));
    });

    test('should detect URL changes and update state', () async {
      const config = WebviewConfig(initialUrl: 'https://www.google.com');
      controller = WebviewController(mockPlatform, config: config);

      final stateChanges = <String>[];
      controller.stateStream.listen((state) {
        if (state.currentUrl.isNotEmpty) {
          stateChanges.add(state.currentUrl);
        }
      });

      await controller.initialize();

      // Navigate to multiple pages
      await controller.loadUrl('https://www.example.com');
      await controller.loadUrl('https://www.github.com');

      await Future.delayed(const Duration(milliseconds: 200));

      // Should have detected all URL changes
      expect(stateChanges, contains('https://www.google.com'));
      expect(stateChanges, contains('https://www.example.com'));
      expect(stateChanges, contains('https://www.github.com'));
    });

    test('should update navigation capabilities correctly', () async {
      const config = WebviewConfig(initialUrl: 'https://www.google.com');
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Initially should not be able to go back
      expect(controller.currentState.canGoBack, isFalse);
      expect(controller.currentState.canGoForward, isFalse);

      // Navigate to a new page
      await controller.loadUrl('https://www.example.com');
      await Future.delayed(const Duration(milliseconds: 200));

      // Should now be able to go back
      expect(controller.currentState.canGoBack, isTrue);
      expect(controller.currentState.canGoForward, isFalse);

      // Go back
      await controller.goBack();
      await Future.delayed(const Duration(milliseconds: 200));

      // Should now be able to go forward
      expect(controller.currentState.canGoBack, isFalse);
      expect(controller.currentState.canGoForward, isTrue);
    });

    test('should handle navigation errors appropriately', () async {
      const config = WebviewConfig(initialUrl: 'https://www.google.com');
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Configure mock to fail navigation
      mockPlatform.setShouldFailNavigation(true);

      // Attempt to navigate to a failing URL
      bool errorThrown = false;
      try {
        await controller.loadUrl('https://failing-site.com');
      } catch (e) {
        errorThrown = true;
        expect(e, isA<WebviewError>());
        expect((e as WebviewError).type, equals(WebviewErrorType.networkError));
      }

      expect(errorThrown, isTrue, reason: 'Expected navigation to fail');

      // State should reflect the error
      expect(controller.currentState.error, isNotNull);
      expect(controller.currentState.error, contains('Network error'));
      expect(controller.currentState.isLoading, isFalse);
    });

    test('should maintain navigation history correctly', () async {
      const config = WebviewConfig(initialUrl: 'https://www.google.com');
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Navigate through multiple pages
      await controller.loadUrl('https://www.example.com');
      await controller.loadUrl('https://www.github.com');
      await controller.loadUrl('https://www.stackoverflow.com');

      // History should contain all visited URLs
      final history = controller.currentState.navigationHistory;
      expect(history, contains('https://www.google.com'));
      expect(history, contains('https://www.example.com'));
      expect(history, contains('https://www.github.com'));
      expect(history, contains('https://www.stackoverflow.com'));
      expect(history.length, equals(4));
    });

    test('should handle back and forward navigation', () async {
      const config = WebviewConfig(initialUrl: 'https://www.google.com');
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Navigate to a new page
      await controller.loadUrl('https://www.example.com');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.currentState.currentUrl, equals('https://www.example.com'));
      expect(controller.currentState.canGoBack, isTrue);

      // Go back
      await controller.goBack();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.currentState.currentUrl, equals('https://www.google.com'));
      expect(controller.currentState.canGoForward, isTrue);
    });

    test('should handle reload functionality', () async {
      const config = WebviewConfig(initialUrl: 'https://www.google.com');
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      final initialLoadCount = mockPlatform.loadedUrls.length;

      // Reload the page
      await controller.reload();

      // Should have loaded the same URL again
      expect(mockPlatform.loadedUrls.length, equals(initialLoadCount + 1));
      expect(mockPlatform.loadedUrls.last, equals('https://www.google.com'));
    });

    test('should limit navigation history size', () async {
      const config = WebviewConfig(initialUrl: 'https://www.google.com');
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Navigate to many pages (more than the limit of 100)
      for (int i = 1; i <= 105; i++) {
        await controller.loadUrl('https://example$i.com');
      }

      // History should be limited to 100 entries
      expect(controller.currentState.navigationHistory.length, lessThanOrEqualTo(100));
    });

    test('should format navigation errors with user-friendly messages', () async {
      const config = WebviewConfig(initialUrl: 'https://www.google.com');
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Test different error types
      final networkError = WebviewError(
        type: WebviewErrorType.networkError,
        message: 'NSURLErrorDomain error',
        code: '-1009',
      );

      final navigationError = WebviewError(type: WebviewErrorType.navigationError, message: 'Invalid URL');

      // Simulate errors through the callback
      controller.onPageError(networkError);
      expect(controller.currentState.error, contains('No internet connection'));

      controller.onPageError(navigationError);
      expect(controller.currentState.error, contains('Navigation failed'));
    });
  });
}
