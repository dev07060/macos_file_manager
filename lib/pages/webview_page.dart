import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../provider/webview_provider.dart';
import '../webview/platform/standard_webview_platform.dart';
import '../webview/webview.dart';

/// Webview page that displays web content within the application.
///
/// This page provides a full-screen webview experience with navigation controls
/// and integrates with the application's theme and state management.
///
/// ## Features:
/// - Full web browsing capabilities
/// - Navigation controls (back, forward, reload)
/// - URL input with automatic protocol detection
/// - Theme consistency with the main application
/// - Proper resource cleanup on navigation
/// - Error handling with user-friendly messages
///
/// ## Usage:
/// ```dart
/// // Navigate to webview page
/// Navigator.of(context).pushNamed(AppRoutes.webview);
/// ```
///
/// ## Integration:
/// - Accessible from the main toolbar web button
/// - Maintains application state during usage
/// - Provides smooth transitions back to file manager
/// - Handles both webview navigation and app navigation
class WebviewPage extends HookConsumerWidget {
  const WebviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch webview configuration and state
    final webviewConfig = ref.watch(webviewConfigProvider);
    final webviewState = ref.watch(webviewProvider);

    // State for webview controller
    final webviewController = useState<WebviewController?>(null);
    final pageTitle = useState<String>('Web Browser');
    final isWebviewSupported = useState<bool>(true);

    // Initialize webview controller
    useEffect(() {
      _initializeWebview(webviewController, webviewConfig, isWebviewSupported);
      return () {
        // Enhanced cleanup - ensure proper resource disposal
        _cleanupWebviewResources(webviewController.value, ref);
      };
    }, []);

    // Update page title based on URL
    useEffect(() {
      if (webviewState.currentUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(webviewState.currentUrl);
          pageTitle.value = uri.host.isNotEmpty ? uri.host : 'Web Browser';
        } catch (e) {
          pageTitle.value = 'Web Browser';
        }
      }
      return null;
    }, [webviewState.currentUrl]);

    // Check if webview is supported
    if (!isWebviewSupported.value) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Web Browser'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.web_asset_off, size: 64),
              SizedBox(height: 16),
              Text('Web Browser Not Supported', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('WebView is not available on this platform.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // Enhanced back navigation handling
        if (!didPop && webviewController.value != null && webviewState.canGoBack) {
          // Try webview back navigation first
          try {
            await webviewController.value!.goBack();
          } catch (e) {
            // If webview back fails, allow normal navigation
            if (context.mounted) {
              await _cleanupWebviewResources(webviewController.value, ref);
              Navigator.of(context).pop();
            }
          }
        } else if (didPop) {
          // Ensure cleanup when actually popping
          await _cleanupWebviewResources(webviewController.value, ref);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle.value),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () async {
                // Enhanced cleanup and navigation back to file manager
                await _cleanupWebviewResources(webviewController.value, ref);

                if (context.mounted) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    // Fallback to home route if no previous route
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                }
              },
              tooltip: 'Back to File Manager',
            ),
          ],
        ),
        body: Column(
          children: [
            // Navigation controls
            if (webviewController.value != null)
              WebviewControls(
                controller: webviewController.value!,
                onUrlSubmitted: (url) {
                  // URL submission is handled by the controls widget
                },
              ),

            // Webview content
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.all(8.0),
                child: WebviewWidget(
                  config: webviewConfig,
                  onUrlChanged: (url) {
                    // URL changes are handled by the widget internally
                  },
                  onLoadingChanged: (isLoading) {
                    // Loading state changes are handled by the widget internally
                  },
                  onError: (error) {
                    // Show error snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Webview Error: ${error.message}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'Dismiss',
                          textColor: Theme.of(context).colorScheme.onError,
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Initializes the webview controller
  void _initializeWebview(
    ValueNotifier<WebviewController?> controllerNotifier,
    WebviewConfig config,
    ValueNotifier<bool> supportedNotifier,
  ) async {
    try {
      // Create platform interface using standard webview
      final platformInterface = StandardWebviewPlatform();

      // Create controller with enhanced configuration for Google.com loading
      final enhancedConfig = config.copyWith(
        initialUrl: config.initialUrl.isEmpty ? 'https://www.google.com' : config.initialUrl,
        autoLoadInitialUrl: true,
        initialLoadTimeoutSeconds: 30,
      );

      final controller = WebviewController(platformInterface, config: enhancedConfig);

      // Initialize the controller (this will automatically load the initial URL)
      await controller.initialize();

      // Set controller
      controllerNotifier.value = controller;
      supportedNotifier.value = true;
    } catch (e) {
      // Webview not supported or initialization failed
      supportedNotifier.value = false;

      // Use proper logging instead of print
      if (kDebugMode) {
        debugPrint('Webview initialization failed: $e');
      }
    }
  }

  /// Enhanced cleanup of webview resources
  Future<void> _cleanupWebviewResources(WebviewController? controller, WidgetRef? ref) async {
    try {
      // Reset webview state in provider only if ref is still valid
      if (ref != null) {
        try {
          ref.read(webviewProvider.notifier).reset();
        } catch (e) {
          // Ignore ref errors during disposal
          if (kDebugMode) {
            debugPrint('Ref no longer available during cleanup: $e');
          }
        }
      }

      // Dispose controller with proper error handling
      if (controller != null) {
        await controller.dispose();
      }
    } catch (e) {
      // Log cleanup errors but don't throw
      if (kDebugMode) {
        debugPrint('Error during webview cleanup: $e');
      }
    }
  }
}
