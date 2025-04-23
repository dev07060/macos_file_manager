import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';

class SelectionService {
  final WidgetRef ref;

  SelectionService(this.ref);

  FileSystemItem? getSelectedItem() {
    return ref.read(selectedFileItemProvider);
  }

  String? getLastSelectedPath() {
    return ref.read(lastSelectedPathProvider);
  }

  List<FileSystemItem> getAllSelectedItems() {
    return ref.read(fileSystemItemListProvider).where((item) => item.isSelected).toList();
  }

  int getSelectedItemsCount() {
    return getAllSelectedItems().length;
  }

  void clearSelections() {
    ref.read(fileSystemItemListProvider.notifier).clearSelections();
    ref.read(lastSelectedPathProvider.notifier).state = null;
    ref.read(selectedFileItemProvider.notifier).state = null;
  }

  void selectItem(String path) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);

    notifier.clearSelections();

    notifier.toggleItemSelection(path);
    final selectedItem = ref
        .read(fileSystemItemListProvider)
        // ignore: cast_from_null_always_fails
        .firstWhere((item) => item.path == path, orElse: () => null as FileSystemItem);

    ref.read(selectedFileItemProvider.notifier).state = selectedItem;
    ref.read(lastSelectedPathProvider.notifier).state = selectedItem.path;
  }

  void handleShiftSelection(FileSystemItem item, String lastSelectedPath) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);

    notifier.toggleItemSelection(item.path, isShiftKeyPressed: true, lastSelectedPath: lastSelectedPath);

    ref.read(lastSelectedPathProvider.notifier).state = item.path;

    if (item.isSelected) {
      ref.read(selectedFileItemProvider.notifier).state = item;
    } else if (ref.read(selectedFileItemProvider)?.path == item.path) {
      ref.read(selectedFileItemProvider.notifier).state = null;
    }
  }

  void handleCtrlSelection(FileSystemItem item) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);

    notifier.toggleItemSelection(item.path);
    ref.read(lastSelectedPathProvider.notifier).state = item.path;

    if (!item.isSelected && ref.read(selectedFileItemProvider)?.path == item.path) {
      ref.read(selectedFileItemProvider.notifier).state = null;
    } else if (item.isSelected) {
      ref.read(selectedFileItemProvider.notifier).state = item;
    }
  }

  void handleSingleSelection(FileSystemItem item) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);
    final selectedItems = getAllSelectedItems();

    if (item.isSelected && selectedItems.length == 1) {
      notifier.clearSelections();
      ref.read(lastSelectedPathProvider.notifier).state = null;
      ref.read(selectedFileItemProvider.notifier).state = null;
    } else {
      notifier.clearSelections();
      notifier.toggleItemSelection(item.path);
      ref.read(lastSelectedPathProvider.notifier).state = item.path;
      ref.read(selectedFileItemProvider.notifier).state = item;
    }
  }

  void handleItemSelection(FileSystemItem item, {bool isShiftKeyPressed = false, bool isCtrlKeyPressed = false}) {
    final lastSelectedPath = getLastSelectedPath();

    if (isShiftKeyPressed && lastSelectedPath != null) {
      handleShiftSelection(item, lastSelectedPath);
      return;
    }

    if (isCtrlKeyPressed) {
      handleCtrlSelection(item);
      return;
    }

    handleSingleSelection(item);
  }

  Future<bool> handleItemClick(
    FileSystemItem item, {
    bool isShiftKeyPressed = false,
    bool isCtrlKeyPressed = false,
  }) async {
    bool shouldNavigate = item.type == FileSystemItemType.directory && !isShiftKeyPressed && !isCtrlKeyPressed;

    if (!shouldNavigate) {
      handleItemSelection(item, isShiftKeyPressed: isShiftKeyPressed, isCtrlKeyPressed: isCtrlKeyPressed);
    }

    return shouldNavigate;
  }
}

final selectionServiceProvider = Provider<SelectionService>((ref) {
  return SelectionService(ref as WidgetRef);
});
