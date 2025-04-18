import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/home_event.dart';
import 'package:macos_file_manager/src/home_state.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/directory_tree_view.dart';
import 'package:macos_file_manager/src/widgets/file_header.dart';
import 'package:macos_file_manager/src/widgets/hover_builder.dart';
import 'package:macos_file_manager/src/widgets/image_preview.dart';
import 'package:macos_file_manager/utils/file_utils.dart';
import 'package:macos_file_manager/utils/image_utils.dart';

class FileDetails extends HookConsumerWidget with HomeState, HomeEvent {
  FileDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItem = selectedFileItem(ref);
    final treeViewState = ref.watch(treeViewNotifierProvider);

    final imageKey = useState(0); // 이미지 새로고침을 위한 키 추가

    // 개별적으로 상태 관리
    final isInfoCollapsed = useState(false);
    final rotationAngle = useState(0);
    final isEditingFilename = useState(false);
    final lastSavedAngle = useState(0);
    final isCropping = useState(false);
    final textEditingController = useTextEditingController();
    final focusNode = useFocusNode();

    // 이미지 크롭 완료 후 처리하는 함수
    Future<void> handleCropComplete() async {
      // 이미지 캐시 클리어
      imageCache.clear();
      imageCache.clearLiveImages();

      // 이미지 키 증가시켜 새로고침
      imageKey.value++;
      isCropping.value = false;
    }

    useEffect(() {
      if (selectedItem != null && FileUtils.isImageFile(selectedItem)) {
        // 저장된 회전 상태 로드
        ImageUtils.getCurrentRotation(selectedItem.path).then((angle) {
          rotationAngle.value = angle;
          lastSavedAngle.value = angle;
        });
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

    // 트리 뷰 상태 처리
    return treeViewState.when(
      data: (state) {
        // 트리 뷰가 활성화되어 있으면 선택된 아이템 유무와 관계없이 트리 뷰 표시
        if (state.isTreeViewActive) {
          return DirectoryTreeView(rootPath: state.rootPath!);
        }

        // 트리 뷰가 비활성화 상태일 때만 선택된 아이템 체크
        if (selectedItem == null) {
          return const Center(child: Text('No file selected', style: TextStyle(fontSize: 16, color: Colors.grey)));
        }
        final isShellScript = FileUtils.isShellScript(selectedItem);
        final isImage = FileUtils.isImageFile(selectedItem);

        // 기존 파일 상세 정보 표시
        return MouseRegion(
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
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
                    // 디렉토리인 경우에만 트리 뷰 버튼 표시
                    if (selectedItem.type == FileSystemItemType.directory)
                      Positioned(right: 16, top: 8, child: _buildTreeViewButton(ref, selectedItem)),
                  ],
                ),
                if (isShellScript) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      child: const Text('Run .sh'),
                      onPressed: () => executeScript(context, ref, selectedItem),
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
                                  child: ImagePreview(
                                    imagePath: selectedItem.path,
                                    isFullView: true,
                                    rotationAngle: rotationAngle,
                                    isCropping: isCropping,
                                    imageKey: imageKey,
                                    onCropComplete: handleCropComplete,
                                  ),
                                ),
                              ),
                              ImageControlsWidget(
                                rotationAngle: rotationAngle,
                                isCropping: isCropping,
                                lastSavedAngle: lastSavedAngle,
                                imagePath: selectedItem.path,
                                imageKey: imageKey,
                                onImageSaved: handleCropComplete,
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
                                        const Text(
                                          'Preview',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 16),
                                        ImagePreview(
                                          imagePath: selectedItem.path,
                                          isFullView: false,
                                          rotationAngle: rotationAngle,
                                          isCropping: isCropping,
                                          imageKey: imageKey,
                                          onCropComplete: handleCropComplete,
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildTreeViewButton(WidgetRef ref, FileSystemItem item) {
    return HoverBuilder(
      builder: (context, isHovered) {
        if (!isHovered) return const SizedBox();

        return IconButton(
          icon: const Icon(Icons.account_tree),
          tooltip: 'Show Directory Tree',
          onPressed: () {
            ref.read(treeViewNotifierProvider.notifier).showTreeView(item.path);
          },
        );
      },
    );
  }
}
