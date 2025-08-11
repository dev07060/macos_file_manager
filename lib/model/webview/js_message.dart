import 'package:freezed_annotation/freezed_annotation.dart';

part 'js_message.freezed.dart';
part 'js_message.g.dart';

/// Represents a message passed between JavaScript and Flutter.
///
/// This model handles bidirectional communication between the webview's
/// JavaScript context and the Flutter application.
@freezed
abstract class JSMessage with _$JSMessage {
  const factory JSMessage({required String type, required Map<String, dynamic> data, String? id, DateTime? timestamp}) =
      _JSMessage;

  factory JSMessage.fromJson(Map<String, dynamic> json) => _$JSMessageFromJson(json);
}
