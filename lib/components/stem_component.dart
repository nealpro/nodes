import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class StemComponent extends PositionComponent {
  static const double stemRadius = 40.0;

  StemComponent(Vector2 position)
    : super(position: position, size: Vector2(stemRadius * 2, stemRadius * 2));

  @override
  void render(Canvas canvas) {
    final stemPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.fill;

    final stemBorderPaint = Paint()
      ..color = Colors.deepPurple.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw stem circle
    canvas.drawCircle(Offset.zero, stemRadius, stemPaint);
    canvas.drawCircle(Offset.zero, stemRadius, stemBorderPaint);

    // Draw "⚪" text
    final stemTextPainter = TextPainter(
      text: const TextSpan(
        text: '⚪',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    stemTextPainter.layout();
    final stemTextOffset = Offset(
      -stemTextPainter.width / 2,
      -stemTextPainter.height / 2,
    );
    stemTextPainter.paint(canvas, stemTextOffset);
  }
}
