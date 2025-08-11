import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../model/webview/webview_config.dart';
import '../model/webview/webview_state.dart';
import '../provider/webview_provider.dart';
import '../webview/controller/webview_controller.dart';
import '../webview/platform/standard_webview_platform.dart';
import '../webview/platform/webview_platform_interface.dart';

/// Core webview widget that integrates with platform implementation.
///
/// This widget provides a complete webview experience with loading indicators,
/// error state handling, and proper lifecycle management. It integrates with
/// the existing app theme and state management system.
///
/// ## Features:
/// - Platform-specific webview implementation
/// - Loading states with progress indicators
/// - Error handling with retry functionality
/// - Theme-consistent UI design
/// - Automatic resource cleanup
/// - State synchronization with providers
///
/// ## Usage:
/// ```dart
/// WebviewWidget(
///   config: WebviewConfig(
///     initialUrl: 'https://example.com',
///     autoLoadInitialUrl: true,
///   ),
///   onUrlChanged: (url) => print('URL changed: $url'),
///   onError: (error) => print('Error: ${error.message}'),
/// )
/// ```
///
/// ## State Management:
/// - Integrates with webviewProvider for state management
/// - Provides reactive updates through streams
/// - Handles initialization and disposal automatically
class WebviewWidget extends HookConsumerWidget {
  const WebviewWidget({super.key, this.config, this.onUrlChanged, this.onLoadingChanged, this.onError});

  /// Optional webview configuration. If not provided, uses default config.
  final WebviewConfig? config;

  /// Callback when URL changes
  final void Function(String url)? onUrlChanged;

  /// Callback when loading state changes
  final void Function(bool isLoading)? onLoadingChanged;

  /// Callback when an error occurs
  final void Function(WebviewError error)? onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get configuration from provider or use provided config
    final WebviewConfig webviewConfig = config ?? ref.watch(webviewConfigProvider);
    final webviewState = ref.watch(webviewProvider);

    // State for webview controller and initialization
    final webviewController = useState<WebviewController?>(null);
    final isInitialized = useState<bool>(false);
    final initializationError = useState<String?>(null);

    // Stream subscriptions
    final stateSubscription = useRef<StreamSubscription<WebviewState>?>(null);
    final errorSubscription = useRef<StreamSubscription<WebviewError>?>(null);

    // Initialize webview controller
    useEffect(() {
      _initializeWebview(
        webviewConfig,
        webviewController,
        isInitialized,
        initializationError,
        ref,
        stateSubscription,
        errorSubscription,
      );

      return () {
        // Cleanup subscriptions and controller
        stateSubscription.value?.cancel();
        errorSubscription.value?.cancel();
        webviewController.value?.dispose();
      };
    }, [webviewConfig]);

    // Handle callbacks
    useEffect(() {
      if (webviewController.value != null) {
        final controller = webviewController.value!;

        // Listen to state changes and trigger callbacks
        stateSubscription.value = controller.stateStream.listen((state) {
          debugPrint(
            'WebView state changed: loading=${state.isLoading}, url=${state.currentUrl}, error=${state.error}',
          );

          // Update provider state using Future to avoid build-time modification
          Future.microtask(() {
            try {
              ref.read(webviewProvider.notifier).setLoading(state.isLoading);
              ref
                  .read(webviewProvider.notifier)
                  .setNavigationCapabilities(canGoBack: state.canGoBack, canGoForward: state.canGoForward);

              if (state.currentUrl != webviewState.currentUrl) {
                ref.read(webviewProvider.notifier).navigateToUrl(state.currentUrl);
              }

              if (state.error != null) {
                ref.read(webviewProvider.notifier).setError(state.error);
              } else {
                // Clear error when state is good
                ref.read(webviewProvider.notifier).setError(null);
              }
            } catch (refError) {
              // Ignore ref errors during disposal
              debugPrint('Ref error in state listener: $refError');
            }
          });

          // These callbacks can be called immediately as they don't modify providers
          if (state.currentUrl != webviewState.currentUrl) {
            onUrlChanged?.call(state.currentUrl);
          }

          if (state.isLoading != webviewState.isLoading) {
            onLoadingChanged?.call(state.isLoading);
          }
        });

        // Listen to errors
        errorSubscription.value = controller.errorStream.listen((error) {
          Future.microtask(() {
            ref.read(webviewProvider.notifier).setError(error.message);
          });
          onError?.call(error);
        });
      }
      return null;
    }, [webviewController.value]);

