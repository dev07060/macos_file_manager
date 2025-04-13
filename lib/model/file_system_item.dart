import 'dart:io';
import 'package:flutter/foundation.dart' show immutable;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as paths;

enum FileSystemItemType { file, directory }

@immutable
class FileSystemItem {
  const FileSystemItem({
    required this.path,
    required this.name,
    required this.type,
    required this.size,
    required this.modifiedAt,
    required this.createdAt,
    this.isSelected = false,
  });

  final String path;
  final String name;
  final FileSystemItemType type;
  final int size; // Size in bytes
  final DateTime modifiedAt;
  final DateTime createdAt;
  final bool isSelected;

  String get formattedSize {
    if (type == FileSystemItemType.directory) return '--';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = this.size.toDouble();
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  String get fileExtension {
    if (type == FileSystemItemType.directory) return '--';
    return paths.extension(name).isNotEmpty ? paths.extension(name).substring(1) : '';
  }

  // Create a copy of this file with different selection state
  FileSystemItem copyWith({bool? isSelected}) {
    return FileSystemItem(
      path: path,
      name: name,
      type: type,
      size: size,
      modifiedAt: modifiedAt,
      createdAt: createdAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  String toString() {
    return 'FileSystemItem(name: $name, type: $type, size: $formattedSize)';
  }
}

/// An object that controls a list of [FileSystemItem].
class FileSystemItemList extends Notifier<List<FileSystemItem>> {
  @override
  List<FileSystemItem> build() => [];

  Future<void> loadDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      final entities = await directory.list().toList();

      final items = <FileSystemItem>[];

      for (var entity in entities) {
        final stat = await entity.stat();
        final name = paths.basename(entity.path);

        items.add(
          FileSystemItem(
            path: entity.path,
            name: name,
            type: entity is Directory ? FileSystemItemType.directory : FileSystemItemType.file,
            size: stat.size,
            modifiedAt: stat.modified,
            createdAt: stat.changed,
            isSelected: false,
          ),
        );
      }

      // Sort directories first, then files, both alphabetically
      items.sort((a, b) {
        if (a.type != b.type) {
          return a.type == FileSystemItemType.directory ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      state = items;
    } catch (e) {
      state = [];
    }
  }

  void selectItem(String path) {
    state = [for (final item in state) item.copyWith(isSelected: item.path == path)];
  }
}
