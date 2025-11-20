import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process dropped item: $e')));
        }
      }
    }

    // Refresh the current directory to show changes
    final currentDir = ref.read(currentDirectoryProvider);
    await ref.read(fileSystemItemListProvider.notifier).loadDirectory(currentDir);
  }

  Future<void> _moveFiles(WidgetRef ref, BuildContext context, List<String> sourcePaths, String targetDirPath) async {
    if (sourcePaths.isEmpty) return;

    final List<Map<String, String>> movedItems = [];

    try {
      await Future.forEach(sourcePaths, (sourcePath) async {
        final fileName = path.basename(sourcePath);
        final destinationPath = path.join(targetDirPath, fileName);

        final sourceType = await FileSystemEntity.type(sourcePath);
        final destinationType = await FileSystemEntity.type(destinationPath);

        if (destinationType != FileSystemEntityType.notFound) {
          if (!context.mounted) return;
          final shouldOverwrite = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(AppStrings.fileAlreadyExistsTitle),
              content: Text(AppStrings.fileAlreadyExistsContent(fileName)),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text(AppStrings.cancel)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(AppStrings.overwrite, style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (shouldOverwrite != true) return;

          if (destinationType == FileSystemEntityType.directory) {
            await Directory(destinationPath).delete(recursive: true);
          } else {
            await File(destinationPath).delete();
          }
        }

        final entity = sourceType == FileSystemEntityType.directory ? Directory(sourcePath) : File(sourcePath);
        await entity.rename(destinationPath);
        movedItems.add({'from': sourcePath, 'to': destinationPath});
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sourcePaths.length == 1 ? 'Move completed' : '${sourcePaths.length} items moved successfully'),
            action: SnackBarAction(label: 'Undo', onPressed: () => _undoMoveFiles(ref, context, movedItems)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      developer.log('Error during move: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during move: $e')));
      }
    }
  }

  Future<void> _undoMoveFiles(WidgetRef ref, BuildContext context, List<Map<String, String>> movedItems) async {
    try {
      await Future.forEach(movedItems, (item) async {
        final from = item['from']!;
        final to = item['to']!;
        final entityType = await FileSystemEntity.type(to);
        final entity = entityType == FileSystemEntityType.directory ? Directory(to) : File(to);
        await entity.rename(from);
      });

      final currentDir = ref.read(currentDirectoryProvider);
      await ref.read(fileSystemItemListProvider.notifier).loadDirectory(currentDir);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Undo complete')));
      }
    } catch (e) {
      developer.log('Error during undo move: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during undo move: $e')));
      }
    }
  }
}