import 'package:flutter/material.dart';
import '../models/node.dart';

class NodeCanvasPainter extends CustomPainter {
  final NodeLinkedList nodeList;
  final Offset rootPosition;
  final double rootRadius;
  final Node? selectedNode;

  NodeCanvasPainter({
    required this.nodeList,
    required this.rootPosition,
    this.rootRadius = 40.0,
    this.selectedNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = nodeList.toList();
    
    // STEP 1: Draw connection lines first (so they appear behind nodes)
    final connectionPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final node in nodes) {
      canvas.drawLine(rootPosition, node.position, connectionPaint);
    }
    
    // STEP 2: Draw the root circle and text
    final rootPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.fill;

    final rootBorderPaint = Paint()
      ..color = Colors.deepPurple.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw root circle
    canvas.drawCircle(rootPosition, rootRadius, rootPaint);
    canvas.drawCircle(rootPosition, rootRadius, rootBorderPaint);

    // Draw "ROOT" text
    final rootTextPainter = TextPainter(
      text: const TextSpan(
        text: 'ROOT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    rootTextPainter.layout();
    final rootTextOffset = Offset(
      rootPosition.dx - rootTextPainter.width / 2,
      rootPosition.dy - rootTextPainter.height / 2,
    );
    rootTextPainter.paint(canvas, rootTextOffset);

    // STEP 3: Draw nodes with proper styling and text
    const nodeRadius = 25.0;

    for (final node in nodes) {
      // Determine if this node is selected
      final isSelected = selectedNode != null && selectedNode!.id == node.id;
      
      // Use different colors for selected vs unselected nodes
      final nodePaint = Paint()
        ..color = isSelected ? Colors.orange.shade200 : Colors.blue.shade100
        ..style = PaintingStyle.fill;

      final nodeBorderPaint = Paint()
        ..color = isSelected ? Colors.orange.shade700 : Colors.blue.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 2.0;

      // Draw node circle
      canvas.drawCircle(node.position, nodeRadius, nodePaint);
      canvas.drawCircle(node.position, nodeRadius, nodeBorderPaint);
      
      // Add selection highlight ring for selected nodes
      if (isSelected) {
        final highlightPaint = Paint()
          ..color = Colors.orange.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(node.position, nodeRadius + 5, highlightPaint);
      }
      
      // Draw node text
      final nodeTextPainter = TextPainter(
        text: TextSpan(
          text: node.text,
          style: TextStyle(
            color: isSelected ? Colors.orange.shade900 : Colors.blue.shade800,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      nodeTextPainter.layout();
      final nodeTextOffset = Offset(
        node.position.dx - nodeTextPainter.width / 2,
        node.position.dy - nodeTextPainter.height / 2,
      );
      nodeTextPainter.paint(canvas, nodeTextOffset);
    }
  }

  @override
  bool shouldRepaint(covariant NodeCanvasPainter oldDelegate) {
    return oldDelegate.nodeList != nodeList ||
           oldDelegate.rootPosition != rootPosition ||
           oldDelegate.selectedNode != selectedNode;
  }
}
