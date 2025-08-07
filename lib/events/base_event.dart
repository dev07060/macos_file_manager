import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:path/path.dart' as path;

mixin class BaseEvent {
  /// Delete selected items
  Future<void> deleteSelectedItems(WidgetRef ref, BuildContext context) async {
    final selectedCount = ref.read(selectedItemsCountProvider);

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete $selectedCount files?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
          title: const Text('Compress Files'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'archive.zip', labelText: 'Compress File Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({'fileName': controller.text});
              },
              child: const Text('Compress'),
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
            title: const Text('File Already Exists'),
            content: Text('$zipFileName file already exists. Do you want to overwrite it?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('overwrite')),
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
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(width: 20),
              const Text('compressing...'),
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
            content: Text('error occurred while compressing file(s): $e'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Confirm'))],
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

  /// Show a simple snackbar message to the user
  void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: duration, action: action));
    }
  }

  /// Show a confirmation dialog
  Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelText)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText, style: isDangerous ? const TextStyle(color: Colors.red) : null),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<T?> handleErrorWithDialog<T>(
    Future<T> Function() action,
    BuildContext context, {
    String title = 'Error',
    String? successMessage,
    bool showErrorDetails = true,
  }) async {
    try {
      final result = await action();
      if (successMessage != null) {
        showSnackBar(context, successMessage);
      }
      return result;
    } catch (e) {
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(title),
              content: Text(showErrorDetails ? 'Error occurred while action: $e' : 'An error occurred'),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Confirm'))],
            ),
      );
      return null;
    }
  }

  /// Show an input dialog
  Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    String? initialValue,
    String? hintText,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool Function(String)? validator,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(hintText: hintText),
                validator: validator != null ? (value) => validator(value ?? '') ? null : 'Input is invalid' : null,
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text(cancelText)),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop(controller.text);
                  }
                },
                child: Text(confirmText),
              ),
            ],
          ),
    );
  }

  /// Show a loading indicator and close it when the task is complete
  Future<T?> showLoadingWhile<T>(
    Future<T> Function() action,
    BuildContext context, {
    String loadingText = 'Processing...',
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [const CircularProgressIndicator.adaptive(), const SizedBox(width: 20), Text(loadingText)],
          ),
        );
      },
    );

    try {
      final result = await action();
      // Close loading dialog after task completion
      if (context.mounted) Navigator.of(context).pop();
      return result;
    } catch (e) {
      // Close loading dialog if an error occurs
      if (context.mounted) Navigator.of(context).pop();
      rethrow; // Rethrow the error to be handled by handleErrorWithDialog
    }
  }
}
