import 'package:freezed_annotation/freezed_annotation.dart';

part 'webview_state.freezed.dart';
part 'webview_state.g.dart';

/// Represents the current state of the webview component.
///
/// This model tracks navigation state, loading status, and error conditions
/// for the webview implementation.
@freezed
abstract class WebviewState with _$WebviewState {
  const factory WebviewState({
    @Default('') String currentUrl,
    @Default(false) bool isLoading,
    @Default(false) bool canGoBack,
    @Default(false) bool canGoForward,
    String? error,
    @Default([]) List<String> navigationHistory,
  }) = _WebviewState;

  factory WebviewState.fromJson(Map<String, dynamic> json) => _$WebviewStateFromJson(json);
}
