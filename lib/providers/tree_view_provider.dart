import 'dart:ui';

import 'package:macos_file_manager/model/directory_node.dart';
import 'package:macos_file_manager/services/directory_service.dart';
import 'package:macos_file_manager/state/tree_view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tree_view_provider.g.dart';

@riverpod
class TreeViewNotifier extends _$TreeViewNotifier {
  final _directoryService = DirectoryService();

  @override
  Future<TreeViewState> build() async {
    return TreeViewState(isTreeViewActive: false, rootPath: null, rootNode: null);
  }

  Future<void> showTreeView(String rootPath) async {
    state = const AsyncValue.loading();

    try {
      final rootNode = await _directoryService.loadDirectoryStructure(rootPath);
      state = AsyncValue.data(TreeViewState(isTreeViewActive: true, rootPath: rootPath, rootNode: rootNode));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateDragOffset(Offset delta) {
    state.whenData((currentState) {
      final newOffset = currentState.dragOffset.translate(delta.dx, delta.dy);
      state = AsyncValue.data(currentState.copyWith(dragOffset: newOffset));
    });
  }

  void resetDragOffset() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(dragOffset: Offset.zero));
    });
  }

  void hideTreeView() {
    state = const AsyncValue.data(TreeViewState(isTreeViewActive: false, rootPath: null, rootNode: null));
  }

  void toggleNode(String path) {
    state.whenData((currentState) {
      _toggleNodeRecursive(currentState.rootNode, path);
      state = AsyncValue.data(currentState);
    });
  }

  void _toggleNodeRecursive(DirectoryNode? node, String path) {
    if (node == null) return;

    if (node.path == path) {
      node.isExpanded = !node.isExpanded;
      return;
    }

    for (final child in node.children) {
      _toggleNodeRecursive(child, path);
    }
  }
}
