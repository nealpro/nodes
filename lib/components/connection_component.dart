import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../nodes_app.dart';

class ConnectionComponent extends Component {
  final NodesApp game;

  ConnectionComponent(this.game);

  @override
  void render(Canvas canvas) {
    final connectionPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final nodes = game.nodeTree.toList();

    // Draw connections from stem to its direct children
    if (game.nodeTree.root != null) {
      for (final child in game.nodeTree.root!.children) {
        canvas.drawLine(
          game.stemPosition.toOffset(),
          child.position,
          connectionPaint,
        );
      }
    }

    // Draw connections between parent and child nodes (excluding root)
    for (final node in nodes) {
      for (final child in node.children) {
        canvas.drawLine(node.position, child.position, connectionPaint);
      }
    }
  }
}
