import 'package:flutter_test/flutter_test.dart';
import 'package:macos_file_manager/model/webview/js_message.dart';
import 'package:macos_file_manager/model/webview/webview_config.dart';
import 'package:macos_file_manager/webview/controller/webview_controller.dart';
import 'package:macos_file_manager/webview/platform/webview_platform_interface.dart';

// Mock platform interface for testing
class MockWebviewPlatform extends WebviewPlatformInterface {
  bool _isInitialized = false;
  String? _currentUrl;
  WebviewCallbacks? _callbacks;
  final List<String> _loadedUrls = [];
  bool _shouldFailInitialization = false;
  bool _shouldFailUrlLoading = false;

  // Function that can be overridden for testing
  Future<void> Function(String)? _customLoadUrl;

  // Test configuration
  void setShouldFailInitialization(bool shouldFail) {
    _shouldFailInitialization = shouldFail;
  }

  void setShouldFailUrlLoading(bool shouldFail) {
    _shouldFailUrlLoading = shouldFail;
  }

  void setCustomLoadUrl(Future<void> Function(String) customLoadUrl) {
    _customLoadUrl = customLoadUrl;
  }

  // Expose private fields for custom loadUrl function
  set currentUrl(String? url) => _currentUrl = url;
  WebviewCallbacks? get callbacks => _callbacks;
  List<String> get mutableLoadedUrls => _loadedUrls;

  List<String> get loadedUrls => List.unmodifiable(_loadedUrls);

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    if (_shouldFailInitialization) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Mock initialization failure');
    }
    _isInitialized = true;
  }

  @override
  void setCallbacks(WebviewCallbacks callbacks) {
    _callbacks = callbacks;
  }

  @override
  Future<void> loadUrl(String url) async {
    // Use custom loadUrl if provided
    if (_customLoadUrl != null) {
      return _customLoadUrl!(url);
    }

    if (!_isInitialized) {
      throw const WebviewError(type: WebviewErrorType.initializationError, message: 'Platform not initialized');
    }

    if (_shouldFailUrlLoading) {
      throw WebviewError(type: WebviewErrorType.networkError, message: 'Mock URL loading failure for: $url');
    }

    _currentUrl = url;
    _loadedUrls.add(url);

    // Simulate page loading events
    _callbacks?.onPageStarted(url);
    await Future.delayed(const Duration(milliseconds: 100));
    _callbacks?.onPageFinished(url);
  }

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}

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
    _loadedUrls.clear();
  }

  @override
  void setJSMessageListener(Function(JSMessage) listener) {}
}

void main() {
  group('WebviewController Initial URL Loading', () {
    late MockWebviewPlatform mockPlatform;
    late WebviewController controller;

    setUp(() {
      mockPlatform = MockWebviewPlatform();
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('should load Google.com as default initial URL', () async {
      const config = WebviewConfig();
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Should have loaded the default Google.com URL
      expect(mockPlatform.loadedUrls, contains('https://www.google.com'));
      expect(controller.currentState.currentUrl, equals('https://www.google.com'));
    });

    test('should load custom initial URL when provided', () async {
      const config = WebviewConfig(initialUrl: 'https://example.com');
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Should have loaded the custom URL
      expect(mockPlatform.loadedUrls, contains('https://example.com'));
      expect(controller.currentState.currentUrl, equals('https://example.com'));
    });

    test('should not auto-load when autoLoadInitialUrl is false', () async {
      const config = WebviewConfig(autoLoadInitialUrl: false);
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Should not have loaded any URLs automatically
      expect(mockPlatform.loadedUrls, isEmpty);
      expect(controller.currentState.currentUrl, equals('https://www.google.com')); // Initial state
    });

    test('should handle initial URL loading failure gracefully', () async {
      const config = WebviewConfig(initialUrl: 'https://example.com');
      controller = WebviewController(mockPlatform, config: config);

      // Configure mock to fail URL loading
      mockPlatform.setShouldFailUrlLoading(true);

      await controller.initialize();

      // Should have attempted to load the URL
      expect(mockPlatform.loadedUrls, isEmpty); // Failed to load
      expect(controller.currentState.error, isNotNull);
      expect(controller.currentState.error, contains('Failed to load https://example.com'));
    });

    test('should try alternative Google URLs when main Google.com fails', () async {
      const config = WebviewConfig(initialUrl: 'https://www.google.com');
      controller = WebviewController(mockPlatform, config: config);

      // Configure mock to fail first URL loading, then succeed
      bool firstAttempt = true;
      mockPlatform.setShouldFailUrlLoading(true);

      // Override loadUrl to simulate failure on first attempt only
      mockPlatform.setCustomLoadUrl((String url) async {
        if (firstAttempt && url == 'https://www.google.com') {
          firstAttempt = false;
          throw const WebviewError(type: WebviewErrorType.networkError, message: 'Network error');
        }
        // Simulate successful loading for alternative URLs
        mockPlatform.currentUrl = url;
        mockPlatform.mutableLoadedUrls.add(url);
        mockPlatform.callbacks?.onPageStarted(url);
        await Future.delayed(const Duration(milliseconds: 50));
        mockPlatform.callbacks?.onPageFinished(url);
      });

      await controller.initialize();

      // Should have tried alternative URLs
      expect(mockPlatform.loadedUrls.length, greaterThan(0));
    });

    test('should respect timeout configuration', () async {
      const config = WebviewConfig(
        initialUrl: 'https://example.com',
        initialLoadTimeoutSeconds: 1, // Very short timeout
      );
      controller = WebviewController(mockPlatform, config: config);

      // Override loadUrl to simulate slow loading
      mockPlatform.setCustomLoadUrl((String url) async {
        await Future.delayed(const Duration(seconds: 2)); // Longer than timeout
        mockPlatform.currentUrl = url;
        mockPlatform.mutableLoadedUrls.add(url);
      });

      await controller.initialize();

      // Should have timed out and set error
      expect(controller.currentState.error, isNotNull);
      expect(controller.currentState.error, contains('timed out'));
    });

    test('should update state correctly during initialization', () async {
      const config = WebviewConfig(initialUrl: 'https://example.com');
      controller = WebviewController(mockPlatform, config: config);

      final stateChanges = <String>[];
      controller.stateStream.listen((state) {
        if (state.isLoading) {
          stateChanges.add('loading');
        } else if (state.error != null) {
          stateChanges.add('error');
        } else if (state.currentUrl.isNotEmpty) {
          stateChanges.add('loaded');
        }
      });

      await controller.initialize();
      await Future.delayed(const Duration(milliseconds: 200)); // Wait for state updates

      // Should have gone through loading and loaded states
      expect(stateChanges, contains('loading'));
      expect(stateChanges, contains('loaded'));
    });

    test('should handle empty initial URL gracefully', () async {
      const config = WebviewConfig(initialUrl: '');
      controller = WebviewController(mockPlatform, config: config);

      await controller.initialize();

      // Should not have attempted to load any URL
      expect(mockPlatform.loadedUrls, isEmpty);
      expect(controller.currentState.error, isNull);
    });
  });
}
