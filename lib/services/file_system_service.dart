import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:path/path.dart' as path;

/// 파일 시스템 관련 작업을 담당하는 서비스 클래스
class FileSystemService {
  final WidgetRef ref;

  FileSystemService(this.ref);

  /// 현재 디렉토리 경로 가져오기
  String getCurrentDirectory() {
    return ref.read(currentDirectoryProvider);
  }

  /// 디렉토리 내용 로드
  Future<void> loadDirectory(String path) async {
    await ref.read(fileSystemItemListProvider.notifier).loadDirectory(path);
    ref.read(currentDirectoryProvider.notifier).state = path;
  }

  /// 선택 항목 개수 가져오기
  int getSelectedItemsCount() {
    return ref.read(selectedItemsCountProvider);
  }

  /// 선택된 항목 가져오기
  List<FileSystemItem> getSelectedItems() {
    return ref.read(fileSystemItemListProvider).where((item) => item.isSelected).toList();
  }

  /// 선택된 항목 삭제
  Future<void> deleteSelectedItems() async {
    await ref.read(fileSystemItemListProvider.notifier).deleteSelectedItems();
  }

  /// 모든 선택 해제
  void clearSelections() {
    ref.read(fileSystemItemListProvider.notifier).clearSelections();
    ref.read(selectedFileItemProvider.notifier).state = null;
    ref.read(lastSelectedPathProvider.notifier).state = null;
  }

  /// 파일 경로로 항목 선택
  void selectItemByPath(String path) {
    ref.read(fileSystemItemListProvider.notifier).selectItem(path);
  }

  /// 항목 이름 변경
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

      // 디렉토리 새로고침 및 선택 업데이트
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

/// 서비스 프로바이더 - 위젯에서 서비스에 접근하기 위한 프로바이더
final fileSystemServiceProvider = Provider<FileSystemService>((ref) {
  return FileSystemService(ref as WidgetRef);
});
