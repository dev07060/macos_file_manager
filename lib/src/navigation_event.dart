import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:path/path.dart' as path;

mixin class NavigationEvent {
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

  /// Navigate to a specific directory
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

  /// Navigate back in history
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

  /// Navigate forward in history
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

  /// Navigate up to parent directory
  Future<void> navigateUp(WidgetRef ref) async {
    final currentPath = ref.read(currentDirectoryProvider);
    final parentPath = path.dirname(currentPath);

    if (parentPath != currentPath) {
      await navigateToDirectory(ref, parentPath);
    }
  }

  /// Navigate to home directory
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

  /// Get the path to the Desktop directory using Platform.environment
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
            return desktopPath;
          } else {
            return homeDir; // If the desktop folder doesn't exist, return the home directory
          }
        } else {
          return '/'; // Fallback to the default path if failed to get the home directory
        }
      } catch (e) {
        return '/'; // Fallback to the default path if an error occurred
      }
    } else {
      // If it's not macOS, keep the existing method (modify as needed)
      final desktopPath = '/Users/${Platform.environment['USER']}/Desktop';
      final directory = Directory(desktopPath);
      final exists = await directory.exists();
      return exists ? desktopPath : Platform.environment['HOME'] ?? '/';
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
