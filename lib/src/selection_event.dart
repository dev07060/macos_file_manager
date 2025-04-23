import 'dart:developer';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';

mixin class SelectionEvent {
  void _updateSelectedItemState(WidgetRef ref, FileSystemItem item) {
    if (item.isSelected) {
      ref.read(selectedFileItemProvider.notifier).state = item;
    } else if (ref.read(selectedFileItemProvider)?.path == item.path) {
      ref.read(selectedFileItemProvider.notifier).state = null;
    }
  }

  void clearSelections(WidgetRef ref) {
    ref.read(fileSystemItemListProvider.notifier).clearSelections();
    ref.read(lastSelectedPathProvider.notifier).state = null;
    ref.read(selectedFileItemProvider.notifier).state = null;
  }

  void _handleShiftSelection(WidgetRef ref, FileSystemItem item, String lastSelectedPath) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);

    notifier.toggleItemSelection(item.path, isShiftKeyPressed: true, lastSelectedPath: lastSelectedPath);
    ref.read(lastSelectedPathProvider.notifier).state = item.path;

    _updateSelectedItemState(ref, item);
  }

  void _handleCtrlSelection(WidgetRef ref, FileSystemItem item) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);

    notifier.toggleItemSelection(item.path);
    ref.read(lastSelectedPathProvider.notifier).state = item.path;

    _updateSelectedItemState(ref, item);
  }

  void _handleSingleSelection(WidgetRef ref, FileSystemItem item) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);
    final selectedItems = ref.read(fileSystemItemListProvider).where((item) => item.isSelected).toList();

    if (item.isSelected && selectedItems.length == 1) {
      clearSelections(ref);
    } else {
      clearSelections(ref);
      notifier.toggleItemSelection(item.path);
      ref.read(lastSelectedPathProvider.notifier).state = item.path;
      ref.read(selectedFileItemProvider.notifier).state = item;
    }
  }

  /// Handle item selection with support for multi-select (Shift/Ctrl)
  void handleItemSelection(
    WidgetRef ref,
    FileSystemItem item, {
    bool isShiftKeyPressed = false,
    bool isCtrlKeyPressed = false,
  }) {
    try {
      final lastSelectedPath = ref.read(lastSelectedPathProvider);

      // Handle item selection with shift key (range selection)
      if (isShiftKeyPressed && lastSelectedPath != null) {
        _handleShiftSelection(ref, item, lastSelectedPath);
        return;
      }

      // Handle item selection with Ctrl key (toggle individual selection)
      if (isCtrlKeyPressed) {
        _handleCtrlSelection(ref, item);
        return;
      }

      // Handle normal click (single selection)
      _handleSingleSelection(ref, item);
    } catch (e) {
      log('Selection error: $e');
      clearSelections(ref);
    }
  }

  Future<void> handleItemClick(
    WidgetRef ref,
    FileSystemItem item, {
    bool isShiftKeyPressed = false,
    bool isCtrlKeyPressed = false,
    Future<void> Function(String)? onNavigate,
  }) async {
    try {
      if (item.type == FileSystemItemType.directory && !isShiftKeyPressed && !isCtrlKeyPressed) {
        if (onNavigate != null) {
          await onNavigate(item.path);
        } else {
          await ref.read(fileSystemItemListProvider.notifier).loadDirectory(item.path);
          ref.read(currentDirectoryProvider.notifier).state = item.path;
          clearSelections(ref);
        }
        return;
      }

      handleItemSelection(ref, item, isShiftKeyPressed: isShiftKeyPressed, isCtrlKeyPressed: isCtrlKeyPressed);
    } catch (e) {
      log('Item click handling error: $e');
    }
  }
}
