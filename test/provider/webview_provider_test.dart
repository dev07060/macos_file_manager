import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_file_manager/model/webview/webview_config.dart';
import 'package:macos_file_manager/model/webview/webview_state.dart';
import 'package:macos_file_manager/provider/webview_provider.dart';

void main() {
  group('WebviewProvider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('webviewConfig provider', () {
      test('should return default WebviewConfig', () {
        final config = container.read(webviewConfigProvider);

        expect(config, isA<WebviewConfig>());
        expect(config.initialUrl, 'https://google.com');
        expect(config.javascriptEnabled, true);
        expect(config.debuggingEnabled, true);
        expect(config.userAgent, 'Flutter WebView');
      });
    });

    group('Webview provider', () {
      test('should initialize with default WebviewState', () {
        final state = container.read(webviewProvider);

        expect(state, isA<WebviewState>());
        expect(state.currentUrl, '');
        expect(state.isLoading, false);
        expect(state.canGoBack, false);
        expect(state.canGoForward, false);
        expect(state.error, null);
        expect(state.navigationHistory, isEmpty);
      });

      test('should navigate to URL correctly', () {
        final webview = container.read(webviewProvider.notifier);
        const testUrl = 'https://example.com';

        webview.navigateToUrl(testUrl);
        final state = container.read(webviewProvider);

        expect(state.currentUrl, testUrl);
        expect(state.isLoading, true);
        expect(state.error, null);
        expect(state.navigationHistory, contains(testUrl));
      });

      test('should not navigate to empty URL', () {
        final webview = container.read(webviewProvider.notifier);
        final initialState = container.read(webviewProvider);

        webview.navigateToUrl('');
        final state = container.read(webviewProvider);

        expect(state, equals(initialState));
      });

      test('should set loading state correctly', () {
        final webview = container.read(webviewProvider.notifier);

        webview.setLoading(true);
        expect(container.read(webviewProvider).isLoading, true);

        webview.setLoading(false);
        expect(container.read(webviewProvider).isLoading, false);
      });

      test('should set navigation capabilities correctly', () {
        final webview = container.read(webviewProvider.notifier);

        webview.setNavigationCapabilities(canGoBack: true, canGoForward: true);

        final state = container.read(webviewProvider);
        expect(state.canGoBack, true);
        expect(state.canGoForward, true);
      });

      test('should set error state correctly', () {
        final webview = container.read(webviewProvider.notifier);
        const errorMessage = 'Network error';

        webview.setError(errorMessage);
        final state = container.read(webviewProvider);

        expect(state.error, errorMessage);
        expect(state.isLoading, false);
      });

      test('should handle go back when canGoBack is true', () {
        final webview = container.read(webviewProvider.notifier);

        // Set up state where going back is possible
        webview.setNavigationCapabilities(canGoBack: true, canGoForward: false);
        webview.goBack();

        final state = container.read(webviewProvider);
        expect(state.isLoading, true);
        expect(state.error, null);
      });

      test('should not go back when canGoBack is false', () {
        final webview = container.read(webviewProvider.notifier);
        final initialState = container.read(webviewProvider);

        // canGoBack is false by default
        webview.goBack();
        final state = container.read(webviewProvider);

        expect(state, equals(initialState));
      });

      test('should handle go forward when canGoForward is true', () {
        final webview = container.read(webviewProvider.notifier);

        // Set up state where going forward is possible
        webview.setNavigationCapabilities(canGoBack: false, canGoForward: true);
        webview.goForward();

        final state = container.read(webviewProvider);
        expect(state.isLoading, true);
        expect(state.error, null);
      });

      test('should not go forward when canGoForward is false', () {
        final webview = container.read(webviewProvider.notifier);
        final initialState = container.read(webviewProvider);

        // canGoForward is false by default
        webview.goForward();
        final state = container.read(webviewProvider);

        expect(state, equals(initialState));
      });

      test('should reload correctly', () {
        final webview = container.read(webviewProvider.notifier);

        webview.reload();
        final state = container.read(webviewProvider);

        expect(state.isLoading, true);
        expect(state.error, null);
      });

      test('should clear navigation history', () {
        final webview = container.read(webviewProvider.notifier);

        // Add some navigation history
        webview.navigateToUrl('https://example1.com');
        webview.navigateToUrl('https://example2.com');

        expect(container.read(webviewProvider).navigationHistory.length, 2);

        webview.clearHistory();
        expect(container.read(webviewProvider).navigationHistory, isEmpty);
      });

      test('should reset to initial state', () {
        final webview = container.read(webviewProvider.notifier);

        // Modify state
        webview.navigateToUrl('https://example.com');
        webview.setLoading(true);
        webview.setError('Some error');

        // Reset
        webview.reset();
        final state = container.read(webviewProvider);

        expect(state.currentUrl, '');
        expect(state.isLoading, false);
        expect(state.canGoBack, false);
        expect(state.canGoForward, false);
        expect(state.error, null);
        expect(state.navigationHistory, isEmpty);
      });
    });
  });
}
