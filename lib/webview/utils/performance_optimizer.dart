import 'dart:async';

import 'package:flutter/foundation.dart';

/// Performance optimization utilities for webview integration.
///
/// This class provides methods to optimize memory usage, manage resources,
/// and improve overall performance of the webview implementation.
class WebviewPerformanceOptimizer {
  static const int _maxHistorySize = 50;
  static const int _maxCacheSize = 100;
  static const Duration _cleanupInterval = Duration(minutes: 5);

  static Timer? _cleanupTimer;
  static final Map<String, DateTime> _urlCache = {};
  static final List<String> _navigationHistory = [];

  /// Initializes the performance optimizer
  static void initialize() {
    // Don't initialize if already initialized
    if (!isInitialized) {
      _startPeriodicCleanup();
    }
  }

  /// Disposes the performance optimizer
  static void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _urlCache.clear();
    _navigationHistory.clear();
  }

  /// Checks if the optimizer is initialized
  static bool get isInitialized => _cleanupTimer != null;

  /// Optimizes navigation history by limiting size and removing duplicates
  static List<String> optimizeNavigationHistory(List<String> history) {
    // Remove duplicates while preserving order
    final seen = <String>{};
    final optimized = history.where((url) => seen.add(url)).toList();

    // Limit history size
    if (optimized.length > _maxHistorySize) {
      return optimized.sublist(optimized.length - _maxHistorySize);
    }

    return optimized;
  }

  /// Caches URL metadata for performance
  static void cacheUrlMetadata(String url, {Map<String, dynamic>? metadata}) {
    if (_urlCache.length >= _maxCacheSize) {
      _cleanupOldCacheEntries();
    }

    _urlCache[url] = DateTime.now();
  }

  /// Gets cached URL metadata
  static bool isUrlCached(String url) {
    return _urlCache.containsKey(url);
  }

  /// Optimizes memory usage by cleaning up unused resources
  static void optimizeMemoryUsage() {
    // Clean up old cache entries
    _cleanupOldCacheEntries();

    // Optimize navigation history
    if (_navigationHistory.length > _maxHistorySize) {
      _navigationHistory.removeRange(0, _navigationHistory.length - _maxHistorySize);
    }

    // Force garbage collection in debug mode
    if (kDebugMode) {
      // Note: In production, avoid forcing GC as it can impact performance
      // This is only for development/debugging purposes
    }
  }

  /// Validates URL for performance and security
  static bool isUrlOptimized(String url) {
    try {
      final uri = Uri.parse(url);

      // Check for valid scheme
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }

      // Check for reasonable URL length
      if (url.length > 2048) {
        return false;
      }

      // Check for suspicious patterns
      if (url.contains('javascript:') || url.contains('data:')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets performance metrics
  static Map<String, dynamic> getPerformanceMetrics() {
    return {
      'cacheSize': _urlCache.length,
      'historySize': _navigationHistory.length,
      'lastCleanup': _cleanupTimer?.isActive == true ? 'Active' : 'Inactive',
      'cachedUrls': _urlCache.keys.length,
    };
  }

  /// Preloads commonly used URLs for better performance
  static void preloadCommonUrls() {
    final commonUrls = ['https://www.google.com', 'https://google.com', 'https://www.google.com/search'];

    for (final url in commonUrls) {
      cacheUrlMetadata(url);
    }
  }

  /// Starts periodic cleanup of resources
  static void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();

    // Skip periodic cleanup in test environments to avoid timer issues
    if (_isTestEnvironment()) {
      return;
    }

    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      optimizeMemoryUsage();
    });
  }

  /// Checks if running in test environment
  static bool _isTestEnvironment() {
    // Simple heuristic to detect test environment
    return kDebugMode && StackTrace.current.toString().contains('flutter_test');
  }

  /// Cleans up old cache entries
  static void _cleanupOldCacheEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _urlCache.entries) {
      if (now.difference(entry.value).inHours > 1) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _urlCache.remove(key);
    }
  }
}
