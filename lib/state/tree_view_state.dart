import 'dart:ui';

import 'package:macos_file_manager/model/directory_node_data.dart';

class TreeViewState {
  final bool isTreeViewActive;
  final String? rootPath;
  final DirectoryNodeData? rootNode;
  final Offset dragOffset;
  final String? activeViewMorePath; // 현재 활성화된 view more의 경로

  const TreeViewState({
    required this.isTreeViewActive,
    required this.rootPath,
    required this.rootNode,
    this.dragOffset = Offset.zero,
    this.activeViewMorePath,
  });

  TreeViewState copyWith({
    bool? isTreeViewActive,
    String? rootPath,
    DirectoryNodeData? rootNode,
    Offset? dragOffset,
    String? activeViewMorePath,
    bool clearActiveViewMorePath = false,
  }) {
    return TreeViewState(
      isTreeViewActive: isTreeViewActive ?? this.isTreeViewActive,
      rootPath: rootPath ?? this.rootPath,
      rootNode: rootNode ?? this.rootNode,
      dragOffset: dragOffset ?? this.dragOffset,
      activeViewMorePath: clearActiveViewMorePath ? null : (activeViewMorePath ?? this.activeViewMorePath),
    );
  }
}
