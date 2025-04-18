import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/providers/tree_view_provider.dart';

class DraggableTreeContainer extends HookConsumerWidget {
  final Widget child;

  const DraggableTreeContainer({super.key, required this.child});
  Offset _constrainDragOffset(Offset offset, Size containerSize, Size contentSize) {
    final minX = -(contentSize.width - containerSize.width).clamp(0.0, double.infinity);
    final minY = -(contentSize.height - containerSize.height).clamp(0.0, double.infinity);

    return Offset(offset.dx.clamp(minX, 0.0), offset.dy.clamp(minY, 0.0));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragStartOffset = useState<Offset?>(null);
    final containerKey = useRef(GlobalKey());
    final contentKey = useRef(GlobalKey());

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            dragStartOffset.value = details.localPosition;
          },
          onPanUpdate: (details) {
            if (dragStartOffset.value != null) {
              final containerSize = containerKey.value.currentContext?.size ?? Size.zero;
              final contentSize = contentKey.value.currentContext?.size ?? Size.zero;

              final delta = details.localPosition - dragStartOffset.value!;
              final constrainedDelta = _constrainDragOffset(delta, containerSize, contentSize);

              ref.read(treeViewNotifierProvider.notifier).updateDragOffset(constrainedDelta);
              dragStartOffset.value = details.localPosition;
            }
          },
          onPanEnd: (_) {
            dragStartOffset.value = null;
          },
          child: Container(
            key: containerKey.value,
            child: ClipRect(child: Container(key: contentKey.value, child: child)),
          ),
        );
      },
    );
  }
}
