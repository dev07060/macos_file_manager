import 'package:flutter/material.dart';
import 'package:macos_file_manager/src/widgets/directory_tree/custom_painter/tree_line_painter.dart';

/// Widget that draws the connection lines between nodes.
class NodeConnectionLines extends StatefulWidget {
  final List<GlobalKey> childKeys;
  final int updateTrigger;
  final bool isDarkMode;

  const NodeConnectionLines({super.key, required this.childKeys, this.updateTrigger = 0, this.isDarkMode = false});

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
    if (widget.childKeys != oldWidget.childKeys ||
        widget.updateTrigger != oldWidget.updateTrigger ||
        widget.isDarkMode != oldWidget.isDarkMode) {
      _schedulePositionUpdate();
    }
  }

  void _schedulePositionUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateNodePositions();
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
            final position = box.localToGlobal(Offset.zero, ancestor: ancestor).dy;
            positions.add(position + 28);
          }
        } catch (e) {
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
        painter: TreeLinePainter(nodePositions: _nodePositions, isDarkMode: widget.isDarkMode),
        size: const Size(40, double.infinity),
      ),
    );
  }
}
