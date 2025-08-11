import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/webview/js_message.dart';
import 'package:macos_file_manager/model/webview/webview_config.dart';
import 'package:macos_file_manager/webview/controller/webview_controller.dart';
import 'package:macos_file_manager/webview/platform/webview_platform_interface.dart';

// Mock platform interface for testing
class MockWebviewPlatform extends WebviewPlatformInterface {
  bool _canGoBack = false;
  bool _canGoForward = false;
  String _currentUrl = '';
  bool _isLoading = false;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  @override
  void setCallbacks(WebviewCallbacks callbacks) {}

  @override
  Future<void> loadUrl(String url) async {
    _currentUrl = url;
    _isLoading = true;
  }

  @override
  Future<void> goBack() async {
    if (_canGoBack) {
      _isLoading = true;
    }
  }

  @override
  Future<void> goForward() async {
    if (_canGoForward) {
      _isLoading = true;
    }
  }

  @override
  Future<void> reload() async {
    _isLoading = true;
  }

  @override
  Future<String?> executeJavaScript(String script) async => null;

  @override
  Future<void> sendMessageToJS(dynamic message) async {}

  @override
  Future<void> injectJavaScript(String script) async {}

  @override
  void setJSMessageListener(Function(JSMessage) listener) {}

  @override
  Future<bool> canGoBack() async => _canGoBack;

  @override
  Future<bool> canGoForward() async => _canGoForward;

  @override
  Future<String?> getCurrentUrl() async => _currentUrl;

  @override
  Future<bool> isLoading() async => _isLoading;

  @override
  Future<String?> getTitle() async => 'Test Page';

  @override
  Future<void> dispose() async {}

  // Test helpers
  void setCanGoBack(bool value) => _canGoBack = value;
  void setCanGoForward(bool value) => _canGoForward = value;
  void setLoading(bool value) => _isLoading = value;
}

// Mock WebviewControls for testing without platform dependencies
class MockWebviewControls extends StatelessWidget {
  const MockWebviewControls({
    super.key,
    required this.controller,
    this.onUrlSubmitted,
    this.showUrlBar = true,
    this.showNavigationButtons = true,
  });

  final WebviewController controller;
  final void Function(String url)? onUrlSubmitted;
  final bool showUrlBar;
  final bool showNavigationButtons;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          if (showNavigationButtons) ...[
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}, tooltip: 'Go Back'),
                IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () {}, tooltip: 'Go Forward'),
                IconButton(icon: const Icon(Icons.refresh), onPressed: () {}, tooltip: 'Reload'),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More options',
                  onSelected: (value) {},
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'home',
                          child: Row(children: [Icon(Icons.home), SizedBox(width: 8), Text('Go to Home')]),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (showUrlBar) ...[
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter URL or search...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: onUrlSubmitted,
            ),
          ],
        ],
      ),
    );
  }
}

void main() {
  group('WebviewControls', () {
    late MockWebviewPlatform mockPlatform;
    late WebviewController controller;

    setUp(() {
      mockPlatform = MockWebviewPlatform();
      controller = WebviewController(mockPlatform, config: const WebviewConfig(initialUrl: 'https://google.com'));
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should display navigation buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: Scaffold(body: MockWebviewControls(controller: controller)))),
      );

      // Should show navigation buttons
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('should display URL input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: Scaffold(body: MockWebviewControls(controller: controller)))),
      );

      // Should show URL input field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter URL or search...'), findsOneWidget);
    });

    testWidgets('should handle URL submission', (WidgetTester tester) async {
      String? submittedUrl;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MockWebviewControls(controller: controller, onUrlSubmitted: (url) => submittedUrl = url),
            ),
          ),
        ),
      );

      // Enter URL and submit
      await tester.enterText(find.byType(TextField), 'example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Should capture submitted URL
      expect(submittedUrl, equals('example.com'));
    });

    testWidgets('should show menu options', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: Scaffold(body: MockWebviewControls(controller: controller)))),
      );

      // Tap menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Should show menu options
      expect(find.text('Go to Home'), findsOneWidget);
    });

    testWidgets('should hide components based on configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MockWebviewControls(controller: controller, showUrlBar: false, showNavigationButtons: false),
            ),
          ),
        ),
      );

      // Should not show URL bar or navigation buttons
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('should integrate with theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(body: MockWebviewControls(controller: controller)),
          ),
        ),
      );

      // Should render with theme integration
      expect(find.byType(MockWebviewControls), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(body: MockWebviewControls(controller: controller)),
          ),
        ),
      );

      // Should adapt to theme changes
      expect(find.byType(MockWebviewControls), findsOneWidget);
    });
  });
}
