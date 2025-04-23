import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/theme_provider.dart';

class FileHeader extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // 테마 모드 상태 확인
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      // 테마에 맞는 구분선 색상 적용
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
        // 테마에 맞는 배경색 적용
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Icon(
            item.type == FileSystemItemType.directory
                ? Icons.folder
                : isImage
                ? Icons.image
                : Icons.insert_drive_file,
            size: 48,
            // 파일 타입별 아이콘 색상은 유지, 일부 조정
            color:
                item.type == FileSystemItemType.directory
                    ? Colors
                        .amber
                        .shade800 // 폴더는 항상 노란색
                    : isImage
                    ? (isDarkMode ? Colors.blue.shade300 : Colors.blue) // 이미지는 파란색 조정
                    : (isDarkMode ? Colors.blueGrey.shade300 : Colors.blueGrey), // 일반 파일
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
                  child: _buildFileName(context, isDarkMode),
                ),
                Text(
                  item.path,
                  // 테마에 맞는 경로 텍스트 색상
                  style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isImage)
            IconButton(
              icon: Icon(
                isInfoCollapsed ? Icons.expand_more : Icons.expand_less,
                // 테마에 맞는 아이콘 색상
                color: Theme.of(context).iconTheme.color,
              ),
              tooltip: isInfoCollapsed ? 'Show information' : 'Hide information',
              onPressed: onCollapseToggle,
            ),
        ],
      ),
    );
  }

  Widget _buildFileName(BuildContext context, bool isDarkMode) {
    if (isEditingFilename.value) {
      return TextField(
        controller: textEditingController,
        focusNode: focusNode,
        // 테마에 맞는 텍스트 스타일
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          // 테마에 맞는 테두리 색상
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
          ),
          // 테마에 맞는 배경색
          fillColor:
              Theme.of(context).inputDecorationTheme.fillColor ?? (isDarkMode ? Colors.grey.shade800 : Colors.white),
          filled: true,
          suffixIcon: IconButton(
            icon: Icon(
              Icons.check,
              // 테마에 맞는 아이콘 색상
              color: Theme.of(context).iconTheme.color,
            ),
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
      // 테마에 맞는 텍스트 색상
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
      overflow: TextOverflow.ellipsis,
    );
  }
}
