import 'dart:developer';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:path/path.dart' as path;

mixin class HomeEvent {
  ///
  /// Navigate to a specific directory
  ///
  Future<void> navigateToDirectory(WidgetRef ref, String? directoryPath) async {
    if (directoryPath == null) return;

    final notifier = ref.read(directoryHistoryProvider.notifier);
    notifier.navigateTo(directoryPath);

    await ref.read(fileSystemItemListProvider.notifier).loadDirectory(directoryPath);
    ref.read(currentDirectoryProvider.notifier).state = directoryPath;
    ref.read(selectedFileItemProvider.notifier).state = null;

    // Clear the last selected path when navigating to a new directory
    ref.read(lastSelectedPathProvider.notifier).state = null;

    // Clear all selections
    ref.read(fileSystemItemListProvider.notifier).clearSelections();
  }

  ///
  /// Handle item click - select item or navigate to directory with multi-select support
  ///
  Future<void> handleItemClick(
    WidgetRef ref,
    FileSystemItem item, {
    bool isShiftKeyPressed = false,
    bool isCtrlKeyPressed = false,
  }) async {
    final lastSelectedPath = ref.read(lastSelectedPathProvider);
    final notifier = ref.read(fileSystemItemListProvider.notifier);
    final selectedItems = ref.read(fileSystemItemListProvider).where((item) => item.isSelected).toList();

    // If it's a directory and no modifier keys are pressed, navigate to it
    if (item.type == FileSystemItemType.directory && !isShiftKeyPressed && !isCtrlKeyPressed) {
      await navigateToDirectory(ref, item.path);
      return;
    }

    // Handle item selection with shift key (range selection)
    if (isShiftKeyPressed && lastSelectedPath != null) {
      notifier.toggleItemSelection(item.path, isShiftKeyPressed: true, lastSelectedPath: lastSelectedPath);
      ref.read(lastSelectedPathProvider.notifier).state = item.path;

      // Update selected item provider if needed
      if (item.isSelected) {
        ref.read(selectedFileItemProvider.notifier).state = item;
      } else if (ref.read(selectedFileItemProvider)?.path == item.path) {
        ref.read(selectedFileItemProvider.notifier).state = null;
      }
      return;
    }

    // Handle item selection with Ctrl key (toggle individual selection)
    if (isCtrlKeyPressed) {
      notifier.toggleItemSelection(item.path);
      ref.read(lastSelectedPathProvider.notifier).state = item.path;

      // If this item was previously selected and is now deselected
      if (!item.isSelected && ref.read(selectedFileItemProvider)?.path == item.path) {
        ref.read(selectedFileItemProvider.notifier).state = null;
      } else if (item.isSelected) {
        ref.read(selectedFileItemProvider.notifier).state = item;
      }
      return;
    }

    // Handle normal click (single selection)
    // If the item is already selected and it's the only selected item, deselect it
    if (item.isSelected && selectedItems.length == 1) {
      notifier.clearSelections();
      ref.read(lastSelectedPathProvider.notifier).state = null;
      ref.read(selectedFileItemProvider.notifier).state = null;
    } else {
      // Otherwise, select only this item
      notifier.clearSelections();
      notifier.toggleItemSelection(item.path);
      ref.read(lastSelectedPathProvider.notifier).state = item.path;
      ref.read(selectedFileItemProvider.notifier).state = item;
    }
  }

  ///
  /// Navigate back in history
  ///
  Future<void> navigateBack(WidgetRef ref) async {
    final history = ref.read(directoryHistoryProvider);
    if (history.canGoBack) {
      ref.read(directoryHistoryProvider.notifier).goBack();
      final newPath = ref.read(directoryHistoryProvider).currentPath;

      await ref.read(fileSystemItemListProvider.notifier).loadDirectory(newPath);
      ref.read(currentDirectoryProvider.notifier).state = newPath;
      ref.read(selectedFileItemProvider.notifier).state = null;

      // Clear the last selected path
      ref.read(lastSelectedPathProvider.notifier).state = null;
    }
  }

  ///
  /// Navigate forward in history
  ///
  Future<void> navigateForward(WidgetRef ref) async {
    final history = ref.read(directoryHistoryProvider);
    if (history.canGoForward) {
      ref.read(directoryHistoryProvider.notifier).goForward();
      final newPath = ref.read(directoryHistoryProvider).currentPath;

      await ref.read(fileSystemItemListProvider.notifier).loadDirectory(newPath);
      ref.read(currentDirectoryProvider.notifier).state = newPath;
      ref.read(selectedFileItemProvider.notifier).state = null;

      // Clear the last selected path
      ref.read(lastSelectedPathProvider.notifier).state = null;
    }
  }

  ///
  /// Navigate up to parent directory
  ///
  Future<void> navigateUp(WidgetRef ref) async {
    final currentPath = ref.read(currentDirectoryProvider);
    final parentPath = path.dirname(currentPath);

    if (parentPath != currentPath) {
      await navigateToDirectory(ref, parentPath);
    }
  }

  ///
  /// Navigate to home directory
  ///
  Future<void> navigateToHome(WidgetRef ref) async {
    String? desktopPath;
    if (Platform.isMacOS) {
      final homeDir = await getHomeDirectory();
      if (homeDir != null) {
        desktopPath = path.join(homeDir, 'Desktop');
        final desktopDir = Directory(desktopPath);
        if (!await desktopDir.exists()) {
          desktopPath = homeDir; // If the desktop folder doesn't exist, fallback to the home directory
        }
      }
    } else {
      desktopPath =
          Platform.environment['HOME'] ?? '/'; // If it's not macOS, keep the existing method (modify as needed)
    }

    if (desktopPath != null) {
      await navigateToDirectory(ref, desktopPath);
    }
  }

  ///
  /// Get the path to the Desktop directory using Platform.environment
  ///
  Future<String?> getDesktopPath() async {
    if (Platform.isMacOS) {
      try {
        String? homeDir;
        if (Platform.isMacOS || Platform.isLinux) {
          homeDir = Platform.environment['HOME'];
        } else if (Platform.isWindows) {
          homeDir = Platform.environment['USERPROFILE'];
        }

        if (homeDir != null) {
          final desktopPath = path.join(homeDir, 'Desktop');
          final desktopDir = Directory(desktopPath);
          if (await desktopDir.exists()) {
            log('Attempting to access (Platform.environment): $desktopPath');
            log('Desktop exists (Platform.environment): true');
            return desktopPath;
          } else {
            log('Desktop does not exist at (Platform.environment): $desktopPath');
            return homeDir; // If the desktop folder doesn't exist, return the home directory
          }
        } else {
          log('Could not get home directory using Platform.environment');
          return '/'; // Fallback to the default path if failed to get the home directory
        }
      } catch (e) {
        log('Error getting desktop path with Platform.environment: $e');
        return '/'; // Fallback to the default path if an error occurred
      }
    } else {
      // If it's not macOS, keep the existing method (modify as needed)
      final desktopPath = '/Users/${Platform.environment['USER']}/Desktop';
      final directory = Directory(desktopPath);
      final exists = await directory.exists();
      log('Attempting to access (original): $desktopPath');
      log('Desktop exists (original): $exists');
      return exists ? desktopPath : Platform.environment['HOME'] ?? '/';
    }
  }

  ///
  /// Delete selected items
  ///
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

  ///
  /// Compress selected items
  ///
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
          content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 20), const Text('압축 중...')]),
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

  ///
  /// Rename a file or directory
  ///
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

  // Update in lib/src/home_event.dart
  Future<void> toggleFavoriteDirectory(WidgetRef ref, String directoryPath) async {
    final directoryName = path.basename(directoryPath);

    // Use the notifier to toggle the favorite status
    ref.read(favoritesProvider.notifier).toggleFavorite(directoryPath, directoryName);
  }

  Future<Map<String, dynamic>> executeShellScript(String scriptPath, BuildContext context) async {
    try {
      // Check and grant execute permission for the script
      final statResult = await Process.run('chmod', ['+x', scriptPath]);
      if (statResult.exitCode != 0) {
        return {'success': false, 'output': 'Failed to grant execute permission: ${statResult.stderr}'};
      }

      // Execute the script
      final result = await Process.run('sh', [scriptPath]);

      return {
        'success': result.exitCode == 0,
        'output': result.stdout,
        'error': result.stderr,
        'exitCode': result.exitCode,
      };
    } catch (e) {
      return {'success': false, 'output': '스크립트 실행 중 오류가 발생했습니다: $e'};
    }
  }

  Future<String?> getHomeDirectory() async {
    if (Platform.isMacOS || Platform.isLinux) {
      return Platform.environment['HOME'];
    } else if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'];
    }
    return null; // Other platforms
  }
}
