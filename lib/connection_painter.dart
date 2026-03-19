import 'package:flutter/material.dart';
import 'node.dart';

class ConnectionPainter extends CustomPainter {
  final List<Node> nodes;

  /// Version notifier - triggers repaint when connections change
  final ValueNotifier<int> connectionVersion;

  /// Notifier for visible rect — triggers repaint on viewport changes
  final ValueNotifier<Rect?> visibleRectNotifier;

  // Reusable paint object
  static final Paint _paint = Paint()
    ..color = Colors.grey[600]!
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  ConnectionPainter({
    required this.nodes,
    required this.connectionVersion,
    required this.visibleRectNotifier,
  }) : super(
          repaint:
              Listenable.merge([connectionVersion, visibleRectNotifier]),
        );

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cullRect = visibleRectNotifier.value;

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
    // Only need full repaint if the node list object itself changed
    return nodes != oldDelegate.nodes;
  }
}
