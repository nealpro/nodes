import 'package:flutter/material.dart';
import 'package:nodes/node.dart';

class NodeWidget extends StatelessWidget {
  final Node node;

  const NodeWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: node.color, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(node.label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '(${node.position.dx.toInt()}, ${node.position.dy.toInt()})',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
