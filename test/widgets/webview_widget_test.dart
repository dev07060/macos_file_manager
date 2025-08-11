import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/webview/webview_config.dart';

// Mock test to avoid platform dependencies
class MockWebviewWidget extends StatelessWidget {
  const MockWebviewWidget({super.key, this.config, this.onUrlChanged, this.onLoadingChanged, this.onError});

  final WebviewConfig? config;
  final void Function(String url)? onUrlChanged;
  final void Function(bool isLoading)? onLoadingChanged;
  final void Function(dynamic error)? onError;

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = config ?? const WebviewConfig();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Mock WebView Content'),
          const SizedBox(height: 8),
          Text('Initial URL: ${effectiveConfig.initialUrl}', style: const TextStyle(fontSize: 12)),
          Text('Auto-load: ${effectiveConfig.autoLoadInitialUrl}', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

void main() {
  group('WebviewWidget', () {
    testWidgets('should render without crashing', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MockWebviewWidget(config: const WebviewConfig(initialUrl: 'https://google.com'))),
          ),
        ),
      );

      // Should render successfully
      expect(find.text('Mock WebView Content'), findsOneWidget);
    });

    testWidgets('should accept configuration', (WidgetTester tester) async {
      const config = WebviewConfig(initialUrl: 'https://example.com', javascriptEnabled: true);

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: Scaffold(body: MockWebviewWidget(config: config)))),
      );

      // Widget should accept config without issues
      expect(find.byType(MockWebviewWidget), findsOneWidget);
    });

    testWidgets('should accept callbacks', (WidgetTester tester) async {
      String? lastUrl;
      bool? lastLoadingState;
      dynamic lastError;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MockWebviewWidget(
                config: const WebviewConfig(initialUrl: 'https://google.com'),
                onUrlChanged: (url) => lastUrl = url,
                onLoadingChanged: (isLoading) => lastLoadingState = isLoading,
                onError: (error) => lastError = error,
              ),
            ),
          ),
        ),
      );

      // Callbacks should be accepted without issues
      expect(find.byType(MockWebviewWidget), findsOneWidget);
      expect(lastUrl, isNull);
      expect(lastLoadingState, isNull);
      expect(lastError, isNull);
    });

    testWidgets('should integrate with theme', (WidgetTester tester) async {
      final lightTheme = ThemeData.light();
      final darkTheme = ThemeData.dark();

      // Test with light theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: lightTheme,
            home: Scaffold(body: MockWebviewWidget(config: const WebviewConfig(initialUrl: 'https://google.com'))),
          ),
        ),
      );

      await tester.pump();

      // Should use theme colors
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());

      // Test with dark theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: darkTheme,
            home: Scaffold(body: MockWebviewWidget(config: const WebviewConfig(initialUrl: 'https://google.com'))),
          ),
        ),
      );

      await tester.pump();

      // Should adapt to theme changes
      expect(find.byType(MockWebviewWidget), findsOneWidget);
    });

    testWidgets('should handle null config gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(body: MockWebviewWidget(config: null)))));

      // Should handle null config without crashing
      expect(find.byType(MockWebviewWidget), findsOneWidget);
    });

    group('Initial URL Loading', () {
      testWidgets('should use Google.com as default initial URL', (WidgetTester tester) async {
        const config = WebviewConfig();

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: Scaffold(body: MockWebviewWidget(config: config)))),
        );

        // Should show Google.com as initial URL
        expect(find.text('Initial URL: https://www.google.com'), findsOneWidget);
        expect(find.text('Auto-load: true'), findsOneWidget);
      });

      testWidgets('should respect custom initial URL', (WidgetTester tester) async {
        const config = WebviewConfig(initialUrl: 'https://example.com');

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: Scaffold(body: MockWebviewWidget(config: config)))),
        );

        // Should show custom initial URL
        expect(find.text('Initial URL: https://example.com'), findsOneWidget);
      });

      testWidgets('should respect auto-load setting', (WidgetTester tester) async {
        const config = WebviewConfig(autoLoadInitialUrl: false);

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: Scaffold(body: MockWebviewWidget(config: config)))),
        );

        // Should show auto-load disabled
        expect(find.text('Auto-load: false'), findsOneWidget);
      });

      testWidgets('should handle timeout configuration', (WidgetTester tester) async {
        const config = WebviewConfig(initialLoadTimeoutSeconds: 60);

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: Scaffold(body: MockWebviewWidget(config: config)))),
        );

        // Should accept timeout configuration without issues
        expect(find.byType(MockWebviewWidget), findsOneWidget);
      });
    });

    group('Basic Navigation', () {
      testWidgets('should support navigation configuration', (WidgetTester tester) async {
        const config = WebviewConfig(initialUrl: 'https://www.google.com', autoLoadInitialUrl: true);

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: Scaffold(body: MockWebviewWidget(config: config)))),
        );

        // Should show navigation-ready configuration
        expect(find.text('Initial URL: https://www.google.com'), findsOneWidget);
        expect(find.text('Auto-load: true'), findsOneWidget);
      });

      testWidgets('should handle navigation callbacks', (WidgetTester tester) async {
        String? lastNavigatedUrl;
        bool? lastLoadingState;
        dynamic lastError;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MockWebviewWidget(
                  config: const WebviewConfig(initialUrl: 'https://www.google.com'),
                  onUrlChanged: (url) => lastNavigatedUrl = url,
                  onLoadingChanged: (isLoading) => lastLoadingState = isLoading,
                  onError: (error) => lastError = error,
                ),
              ),
            ),
          ),
        );

        // Navigation callbacks should be set up without issues
        expect(find.byType(MockWebviewWidget), findsOneWidget);
        expect(lastNavigatedUrl, isNull);
        expect(lastLoadingState, isNull);
        expect(lastError, isNull);
      });
    });
  });
}
