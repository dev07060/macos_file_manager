import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/webview/webview_config.dart';
import '../model/webview/webview_state.dart';

part 'webview_provider.g.dart';

/// Provider for webview configuration
@riverpod
WebviewConfig webviewConfig(Ref ref) {
  return const WebviewConfig();
}

/// StateNotifier for managing webview state
class WebviewNotifier extends StateNotifier<WebviewState> {
  WebviewNotifier() : super(const WebviewState());

  /// Navigate to a new URL
  void navigateToUrl(String url) {
    if (url.isEmpty) return;

    state = state.copyWith(
      currentUrl: url,
      isLoading: true,
      error: null,
      navigationHistory: [...state.navigationHistory, url],
    );
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set navigation capabilities
  void setNavigationCapabilities({required bool canGoBack, required bool canGoForward}) {
    state = state.copyWith(canGoBack: canGoBack, canGoForward: canGoForward);
  }

  /// Set error state
  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Go back in navigation history
  void goBack() {
    if (!state.canGoBack) return;

    state = state.copyWith(isLoading: true, error: null);
  }

  /// Go forward in navigation history
  void goForward() {
    if (!state.canGoForward) return;

    state = state.copyWith(isLoading: true, error: null);
  }

  /// Reload current page
  void reload() {
    state = state.copyWith(isLoading: true, error: null);
  }

  /// Clear navigation history
  void clearHistory() {
    state = state.copyWith(navigationHistory: []);
  }

  /// Reset webview state with enhanced cleanup
  void reset() {
    // Clear all state including history to free memory
    state = const WebviewState();
  }

  /// Dispose method for proper resource cleanup
  void dispose() {
    // Clear navigation history to free memory
    state = state.copyWith(navigationHistory: []);
  }
}

/// Provider for webview state management
@riverpod
class Webview extends _$Webview {
  @override
  WebviewState build() {
    return const WebviewState();
  }

  /// Navigate to a new URL
  void navigateToUrl(String url) {
    if (url.isEmpty) return;

    state = state.copyWith(
      currentUrl: url,
      isLoading: true,
      error: null,
      navigationHistory: [...state.navigationHistory, url],
    );
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set navigation capabilities
  void setNavigationCapabilities({required bool canGoBack, required bool canGoForward}) {
    state = state.copyWith(canGoBack: canGoBack, canGoForward: canGoForward);
  }

  /// Set error state
  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Go back in navigation history
  void goBack() {
    if (!state.canGoBack) return;

    state = state.copyWith(isLoading: true, error: null);
  }

  /// Go forward in navigation history
  void goForward() {
    if (!state.canGoForward) return;

    state = state.copyWith(isLoading: true, error: null);
  }

  /// Reload current page
  void reload() {
    state = state.copyWith(isLoading: true, error: null);
  }

  /// Clear navigation history
  void clearHistory() {
    state = state.copyWith(navigationHistory: []);
  }

  /// Reset webview state with enhanced cleanup
  void reset() {
    // Clear all state including history to free memory
    state = const WebviewState();
  }

  /// Dispose method for proper resource cleanup
  void dispose() {
    // Clear navigation history to free memory
    state = state.copyWith(navigationHistory: []);
  }
}
