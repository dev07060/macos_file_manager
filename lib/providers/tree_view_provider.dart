import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/directory_node_data.dart';
import 'package:macos_file_manager/services/directory_service.dart';
import 'package:macos_file_manager/state/tree_view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tree_view_provider.g.dart';

final selectedPathProvider = StateProvider<String?>((ref) => null);

@riverpod
class TreeViewNotifier extends _$TreeViewNotifier {
  final _directoryService = DirectoryService();

  @override
  Future<TreeViewState> build() async {
    return TreeViewState(isTreeViewActive: false, rootPath: null, rootNode: null, activeViewMorePath: null);
  }

  Future<void> showTreeView(String rootPath) async {
    state = const AsyncValue.loading();
    try {
      final rootNode = await _directoryService.loadDirectoryStructure(rootPath);
      state = AsyncValue.data(
        TreeViewState(isTreeViewActive: true, rootPath: rootPath, rootNode: rootNode, activeViewMorePath: null),
      );
    } catch (e, st) {
      state = AsyncValue.error(e is Exception ? e : Exception('Too many nodes to load tree-view'), st);
    }
  }

  void selectNode(String path) {
    ref.read(selectedPathProvider.notifier).state = path;

    final currentState = state.value;
    if (currentState == null) return;

    final updatedRoot = _updateSelection(currentState.rootNode!, path);

    state = AsyncValue.data(currentState.copyWith(rootNode: updatedRoot));
  }

  DirectoryNodeData _updateSelection(DirectoryNodeData node, String selectedPath) {
    final bool isSelected = node.path == selectedPath;

    return DirectoryNodeData(
      name: node.name,
      path: node.path,
      isSelected: isSelected,
      isExpanded: isSelected || node.isExpanded,
      isViewMoreExpanded: node.isViewMoreExpanded,
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
    state = const AsyncValue.data(
      TreeViewState(isTreeViewActive: false, rootPath: null, rootNode: null, activeViewMorePath: null),
    );
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

  void expandAll() {
    state.whenData((currentState) {
      _expandAllRecursive(currentState.rootNode);
      state = AsyncValue.data(currentState);
    });
  }

  void _expandAllRecursive(DirectoryNodeData? node) {
    if (node == null) return;
    node.isExpanded = true;
    for (final child in node.children) {
      _expandAllRecursive(child);
    }
  }

  void _collapseAllRecursive(DirectoryNodeData? node) {
    if (node == null) return;
    node.isExpanded = false;
    for (final child in node.children) {
      _collapseAllRecursive(child);
    }
  }

  // View More 기능 토글
  void toggleViewMore(String path) {
    state.whenData((currentState) {
      // 다른 모든 view more를 닫고 현재 것만 토글
      _collapseAllViewMore(currentState.rootNode);

      final isCurrentlyExpanded = currentState.activeViewMorePath == path;

      if (!isCurrentlyExpanded) {
        // 새로운 view more 열기
        _setViewMoreExpanded(currentState.rootNode, path, true);
        state = AsyncValue.data(currentState.copyWith(activeViewMorePath: path));
      } else {
        // 현재 view more 닫기
        _setViewMoreExpanded(currentState.rootNode, path, false);
        state = AsyncValue.data(currentState.copyWith(activeViewMorePath: null));
      }
    });
  }

  // 모든 view more를 닫기
  void _collapseAllViewMore(DirectoryNodeData? node) {
    if (node == null) return;
    node.isViewMoreExpanded = false;
    for (final child in node.children) {
      _collapseAllViewMore(child);
    }
  }

  // 특정 경로의 view more 상태 설정
  void _setViewMoreExpanded(DirectoryNodeData? node, String path, bool expanded) {
    if (node == null) return;

    if (node.path == path) {
      node.isViewMoreExpanded = expanded;
      return;
    }

    for (final child in node.children) {
      _setViewMoreExpanded(child, path, expanded);
    }
  }
}
