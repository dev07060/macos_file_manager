// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'js_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JSMessage _$JSMessageFromJson(Map<String, dynamic> json) => _JSMessage(
  type: json['type'] as String,
  data: json['data'] as Map<String, dynamic>,
  id: json['id'] as String?,
  timestamp:
      json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$JSMessageToJson(_JSMessage instance) =>
    <String, dynamic>{
      'type': instance.type,
      'data': instance.data,
      'id': instance.id,
      'timestamp': instance.timestamp?.toIso8601String(),
    };
