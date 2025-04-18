import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/directory_node.dart';

class DirectoryTreeView extends ConsumerWidget {
  final String rootPath;

  const DirectoryTreeView({super.key, required this.rootPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeState = ref.watch(treeViewNotifierProvider);

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
                  return Container(
                    width: 10000, // 충분히 큰 너비
                    height: 10000, // 충분히 큰 높이
                    padding: const EdgeInsets.all(16.0),
                    child: DirectoryNodeWidget(
                      node: state.rootNode!,
                      onNodeSelected: (path) {
                        // 노드 선택 처리
                      },
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
