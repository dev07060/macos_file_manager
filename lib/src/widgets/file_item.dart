part of '../home.dart';

class FileItem extends HookConsumerWidget with HomeEvent {
  const FileItem({super.key, required this.item});

  final FileSystemItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = item.isSelected;
    final selectedCount = ref.watch(selectedItemsCountProvider);

    // Use FocusNode to detect keyboard events
    final focusNode = useFocusNode();

    // Widget for the file or folder item
    Widget itemWidget = Material(
      color: isSelected ? Colors.blue.withValues(alpha: .1) : Colors.transparent,
      child: InkWell(
        onTap: () {
          // Get modifier key states
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                item.type == FileSystemItemType.directory ? Icons.folder : _getFileIcon(item.name),
                color: item.type == FileSystemItemType.directory ? Colors.amber.shade800 : Colors.blueGrey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Only show check icon if multiple items are selected
              if (isSelected && selectedCount > 1) const Icon(Icons.check_circle, color: Colors.blue, size: 16),
            ],
          ),
        ),
      ),
    );

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        // Handle key events
        if (event.logicalKey == LogicalKeyboardKey.shift ||
            event.logicalKey == LogicalKeyboardKey.control ||
            event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child:
          item.type == FileSystemItemType.directory
              ? _buildDroppableFolder(context, ref, itemWidget)
              : _buildDraggableFile(context, ref, itemWidget),
    );
  }

  // Make file items draggable
  Widget _buildDraggableFile(BuildContext context, WidgetRef ref, Widget child) {
    return DragItemWidget(
      allowedOperations: () => [DropOperation.copy, DropOperation.move],
      canAddItemToExistingSession: true,
      dragItemProvider: (request) async {
        // Get all selected items
        final selectedItems = ref.read(fileSystemItemListProvider).where((i) => i.isSelected).toList();

        // If this item is not among selected items, only drag this item
        if (!selectedItems.contains(item)) {
          return _createDragItemForFile(item);
        }

        // Otherwise, create a drag item for all selected files
        final allPaths = selectedItems.where((i) => i.type == FileSystemItemType.file).map((i) => i.path).toList();

        if (allPaths.isEmpty) {
          return null;
        }

        final dragItem = DragItem(
          localData: {'paths': allPaths},
          suggestedName: allPaths.length == 1 ? item.name : '${allPaths.length} files',
        );

        // Add plain text format with all file paths
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
        await _handleFileDrop(ref, context, event);
      },
      child: child,
    );
  }

  Future<DragItem?> _createDragItemForFile(FileSystemItem fileItem) async {
    if (fileItem.type != FileSystemItemType.file) {
      return null;
    }

    final dragItem = DragItem(
      localData: {
        'paths': [fileItem.path],
      },
      suggestedName: fileItem.name,
    );

    // Add plain text format with file path
    dragItem.add(Formats.plainText(fileItem.path));

    return dragItem;
  }

  Future<void> _handleFileDrop(WidgetRef ref, BuildContext context, PerformDropEvent event) async {
    // Get the target directory path
    final targetDirectoryPath = item.path;

    // Get all items from the drop session
    for (final dropItem in event.session.items) {
      final reader = dropItem.dataReader;
      if (reader == null) continue;

      try {
        // Try to get paths from local data first
        if (dropItem.localData != null && dropItem.localData is Map) {
          final Map localData = dropItem.localData as Map;
          if (localData.containsKey('paths')) {
            final List<String> paths = List<String>.from(localData['paths']);
            await _moveFiles(ref, context, paths, targetDirectoryPath);
            continue;
          }
        }

        // If no local data, try to read as plain text (might contain paths)
        if (reader.canProvide(Formats.plainText)) {
          final text = await reader.getSuggestedName();
          final paths = text!.split('\n').where((p) => p.isNotEmpty).toList();
          await _moveFiles(ref, context, paths, targetDirectoryPath);
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process dropped item: $e')));
      }
    }

    // Refresh the current directory to show changes
    final currentDir = ref.read(currentDirectoryProvider);
    await ref.read(fileSystemItemListProvider.notifier).loadDirectory(currentDir);
  }

  Future<void> _moveFiles(WidgetRef ref, BuildContext context, List<String> sourcePaths, String targetDirPath) async {
    if (sourcePaths.isEmpty) return;

    try {
      for (final sourcePath in sourcePaths) {
        final sourceFile = File(sourcePath);
        if (await sourceFile.exists()) {
          final fileName = path.basename(sourcePath);
          final destinationPath = path.join(targetDirPath, fileName);

          // Check if destination already exists
          final destinationFile = File(destinationPath);
          if (await destinationFile.exists()) {
            // Ask for confirmation to overwrite
            final shouldOverwrite = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('파일이 이미 존재합니다'),
                    content: Text('$fileName 파일이 이미 존재합니다. 덮어쓰시겠습니까?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('덮어쓰기', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
            );

            if (shouldOverwrite != true) continue;
          }

          // Move file
          await sourceFile.rename(destinationPath);
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sourcePaths.length == 1 ? '파일을 이동했습니다' : '${sourcePaths.length}개의 파일을 이동했습니다')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('파일 이동 중 오류가 발생했습니다: $e')));
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'sh':
        return Icons.terminal;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'svg':
      case 'heic':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.video_file;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return Icons.description;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }
}
