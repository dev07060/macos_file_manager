import 'dart:collection';
import 'dart:developer' as developer;

import 'package:macos_file_manager/model/webview/js_message.dart';
import 'package:macos_file_manager/webview/utils/message_serializer.dart';

/// Logger for webview communication debugging and monitoring.
///
/// This class provides comprehensive logging capabilities for tracking
/// message flow, performance metrics, and debugging information.
class CommunicationLogger {
  static const String _loggerName = 'WebviewCommunication';
  static const int _maxLogEntries = 1000;

  final Queue<LogEntry> _logEntries = Queue<LogEntry>();
  final Map<String, RequestMetrics> _requestMetrics = {};
  final Map<String, int> _messageTypeCounts = {};

  bool _isEnabled = true;
  LogLevel _logLevel = LogLevel.info;

  /// Enables or disables logging.
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Sets the minimum log level.
  void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  /// Logs an outgoing message to JavaScript.
  void logOutgoingMessage(JSMessage message) {
    if (!_isEnabled) return;

    _incrementMessageTypeCount('outgoing_${message.type}');

    final entry = LogEntry(
      timestamp: DateTime.now(),
      direction: MessageDirection.outgoing,
      message: message,
      level: LogLevel.debug,
    );

    _addLogEntry(entry);

    if (message.id != null && message.type != 'response' && message.type != 'error') {
      // Track request metrics
      _requestMetrics[message.id!] = RequestMetrics(
        requestId: message.id!,
        requestType: message.type,
        startTime: DateTime.now(),
      );
    }

    _logToConsole(entry);
  }

  /// Logs an incoming message from JavaScript.
  void logIncomingMessage(JSMessage message) {
    if (!_isEnabled) return;

    _incrementMessageTypeCount('incoming_${message.type}');

    final entry = LogEntry(
      timestamp: DateTime.now(),
      direction: MessageDirection.incoming,
      message: message,
      level: LogLevel.debug,
    );

    _addLogEntry(entry);

    // Update request metrics if this is a response
    if (message.id != null && _requestMetrics.containsKey(message.id)) {
      final metrics = _requestMetrics[message.id!]!;
      metrics.endTime = DateTime.now();
      metrics.responseType = message.type;

      if (message.type == 'error') {
        metrics.isError = true;
        metrics.errorMessage = message.data['message']?.toString();
      }

      _logRequestCompletion(metrics);
    }

    _logToConsole(entry);
  }

  /// Logs a JavaScript execution.
  void logJavaScriptExecution(String script, {String? result, Exception? error}) {
    if (!_isEnabled) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      direction: MessageDirection.execution,
      level: error != null ? LogLevel.error : LogLevel.debug,
      executionInfo: ExecutionInfo(script: script, result: result, error: error),
    );

    _addLogEntry(entry);
    _logToConsole(entry);
  }

  /// Logs a communication error.
  void logError(String error, {Exception? exception, Map<String, dynamic>? context}) {
    if (!_isEnabled) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      direction: MessageDirection.error,
      level: LogLevel.error,
      errorInfo: ErrorInfo(message: error, exception: exception, context: context ?? {}),
    );

    _addLogEntry(entry);
    _logToConsole(entry);
  }

  /// Logs performance metrics.
  void logPerformanceMetric(String metric, Duration duration, {Map<String, dynamic>? context}) {
    if (!_isEnabled || _logLevel.index > LogLevel.info.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      direction: MessageDirection.performance,
      level: LogLevel.info,
      performanceInfo: PerformanceInfo(metric: metric, duration: duration, context: context ?? {}),
    );

    _addLogEntry(entry);
    _logToConsole(entry);
  }

  /// Gets communication statistics.
  CommunicationStats getStats() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(Duration(minutes: 1));
    final oneHourAgo = now.subtract(Duration(hours: 1));

    final recentEntries = _logEntries.where((e) => e.timestamp.isAfter(oneMinuteAgo)).toList();
    final hourlyEntries = _logEntries.where((e) => e.timestamp.isAfter(oneHourAgo)).toList();

    final completedRequests = _requestMetrics.values.where((r) => r.endTime != null).toList();
    final averageResponseTime =
        completedRequests.isEmpty
            ? Duration.zero
            : Duration(
              milliseconds:
                  completedRequests
                      .map((r) => r.endTime!.difference(r.startTime).inMilliseconds)
                      .reduce((a, b) => a + b) ~/
                  completedRequests.length,
            );

    return CommunicationStats(
      totalMessages: _logEntries.length,
      recentMessages: recentEntries.length,
      hourlyMessages: hourlyEntries.length,
      messageTypeCounts: Map.from(_messageTypeCounts),
      pendingRequests: _requestMetrics.values.where((r) => r.endTime == null).length,
      completedRequests: completedRequests.length,
      averageResponseTime: averageResponseTime,
      errorCount: _logEntries.where((e) => e.level == LogLevel.error).length,
    );
  }

  /// Gets recent log entries.
  List<LogEntry> getRecentEntries({int limit = 100}) {
    final entries = _logEntries.toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(limit).toList();
  }

  /// Gets log entries for a specific request ID.
  List<LogEntry> getEntriesForRequest(String requestId) {
    return _logEntries.where((e) => e.message?.id == requestId).toList();
  }

  /// Clears all log entries.
  void clearLogs() {
    _logEntries.clear();
    _requestMetrics.clear();
    _messageTypeCounts.clear();
  }

  /// Exports logs as JSON for debugging.
  Map<String, dynamic> exportLogs() {
    return {
      'entries': _logEntries.map((e) => e.toJson()).toList(),
      'stats': getStats().toJson(),
      'exportTime': DateTime.now().toIso8601String(),
    };
  }

  void _addLogEntry(LogEntry entry) {
    _logEntries.add(entry);

    // Keep only the most recent entries
    while (_logEntries.length > _maxLogEntries) {
      _logEntries.removeFirst();
    }
  }

  void _incrementMessageTypeCount(String type) {
    _messageTypeCounts[type] = (_messageTypeCounts[type] ?? 0) + 1;
  }

  void _logRequestCompletion(RequestMetrics metrics) {
    final duration = metrics.endTime!.difference(metrics.startTime);

    logPerformanceMetric(
      'request_${metrics.requestType}',
      duration,
      context: {'requestId': metrics.requestId, 'isError': metrics.isError, 'responseType': metrics.responseType},
    );
  }

  void _logToConsole(LogEntry entry) {
    if (_logLevel.index > entry.level.index) return;

    final levelName = entry.level.name.toUpperCase();
    final direction = entry.direction.name.toUpperCase();
    final timestamp = entry.timestamp.toIso8601String();

    String message;

    switch (entry.direction) {
      case MessageDirection.outgoing:
        final msg = entry.message!;
        final debugInfo = MessageSerializer.extractDebugInfo(msg);
        message = 'OUTGOING ${msg.type} (${debugInfo['dataSize']} bytes)';
        if (msg.id != null) message += ' [${msg.id}]';
        break;

      case MessageDirection.incoming:
        final msg = entry.message!;
        final debugInfo = MessageSerializer.extractDebugInfo(msg);
        message = 'INCOMING ${msg.type} (${debugInfo['dataSize']} bytes)';
        if (msg.id != null) message += ' [${msg.id}]';
        break;

      case MessageDirection.execution:
        final exec = entry.executionInfo!;
        message = 'JS_EXEC ${exec.script.length > 50 ? '${exec.script.substring(0, 50)}...' : exec.script}';
        if (exec.error != null) message += ' ERROR: ${exec.error}';
        break;

      case MessageDirection.error:
        final error = entry.errorInfo!;
        message = 'ERROR ${error.message}';
        if (error.exception != null) message += ' (${error.exception})';
        break;

      case MessageDirection.performance:
        final perf = entry.performanceInfo!;
        message = 'PERF ${perf.metric}: ${perf.duration.inMilliseconds}ms';
        break;
    }

    developer.log(message, time: entry.timestamp, name: '$_loggerName.$direction', level: _getLogLevel(entry.level));
  }

  int _getLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}

