import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:path/path.dart' as path;

// TODO: This code is for refactoring and should be moved to a separate file
class FileSystemService {
  // WidgetRef 대신 Ref (또는 ProviderRef)를 사용합니다.
  final Ref ref;

  FileSystemService(this.ref);

  String getCurrentDirectory() {
    return ref.read(currentDirectoryProvider);
  }

  Future<void> loadDirectory(String path) async {
    await ref.read(fileSystemItemListProvider.notifier).loadDirectory(path);
    ref.read(currentDirectoryProvider.notifier).state = path;
  }

  int getSelectedItemsCount() {
    return ref.read(selectedItemsCountProvider);
  }

  List<FileSystemItem> getSelectedItems() {
    return ref.read(fileSystemItemListProvider).where((item) => item.isSelected).toList();
  }

  Future<void> deleteSelectedItems() async {
    await ref.read(fileSystemItemListProvider.notifier).deleteSelectedItems();
  }

  void clearSelections() {
    ref.read(fileSystemItemListProvider.notifier).clearSelections();
    ref.read(selectedFileItemProvider.notifier).state = null;
    ref.read(lastSelectedPathProvider.notifier).state = null;
  }

  void selectItemByPath(String path) {
    ref.read(fileSystemItemListProvider.notifier).selectItem(path);
  }

  Future<bool> renameItem(FileSystemItem item, String newName) async {
    try {
      final directory = path.dirname(item.path);
      final newPath = path.join(directory, newName);

      if (item.type == FileSystemItemType.file) {
        final file = File(item.path);
        await file.rename(newPath);
      } else {
        final directory = Directory(item.path);
        await directory.rename(newPath);
      }

      final currentDir = getCurrentDirectory();
      await loadDirectory(currentDir);

      final updatedItemIndex = ref.read(fileSystemItemListProvider).indexWhere((i) => i.path == newPath);

      if (updatedItemIndex != -1) {
        final updatedItem = ref.read(fileSystemItemListProvider)[updatedItemIndex];
        ref.read(selectedFileItemProvider.notifier).state = updatedItem;
        ref.read(lastSelectedPathProvider.notifier).state = updatedItem.path;
        selectItemByPath(updatedItem.path);
      } else {
        clearSelections();
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

final fileSystemServiceProvider = Provider<FileSystemService>((ref) {
  // ref를 그대로 전달합니다. Provider 콜백의 ref는 ProviderRef 타입입니다.
  return FileSystemService(ref);
});
