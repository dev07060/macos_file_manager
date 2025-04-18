import 'package:flutter/material.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/utils/file_utils.dart';

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
