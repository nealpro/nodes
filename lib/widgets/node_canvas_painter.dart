import 'package:flutter/material.dart';
import '../models/node.dart';

class NodeCanvasPainter extends CustomPainter {
  final NodeTree nodeTree;
  final Offset stemPosition;
  final double stemRadius;
  final Node? selectedNode;

  NodeCanvasPainter({
    required this.nodeTree,
    required this.stemPosition,
    this.stemRadius = 40.0,
    this.selectedNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = nodeTree.toList();

    // STEP 1: Draw connection lines first (so they appear behind nodes)
    final connectionPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw connections from stem to its direct children
    if (nodeTree.root != null) {
      for (final child in nodeTree.root!.children) {
        canvas.drawLine(stemPosition, child.position, connectionPaint);
      }
    }

    // Draw connections between parent and child nodes (excluding root)
    for (final node in nodes) {
      for (final child in node.children) {
        canvas.drawLine(node.position, child.position, connectionPaint);
      }
    }

    // STEP 2: Draw the stem circle and text
    final stemPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.fill;

    final stemBorderPaint = Paint()
      ..color = Colors.deepPurple.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw stem circle
    canvas.drawCircle(stemPosition, stemRadius, stemPaint);
    canvas.drawCircle(stemPosition, stemRadius, stemBorderPaint);

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
      stemPosition.dx - stemTextPainter.width / 2,
      stemPosition.dy - stemTextPainter.height / 2,
    );
    stemTextPainter.paint(canvas, stemTextOffset);

    // STEP 3: Draw nodes with proper styling and text
    const minNodeWidth = 60.0; // Minimum width for nodes
    const nodeHeight = 60.0; // Fixed height for nodes
    const cornerRadius = 8.0;
    const textPadding = 8.0;
    const maxLines = 3;

    for (final node in nodes) {
      // Determine if this node is selected
      final isSelected = selectedNode != null && selectedNode!.id == node.id;

      // Draw node text with custom word wrapping and dynamic sizing
      final textStyle = TextStyle(
        color: isSelected ? Colors.orange.shade900 : Colors.blue.shade800,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
      );

      // First, split text into words and build lines without width constraints
      final words = node.text.split(' ');
      final lines = <String>[];
      String currentLine = '';

      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        final testLine = currentLine.isEmpty ? word : '$currentLine $word';

        // If we haven't hit the max lines yet, just keep adding words to build natural lines
        if (lines.length < maxLines - 1) {
          // For the first two lines, we can be more generous with width
          final testPainter = TextPainter(
            text: TextSpan(text: testLine, style: textStyle),
            textDirection: TextDirection.ltr,
          );
          testPainter.layout();

          // Use a reasonable max width (e.g., 120px) but allow expansion
          if (testPainter.width <= 120.0 || currentLine.isEmpty) {
            currentLine = testLine;
          } else {
            // Line is getting too long, break here
            lines.add(currentLine);
            currentLine = word;
          }
        } else {
          // This is the last line - we need to handle truncation
          final remainingWords = words.sublist(i);
          final remainingText = remainingWords.join(' ');

          // Try to fit remaining text on the last line
          final testLastLine = currentLine.isEmpty
              ? remainingText
              : '$currentLine $remainingText';
          final testPainter = TextPainter(
            text: TextSpan(text: testLastLine, style: textStyle),
            textDirection: TextDirection.ltr,
          );
          testPainter.layout();

          if (testPainter.width <= 120.0) {
            // All remaining text fits
            currentLine = testLastLine;
            break;
          } else {
            // Need to truncate with ellipsis
            String truncatedLine = currentLine.isEmpty
                ? word
                : '$currentLine $word';

            // Keep adding words until we can't fit anymore
            for (int j = i + 1; j < words.length; j++) {
              final testWithNext = '$truncatedLine ${words[j]}';
              final testPainter = TextPainter(
                text: TextSpan(text: '$testWithNext...', style: textStyle),
                textDirection: TextDirection.ltr,
              );
              testPainter.layout();

              if (testPainter.width <= 120.0) {
                truncatedLine = testWithNext;
              } else {
                break;
              }
            }

            currentLine = '$truncatedLine...';
            break;
          }
        }
      }

      // Add the last line if it's not empty
      if (currentLine.isNotEmpty) {
        lines.add(currentLine);
      }

      // Create the final text and measure it
      final finalText = lines.join('\n');
      final nodeTextPainter = TextPainter(
        text: TextSpan(text: finalText, style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      nodeTextPainter.layout();

      // Calculate dynamic node width based on text width
      final textWidth = nodeTextPainter.width;
      final nodeWidth = (textWidth + (textPadding * 2)).clamp(
        minNodeWidth,
        180.0,
      );

      // Use different colors for selected vs unselected nodes
      final nodePaint = Paint()
        ..color = isSelected ? Colors.orange.shade200 : Colors.blue.shade100
        ..style = PaintingStyle.fill;

      final nodeBorderPaint = Paint()
        ..color = isSelected ? Colors.orange.shade700 : Colors.blue.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 2.0;

      // Create rounded rectangle for node with dynamic width
      final nodeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: node.position,
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
            center: node.position,
            width: nodeWidth + 10,
            height: nodeHeight + 10,
          ),
          const Radius.circular(cornerRadius + 5),
        );
        canvas.drawRRect(highlightRect, highlightPaint);
      }

      // Draw the text
      final nodeTextOffset = Offset(
        node.position.dx - nodeTextPainter.width / 2,
        node.position.dy - nodeTextPainter.height / 2,
      );
      nodeTextPainter.paint(canvas, nodeTextOffset);
    }
  }

  @override
  bool shouldRepaint(covariant NodeCanvasPainter oldDelegate) {
    return oldDelegate.nodeTree != nodeTree ||
        oldDelegate.stemPosition != stemPosition ||
        oldDelegate.selectedNode != selectedNode;
  }
}
