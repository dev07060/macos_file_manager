import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/directory_node.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';

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
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
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
                      // 토글 상태 변경
                      ref.read(treeViewNotifierProvider.notifier).toggleNode(node.path);
                      // 트리 뷰 업데이트 상태 변경 (업데이트 강제 트리거)
                      ref.read(treeViewUpdateProvider.notifier).state++;
                    },
                    child: Icon(node.isExpanded ? Icons.chevron_right : Icons.expand_more, size: 16),
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
                  left: 0,
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

/// Widget that draws the connection lines between nodes.
class NodeConnectionLines extends StatefulWidget {
  final List<GlobalKey> childKeys;
  final int updateTrigger;

  const NodeConnectionLines({super.key, required this.childKeys, this.updateTrigger = 0});

  @override
  State<NodeConnectionLines> createState() => _NodeConnectionLinesState();
}

class _NodeConnectionLinesState extends State<NodeConnectionLines> {
  List<double> _nodePositions = [];
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _schedulePositionUpdate();
  }

  @override
  void didUpdateWidget(NodeConnectionLines oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.childKeys != oldWidget.childKeys || widget.updateTrigger != oldWidget.updateTrigger) {
      _schedulePositionUpdate();
    }
  }

  void _schedulePositionUpdate() {
    // 첫 번째 프레임 렌더링 후 위치 계산
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateNodePositions();

      // 모든 위젯이 렌더링된 후 한 번 더 업데이트 (레이아웃 안정화 이후)
      if (_isFirstBuild) {
        _isFirstBuild = false;
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _calculateNodePositions();
          }
        });
      }
    });
  }

  void _calculateNodePositions() {
    if (!mounted) return;

    List<double> positions = [];

    for (GlobalKey key in widget.childKeys) {
      if (key.currentContext != null) {
        try {
          final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
          final RenderBox? ancestor = context.findRenderObject() as RenderBox?;

          if (box.hasSize && ancestor != null && ancestor.hasSize) {
            // 현재 위젯 기준으로 상대 위치 계산
            final position = box.localToGlobal(Offset.zero, ancestor: ancestor).dy;
            // 노드의 중앙 위치 계산
            positions.add(position + 20); // 대략적인 노드의 중앙 위치
          }
        } catch (e) {
          // RenderBox 관련 오류 처리
          debugPrint('RenderBox error: $e');
        }
      }
    }

    if (mounted && positions.isNotEmpty) {
      setState(() {
        _nodePositions = positions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: TreeLinePainter(nodePositions: _nodePositions),
        size: const Size(20, double.infinity),
      ),
    );
  }
}

/// Custom painter that draws the tree connection lines (both horizontal and vertical lines).
class TreeLinePainter extends CustomPainter {
  final List<double> nodePositions;

  TreeLinePainter({required this.nodePositions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    if (nodePositions.isEmpty) return;

    // Draw vertical lines
    // Connect the first node to the last node with a vertical line
    final double startY = nodePositions.first;
    final double endY = nodePositions.last;

    // Vertical line is positioned in the center horizontally
    final double verticalLineX = 10;
    canvas.drawLine(Offset(verticalLineX, startY), Offset(verticalLineX, endY), paint);

    // Draw horizontal lines at each node position
    for (double y in nodePositions) {
      // Horizontal line extending to the right from the vertical line
      canvas.drawLine(Offset(verticalLineX, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant TreeLinePainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions;
  }
}
