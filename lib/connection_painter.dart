import 'package:flutter/material.dart';
import 'node.dart';

class ConnectionPainter extends CustomPainter {
  final List<Node> nodes;

  ConnectionPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (var node in nodes) {
      for (var child in node.children) {
        // Start from the right center of the parent node
        final start = node.position + const Offset(120, 30);
        // End at the left center of the child node
        final end = child.position + const Offset(0, 30);

        // Draw a cubic bezier curve
        final controlPoint1 = start + const Offset(50, 0);
        final controlPoint2 = end - const Offset(50, 0);

        path.moveTo(start.dx, start.dy);
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          end.dx,
          end.dy,
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return true;
  }
}
