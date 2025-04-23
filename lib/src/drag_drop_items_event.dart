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

    // Undo 정보를 저장
    final List<Map<String, String>> movedItems = [];

    try {
      for (final sourcePath in sourcePaths) {
        final entity =
            FileSystemEntity.typeSync(sourcePath) == FileSystemEntityType.directory
                ? Directory(sourcePath)
                : File(sourcePath);
        final fileName = path.basename(sourcePath);
        final destinationPath = path.join(targetDirPath, fileName);

        // Check if destination already exists
        final destinationType = FileSystemEntity.typeSync(destinationPath);
        if (destinationType != FileSystemEntityType.notFound) {
          // Ask for confirmation to overwrite
          final shouldOverwrite = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('이미 존재합니다'),
                  content: Text('$fileName 이(가) 이미 존재합니다. 덮어쓰시겠습니까?'),
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
          // 삭제
          if (destinationType == FileSystemEntityType.directory) {
            await Directory(destinationPath).delete(recursive: true);
          } else {
            await File(destinationPath).delete();
          }
        }
        // Move entity
        await entity.rename(destinationPath);
        movedItems.add({'from': sourcePath, 'to': destinationPath});
      }

      // Show success message with Undo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sourcePaths.length == 1 ? '이동 완료' : '${sourcePaths.length}개 항목 이동 완료'),
          action: SnackBarAction(label: 'Undo', onPressed: () => _undoMoveFiles(ref, context, movedItems)),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이동 중 오류: $e')));
    }
  }

  Future<void> _undoMoveFiles(WidgetRef ref, BuildContext context, List<Map<String, String>> movedItems) async {
    try {
      for (final item in movedItems) {
        final from = item['from']!;
        final to = item['to']!;
        final entityType = FileSystemEntity.typeSync(to);
        if (entityType == FileSystemEntityType.directory) {
          await Directory(to).rename(from);
        } else if (entityType == FileSystemEntityType.file) {
          await File(to).rename(from);
        }
      }
      // Refresh the current directory after undo
      final currentDir = ref.read(currentDirectoryProvider);
      await ref.read(fileSystemItemListProvider.notifier).loadDirectory(currentDir);

      // 안전하게 메시지 띄우기
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('undo complete')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error while undo move: $e')));
      }
    }
  }
}
