import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/providers/theme_provider.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/base_event.dart';
import 'package:macos_file_manager/src/base_state.dart';
import 'package:macos_file_manager/src/file_operation_event.dart';
import 'package:macos_file_manager/src/script_event.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/node/directory_tree_view.dart';
import 'package:macos_file_manager/src/widgets/file_header.dart';
import 'package:macos_file_manager/src/widgets/file_information.dart';
import 'package:macos_file_manager/src/widgets/hover_builder.dart';
import 'package:macos_file_manager/src/widgets/image_controls.dart';
import 'package:macos_file_manager/src/widgets/image_preview.dart';
import 'package:macos_file_manager/utils/file_utils.dart';
import 'package:macos_file_manager/utils/image_utils.dart';

class FileDetails extends HookConsumerWidget with BaseState, BaseEvent, FileOperationEvent, ScriptEvent {
  FileDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItem = selectedFileItem(ref);
    final treeViewState = ref.watch(treeViewNotifierProvider);
    final treeViewProvider = ref.read(treeViewNotifierProvider.notifier);
    final textEditingController = useTextEditingController();
    final focusNode = useFocusNode();

    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    // Individual state management
    final isInfoCollapsed = useState(false);
    final isCropping = useState(false);
    final isEditingFilename = useState(false);

    final rotationAngle = useState(0);
    final lastSavedAngle = useState(0);
    final imageKey = useState(0);

    // Function to handle crop completion after image cropping
    Future<void> handleCropComplete() async {
      // Clear image cache
      imageCache.clear();
      imageCache.clearLiveImages();

      // Increase the image key to trigger refresh
      imageKey.value++;
      isCropping.value = false;
    }

    useEffect(() {
      if (selectedItem != null && FileUtils.isImageFile(selectedItem)) {
        // Load the saved rotation angle
        ImageUtils.getCurrentRotation(selectedItem.path).then((angle) {
          rotationAngle.value = angle;
          lastSavedAngle.value = angle;
        });
      }
      return null;
    }, [selectedItem]);

    // Set up focus listener
    useEffect(() {
      void onFocusChange() {
        if (!focusNode.hasFocus && isEditingFilename.value) {
          isEditingFilename.value = false;
        }
      }

      focusNode.addListener(onFocusChange);
      return () => focusNode.removeListener(onFocusChange);
    }, [focusNode]);

    // Handle the tree view state
    return treeViewState.when(
      data: (state) {
        // If the tree view is active, show the directory tree regardless of the selected item
        if (state.isTreeViewActive) {
          return DirectoryTreeView(rootPath: state.rootPath!);
        }

        // If the tree view is inactive, check if a file is selected
        if (selectedItem == null) {
          return Center(
            child: Text(
              'No file selected',
              style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
            ),
          );
        }
        final isShellScript = FileUtils.isShellScript(selectedItem);
        final isImage = FileUtils.isImageFile(selectedItem);

        // Show the file details
        return MouseRegion(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
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
                    // Show the tree view button only for directories
                    if (selectedItem.type == FileSystemItemType.directory)
                      Positioned(right: 16, top: 8, child: _buildTreeViewButton(ref, selectedItem, isDarkMode)),
                  ],
                ),
                if (isShellScript) ...[
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                        backgroundColor:
                            isDarkMode ? Colors.blue.withValues(alpha: .1) : Colors.blue.withValues(alpha: .05),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
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
                                  Divider(height: 1, color: Theme.of(context).dividerColor),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Preview',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.titleLarge?.color,
                                          ),
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
      loading:
          () => Center(
            child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700),
            ),
          ),
      error:
          (error, stack) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error', style: TextStyle(color: isDarkMode ? Colors.red.shade300 : Colors.red)),
                TextButton(child: const Text('go back'), onPressed: () => treeViewProvider.hideTreeView()),
              ],
            ),
          ),
    );
  }

  /// Builds the tree view button for the given [item].
  Widget _buildTreeViewButton(WidgetRef ref, FileSystemItem item, bool isDarkMode) {
    return HoverBuilder(
      builder: (context, isHovered) {
        if (!isHovered) return const SizedBox();

        return IconButton(
          icon: Icon(Icons.account_tree, color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700),
          tooltip: 'Show Directory Tree',
          onPressed: () {
            ref.read(treeViewNotifierProvider.notifier).showTreeView(item.path);
          },
        );
      },
    );
  }
}
