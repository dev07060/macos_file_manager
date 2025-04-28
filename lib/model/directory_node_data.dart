import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart';

class DirectoryNodeData {
  final String name;
  final String path;
  final List<DirectoryNodeData> children;
  bool isExpanded;
  bool isSelected;

  DirectoryNodeData({
    required this.name,
    required this.path,
    List<DirectoryNodeData>? children,
    this.isExpanded = false,
    this.isSelected = false,
  }) : children = children ?? [];

  static Future<DirectoryNodeData> fromDirectory(
    String dirPath, {
    int maxNodes = 500,
    Stopwatch? stopwatch,
    Duration timeout = const Duration(seconds: 10),
    int currentCount = 0,
  }) async {
    final dir = Directory(dirPath);
    final name = basename(dirPath);

    List<DirectoryNodeData> children = [];
    stopwatch ??= Stopwatch()..start();

    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (stopwatch.elapsed > timeout) {
          throw Exception('Too many nodes to load directory structure');
        }
        if (currentCount + children.length > maxNodes) {
          throw Exception('Too many nodes to load directory structure (max node : $maxNodes)');
        }
        if (entity is Directory) {
          final child = await fromDirectory(
            entity.path,
            maxNodes: maxNodes,
            stopwatch: stopwatch,
            timeout: timeout,
            currentCount: currentCount + children.length,
          );
          children.add(child);
        }
      }
      children.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      log('Error loading directory: $e');
      if (e is Exception) rethrow;
    }

    return DirectoryNodeData(name: name, path: dirPath, children: children);
  }
}
