import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart';

class DirectoryNode {
  final String name;
  final String path;
  final List<DirectoryNode> children;
  bool isExpanded;
  bool isSelected;

  DirectoryNode({
    required this.name,
    required this.path,
    List<DirectoryNode>? children,
    this.isExpanded = false,
    this.isSelected = false,
  }) : children = children ?? [];

  static Future<DirectoryNode> fromDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    final name = basename(dirPath);

    List<DirectoryNode> children = [];

    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) {
          final child = await fromDirectory(entity.path);
          children.add(child);
        }
      }

      // 알파벳 순으로 정렬
      children.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      log('Error loading directory: $e');
    }

    return DirectoryNode(name: name, path: dirPath, children: children);
  }
}
