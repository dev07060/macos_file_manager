import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/src/home_event.dart';
import 'package:macos_file_manager/src/home_state.dart';
import 'package:macos_file_manager/src/widgets/file_header.dart';
import 'package:macos_file_manager/src/widgets/image_preview.dart';
import 'package:macos_file_manager/utils/dialog_utils.dart';
import 'package:macos_file_manager/utils/file_utils.dart';

class FileDetails extends HookConsumerWidget with HomeState, HomeEvent {
  FileDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItem = selectedFileItem(ref);

    // 개별적으로 상태 관리
    final isInfoCollapsed = useState(false);
    final rotationAngle = useState(0);
    final isEditingFilename = useState(false);
    final lastSavedAngle = useState(0);
    final isCropping = useState(false);
    final textEditingController = useTextEditingController();
    final focusNode = useFocusNode();

    // 초기 설정
    useEffect(() {
      if (selectedItem != null) {
        textEditingController.text = selectedItem.name;
      }
      return null;
    }, [selectedItem]);

    // 포커스 리스너 설정
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

    final isShellScript = FileUtils.isShellScript(selectedItem);
    final isImage = FileUtils.isImageFile(selectedItem);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FileHeader(
            item: selectedItem,
            isImage: isImage,
            isInfoCollapsed: isInfoCollapsed.value,
            onCollapseToggle: () {
              isInfoCollapsed.value = !isInfoCollapsed.value;
            },
            isEditingFilename: isEditingFilename,
            textEditingController: textEditingController,
            focusNode: focusNode,
            onRename: (newName) {
              renameFileSystemItem(ref, selectedItem, newName, context);
            },
          ),
          if (isShellScript) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                child: const Text('Run .sh'),
                onPressed: () => _executeScript(context, ref, selectedItem),
              ),
            ),
          ],
          Expanded(
            child:
                isImage && isInfoCollapsed.value
                    ? Column(
                      children: [
                        Expanded(
                          child: ClipRect(
                            // ClipRect 추가
                            child: ImagePreview(
                              imagePath: selectedItem.path,
                              isFullView: true,
                              rotationAngle: rotationAngle,
                              isCropping: isCropping,
                            ),
                          ),
                        ),
                        ImageControlsWidget(
                          rotationAngle: rotationAngle,
                          isCropping: isCropping,
                          lastSavedAngle: lastSavedAngle,
                          imagePath: selectedItem.path,
                        ),
                      ],
                    )
                    : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FileInformationWidget(item: selectedItem),
                          if (isImage) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  ImagePreview(
                                    imagePath: selectedItem.path,
                                    isFullView: false,
                                    rotationAngle: rotationAngle,
                                    isCropping: isCropping,
                                  ),
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

  Future<void> _executeScript(BuildContext context, WidgetRef ref, FileSystemItem item) async {
    final shouldProceed = await DialogUtils.showShellScriptWarning(context);
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
    Navigator.of(context).pop();

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
}
