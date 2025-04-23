import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';

mixin class SelectionEvent {
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
      await ref.read(fileSystemItemListProvider.notifier).loadDirectory(item.path);
      ref.read(currentDirectoryProvider.notifier).state = item.path;
      ref.read(selectedFileItemProvider.notifier).state = null;
      ref.read(lastSelectedPathProvider.notifier).state = null;
      notifier.clearSelections();
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
}
