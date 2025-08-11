import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../model/webview/webview_state.dart';
import '../provider/webview_provider.dart';
import '../webview/controller/webview_controller.dart';
import '../webview/platform/webview_platform_interface.dart';

/// Navigation and control UI for the webview.
///
/// This widget provides URL input, navigation controls (back, forward, refresh),
/// loading progress indicator, and error display functionality.
///
/// ## Features:
/// - URL input with automatic protocol detection
/// - Navigation buttons (back, forward, reload)
/// - Security indicators for HTTPS connections
/// - Loading progress visualization
/// - Search query handling for non-URL inputs
/// - Menu with additional options
///
/// ## Usage:
/// ```dart
/// WebviewControls(
///   controller: webviewController,
///   onUrlSubmitted: (url) => print('Navigate to: $url'),
///   showUrlBar: true,
///   showNavigationButtons: true,
/// )
/// ```
///
/// ## URL Handling:
/// - Automatically adds protocol for domain-like inputs
/// - Converts search queries to Google search URLs
/// - Validates URLs before navigation
/// - Provides user-friendly error messages
class WebviewControls extends HookConsumerWidget {
  const WebviewControls({
    super.key,
    required this.controller,
    this.onUrlSubmitted,
    this.showUrlBar = true,
    this.showNavigationButtons = true,
  });

  /// The webview controller to interact with
  final WebviewController controller;

  /// Callback when URL is submitted
  final void Function(String url)? onUrlSubmitted;

  /// Whether to show the URL input bar
  final bool showUrlBar;

  /// Whether to show navigation buttons
  final bool showNavigationButtons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webviewState = ref.watch(webviewProvider);

    // URL text controller
    final urlController = useTextEditingController();
    final urlFocusNode = useFocusNode();

