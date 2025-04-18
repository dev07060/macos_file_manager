import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/directory_node.dart';
import 'package:macos_file_manager/providers/file_system_providers.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';

class DirectoryNodeWidget extends ConsumerWidget {
  final DirectoryNode node;
  final double indentation;
  final Function(String) onNodeSelected;

  const DirectoryNodeWidget({super.key, required this.node, this.indentation = 0, required this.onNodeSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 노드 박스
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
                // 클릭 가능한 텍스트로 변경
                InkWell(
                  onTap: () async {
                    // 클릭한 디렉토리의 파일 목록을 로드
                    await ref.read(fileSystemItemListProvider.notifier).loadDirectory(node.path);
                    // 현재 디렉토리 경로 업데이트
                    ref.read(currentDirectoryProvider.notifier).state = node.path;
                    // 선택된 파일 초기화
                    ref.read(selectedFileItemProvider.notifier).state = null;
                    // 마지막 선택 경로 초기화
                    ref.read(lastSelectedPathProvider.notifier).state = null;
                    // 모든 선택 해제
                    ref.read(fileSystemItemListProvider.notifier).clearSelections();
                    // 디렉토리 히스토리 업데이트
                    ref.read(directoryHistoryProvider.notifier).navigateTo(node.path);
                  },
                  child: Text(
                    node.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blue, // 클릭 가능함을 나타내는 색상
                    ),
                  ),
                ),
                if (node.children.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ref.read(treeViewNotifierProvider.notifier).toggleNode(node.path);
                    },
                    child: Icon(node.isExpanded ? Icons.chevron_right : Icons.expand_more, size: 16),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 자식 노드들과 연결선
        if (node.isExpanded && node.children.isNotEmpty)
          Flexible(
            child: Stack(
              children: [
                // 연결선
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(20, double.infinity),
                    painter: TreeLinePainter(
                      childCount: node.children.length,
                      spacing: 40.0, // 노드 간 수직 간격
                    ),
                  ),
                ),
                // 자식 노드들
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...node.children.map(
                        (child) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: DirectoryNodeWidget(
                            node: child,
                            indentation: indentation + 40,
                            onNodeSelected: onNodeSelected,
                          ),
                        ),
                      ),
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

// 트리 연결선 그리기
class TreeLinePainter extends CustomPainter {
  final int childCount;
  final double spacing;

  TreeLinePainter({required this.childCount, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    final double startY = spacing / 2;
    final double totalHeight = childCount * spacing;

    // 수평 연결선
    for (int i = 0; i < childCount; i++) {
      final double y = startY + (i * spacing);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
