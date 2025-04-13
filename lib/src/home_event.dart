import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';

mixin class HomeEvent {
  ///
  /// Navigate to a specific directory
  ///
  Future<void> navigateToDirectory(WidgetRef ref, String directoryPath) async {
    final notifier = ref.read(directoryHistoryProvider.notifier);
    notifier.navigateTo(directoryPath);

    await ref.read(fileSystemItemListProvider.notifier).loadDirectory(directoryPath);
    ref.read(currentDirectoryProvider.notifier).state = directoryPath;
    ref.read(selectedFileItemProvider.notifier).state = null;
  }

  ///
  /// Handle item click - select item or navigate to directory
  ///
  Future<void> handleItemClick(WidgetRef ref, FileSystemItem item) async {
    if (item.type == FileSystemItemType.directory) {
      await navigateToDirectory(ref, item.path);
    } else {
      ref.read(fileSystemItemListProvider.notifier).selectItem(item.path);
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
    final homePath = Platform.environment['HOME'] ?? '/';
    await navigateToDirectory(ref, homePath);
  }
}
