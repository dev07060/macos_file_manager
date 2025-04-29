import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/directory_node_data.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/theme_provider.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/node/directory_node.dart';
import 'package:macos_file_manager/src/widgets/search_bar.dart';

class DirectoryTreeView extends HookConsumerWidget {
  final String rootPath;

  const DirectoryTreeView({super.key, required this.rootPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transformationController = useMemoized(() => TransformationController(), []);
    final searchController = useTextEditingController();
    final scale = useState<double>(1.0);
    final isTreeExpanded = useState<bool>(false);
    final searchDebounce = useState<Timer?>(null);
    final treeViewProvider = ref.read(treeViewNotifierProvider.notifier);
    final treeState = ref.watch(treeViewNotifierProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    useEffect(() {
      return () {
        searchDebounce.value?.cancel();
      };
    }, []);

    final allPaths = useMemoized(() {
      if (treeState is AsyncData) {
        final state = (treeState as AsyncData).value;
        return _collectAllPaths(state.rootNode);
      }
      return <String>[];
    }, [treeState]);

    final filteredPaths = useMemoized(() {
      if (searchQuery == null || searchQuery.isEmpty) return <String>[];
      return allPaths.where((p) => p.split('/').last.contains(searchQuery)).toList();
    }, [searchQuery, allPaths]);

    void handleSearchResultTap(String path) async {
      // decrease value per indentation count
      scale.value = 1.0;
      transformationController.value = Matrix4.identity()..scale(scale.value);

      treeViewProvider.collapseAll();
      await ref.read(fileSystemItemListProvider.notifier).loadDirectory(path);
      treeViewProvider.expandPath(path);
      treeViewProvider.selectNode(path);

      ref.read(currentDirectoryProvider.notifier).state = path;
      ref.read(directoryHistoryProvider.notifier).navigateTo(path);
    }

    if (treeState is AsyncLoading) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        onPressed: () {
          scale.value = isTreeExpanded.value ? 1.0 : 0.5;
          isTreeExpanded.value = isTreeExpanded.value ? false : true;
          transformationController.value = Matrix4.identity()..scale(scale.value);
          isTreeExpanded.value ? treeViewProvider.expandAll() : treeViewProvider.collapseAll();
        },
        child: Icon(
          !isTreeExpanded.value ? Icons.fullscreen : Icons.fullscreen_exit,
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                      hintText: 'You can search directory name here within the tree via press "enter"',
                      controller: searchController,
                      onChanged: (value) {
                        // Do nothing or implement live preview if needed
                      },
                      onSubmitted: (value) {
                        if (value.isEmpty) {
                          ref.read(searchQueryProvider.notifier).state = null;
                        } else {
                          ref.read(searchQueryProvider.notifier).state = value;
                        }
                      },
                      onClear: () {
                        ref.read(searchQueryProvider.notifier).state = null;
                        searchController.clear();
                      },
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
                    onPressed: () {
                      searchDebounce.value?.cancel();
                      searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = null;
                      treeViewProvider.hideTreeView();
                    },
                  ),
                ],
              ),
            ),

            if (searchQuery != null && searchQuery.isNotEmpty)
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Theme.of(context).cardColor,
                  ),
                  child:
                      filteredPaths.isEmpty
                          ? Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                            itemCount: filteredPaths.length,
                            itemExtent: 35,
                            itemBuilder: (context, index) {
                              final path = filteredPaths[index];
                              final segments = path.split('/').where((e) => e.isNotEmpty).toList();
                              final shortSegments =
                                  segments.length >= 3 ? segments.sublist(segments.length - 3) : segments;

                              return InkWell(
                                hoverColor: Theme.of(context).hoverColor,
                                onTap: () => handleSearchResultTap(path),
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
                                              // fontWeight: FontWeight.bold,
                                              color:
                                                  isDarkMode
                                                      ? [Colors.green[400], Colors.blue[300], Colors.orange[300]][i % 3]
                                                      : [Colors.green[500], Colors.blue[700], Colors.orange[700]][i %
                                                          3],
                                            ),
                                          ),
                                          if (i != shortSegments.length - 1)
                                            TextSpan(
                                              text: ' > ',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
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
              ),

            Expanded(
              flex: searchQuery != null && searchQuery.isNotEmpty ? 8 : 10,
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.5,
                maxScale: 2.0,
                constrained: false,
                transformationController: transformationController,
                child: treeState.when(
                  data: (state) {
                    if (state.rootNode == null) {
                      return Center(
                        child: Text(
                          'No directory structure',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      );
                    }
                    return Container(
                      constraints: const BoxConstraints(minWidth: 600, maxWidth: 3000),
                      padding: const EdgeInsets.all(16.0),
                      child: DirectoryNodeWidget(
                        node: state.rootNode!,
                        onNodeSelected: (path) {
                          ref.read(treeViewNotifierProvider.notifier).selectNode(path);
                        },
                        searchQuery: searchQuery,
                      ),
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                  error:
                      (error, stack) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading tree: $error',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.refresh(treeViewNotifierProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _collectAllPaths(DirectoryNodeData? node) {
    if (node == null) return [];
    List<String> paths = [node.path];
    for (final child in node.children) {
      paths.addAll(_collectAllPaths(child));
    }
    return paths;
  }
}
