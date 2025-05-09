import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/directory_node_data.dart';
import 'package:macos_file_manager/providers/theme_provider.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';
import 'package:macos_file_manager/src/base_state.dart';
import 'package:macos_file_manager/src/drag_drop_items_event.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/node/node_connection_lines.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/node/node_container.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

final treeViewUpdateProvider = StateProvider<int>((ref) => 0);
final treeIndentationProvider = StateProvider<double>((ref) => 0);

class DirectoryNodeWidget extends HookConsumerWidget with DragDropItemsEvent, BaseState {
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
    final selectedPath = ref.watch(selectedPathProvider);
    final currentKey = GlobalKey();

    if (node.isSelected && selectedPath == node.path) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentKey.currentContext != null) {
          Scrollable.ensureVisible(
            currentKey.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    return Row(
      key: currentKey,
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
          child: NodeContainer(
            node: node,
            isDarkMode: isDarkMode,
            size: size,
            ref: ref,
            indentation: indentation,
            searchQuery: searchQuery,
          ),
        ),

        // Child nodes and connection lines
        if (node.isExpanded && node.children.isNotEmpty)
          Stack(
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
      ],
    );
  }
}
