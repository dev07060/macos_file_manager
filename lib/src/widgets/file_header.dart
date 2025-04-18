import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/utils/file_utils.dart';
import 'package:macos_file_manager/utils/image_utils.dart';

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

// lib/src/widgets/file_details/widgets/file_information_widget.dart

class FileInformationWidget extends StatelessWidget {
  final FileSystemItem item;

  const FileInformationWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoItem(
            'Type',
            item.type == FileSystemItemType.directory ? 'Directory' : 'File (${item.fileExtension})',
          ),
          _buildInfoItem('Size', item.formattedSize),
          if (item.type == FileSystemItemType.directory) _buildInfoItem('Contents', item.subItemCount.formattedCount),
          _buildInfoItem('Created', FileUtils.formatDate(item.createdAt)),
          _buildInfoItem('Modified', FileUtils.formatDate(item.modifiedAt)),
          _buildInfoItem('Location', FileUtils.getParentPath(item.path)),
          if (item.type == FileSystemItemType.file)
            _buildInfoItem('Extension', item.fileExtension.isEmpty ? 'None' : item.fileExtension),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}

class ImageControlsWidget extends StatelessWidget {
  final ValueNotifier<int> rotationAngle;
  final ValueNotifier<bool> isCropping;
  final ValueNotifier<int> lastSavedAngle;
  final String imagePath;
  final ValueNotifier<int> imageKey;

  final Function()? onImageSaved;

  const ImageControlsWidget({
    super.key,
    required this.rotationAngle,
    required this.isCropping,
    required this.lastSavedAngle,
    required this.imagePath,
    required this.imageKey,
    this.onImageSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentedButton(
              icon: const Icon(Icons.rotate_left, size: 20),
              tooltipText: 'rotate left 90°',
              onPressed:
                  isCropping.value
                      ? null
                      : () {
                        // 반시계 방향 (왼쪽) 회전
                        int newAngle = (rotationAngle.value - 90) % 360;
                        if (newAngle < 0) newAngle += 360;
                        rotationAngle.value = newAngle;
                        log('왼쪽 회전: ${rotationAngle.value}');
                      },
              isFirst: true,
            ),
            _buildSegmentedButton(
              icon: const Icon(Icons.rotate_right, size: 20),
              tooltipText: 'rotate right 90°',
              onPressed:
                  isCropping.value
                      ? null
                      : () {
                        // 시계 방향 (오른쪽) 회전
                        rotationAngle.value = (rotationAngle.value + 90) % 360;
                        log('오른쪽 회전: ${rotationAngle.value}');
                      },
            ),
            _buildSegmentedButton(
              icon: const Icon(Icons.crop, size: 20),
              tooltipText: 'crop image',
              onPressed: () {
                isCropping.value = !isCropping.value;
              },
            ),
            _buildSegmentedButton(
              icon: const Icon(Icons.save, size: 20),
              tooltipText: 'save rotated image',
              onPressed:
                  isCropping.value || rotationAngle.value == lastSavedAngle.value
                      ? null
                      : () async {
                        await ImageUtils.rotateAndSaveImage(imagePath, rotationAngle.value, context);
                        lastSavedAngle.value = rotationAngle.value;
                        rotationAngle.value = 0;

                        // 이미지 저장 후 새로고침
                        if (onImageSaved != null) {
                          onImageSaved!();
                        }
                      },
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedButton({
    required Widget icon,
    required String tooltipText,
    required VoidCallback? onPressed,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: isFirst ? BorderSide.none : BorderSide(color: Colors.grey.shade400),
          right: isLast ? BorderSide.none : BorderSide(color: Colors.grey.shade400),
        ),
      ),
      child: IconButton(
        icon: icon,
        tooltip: tooltipText,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
          backgroundColor: onPressed == null ? Colors.grey.shade300 : null,
        ),
      ),
    );
  }
}