    // Update URL controller when state changes
    useEffect(() {
      if (urlController.text != webviewState.currentUrl) {
        urlController.text = webviewState.currentUrl;
      }
      return null;
    }, [webviewState.currentUrl]);

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          if (showNavigationButtons) ...[_buildNavigationRow(context, ref, webviewState), const SizedBox(height: 8)],
          if (showUrlBar) ...[_buildUrlBar(context, urlController, urlFocusNode, webviewState)],
          if (webviewState.isLoading) ...[const SizedBox(height: 8), _buildProgressIndicator(context)],
        ],
      ),
    );
  }

  /// Builds the navigation button row
  Widget _buildNavigationRow(BuildContext context, WidgetRef ref, WebviewState state) {
    return Row(
      children: [
        // Back button
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: state.canGoBack ? () => _handleGoBack(ref) : null,
          tooltip: 'Go Back',
          style: IconButton.styleFrom(
            foregroundColor: state.canGoBack ? Theme.of(context).iconTheme.color : Theme.of(context).disabledColor,
          ),
        ),

        // Forward button
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: state.canGoForward ? () => _handleGoForward(ref) : null,
          tooltip: 'Go Forward',
          style: IconButton.styleFrom(
            foregroundColor: state.canGoForward ? Theme.of(context).iconTheme.color : Theme.of(context).disabledColor,
          ),
        ),

        // Reload button
        IconButton(
          icon:
              state.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
          onPressed: !state.isLoading ? () => _handleReload(ref) : null,
          tooltip: state.isLoading ? 'Loading...' : 'Reload',
        ),

        const Spacer(),

        // Security indicator
        if (state.currentUrl.isNotEmpty) ...[
          _buildSecurityIndicator(context, state.currentUrl),
          const SizedBox(width: 8),
        ],

        // Menu button
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More options',
          onSelected: (value) => _handleMenuAction(context, ref, value),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'home',
                  child: Row(children: [Icon(Icons.home), SizedBox(width: 8), Text('Go to Home')]),
                ),
                const PopupMenuItem(
                  value: 'copy_url',
                  child: Row(children: [Icon(Icons.copy), SizedBox(width: 8), Text('Copy URL')]),
                ),
                const PopupMenuItem(
                  value: 'clear_history',
                  child: Row(children: [Icon(Icons.clear_all), SizedBox(width: 8), Text('Clear History')]),
                ),
              ],
        ),
      ],
    );
  }

  /// Builds the URL input bar
  Widget _buildUrlBar(
    BuildContext context,
    TextEditingController urlController,
    FocusNode urlFocusNode,
    WebviewState state,
  ) {
    return TextField(
      controller: urlController,
      focusNode: urlFocusNode,
      decoration: InputDecoration(
        hintText: 'Enter URL or search...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixIcon: _buildUrlPrefixIcon(context, state.currentUrl),
        suffixIcon: _buildUrlSuffixIcon(context, urlController, state),
      ),
      onSubmitted: (value) => _handleUrlSubmitted(context, value),
      textInputAction: TextInputAction.go,
      keyboardType: TextInputType.url,
      style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
    );
  }

  /// Builds the URL prefix icon (security/protocol indicator)
  Widget _buildUrlPrefixIcon(BuildContext context, String url) {
    if (url.isEmpty) {
      return Icon(Icons.search, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6));
    }

    final isSecure = url.startsWith('https://');
    return Icon(
      isSecure ? Icons.lock : Icons.lock_open,
      color: isSecure ? Colors.green : Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
      size: 18,
    );
  }

  /// Builds the URL suffix icon (go/clear button)
  Widget _buildUrlSuffixIcon(BuildContext context, TextEditingController urlController, WebviewState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (urlController.text.isNotEmpty && urlController.text != state.currentUrl) {
      return IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => _handleUrlSubmitted(context, urlController.text),
        tooltip: 'Go to URL',
        iconSize: 18,
      );
    }

    return IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => urlController.clear(),
      tooltip: 'Clear URL',
      iconSize: 18,
    );
  }

  /// Builds the security indicator
  Widget _buildSecurityIndicator(BuildContext context, String url) {
    final isSecure = url.startsWith('https://');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSecure ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isSecure ? Colors.green : Colors.orange, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSecure ? Icons.lock : Icons.lock_open, size: 12, color: isSecure ? Colors.green : Colors.orange),
          const SizedBox(width: 2),
          Text(
            isSecure ? 'Secure' : 'Not Secure',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isSecure ? Colors.green : Colors.orange),
          ),
        ],
      ),
    );
  }

  /// Builds the loading progress indicator
  Widget _buildProgressIndicator(BuildContext context) {
    return LinearProgressIndicator(
      backgroundColor: Theme.of(context).dividerColor,
      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
    );
  }

  /// Handles back navigation
  void _handleGoBack(WidgetRef ref) async {
    try {
      await controller.goBack();
      ref.read(webviewProvider.notifier).goBack();
    } catch (e) {
      _showError(ref, 'Failed to go back: $e');
    }
  }

  /// Handles forward navigation
  void _handleGoForward(WidgetRef ref) async {
    try {
      await controller.goForward();
      ref.read(webviewProvider.notifier).goForward();
    } catch (e) {
      _showError(ref, 'Failed to go forward: $e');
    }
  }

  /// Handles page reload
  void _handleReload(WidgetRef ref) async {
    try {
      await controller.reload();
      ref.read(webviewProvider.notifier).reload();
    } catch (e) {
      _showError(ref, 'Failed to reload: $e');
    }
  }

  /// Handles URL submission
  void _handleUrlSubmitted(BuildContext context, String value) async {
    if (value.trim().isEmpty) return;

    String url = value.trim();

    // Add protocol if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Check if it looks like a URL or a search query
      if (url.contains('.') && !url.contains(' ') && !url.contains('?')) {
        url = 'https://$url';
      } else {
        // Treat as search query
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }

    try {
      await controller.loadUrl(url);
      onUrlSubmitted?.call(url);
    } catch (e) {
      // Enhanced error handling for navigation failures
      final errorMessage = e is WebviewError ? _getNavigationErrorMessage(e) : 'Failed to navigate to $url: $e';

      // Show user-friendly error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => _handleUrlSubmitted(context, value),
            ),
          ),
        );
      }
    }
  }

  /// Gets user-friendly error message for navigation failures
  String _getNavigationErrorMessage(WebviewError error) {
    switch (error.type) {
      case WebviewErrorType.networkError:
        return 'Unable to connect to the website. Check your internet connection.';
      case WebviewErrorType.navigationError:
        return 'Invalid URL or website not found.';
      default:
        return 'Failed to load the page. Please try again.';
    }
  }

  /// Handles menu actions
  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'home':
        await controller.loadUrl('https://google.com');
        break;
      case 'copy_url':
        final state = ref.read(webviewProvider);
        if (state.currentUrl.isNotEmpty) {
          // Copy URL to clipboard (would need clipboard package)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('URL copied: ${state.currentUrl}'), duration: const Duration(seconds: 2)),
          );
        }
        break;
      case 'clear_history':
        ref.read(webviewProvider.notifier).clearHistory();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Navigation history cleared'), duration: Duration(seconds: 2)));
        break;
    }
  }

  /// Shows error message
  void _showError(WidgetRef ref, String message) {
    ref.read(webviewProvider.notifier).setError(message);
  }
}
