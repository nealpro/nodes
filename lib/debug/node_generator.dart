import 'dart:math';
import 'package:flutter/material.dart';
import '../node.dart';

void generateNodes(List<Node> nodes, double canvasSize) {
  const int totalNodes = 30;
  final Random random = Random();

  nodes.clear();

  // Create root node
  nodes.add(
    Node(
      id: 'node_0',
      position: Offset(
        random.nextDouble() * (canvasSize - 150),
        random.nextDouble() * (canvasSize - 100),
      ),
      label: 'Node 0',
      color: Colors.primaries[random.nextInt(Colors.primaries.length)],
    ),
  );

  int parentIndex = 0;
  while (nodes.length < totalNodes) {
    // Safety check, though logic ensures we shouldn't run out of parents before hitting totalNodes
    if (parentIndex >= nodes.length) break;

    final parent = nodes[parentIndex];

    // Add up to 3 children for this parent
    for (int i = 0; i < 3; i++) {
      if (nodes.length >= totalNodes) break;

      final newNode = Node(
        id: 'node_${nodes.length}',
        position: Offset(
          random.nextDouble() * (canvasSize - 150),
          random.nextDouble() * (canvasSize - 100),
        ),
        label: 'Node ${nodes.length}',
        color: Colors.primaries[random.nextInt(Colors.primaries.length)],
        parent: parent,
      );

      nodes.add(newNode);
      parent.children.add(newNode);
    }
    parentIndex++;
  }
}
