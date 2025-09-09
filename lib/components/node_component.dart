import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/node.dart';
import '../nodes_app.dart';

class NodeComponent extends PositionComponent {
  final Node node;
  final NodesApp game;
  bool isSelected = false;

  static const double nodeHeight = 60.0;
  static const double cornerRadius = 8.0;
  static const double textPadding = 8.0;
  static const int maxLines = 3;
  static const double maxWidth = 120.0;
  static const double minNodeWidth = 60.0;

  NodeComponent(this.node, this.game)
    : super(
        position: Vector2(node.position.dx, node.position.dy),
        size: Vector2(minNodeWidth, nodeHeight),
      );

  void updateSelection(Node? selectedNode) {
    isSelected = selectedNode != null && selectedNode.id == node.id;
  }

  @override
  void render(Canvas canvas) {
    // Use different colors for selected vs unselected nodes
    final nodePaint = Paint()
      ..color = isSelected ? Colors.orange.shade200 : Colors.blue.shade100
      ..style = PaintingStyle.fill;

    final nodeBorderPaint = Paint()
      ..color = isSelected ? Colors.orange.shade700 : Colors.blue.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;

    // Draw node text with simplified text wrapping
    final textStyle = TextStyle(
      color: isSelected ? Colors.orange.shade900 : Colors.blue.shade800,
      fontSize: 11,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
    );

    // Create text painter with width constraints for automatic wrapping
    final nodeTextPainter = TextPainter(
      text: TextSpan(text: node.text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: maxLines,
    );

    // Layout with width constraint to enable automatic text wrapping
    nodeTextPainter.layout(maxWidth: maxWidth);

    // Calculate dynamic node width based on text width
    final textWidth = nodeTextPainter.width;
    final nodeWidth = (textWidth + (textPadding * 2)).clamp(
      minNodeWidth,
      maxWidth + (textPadding * 2),
    );

    // Update size
    size = Vector2(nodeWidth, nodeHeight);

    // Create rounded rectangle for node with dynamic width
    final nodeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: nodeWidth,
        height: nodeHeight,
      ),
      const Radius.circular(cornerRadius),
    );

    // Draw node rounded rectangle
    canvas.drawRRect(nodeRect, nodePaint);
    canvas.drawRRect(nodeRect, nodeBorderPaint);

    // Add selection highlight ring for selected nodes
    if (isSelected) {
      final highlightPaint = Paint()
        ..color = Colors.orange.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final highlightRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: nodeWidth + 10,
          height: nodeHeight + 10,
        ),
        const Radius.circular(cornerRadius + 5),
      );
      canvas.drawRRect(highlightRect, highlightPaint);
    }

    // Draw the text
    final nodeTextOffset = Offset(
      -nodeTextPainter.width / 2,
      -nodeTextPainter.height / 2,
    );
    nodeTextPainter.paint(canvas, nodeTextOffset);
  }
}
