import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/directory_node.dart';

// 트리 뷰의 최대 넓이를 추적하는 provider
final treeWidthProvider = StateProvider<double>((ref) => 300.0); // 기본값으로 300 지정

class DirectoryTreeView extends ConsumerWidget {
  final String rootPath;

  const DirectoryTreeView({super.key, required this.rootPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeState = ref.watch(treeViewNotifierProvider);
    final treeWidth = ref.watch(treeWidthProvider);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더는 고정
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Directory Tree: $rootPath'),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(treeViewNotifierProvider.notifier).hideTreeView();
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          // 트리 내용은 InteractiveViewer로 감싸기
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.5,
              maxScale: 2.0,
              constrained: false, // 컨테이너 크기에 제약받지 않도록
              child: treeState.when(
                data: (state) {
                  if (state.rootNode == null) {
                    return const Text('No directory structure');
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 300, // 최소 너비 설정
                        maxWidth: MediaQuery.of(context).size.width * 3, // 화면 너비의 3배로 제한 확장
                      ),
                      child: SingleChildScrollView(
                        child: Container(
                          width: treeWidth, // 동적으로 계산된 넓이 사용
                          padding: const EdgeInsets.all(16.0),
                          child: DirectoryNodeWidget(
                            node: state.rootNode!,
                            onNodeSelected: (path) {
                              // 노드 선택 처리
                            },
                            // 최대 넓이 갱신 콜백 전달
                            updateMaxWidth: (maxWidth) {
                              // 기존 넓이보다 큰 경우에만 업데이트 (최대 화면 너비의 3배까지만)
                              final maxAllowedWidth = MediaQuery.of(context).size.width * 3;
                              final newWidth = maxWidth + 50 < maxAllowedWidth ? maxWidth + 50 : maxAllowedWidth;

                              if (newWidth > ref.read(treeWidthProvider)) {
                                ref.read(treeWidthProvider.notifier).state = newWidth;
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
