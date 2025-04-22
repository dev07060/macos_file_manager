import 'package:flutter/material.dart';
import 'package:macos_file_manager/model/file_system_item.dart';

class FileHeader extends StatelessWidget {
  final FileSystemItem item;
  final bool isImage;
  final bool isInfoCollapsed;
  final VoidCallback onCollapseToggle;
  final ValueNotifier<bool> isEditingFilename;
  final TextEditingController textEditingController;
  final FocusNode focusNode;
  final Function(String) onRename;

  const FileHeader({
    super.key,
    required this.item,
    required this.isImage,
    required this.isInfoCollapsed,
    required this.onCollapseToggle,
    required this.isEditingFilename,
    required this.textEditingController,
    required this.focusNode,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Icon(
            item.type == FileSystemItemType.directory
                ? Icons.folder
                : isImage
                ? Icons.image
                : Icons.insert_drive_file,
            size: 48,
            color:
                item.type == FileSystemItemType.directory
                    ? Colors.amber.shade800
                    : isImage
                    ? Colors.blue
                    : Colors.blueGrey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (!isEditingFilename.value) {
                      isEditingFilename.value = true;
                      textEditingController.text = item.name;
                      Future.microtask(() => focusNode.requestFocus());
                    }
                  },
                  child: _buildFileName(),
                ),
                Text(
                  item.path,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isImage)
            IconButton(
              icon: Icon(isInfoCollapsed ? Icons.expand_more : Icons.expand_less),
              tooltip: isInfoCollapsed ? 'Show information' : 'Hide information',
              onPressed: onCollapseToggle,
            ),
        ],
      ),
    );
  }

  Widget _buildFileName() {
    if (isEditingFilename.value) {
      return TextField(
        controller: textEditingController,
        focusNode: focusNode,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              onRename(textEditingController.text);
              isEditingFilename.value = false;
            },
          ),
        ),
        onSubmitted: (value) {
          onRename(value);
          isEditingFilename.value = false;
        },
      );
    }
    return Text(
      item.name,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      overflow: TextOverflow.ellipsis,
    );
  }
}
