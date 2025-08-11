// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webview_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WebviewState _$WebviewStateFromJson(Map<String, dynamic> json) =>
    _WebviewState(
      currentUrl: json['currentUrl'] as String? ?? '',
      isLoading: json['isLoading'] as bool? ?? false,
      canGoBack: json['canGoBack'] as bool? ?? false,
      canGoForward: json['canGoForward'] as bool? ?? false,
      error: json['error'] as String?,
      navigationHistory:
          (json['navigationHistory'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WebviewStateToJson(_WebviewState instance) =>
    <String, dynamic>{
      'currentUrl': instance.currentUrl,
      'isLoading': instance.isLoading,
      'canGoBack': instance.canGoBack,
      'canGoForward': instance.canGoForward,
      'error': instance.error,
      'navigationHistory': instance.navigationHistory,
    };
