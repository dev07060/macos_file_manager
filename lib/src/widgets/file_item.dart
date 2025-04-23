import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/file_constants.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/theme_provider.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/base_event.dart';
import 'package:macos_file_manager/src/drag_drop_items_event.dart';
import 'package:macos_file_manager/src/navigation_event.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class FileItem extends HookConsumerWidget with BaseEvent, DragDropItemsEvent, NavigationEvent {
  const FileItem({super.key, required this.item});

  final FileSystemItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);
    final isSelected = item.isSelected;
    final focusNode = useFocusNode();

    // 테마 상태 감시
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    Widget itemWidget = Material(
      // 테마에 맞는 선택 배경색 적용
      color:
          isSelected
              ? (isDarkMode ? Colors.blue.shade700.withOpacity(0.2) : Colors.blue.withOpacity(0.1))
              : Colors.transparent,
      child: MouseRegion(
        onEnter: (_) => isHovered.value = true,
        onExit: (_) => isHovered.value = false,
        child: InkWell(
          // 테마에 맞는 호버 색상 적용
          hoverColor: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.03),
          onTap: () {
            final isShiftPressed =
                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shift) ||
                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);

            final isCtrlPressed =
                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.control) ||
                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight);

            handleItemClick(ref, item, isShiftKeyPressed: isShiftPressed, isCtrlKeyPressed: isCtrlPressed);
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      item.type == FileSystemItemType.directory ? Icons.folder : FileConstants.getFileIcon(item.name),
                      // 폴더 아이콘은 항상 노란색, 파일 아이콘은 테마에 맞게 조정
                      color:
                          item.type == FileSystemItemType.directory
                              ? Colors.amber.shade800
                              : isDarkMode
                              ? Colors.blueGrey.shade300
                              : Colors.blueGrey,
                      size: 24,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          // 테마에 맞는 텍스트 색상
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.type == FileSystemItemType.directory && isHovered.value)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(searchQueryProvider.notifier).state = null;
                          ref.read(treeViewNotifierProvider.notifier).showTreeView(item.path);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            // 테마에 맞는 배경색
                            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.account_tree,
                            size: 16,
                            // 테마에 맞는 아이콘 색상
                            color: isDarkMode ? Colors.grey.shade300 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.shift ||
            event.logicalKey == LogicalKeyboardKey.control ||
            event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: _buildDraggableEntity(
        context,
        ref,
        item.type == FileSystemItemType.directory ? _buildDroppableFolder(context, ref, itemWidget) : itemWidget,
      ),
    );
  }

  // Allow not only files but also directories to be created as drag items
  Future<DragItem?> createDragItemForEntity(FileSystemItem entity) async {
    final dragItem = DragItem(
      localData: {
        'paths': [entity.path],
      },
      suggestedName: entity.name,
    );
    dragItem.add(Formats.plainText(entity.path));
    return dragItem;
  }

  // _buildDraggableFile → renamed and used as _buildDraggableEntity
  Widget _buildDraggableEntity(BuildContext context, WidgetRef ref, Widget child) {
    return DragItemWidget(
      allowedOperations: () => [DropOperation.copy, DropOperation.move],
      canAddItemToExistingSession: true,
      dragItemProvider: (request) async {
        final selectedItems = ref.read(fileSystemItemListProvider).where((i) => i.isSelected).toList();
        if (!selectedItems.contains(item)) {
          return createDragItemForEntity(item);
        }
        final allPaths = selectedItems.map((i) => i.path).toList();
        if (allPaths.isEmpty) return null;
        final dragItem = DragItem(
          localData: {'paths': allPaths},
          suggestedName: allPaths.length == 1 ? item.name : '${allPaths.length} items',
        );
        dragItem.add(Formats.plainText(allPaths.join('\n')));
        return dragItem;
      },
      child: DraggableWidget(child: child),
    );
  }

  // Make folder items accept drops
  Widget _buildDroppableFolder(BuildContext context, WidgetRef ref, Widget child) {
    return DropRegion(
      formats: const [...Formats.standardFormats],
      hitTestBehavior: HitTestBehavior.translucent,
      onDropOver: (event) {
        // Show visual indicator that this is a drop target
        return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
      },
      onPerformDrop: (event) async {
        await handleFileDrop(ref, context, event, item.path);
      },
      child: child,
    );
  }
}
