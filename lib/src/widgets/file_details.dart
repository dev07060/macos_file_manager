part of '../home.dart';

class FileDetails extends HookConsumerWidget with HomeState, HomeEvent {
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

  // 실행 메서드 구현
  Future<void> _executeScript(BuildContext context, WidgetRef ref, FileSystemItem item) async {
    // 보안 경고 다이얼로그 표시
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('보안 경고'),
            content: const Text('쉘 스크립트를 실행하면 시스템에 영향을 줄 수 있습니다. 신뢰할 수 있는 스크립트만 실행하세요.\n\n계속하시겠습니까?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('실행', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (shouldProceed != true) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text('Running shell script...')]),
          ),
    );

    final result = await executeShellScript(item.path, context);

    // 다이얼로그 닫기
    Navigator.of(context).pop();

    // 결과 표시
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(result['success'] ? '실행 성공' : '실행 실패'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (result['success']) Text('종료 코드: ${result['exitCode'] ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  const Text('출력:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                    width: double.infinity,
                    child: SelectableText(
                      result['output'] ?? '출력 없음',
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    ),
                  ),
                  if (result['error'] != null && result['error'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('오류:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                      width: double.infinity,
                      child: SelectableText(
                        result['error'] ?? '',
                        style: const TextStyle(color: Colors.red, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('닫기'))],
          ),
    );
  }

  // image checker
  bool _isImageFile(FileSystemItem item) {
    if (item.type == FileSystemItemType.file) {
      final extension = item.fileExtension.toLowerCase();
      return _imageExtensions.contains(extension);
    }
    return false;
  }

  bool _isShellScript(FileSystemItem item) {
    if (item.type == FileSystemItemType.file) {
      final extension = item.fileExtension.toLowerCase();
      return extension == 'sh';
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItem = selectedFileItem(ref);

    // isInfoCollapsed state
    final isInfoCollapsed = useState(false);

    // Editing state for filename
    final isEditingFilename = useState(false);
    final textEditingController = useTextEditingController();
    final focusNode = useFocusNode();

    // Set up text controller when selected item changes
    useEffect(() {
      if (selectedItem != null) {
        textEditingController.text = selectedItem.name;
      }
      return null;
    }, [selectedItem]);

    // Set up focus listener to exit editing mode when focus is lost
    useEffect(() {
      void onFocusChange() {
        if (!focusNode.hasFocus && isEditingFilename.value) {
          isEditingFilename.value = false;
        }
      }

      focusNode.addListener(onFocusChange);
      return () => focusNode.removeListener(onFocusChange);
    }, [focusNode]);

    if (selectedItem == null) {
      return const Center(child: Text('No file selected', style: TextStyle(fontSize: 16, color: Colors.grey)));
    }

    final isShellScript = _isShellScript(selectedItem);
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
                      // Editable filename
                      GestureDetector(
                        onTap: () {
                          if (!isEditingFilename.value) {
                            isEditingFilename.value = true;
                            // Ensure focus in the next frame after state changes
                            Future.microtask(() => focusNode.requestFocus());
                          }
                        },
                        child:
                            isEditingFilename.value
                                ? TextField(
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
                                        renameFileSystemItem(ref, selectedItem, textEditingController.text, context);
                                        isEditingFilename.value = false;
                                      },
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    renameFileSystemItem(ref, selectedItem, value, context);
                                    isEditingFilename.value = false;
                                  },
                                )
                                : Text(
                                  selectedItem.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                      ),
                      Text(
                        selectedItem.path,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isShellScript) ...[
                  // 스크립트 실행 섹션
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // 실행 버튼
                        TextButton(
                          child: const Text('Run .sh'),
                          onPressed: () => _executeScript(context, ref, selectedItem),
                        ),
                      ],
                    ),
                  ),
                ],

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
