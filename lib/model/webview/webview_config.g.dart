// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webview_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WebviewConfig _$WebviewConfigFromJson(
  Map<String, dynamic> json,
) => _WebviewConfig(
  initialUrl: json['initialUrl'] as String? ?? 'https://www.google.com',
  javascriptEnabled: json['javascriptEnabled'] as bool? ?? true,
  debuggingEnabled: json['debuggingEnabled'] as bool? ?? true,
  userAgent:
      json['userAgent'] as String? ??
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Flutter WebView',
  initialLoadTimeoutSeconds:
      (json['initialLoadTimeoutSeconds'] as num?)?.toInt() ?? 30,
  autoLoadInitialUrl: json['autoLoadInitialUrl'] as bool? ?? true,
);

Map<String, dynamic> _$WebviewConfigToJson(_WebviewConfig instance) =>
    <String, dynamic>{
      'initialUrl': instance.initialUrl,
      'javascriptEnabled': instance.javascriptEnabled,
      'debuggingEnabled': instance.debuggingEnabled,
      'userAgent': instance.userAgent,
      'initialLoadTimeoutSeconds': instance.initialLoadTimeoutSeconds,
      'autoLoadInitialUrl': instance.autoLoadInitialUrl,
    };
