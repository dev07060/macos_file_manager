part of '../home.dart';

class FileDetails extends HookConsumerWidget with HomeState {
  const FileDetails({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItem = selectedFileItem(ref);

    if (selectedItem == null) {
      return const Center(child: Text('No file selected', style: TextStyle(fontSize: 16, color: Colors.grey)));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selectedItem.type == FileSystemItemType.directory ? Icons.folder : Icons.insert_drive_file,
                size: 48,
                color: selectedItem.type == FileSystemItemType.directory ? Colors.amber.shade800 : Colors.blueGrey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedItem.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      selectedItem.path,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoItem(
            'Type',
            selectedItem.type == FileSystemItemType.directory ? 'Directory' : 'File (${selectedItem.fileExtension})',
          ),
          _buildInfoItem('Size', selectedItem.formattedSize),
          _buildInfoItem('Created', _formatDate(selectedItem.createdAt)),
          _buildInfoItem('Modified', _formatDate(selectedItem.modifiedAt)),
          _buildInfoItem('Location', _getParentPath(selectedItem.path)),
          if (selectedItem.type == FileSystemItemType.file)
            _buildInfoItem('Extension', selectedItem.fileExtension.isEmpty ? 'None' : selectedItem.fileExtension),
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

  String _formatDate(DateTime dateTime) {
    final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final time = '${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}';
    return '$date $time';
  }

  String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }

  String _getParentPath(String filePath) {
    final lastSeparator = filePath.lastIndexOf(Platform.pathSeparator);
    if (lastSeparator <= 0) return filePath;
    return filePath.substring(0, lastSeparator);
  }
}