/// Log entry for communication events.
class LogEntry {
  final DateTime timestamp;
  final MessageDirection direction;
  final LogLevel level;
  final JSMessage? message;
  final ExecutionInfo? executionInfo;
  final ErrorInfo? errorInfo;
  final PerformanceInfo? performanceInfo;

  LogEntry({
    required this.timestamp,
    required this.direction,
    required this.level,
    this.message,
    this.executionInfo,
    this.errorInfo,
    this.performanceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'direction': direction.name,
      'level': level.name,
      'message': message?.toJson(),
      'executionInfo': executionInfo?.toJson(),
      'errorInfo': errorInfo?.toJson(),
      'performanceInfo': performanceInfo?.toJson(),
    };
  }
}

/// Information about JavaScript execution.
class ExecutionInfo {
  final String script;
  final String? result;
  final Exception? error;

  ExecutionInfo({required this.script, this.result, this.error});

  Map<String, dynamic> toJson() {
    return {'script': script, 'result': result, 'error': error?.toString()};
  }
}

/// Information about communication errors.
class ErrorInfo {
  final String message;
  final Exception? exception;
  final Map<String, dynamic> context;

  ErrorInfo({required this.message, this.exception, required this.context});

  Map<String, dynamic> toJson() {
    return {'message': message, 'exception': exception?.toString(), 'context': context};
  }
}

/// Information about performance metrics.
class PerformanceInfo {
  final String metric;
  final Duration duration;
  final Map<String, dynamic> context;

  PerformanceInfo({required this.metric, required this.duration, required this.context});

  Map<String, dynamic> toJson() {
    return {'metric': metric, 'duration': duration.inMilliseconds, 'context': context};
  }
}

/// Metrics for tracking request-response patterns.
class RequestMetrics {
  final String requestId;
  final String requestType;
  final DateTime startTime;
  DateTime? endTime;
  String? responseType;
  bool isError = false;
  String? errorMessage;

  RequestMetrics({required this.requestId, required this.requestType, required this.startTime});
}

/// Communication statistics.
class CommunicationStats {
  final int totalMessages;
  final int recentMessages;
  final int hourlyMessages;
  final Map<String, int> messageTypeCounts;
  final int pendingRequests;
  final int completedRequests;
  final Duration averageResponseTime;
  final int errorCount;

  CommunicationStats({
    required this.totalMessages,
    required this.recentMessages,
    required this.hourlyMessages,
    required this.messageTypeCounts,
    required this.pendingRequests,
    required this.completedRequests,
    required this.averageResponseTime,
    required this.errorCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalMessages': totalMessages,
      'recentMessages': recentMessages,
      'hourlyMessages': hourlyMessages,
      'messageTypeCounts': messageTypeCounts,
      'pendingRequests': pendingRequests,
      'completedRequests': completedRequests,
      'averageResponseTime': averageResponseTime.inMilliseconds,
      'errorCount': errorCount,
    };
  }
}

/// Message direction for logging.
enum MessageDirection { outgoing, incoming, execution, error, performance }

/// Log levels.
enum LogLevel { debug, info, warning, error }

/// Global communication logger instance.
final communicationLogger = CommunicationLogger();
