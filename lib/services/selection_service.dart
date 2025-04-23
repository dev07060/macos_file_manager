import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';

/// 항목 선택 관련 기능을 담당하는 서비스 클래스
class SelectionService {
  final WidgetRef ref;

  SelectionService(this.ref);

  /// 현재 선택된 항목 가져오기
  FileSystemItem? getSelectedItem() {
    return ref.read(selectedFileItemProvider);
  }

  /// 마지막으로 선택한 항목의 경로 가져오기
  String? getLastSelectedPath() {
    return ref.read(lastSelectedPathProvider);
  }

  /// 선택된 모든 항목 목록 가져오기
  List<FileSystemItem> getAllSelectedItems() {
    return ref.read(fileSystemItemListProvider).where((item) => item.isSelected).toList();
  }

  /// 선택된 항목 개수 가져오기
  int getSelectedItemsCount() {
    return getAllSelectedItems().length;
  }

  /// 모든 선택 지우기
  void clearSelections() {
    ref.read(fileSystemItemListProvider.notifier).clearSelections();
    ref.read(lastSelectedPathProvider.notifier).state = null;
    ref.read(selectedFileItemProvider.notifier).state = null;
  }

  /// 특정 경로의 항목 선택
  void selectItem(String path) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);

    // 먼저 모든 선택 해제
    notifier.clearSelections();

    // 해당 항목 선택
    notifier.toggleItemSelection(path);

    // 선택된 항목 상태 업데이트
    final selectedItem = ref
        .read(fileSystemItemListProvider)
        .firstWhere((item) => item.path == path, orElse: () => null as FileSystemItem);

    ref.read(selectedFileItemProvider.notifier).state = selectedItem;
    ref.read(lastSelectedPathProvider.notifier).state = selectedItem.path;
  }

  /// Shift 키와 함께 범위 선택 처리
  void handleShiftSelection(FileSystemItem item, String lastSelectedPath) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);

    // 범위 선택 로직 실행
    notifier.toggleItemSelection(item.path, isShiftKeyPressed: true, lastSelectedPath: lastSelectedPath);

    // 선택 상태 업데이트
    ref.read(lastSelectedPathProvider.notifier).state = item.path;

    if (item.isSelected) {
      ref.read(selectedFileItemProvider.notifier).state = item;
    } else if (ref.read(selectedFileItemProvider)?.path == item.path) {
      ref.read(selectedFileItemProvider.notifier).state = null;
    }
  }

  /// Ctrl 키와 함께 개별 선택 처리
  void handleCtrlSelection(FileSystemItem item) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);

    // 개별 항목 토글
    notifier.toggleItemSelection(item.path);
    ref.read(lastSelectedPathProvider.notifier).state = item.path;

    // 선택 상태 업데이트
    if (!item.isSelected && ref.read(selectedFileItemProvider)?.path == item.path) {
      ref.read(selectedFileItemProvider.notifier).state = null;
    } else if (item.isSelected) {
      ref.read(selectedFileItemProvider.notifier).state = item;
    }
  }

  /// 단일 클릭 선택 처리 (일반 선택)
  void handleSingleSelection(FileSystemItem item) {
    final notifier = ref.read(fileSystemItemListProvider.notifier);
    final selectedItems = getAllSelectedItems();

    // 이미 선택된 항목을 다시 클릭한 경우 선택 해제
    if (item.isSelected && selectedItems.length == 1) {
      notifier.clearSelections();
      ref.read(lastSelectedPathProvider.notifier).state = null;
      ref.read(selectedFileItemProvider.notifier).state = null;
    } else {
      // 다른 항목을 선택한 경우, 기존 선택 해제 후 새 항목 선택
      notifier.clearSelections();
      notifier.toggleItemSelection(item.path);
      ref.read(lastSelectedPathProvider.notifier).state = item.path;
      ref.read(selectedFileItemProvider.notifier).state = item;
    }
  }

  /// 종합 항목 선택 처리 (Shift, Ctrl 키 지원)
  void handleItemSelection(FileSystemItem item, {bool isShiftKeyPressed = false, bool isCtrlKeyPressed = false}) {
    final lastSelectedPath = getLastSelectedPath();

    // Shift 키를 사용한 범위 선택
    if (isShiftKeyPressed && lastSelectedPath != null) {
      handleShiftSelection(item, lastSelectedPath);
      return;
    }

    // Ctrl 키를 사용한 다중 선택
    if (isCtrlKeyPressed) {
      handleCtrlSelection(item);
      return;
    }

    // 일반 단일 선택
    handleSingleSelection(item);
  }

  /// 항목 클릭 처리 (네비게이션 포함)
  Future<bool> handleItemClick(
    FileSystemItem item, {
    bool isShiftKeyPressed = false,
    bool isCtrlKeyPressed = false,
  }) async {
    // 디렉토리이고 수정자 키가 없으면 네비게이션 필요
    bool shouldNavigate = item.type == FileSystemItemType.directory && !isShiftKeyPressed && !isCtrlKeyPressed;

    if (!shouldNavigate) {
      // 네비게이션이 필요하지 않으면 선택만 처리
      handleItemSelection(item, isShiftKeyPressed: isShiftKeyPressed, isCtrlKeyPressed: isCtrlKeyPressed);
    }

    // 네비게이션이 필요한지 여부 반환 (외부에서 처리)
    return shouldNavigate;
  }
}

/// SelectionService 제공을 위한 Provider
final selectionServiceProvider = Provider<SelectionService>((ref) {
  return SelectionService(ref as WidgetRef);
});
