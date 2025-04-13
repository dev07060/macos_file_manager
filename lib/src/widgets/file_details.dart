part of '../home.dart';

class FileDetails extends HookConsumerWidget with HomeState {
  const FileDetails({super.key});

  // file format list
  final List<String> _imageExtensions = const [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
    'tiff',
    'tif',
  ];

  // image checker
  bool _isImageFile(FileSystemItem item) {
    if (item.type == FileSystemItemType.file) {
      final extension = item.fileExtension.toLowerCase();
      return _imageExtensions.contains(extension);
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItem = selectedFileItem(ref);

    // isInfoCollapsed state
    final isInfoCollapsed = useState(false);

    if (selectedItem == null) {
      return const Center(child: Text('No file selected', style: TextStyle(fontSize: 16, color: Colors.grey)));
    }

    final isImage = _isImageFile(selectedItem);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                Icon(
                  selectedItem.type == FileSystemItemType.directory
                      ? Icons.folder
                      : isImage
                      ? Icons.image
                      : Icons.insert_drive_file,
                  size: 48,
                  color:
                      selectedItem.type == FileSystemItemType.directory
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
                if (isImage)
                  IconButton(
                    icon: Icon(isInfoCollapsed.value ? Icons.expand_more : Icons.expand_less),
                    tooltip: isInfoCollapsed.value ? 'Show information' : 'Hide information',
                    onPressed: () {
                      isInfoCollapsed.value = !isInfoCollapsed.value;
                    },
                  ),
              ],
            ),
          ),

          Expanded(
            child:
                isImage && isInfoCollapsed.value
                    ? _buildFullImagePreview(selectedItem.path)
                    : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Information Section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                _buildInfoItem(
                                  'Type',
                                  selectedItem.type == FileSystemItemType.directory
                                      ? 'Directory'
                                      : 'File (${selectedItem.fileExtension})',
                                ),
                                _buildInfoItem('Size', selectedItem.formattedSize),
                                // Show subItemCount only for directories
                                if (selectedItem.type == FileSystemItemType.directory)
                                  _buildInfoItem('Contents', selectedItem.subItemCount.formattedCount),
                                _buildInfoItem('Created', _formatDate(selectedItem.createdAt)),
                                _buildInfoItem('Modified', _formatDate(selectedItem.modifiedAt)),
                                _buildInfoItem('Location', _getParentPath(selectedItem.path)),
                                if (selectedItem.type == FileSystemItemType.file)
                                  _buildInfoItem(
                                    'Extension',
                                    selectedItem.fileExtension.isEmpty ? 'None' : selectedItem.fileExtension,
                                  ),
                              ],
                            ),
                          ),

                          // Image Preview Section
                          if (isImage) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  _buildImagePreview(selectedItem.path),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // Image Preview(folded)
  Widget _buildImagePreview(String imagePath) {
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxHeight: 300),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Text('Unable to load image', style: TextStyle(color: Colors.red)));
        },
      ),
    );
  }

  // Image Preview(expanded)
  Widget _buildFullImagePreview(String imagePath) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Text('Unable to load image', style: TextStyle(color: Colors.red)));
        },
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
