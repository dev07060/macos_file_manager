import 'dart:ui';

import 'package:macos_file_manager/model/directory_node_data.dart';

class TreeViewState {
  final bool isTreeViewActive;
  final String? rootPath;
  final DirectoryNodeData? rootNode;
  final Offset dragOffset; // 드래그 위치 저장

  const TreeViewState({
    required this.isTreeViewActive,
    required this.rootPath,
    required this.rootNode,
    this.dragOffset = Offset.zero,
  });

  TreeViewState copyWith({bool? isTreeViewActive, String? rootPath, DirectoryNodeData? rootNode, Offset? dragOffset}) {
    return TreeViewState(
      isTreeViewActive: isTreeViewActive ?? this.isTreeViewActive,
      rootPath: rootPath ?? this.rootPath,
      rootNode: rootNode ?? this.rootNode,
      dragOffset: dragOffset ?? this.dragOffset,
    );
  }
}