    // Build the widget based on current state
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildWebviewContent(
          context,
          webviewController.value,
          isInitialized.value,
          initializationError.value,
          webviewState,
        ),
      ),
    );
  }

  /// Initializes the webview controller and sets up listeners
  void _initializeWebview(
    WebviewConfig config,
    ValueNotifier<WebviewController?> controllerNotifier,
    ValueNotifier<bool> isInitializedNotifier,
    ValueNotifier<String?> errorNotifier,
    WidgetRef ref,
    ObjectRef<StreamSubscription<WebviewState>?> stateSubscription,
    ObjectRef<StreamSubscription<WebviewError>?> errorSubscription,
  ) async {
    try {
      // Update provider to show we're starting initialization
      Future.microtask(() {
        ref.read(webviewProvider.notifier).setLoading(true);
      });

      // Create platform interface - use StandardWebviewPlatform for macOS compatibility
      final platformInterface = StandardWebviewPlatform();

      // Create controller
      final controller = WebviewController(platformInterface, config: config);

      // Initialize controller (this will automatically load the initial URL if configured)
      await controller.initialize();

      // Update state
      controllerNotifier.value = controller;
      isInitializedNotifier.value = true;
      errorNotifier.value = null;

      // Update provider with initial URL if auto-loading is enabled
      Future.microtask(() {
        if (config.autoLoadInitialUrl && config.initialUrl.isNotEmpty) {
          ref.read(webviewProvider.notifier).navigateToUrl(config.initialUrl);
        } else {
          // If auto-loading is disabled, just set loading to false
          ref.read(webviewProvider.notifier).setLoading(false);
        }
      });
    } catch (e) {
      final errorMessage = e is WebviewError ? e.message : 'Failed to initialize webview: $e';
      errorNotifier.value = errorMessage;
      isInitializedNotifier.value = false;

      // Update provider with error using Future to avoid build-time modification
      Future.microtask(() {
        ref.read(webviewProvider.notifier).setError(errorMessage);
        ref.read(webviewProvider.notifier).setLoading(false);
      });
    }
  }

  /// Builds the webview content based on current state
  Widget _buildWebviewContent(
    BuildContext context,
    WebviewController? controller,
    bool isInitialized,
    String? initializationError,
    WebviewState state,
  ) {
    // Show initialization error
    if (initializationError != null) {
      return _buildErrorState(
        context,
        'Initialization Error',
        initializationError,
        onRetry: controller != null ? () => controller.initialize() : null,
      );
    }

    // Show loading during initialization
    if (!isInitialized || controller == null) {
      return _buildLoadingState(context, 'Initializing webview...');
    }

    // Show error state
    if (state.error != null) {
      return _buildErrorState(context, 'Loading Error', state.error!, onRetry: () => controller.reload());
    }

    // Show loading state
    if (state.isLoading) {
      return Stack(
        children: [
          // Webview content (may be partially loaded)
          _buildWebviewContainer(context, controller),
          // Loading overlay
          _buildLoadingOverlay(context, state.currentUrl),
        ],
      );
    }

    // Show webview content
    return _buildWebviewContainer(context, controller);
  }

  /// Builds the main webview container
  Widget _buildWebviewContainer(BuildContext context, WebviewController? controller) {
    // Try to get the standard webview controller
    if (controller != null) {
      // Check if we have a standard webview platform
      final platform = controller.platformInterface;
      if (platform is StandardWebviewPlatform && platform.controller != null) {
        // Use the standard webview widget
        return WebViewWidget(controller: platform.controller!);
      }
    }

    // Fallback to placeholder
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).cardColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web, size: 48, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'WebView Content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Web content will appear here',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the loading state widget
  Widget _buildLoadingState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).cardColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
          ],
        ),
      ),
    );
  }

  /// Builds the loading overlay for when webview is loading
  Widget _buildLoadingOverlay(BuildContext context, String url) {
    return Container(
      color: Theme.of(context).cardColor.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                url,
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the error state widget
  Widget _buildErrorState(BuildContext context, String title, String message, {VoidCallback? onRetry}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
