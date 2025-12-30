import 'package:flutter/material.dart';
import 'node.dart';

/// Tracks version changes for efficient repaint decisions
class ConnectionVersion {
  int _version = 0;
  int get version => _version;
  void increment() => _version++;
}

class ConnectionPainter extends CustomPainter {
  final List<Node> nodes;

  /// Version counter - increment when connections need repainting
  final int version;

  /// Optional visible rect for culling (optimization for large canvases)
  final Rect? visibleRect;

  // Reusable paint object
  static final Paint _paint = Paint()
    ..color = Colors.grey[600]!
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  ConnectionPainter({required this.nodes, this.version = 0, this.visibleRect});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cullRect = visibleRect;

    for (var node in nodes) {
      for (var child in node.children) {
        // Start from the right center of the parent node
        final start = node.position + const Offset(120, 30);
        // End at the left center of the child node
        final end = child.position + const Offset(0, 30);

        // Culling: skip connections entirely outside visible rect
        if (cullRect != null) {
          final connectionBounds = Rect.fromPoints(start, end).inflate(50);
          if (!connectionBounds.overlaps(cullRect)) {
            continue;
          }
        }

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

    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    // Only repaint if version changed (positions updated, nodes added/removed)
    return version != oldDelegate.version ||
        visibleRect != oldDelegate.visibleRect;
  }
}
