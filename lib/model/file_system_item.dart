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
    this.subItemCount = const SubItemCount(files: 0, directories: 0), // Added subItemCount
  });

  final String path;
  final String name;
  final FileSystemItemType type;
  final int size; // Size in bytes
  final DateTime modifiedAt;
  final DateTime createdAt;
  final bool isSelected;
  final SubItemCount subItemCount; // Track count of subdirectories and files

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
  FileSystemItem copyWith({bool? isSelected, SubItemCount? subItemCount}) {
    return FileSystemItem(
      path: path,
      name: name,
      type: type,
      size: size,
      modifiedAt: modifiedAt,
      createdAt: createdAt,
      isSelected: isSelected ?? this.isSelected,
      subItemCount: subItemCount ?? this.subItemCount,
    );
  }

  @override
  String toString() {
    return 'FileSystemItem(name: $name, type: $type, size: $formattedSize)';
  }
}

// A class to hold counts of subdirectories and files
class SubItemCount {
  final int files;
  final int directories;

  const SubItemCount({required this.files, required this.directories});

  int get total => files + directories;

  String get formattedCount {
    if (total == 0) return 'Empty';
    final parts = <String>[];
    if (directories > 0) {
      parts.add('$directories ${directories == 1 ? 'folder' : 'folders'}');
    }
    if (files > 0) {
      parts.add('$files ${files == 1 ? 'file' : 'files'}');
    }
    return parts.join(', ');
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

        // Count subdirectories and files for directories
        SubItemCount subItemCount = const SubItemCount(files: 0, directories: 0);

        if (entity is Directory) {
          subItemCount = await _countSubItems(entity.path);
        }

        items.add(
          FileSystemItem(
            path: entity.path,
            name: name,
            type: entity is Directory ? FileSystemItemType.directory : FileSystemItemType.file,
            size: stat.size,
            modifiedAt: stat.modified,
            createdAt: stat.changed,
            isSelected: false,
            subItemCount: subItemCount,
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

  // Helper method to count files and directories in a directory
  Future<SubItemCount> _countSubItems(String directoryPath) async {
    try {
      int files = 0;
      int directories = 0;

      final directory = Directory(directoryPath);
      final entities = await directory.list().toList();

      for (var entity in entities) {
        if (entity is Directory) {
          directories++;
        } else {
          files++;
        }
      }

      return SubItemCount(files: files, directories: directories);
    } catch (e) {
      return const SubItemCount(files: 0, directories: 0);
    }
  }

  void selectItem(String path) {
    state = [for (final item in state) item.copyWith(isSelected: item.path == path)];
  }
}
