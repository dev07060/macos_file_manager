import 'dart:ui';

import 'package:macos_file_manager/model/directory_node_data.dart';
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

  void selectNode(String path) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedRoot = _updateSelection(currentState.rootNode!, path);

    state = AsyncValue.data(currentState.copyWith(rootNode: updatedRoot));
  }

  DirectoryNodeData _updateSelection(DirectoryNodeData node, String selectedPath) {
    bool isSelected = node.path == selectedPath;

    return DirectoryNodeData(
      name: node.name,
      path: node.path,
      isSelected: isSelected,
      isExpanded: isSelected || node.isExpanded,
      children: node.children.map((child) => _updateSelection(child, selectedPath)).toList(),
    );
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

  void _toggleNodeRecursive(DirectoryNodeData? node, String path) {
    if (node == null) return;

    if (node.path == path) {
      node.isExpanded = !node.isExpanded;
      return;
    }

    for (final child in node.children) {
      _toggleNodeRecursive(child, path);
    }
  }

  void expandPath(String path) {
    state.whenData((currentState) {
      final segments = path.split('/').where((e) => e.isNotEmpty).toList();
      String current = '';
      for (final segment in segments) {
        current += '/$segment';
        _expandNodeRecursive(currentState.rootNode, current);
      }
      state = AsyncValue.data(currentState);
    });
  }

  void _expandNodeRecursive(DirectoryNodeData? node, String path) {
    if (node == null) return;
    if (node.path == path) {
      node.isExpanded = true;
      return;
    }
    for (final child in node.children) {
      _expandNodeRecursive(child, path);
    }
  }

  void collapseAll() {
    state.whenData((currentState) {
      _collapseAllRecursive(currentState.rootNode);
      state = AsyncValue.data(currentState);
    });
  }

  void _collapseAllRecursive(DirectoryNodeData? node) {
    if (node == null) return;
    node.isExpanded = false;
    for (final child in node.children) {
      _collapseAllRecursive(child);
    }
  }
}
