import 'package:flutter/material.dart';

/// Custom painter that draws the tree connection lines (both horizontal and vertical lines).
class TreeLinePainter extends CustomPainter {
  final List<double> nodePositions;
  final bool isDarkMode;

  TreeLinePainter({required this.nodePositions, this.isDarkMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    final Color lineColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;

    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 3
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
    return oldDelegate.nodePositions != nodePositions || oldDelegate.isDarkMode != isDarkMode;
  }
}
