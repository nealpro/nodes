import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  /// Optional visible rect for culling - only draw lines in visible area
  final Rect? visibleRect;

  // Reusable paint object
  static final Paint _paint = Paint()
    ..color = Colors.grey[300]!
    ..strokeWidth = 1;

  const GridPainter({this.visibleRect});

  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 50;

    // If we have a visible rect, only draw lines in that area (with padding)
    final double startX;
    final double endX;
    final double startY;
    final double endY;

    if (visibleRect != null) {
      // Round to grid boundaries and add padding
      startX = (visibleRect!.left / gridSize).floor() * gridSize;
      endX = ((visibleRect!.right / gridSize).ceil() + 1) * gridSize;
      startY = (visibleRect!.top / gridSize).floor() * gridSize;
      endY = ((visibleRect!.bottom / gridSize).ceil() + 1) * gridSize;
    } else {
      startX = 0;
      endX = size.width;
      startY = 0;
      endY = size.height;
    }

    // Clamp to canvas bounds
    final clampedStartX = startX.clamp(0.0, size.width);
    final clampedEndX = endX.clamp(0.0, size.width);
    final clampedStartY = startY.clamp(0.0, size.height);
    final clampedEndY = endY.clamp(0.0, size.height);

    // Draw vertical lines
    for (double x = clampedStartX; x <= clampedEndX; x += gridSize) {
      canvas.drawLine(Offset(x, clampedStartY), Offset(x, clampedEndY), _paint);
    }

    // Draw horizontal lines
    for (double y = clampedStartY; y <= clampedEndY; y += gridSize) {
      canvas.drawLine(Offset(clampedStartX, y), Offset(clampedEndX, y), _paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return visibleRect != oldDelegate.visibleRect;
  }
}
