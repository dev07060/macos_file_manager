import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:path/path.dart' as path;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

mixin class DragDropItemsEvent {
  Future<DragItem?> createDragItemForFile(FileSystemItem fileItem) async {
    if (fileItem.type != FileSystemItemType.file) {
      return null;
    }

    final dragItem = DragItem(
      localData: {
        'paths': [fileItem.path],
      },
      suggestedName: fileItem.name,
    );

    // Add plain text format with file path
    dragItem.add(Formats.plainText(fileItem.path));

    return dragItem;
  }

  Future<void> handleFileDrop(WidgetRef ref, BuildContext context, PerformDropEvent event, String itemPath) async {
    // Get the target directory path
    final targetDirectoryPath = itemPath;

    // Get all items from the drop session
    for (final dropItem in event.session.items) {
      final reader = dropItem.dataReader;
      if (reader == null) continue;

      try {
        // Try to get paths from local data first
        if (dropItem.localData != null && dropItem.localData is Map) {
          final Map localData = dropItem.localData as Map;
          if (localData.containsKey('paths')) {
            final List<String> paths = List<String>.from(localData['paths']);
            await _moveFiles(ref, context, paths, targetDirectoryPath);
            continue;
          }
        }

        // If no local data, try to read as plain text (might contain paths)
        if (reader.canProvide(Formats.plainText)) {
          final text = await reader.getSuggestedName();
          final paths = text!.split('\n').where((p) => p.isNotEmpty).toList();
          await _moveFiles(ref, context, paths, targetDirectoryPath);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process dropped item: $e')));
      }
    }

    // Refresh the current directory to show changes
    final currentDir = ref.read(currentDirectoryProvider);
    await ref.read(fileSystemItemListProvider.notifier).loadDirectory(currentDir);
  }

  Future<void> _moveFiles(WidgetRef ref, BuildContext context, List<String> sourcePaths, String targetDirPath) async {
    if (sourcePaths.isEmpty) return;

    try {
      for (final sourcePath in sourcePaths) {
        final sourceFile = File(sourcePath);
        if (await sourceFile.exists()) {
          final fileName = path.basename(sourcePath);
          final destinationPath = path.join(targetDirPath, fileName);

          // Check if destination already exists
          final destinationFile = File(destinationPath);
          if (await destinationFile.exists()) {
            // Ask for confirmation to overwrite
            final shouldOverwrite = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('파일이 이미 존재합니다'),
                    content: Text('$fileName 파일이 이미 존재합니다. 덮어쓰시겠습니까?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('덮어쓰기', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
            );
            if (shouldOverwrite != true) continue;
          }
          // Move file
          await sourceFile.rename(destinationPath);
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sourcePaths.length == 1 ? '파일을 이동했습니다' : '${sourcePaths.length}개의 파일을 이동했습니다')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('파일 이동 중 오류가 발생했습니다: $e')));
    }
  }
}
