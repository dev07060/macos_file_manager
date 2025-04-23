import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:path/path.dart' as path;

mixin class FileOperationEvent {
  /// Delete selected items
  Future<void> deleteSelectedItems(WidgetRef ref, BuildContext context) async {
    final selectedCount = ref.read(selectedItemsCountProvider);

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('정말 선택된 $selectedCount개의 파일을 삭제하시겠습니까?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref.read(fileSystemItemListProvider.notifier).deleteSelectedItems();
      // Refresh the directory
      final currentDir = ref.read(currentDirectoryProvider);
      await ref.read(fileSystemItemListProvider.notifier).loadDirectory(currentDir);

      // Clear the selected file item and last selected path
      ref.read(selectedFileItemProvider.notifier).state = null;
      ref.read(lastSelectedPathProvider.notifier).state = null;
    }
  }

  /// Compress selected items
  Future<void> compressSelectedItems(WidgetRef ref, BuildContext context) async {
    final currentDir = ref.read(currentDirectoryProvider);
    final selectedItems = ref.read(fileSystemItemListProvider).where((item) => item.isSelected).toList();

    if (selectedItems.isEmpty) return;

    // Default archive name based on the first selected item
    final firstItemName = path.basenameWithoutExtension(selectedItems.first.name);
    String archiveName = firstItemName;

    // Show dialog to set archive name
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController(text: '$archiveName.zip');

        return AlertDialog(
          title: const Text('압축 파일 생성'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'archive.zip', labelText: '압축 파일 이름'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('취소')),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({'fileName': controller.text});
              },
              child: const Text('압축'),
            ),
          ],
        );
      },
    );

    if (result == null) return; // User canceled

    final zipFileName = result['fileName'];
    final zipFilePath = path.join(currentDir, zipFileName);

    // Check if a file with this name already exists
    if (File(zipFilePath).existsSync()) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('파일이 이미 존재합니다'),
            content: Text('$zipFileName 파일이 이미 존재합니다. 덮어쓰시겠습니까?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('덮어쓰기')),
            ],
          );
        },
      );

      if (confirmed != true) return; // User canceled overwrite
    }

    // Show progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [const CircularProgressIndicator.adaptive(), const SizedBox(width: 20), const Text('압축 중...')],
          ),
        );
      },
    );

    try {
      // Create archive
      final archive = Archive();

      // Add selected items to archive
      for (final item in selectedItems) {
        if (item.type == FileSystemItemType.file) {
          // Add file to archive
          final file = File(item.path);
          final bytes = await file.readAsBytes();

          // Use relative path from current directory
          String archivePath = path.basename(item.path);
          archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
        } else if (item.type == FileSystemItemType.directory) {
          // Add directory and its contents recursively
          await _addDirectoryToArchive(archive, item.path, path.basename(item.path));
        }
      }

      // Encode the archive to zip
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        // Write zip to file
        final zipFile = File(zipFilePath);
        await zipFile.writeAsBytes(zipData);
      }

      // Close progress dialog
      Navigator.of(context).pop();

      // Reload the directory to show the new zip file
      await ref.read(fileSystemItemListProvider.notifier).loadDirectory(currentDir);
    } catch (e) {
      // Close progress dialog
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('압축 중 오류가 발생했습니다: $e'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
          );
        },
      );
    }
  }

  // Helper method to add a directory and its contents to an archive
  Future<void> _addDirectoryToArchive(Archive archive, String dirPath, String archivePath) async {
    final dir = Directory(dirPath);
    final entities = await dir.list(recursive: false).toList();

    for (final entity in entities) {
      final relativePath = path.join(archivePath, path.basename(entity.path));

      if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      } else if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity.path, relativePath);
      }
    }
  }

  /// Rename a file or directory
  Future<void> renameFileSystemItem(WidgetRef ref, FileSystemItem item, String newName, BuildContext context) async {
    if (newName.isEmpty || newName == item.name) return;

    final directory = path.dirname(item.path);
    final newPath = path.join(directory, newName);

    // Check if a file with this name already exists
    if (File(newPath).existsSync() || Directory(newPath).existsSync()) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('파일 "$newName"은(는) 이미 존재합니다.'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
          );
        },
      );
      return;
    }

    try {
      if (item.type == FileSystemItemType.file) {
        final file = File(item.path);
        await file.rename(newPath);
      } else {
        final directory = Directory(item.path);
        await directory.rename(newPath);
      }

      // Refresh the current directory
      final currentDir = ref.read(currentDirectoryProvider);
      await ref.read(fileSystemItemListProvider.notifier).loadDirectory(currentDir);

      // Update the selectedFileItemProvider with the renamed item
      final updatedItemIndex = ref.read(fileSystemItemListProvider).indexWhere((i) => i.path == newPath);
      if (updatedItemIndex != -1) {
        final updatedItem = ref.read(fileSystemItemListProvider)[updatedItemIndex];
        ref.read(selectedFileItemProvider.notifier).state = updatedItem;

        // Update the lastSelectedPathProvider
        ref.read(lastSelectedPathProvider.notifier).state = updatedItem.path;

        // Make sure the renamed item is selected in the list
        ref.read(fileSystemItemListProvider.notifier).selectItem(updatedItem.path);
      } else {
        // If the item can't be found, clear the selection
        ref.read(selectedFileItemProvider.notifier).state = null;
        ref.read(lastSelectedPathProvider.notifier).state = null;
      }
    } catch (e) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('파일 이름을 변경하지 못했습니다: $e'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
          );
        },
      );
    }
  }
}
