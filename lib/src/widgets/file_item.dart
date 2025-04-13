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
      child: Material(
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
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'svg':
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
