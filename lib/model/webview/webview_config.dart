import 'package:freezed_annotation/freezed_annotation.dart';

part 'webview_config.freezed.dart';
part 'webview_config.g.dart';

/// Configuration settings for the webview component.
///
/// This model defines the initial settings and behavior configuration
/// for the webview implementation.
@freezed
abstract class WebviewConfig with _$WebviewConfig {
  const factory WebviewConfig({
    /// Initial URL to load when webview starts. Defaults to Google.com.
    @Default('https://www.google.com') String initialUrl,

    /// Whether JavaScript execution is enabled in the webview.
    @Default(true) bool javascriptEnabled,

    /// Whether debugging features are enabled for development.
    @Default(true) bool debuggingEnabled,

    /// Custom user agent string for the webview.
    @Default(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Flutter WebView',
    )
    String userAgent,

    /// Timeout for initial URL loading in seconds.
    @Default(30) int initialLoadTimeoutSeconds,

    /// Whether to automatically load the initial URL on webview creation.
    @Default(true) bool autoLoadInitialUrl,
  }) = _WebviewConfig;

  factory WebviewConfig.fromJson(Map<String, dynamic> json) => _$WebviewConfigFromJson(json);
}
