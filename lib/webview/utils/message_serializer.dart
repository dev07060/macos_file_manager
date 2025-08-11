import 'dart:convert';
import 'dart:developer' as developer;

import 'package:macos_file_manager/model/webview/js_message.dart';

/// Utility class for serializing and deserializing messages between Flutter and JavaScript.
///
/// This class handles the conversion of complex Dart objects to JSON-safe formats
/// and vice versa, ensuring proper data transmission across the bridge.
class MessageSerializer {
  /// Serializes a JSMessage to a JSON string.
  static String serializeMessage(JSMessage message) {
    try {
      final messageMap = message.toJson();

      // Ensure all data is JSON-serializable
      final sanitizedData = _sanitizeData(messageMap['data']);
      messageMap['data'] = sanitizedData;

      return jsonEncode(messageMap);
    } catch (e) {
      developer.log('Failed to serialize message: $e', name: 'MessageSerializer', level: 1000);

      // Return a fallback error message
      return jsonEncode({
        'type': 'error',
        'data': {'message': 'Serialization failed', 'originalType': message.type, 'error': e.toString()},
        'id': message.id,
        'timestamp': message.timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
      });
    }
  }

  /// Deserializes a JSON string to a JSMessage.
  static JSMessage deserializeMessage(String jsonString) {
    try {
      final Map<String, dynamic> messageMap = jsonDecode(jsonString);
      return JSMessage.fromJson(messageMap);
    } catch (e) {
      developer.log('Failed to deserialize message: $e', name: 'MessageSerializer', level: 1000);

      // Return an error message
      return JSMessage(
        type: 'error',
        data: {'message': 'Deserialization failed', 'originalData': jsonString, 'error': e.toString()},
        timestamp: DateTime.now(),
      );
    }
  }

  /// Deserializes a dynamic object (from platform channel) to a JSMessage.
  static JSMessage deserializeFromDynamic(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return JSMessage.fromJson(data);
      } else if (data is String) {
        return deserializeMessage(data);
      } else {
        // Wrap non-message data in a message structure
        return JSMessage(type: 'message', data: {'content': data}, timestamp: DateTime.now());
      }
    } catch (e) {
      developer.log('Failed to deserialize dynamic data: $e', name: 'MessageSerializer', level: 1000);

      return JSMessage(
        type: 'error',
        data: {'message': 'Dynamic deserialization failed', 'originalData': data.toString(), 'error': e.toString()},
        timestamp: DateTime.now(),
      );
    }
  }

  /// Sanitizes data to ensure it's JSON-serializable.
  static dynamic _sanitizeData(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is bool || data is num || data is String) {
      return data;
    }

    if (data is DateTime) {
      return data.toIso8601String();
    }

    if (data is List) {
      return data.map(_sanitizeData).toList();
    }

    if (data is Map) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        final stringKey = key.toString();
        sanitized[stringKey] = _sanitizeData(value);
      });
      return sanitized;
    }

    // For other types, convert to string
    return data.toString();
  }

  /// Validates that a message has the required structure.
  static bool validateMessage(Map<String, dynamic> messageMap) {
    try {
      // Check required fields
      if (!messageMap.containsKey('type') || messageMap['type'] is! String) {
        return false;
      }

      if (!messageMap.containsKey('data') || messageMap['data'] is! Map) {
        return false;
      }

      // Check optional fields if present
      if (messageMap.containsKey('id') && messageMap['id'] is! String?) {
        return false;
      }

      if (messageMap.containsKey('timestamp')) {
        final timestamp = messageMap['timestamp'];
        if (timestamp is! String && timestamp is! DateTime) {
          return false;
        }
      }

      return true;
    } catch (e) {
      developer.log('Message validation failed: $e', name: 'MessageSerializer', level: 1000);
      return false;
    }
  }

  /// Creates a standardized error message.
  static JSMessage createErrorMessage(String error, {String? messageId, Map<String, dynamic>? details}) {
    return JSMessage(
      type: 'error',
      data: {'message': error, 'details': details ?? {}, 'source': 'flutter'},
      id: messageId,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a standardized response message.
  static JSMessage createResponseMessage(dynamic data, String requestId) {
    return JSMessage(type: 'response', data: _sanitizeData(data), id: requestId, timestamp: DateTime.now());
  }

  /// Creates a standardized request message.
  static JSMessage createRequestMessage(String type, Map<String, dynamic> data, String requestId) {
    return JSMessage(type: type, data: _sanitizeData(data), id: requestId, timestamp: DateTime.now());
  }

  /// Extracts debugging information from a message.
  static Map<String, dynamic> extractDebugInfo(JSMessage message) {
    return {
      'type': message.type,
      'hasId': message.id != null,
      'dataKeys': message.data.keys.toList(),
      'dataSize': _calculateDataSize(message.data),
      'timestamp': message.timestamp?.toIso8601String(),
      'isRequest': message.id != null && message.type != 'response' && message.type != 'error',
      'isResponse': message.type == 'response',
      'isError': message.type == 'error',
    };
  }

  /// Calculates the approximate size of message data.
  static int _calculateDataSize(Map<String, dynamic> data) {
    try {
      return jsonEncode(data).length;
    } catch (e) {
      return 0;
    }
  }

  /// Compresses large message data for transmission.
  static Map<String, dynamic> compressMessageData(Map<String, dynamic> data, {int maxSize = 10000}) {
    final dataSize = _calculateDataSize(data);

    if (dataSize <= maxSize) {
      return data;
    }

    // For large data, create a summary
    final compressed = <String, dynamic>{
      '_compressed': true,
      '_originalSize': dataSize,
      '_summary': _createDataSummary(data),
    };

    // Include small values directly
    data.forEach((key, value) {
      if (value is String && value.length < 100) {
        compressed[key] = value;
      } else if (value is num || value is bool) {
        compressed[key] = value;
      } else if (value is List && value.length < 10) {
        compressed[key] = value;
      }
    });

    return compressed;
  }

  /// Creates a summary of large data structures.
  static Map<String, dynamic> _createDataSummary(Map<String, dynamic> data) {
    final summary = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is String) {
        summary[key] = '${value.length} characters';
      } else if (value is List) {
        summary[key] = '${value.length} items';
      } else if (value is Map) {
        summary[key] = '${value.length} properties';
      } else {
        summary[key] = value.runtimeType.toString();
      }
    });

    return summary;
  }

  /// Decompresses message data if it was compressed.
  static Map<String, dynamic> decompressMessageData(Map<String, dynamic> data) {
    if (data['_compressed'] == true) {
      // This is compressed data - in a real implementation, you might
      // request the full data from the source or handle it appropriately
      developer.log('Received compressed message data', name: 'MessageSerializer');
      return data;
    }

    return data;
  }
}

/// Exception thrown when message serialization/deserialization fails.
class MessageSerializationException implements Exception {
  final String message;
  final dynamic originalData;
  final Exception? cause;

  const MessageSerializationException(this.message, {this.originalData, this.cause});

  @override
  String toString() => 'MessageSerializationException: $message';
}
