import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/directory_node_data.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/theme_provider.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/base_state.dart';
import 'package:macos_file_manager/src/drag_drop_items_event.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/node_connection_lines.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

final treeViewUpdateProvider = StateProvider<int>((ref) => 0);

class DirectoryNodeWidget extends ConsumerWidget with DragDropItemsEvent, BaseState {
  final DirectoryNodeData node;
  final double indentation;
  final Function(String) onNodeSelected;
  final String? searchQuery;

  const DirectoryNodeWidget({
    super.key,
    required this.node,
    this.indentation = 0,
    required this.onNodeSelected,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<GlobalKey> childKeys = node.isExpanded ? List.generate(node.children.length, (_) => GlobalKey()) : [];
    ref.watch(treeViewUpdateProvider);
    final size = MediaQuery.of(context).size;

    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Node box
        DropRegion(
          formats: const [...Formats.standardFormats],
          hitTestBehavior: HitTestBehavior.translucent,
          onDropOver: (event) {
            return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
          },
          onPerformDrop: (event) async {
            await handleFileDrop(ref, context, event, node.path);
          },
          child: IntrinsicWidth(
            child: Flexible(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: node.isSelected ? Colors.orange : Theme.of(context).dividerColor,
                    width: node.isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.black26 : Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    InkWell(
                      onSecondaryTap: () {
                        showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(size.width / 2, size.height - 100, size.width / 2, 0),
                          items: [
                            PopupMenuItem(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Center(
                                child: Center(
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Tree View from ',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: node.name,
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () {
                                ref.read(searchQueryProvider.notifier).state = null;
                                ref.read(treeViewNotifierProvider.notifier).showTreeView(node.path);
                              },
                            ),
                          ],
                        );
                      },
                      onTap: () async {
                        await ref.read(fileSystemItemListProvider.notifier).loadDirectory(node.path);
                        ref.read(currentDirectoryProvider.notifier).state = node.path;
                        ref.read(selectedFileItemProvider.notifier).state = null;
                        ref.read(lastSelectedPathProvider.notifier).state = null;
                        ref.read(fileSystemItemListProvider.notifier).clearSelections();
                        ref.read(directoryHistoryProvider.notifier).navigateTo(node.path);
                      },
                      child: Text(
                        node.name,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              node.isSelected
                                  ? Colors.orange
                                  : (searchQuery != null &&
                                      searchQuery!.isNotEmpty &&
                                      node.name.toLowerCase().contains(searchQuery!.toLowerCase()))
                                  ? Colors.blue
                                  : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: node.isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (node.children.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          log(indentation.toString());
                          ref.read(treeViewNotifierProvider.notifier).toggleNode(node.path);
                          ref.read(treeViewUpdateProvider.notifier).state++;
                        },
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                          child: Icon(
                            node.isExpanded ? Icons.chevron_right : Icons.expand_more,
                            size: 20,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Child nodes and connection lines
        if (node.isExpanded && node.children.isNotEmpty)
          Flexible(
            child: Stack(
              children: [
                // Connection lines (placed at the bottom layer)
                Positioned(
                  left: -9,
                  top: 0,
                  bottom: 0,
                  child: NodeConnectionLines(
                    childKeys: childKeys,
                    updateTrigger: ref.watch(treeViewUpdateProvider),
                    isDarkMode: isDarkMode,
                  ),
                ),

                // Child nodes
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...node.children.asMap().entries.map((entry) {
                        int index = entry.key;
                        DirectoryNodeData child = entry.value;

                        return Padding(
                          key: childKeys[index],
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: DirectoryNodeWidget(
                            node: child,
                            indentation: indentation + 40,
                            onNodeSelected: onNodeSelected,
                            searchQuery: searchQuery,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
