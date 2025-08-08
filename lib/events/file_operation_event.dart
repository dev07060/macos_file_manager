import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/services/file_system_service.dart';
import 'package:macos_file_manager/utils/archive_utils.dart';
import 'package:path/path.dart' as path;

mixin class FileOperationEvent {
  /// Delete selected items
  Future<void> deleteSelectedItems(WidgetRef ref, BuildContext context) async {
    final service = ref.read(fileSystemServiceProvider);
    final selectedCount = service.getSelectedItemsCount();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppStrings.deleteConfirmTitle),
          content: Text(AppStrings.deleteConfirmContent(selectedCount)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text(AppStrings.cancel)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.delete, style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await service.deleteSelectedItems();

      final currentDir = service.getCurrentDirectory();
      await service.loadDirectory(currentDir);

      service.clearSelections();
    }
  }

  Future<void> compressSelectedItems(WidgetRef ref, BuildContext context) async {
    final currentDir = ref.read(fileSystemServiceProvider).getCurrentDirectory();
    final selectedItems = ref.read(fileSystemServiceProvider).getSelectedItems();

    if (selectedItems.isEmpty) return;

    final firstItemName = path.basenameWithoutExtension(selectedItems.first.name);
    String archiveName = firstItemName;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController(text: '$archiveName.zip');

        return AlertDialog(
          title: const Text(AppStrings.createArchiveTitle),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'archive.zip', labelText: AppStrings.archiveFileNameLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text(AppStrings.cancel)),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({'fileName': controller.text});
              },
              child: const Text(AppStrings.compress),
            ),
          ],
        );
      },
    );

    if (result == null) return; // User canceled

    final inputName = (result['fileName'] as String).trim();
    final zipFileName = inputName.toLowerCase().endsWith('.zip') ? inputName : '$inputName.zip';
    final zipFilePath = path.join(currentDir, zipFileName);

    if (File(zipFilePath).existsSync()) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(AppStrings.fileAlreadyExistsTitle),
            content: Text(AppStrings.fileAlreadyExistsContent(zipFileName)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text(AppStrings.cancel)),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text(AppStrings.overwrite)),
            ],
          );
        },
      );

      if (confirmed != true) return; // User canceled overwrite
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(width: 20),
              const Text(AppStrings.compressing),
            ],
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
          await ArchiveUtils.addDirectoryToArchive(archive, item.path, path.basename(item.path));
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
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Reload the directory to show the new zip file
      await ref.read(fileSystemServiceProvider).loadDirectory(currentDir);
    } catch (e) {
      // Close progress dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(AppStrings.error),
            content: Text('${AppStrings.compressError} $e'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.confirm))],
          );
        },
      );
    }
  }

  /// Rename a file or directory
  Future<void> renameFileSystemItem(WidgetRef ref, FileSystemItem item, String newName, BuildContext context) async {
    if (newName.isEmpty || newName == item.name) return;

    final service = ref.read(fileSystemServiceProvider);

    // Check if a file with this name already exists
    final directory = path.dirname(item.path);
    final newPath = path.join(directory, newName);

    if (File(newPath).existsSync() || Directory(newPath).existsSync()) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(AppStrings.error),
            content: Text(AppStrings.renameAlreadyExistsContent(newName)),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.confirm))],
          );
        },
      );
      return;
    }

    final success = await service.renameItem(item, newName);

    if (!success) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(AppStrings.error),
            content: const Text(AppStrings.renameFailed),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.confirm))],
          );
        },
      );
    }
  }
}
