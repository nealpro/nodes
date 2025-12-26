import 'package:flutter/material.dart';
import 'package:nodes/node.dart';

class NodeWidget extends StatelessWidget {
  final Node node;
  final bool isSelected;

  const NodeWidget({super.key, required this.node, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 60,
      decoration: BoxDecoration(
        color: isSelected ? node.color.withValues(alpha: 0.2) : Colors.white,
        border: Border.all(color: node.color, width: isSelected ? 4 : 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? node.color.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: isSelected ? 12 : 8,
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
