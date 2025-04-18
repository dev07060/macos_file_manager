import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/directory_node.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/node_connection_lines.dart';

final treeViewUpdateProvider = StateProvider<int>((ref) => 0);

/// Widget that represents a directory node in the directory tree.
class DirectoryNodeWidget extends ConsumerWidget {
  final DirectoryNode node;
  final double indentation;
  final Function(String) onNodeSelected;

  const DirectoryNodeWidget({super.key, required this.node, this.indentation = 0, required this.onNodeSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // List of keys to track the actual height of the nodes
    final List<GlobalKey> childKeys = node.isExpanded ? List.generate(node.children.length, (_) => GlobalKey()) : [];
    ref.watch(treeViewUpdateProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Node box
        IntrinsicWidth(
          child: Container(
            constraints: BoxConstraints(minWidth: 100, maxWidth: 2000),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder, size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    await ref.read(fileSystemItemListProvider.notifier).loadDirectory(node.path);
                    ref.read(currentDirectoryProvider.notifier).state = node.path;
                    ref.read(selectedFileItemProvider.notifier).state = null;
                    ref.read(lastSelectedPathProvider.notifier).state = null;
                    ref.read(fileSystemItemListProvider.notifier).clearSelections();
                    ref.read(directoryHistoryProvider.notifier).navigateTo(node.path);
                  },
                  child: Text(node.name, style: const TextStyle(fontSize: 13, color: Colors.blue)),
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
                      backgroundColor: Colors.grey.shade50,
                      child: Icon(
                        node.isExpanded ? Icons.chevron_right : Icons.expand_more,
                        size: 20,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ],
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
                  child: NodeConnectionLines(childKeys: childKeys, updateTrigger: ref.watch(treeViewUpdateProvider)),
                ),

                // Child nodes
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...node.children.asMap().entries.map((entry) {
                        int index = entry.key;
                        DirectoryNode child = entry.value;

                        return Padding(
                          key: childKeys[index],
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: DirectoryNodeWidget(
                            node: child,
                            indentation: indentation + 40,
                            onNodeSelected: onNodeSelected,
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
