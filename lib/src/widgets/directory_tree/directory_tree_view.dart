import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/directory_node_data.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/directory_node.dart';
import 'package:macos_file_manager/src/widgets/search_bar.dart';

class DirectoryTreeView extends HookConsumerWidget {
  final String rootPath;

  DirectoryTreeView({super.key, required this.rootPath});
  final TransformationController transformationController = useMemoized(() => TransformationController(), []);
  final TextEditingController searchController = useTextEditingController();
  final scale = useState<double>(1.0);

  List<String> collectAllPaths(DirectoryNodeData? node) {
    if (node == null) return [];
    List<String> paths = [node.path];
    for (final child in node.children) {
      paths.addAll(collectAllPaths(child));
    }
    return paths;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeViewProvider = ref.read(treeViewNotifierProvider.notifier);

    final treeState = ref.watch(treeViewNotifierProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    List<String> allPaths = [];
    treeState.when(
      data: (state) {
        allPaths = collectAllPaths(state.rootNode);
      },
      error: (error, stackTrace) {},
      loading: () {
        return const Center(child: CircularProgressIndicator.adaptive());
      },
    );

    final filteredPaths =
        searchQuery == null ? [] : allPaths.where((p) => p.split('/').last.contains(searchQuery)).toList();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FSearchBar(
                    variant: FSearchBarVariant.normal,
                    hintText: 'You can search directory name here within the tree',
                    controller: searchController,
                    onChanged: (value) {
                      if (value.isEmpty) {
                        ref.read(searchQueryProvider.notifier).state = null;
                      } else {
                        ref.read(searchQueryProvider.notifier).state = value;
                      }
                    },
                    onClear: () {
                      ref.read(searchQueryProvider.notifier).state = null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = null;
                    treeViewProvider.hideTreeView();
                  },
                ),
              ],
            ),
          ),

          searchController.text.isNotEmpty || searchController.text != '' || filteredPaths.isNotEmpty
              ? Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child:
                      filteredPaths.isEmpty
                          ? Center(child: (Text('No results found')))
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                            itemCount: filteredPaths.length,
                            itemExtent: 40,
                            itemBuilder: (context, index) {
                              final path = filteredPaths[index];
                              final segments = path.split('/').where((String e) => e.isNotEmpty).toList();
                              final shortSegments =
                                  segments.length >= 3 ? segments.sublist(segments.length - 3) : segments;
                              return InkWell(
                                onTap: () async {
                                  // TODO: clean and refactor this code
                                  scale.value = 1.0;
                                  transformationController.value = Matrix4.identity()..scale(scale.value);
                                  treeViewProvider.collapseAll();
                                  await ref.read(fileSystemItemListProvider.notifier).loadDirectory(path);
                                  treeViewProvider.expandPath(path);
                                  treeViewProvider.selectNode(path);
                                  ref.read(currentDirectoryProvider.notifier).state = path;
                                  ref.read(directoryHistoryProvider.notifier).navigateTo(path);
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        for (int i = 0; i < shortSegments.length; i++) ...[
                                          TextSpan(
                                            text: shortSegments[i],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: [Colors.grey[500], Colors.blue[200], Colors.purple[200]][i % 3],
                                            ),
                                          ),
                                          if (i != shortSegments.length - 1)
                                            TextSpan(
                                              text: ' > ',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              )
              : SizedBox.shrink(),
          Expanded(
            flex: 8,
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.5,
              maxScale: 2.0,
              constrained: false,
              transformationController: transformationController,
              child: treeState.when(
                data: (state) {
                  if (state.rootNode == null) {
                    return const Text('No directory structure');
                  }
                  return Container(
                    constraints: BoxConstraints(minWidth: 600, maxWidth: 2000),
                    padding: const EdgeInsets.all(16.0),
                    child: DirectoryNodeWidget(
                      node: state.rootNode!,
                      onNodeSelected: (path) {
                        ref.read(treeViewNotifierProvider.notifier).selectNode(path);
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
