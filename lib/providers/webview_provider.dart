import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing webview state at the application level.
///
/// This provider manages the global webview state and provides access
/// to webview functionality throughout the application.
class WebviewState {
  const WebviewState({this.isWebviewAvailable = false, this.currentUrl = '', this.isLoading = false, this.error});

  final bool isWebviewAvailable;
  final String currentUrl;
  final bool isLoading;
  final String? error;

  WebviewState copyWith({bool? isWebviewAvailable, String? currentUrl, bool? isLoading, String? error}) {
    return WebviewState(
      isWebviewAvailable: isWebviewAvailable ?? this.isWebviewAvailable,
      currentUrl: currentUrl ?? this.currentUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// StateNotifier for managing webview state.
class WebviewStateNotifier extends StateNotifier<WebviewState> {
  WebviewStateNotifier() : super(const WebviewState());

  /// Updates the webview availability status.
  void setWebviewAvailable(bool available) {
    state = state.copyWith(isWebviewAvailable: available);
  }

  /// Updates the current URL.
  void updateUrl(String url) {
    state = state.copyWith(currentUrl: url);
  }

  /// Updates the loading state.
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Sets an error message.
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Clears the error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for webview state management.
final webviewStateProvider = StateNotifierProvider<WebviewStateNotifier, WebviewState>((ref) => WebviewStateNotifier());

/// Provider for webview configuration.
final webviewConfigProvider = Provider<Map<String, dynamic>>((ref) {
  return const {
    'initialUrl': 'https://google.com',
    'javascriptEnabled': true,
    'debuggingEnabled': true,
    'userAgent': 'Flutter WebView',
  };
});

/// Provider for checking if webview is supported on the current platform.
final webviewSupportProvider = Provider<bool>((ref) {
  // WebView is supported on macOS using WKWebView
  return true; // Assuming we're running on macOS for this implementation
});
