import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_file_manager/model/directory_node_data.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/node/directory_node.dart';

class NodeContainer extends StatelessWidget {
  final DirectoryNodeData node;
  final bool isDarkMode;
  final Size size;
  final WidgetRef ref;
  final double indentation;
  final String? searchQuery;

  const NodeContainer({
    super.key,
    required this.node,
    required this.isDarkMode,
    required this.size,
    required this.ref,
    required this.indentation,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: IntrinsicWidth(
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
                                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
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
                InkWell(
                  onTap: () {
                    log(indentation.toString());
                    ref.read(treeViewNotifierProvider.notifier).toggleNode(node.path);
                    ref.read(treeViewUpdateProvider.notifier).state++;
                    ref.read(treeIndentationProvider.notifier).state = indentation;
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
    );
  }
}
