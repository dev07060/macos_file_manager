import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/theme_provider.dart';
import 'package:macos_file_manager/utils/file_utils.dart';

class FileInformationWidget extends ConsumerWidget {
  final FileSystemItem item;

  const FileInformationWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check theme mode state
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              // Text color according to theme
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            'Type',
            item.type == FileSystemItemType.directory ? 'Directory' : 'File (${item.fileExtension})',
            isDarkMode,
            context,
          ),
          _buildInfoItem('Size', item.formattedSize, isDarkMode, context),
          if (item.type == FileSystemItemType.directory)
            _buildInfoItem('Contents', item.subItemCount.formattedCount, isDarkMode, context),
          _buildInfoItem('Created', FileUtils.formatDate(item.createdAt), isDarkMode, context),
          _buildInfoItem('Modified', FileUtils.formatDate(item.modifiedAt), isDarkMode, context),
          _buildInfoItem('Location', FileUtils.getParentPath(item.path), isDarkMode, context),
          if (item.type == FileSystemItemType.file)
            _buildInfoItem('Extension', item.fileExtension.isEmpty ? 'None' : item.fileExtension, isDarkMode, context),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDarkMode, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                // Label color according to theme
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                // Value color according to theme
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
