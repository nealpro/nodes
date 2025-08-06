import 'package:flutter/material.dart';
import '../models/node.dart';
import 'dart:math' as math;

class NodeOperations {
  static String generateNodeId() {
    return 'node_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Offset calculateChildPosition(Node parent, int childIndex) {
    double angle = childIndex * 0.5; // Spread children around parent
    double distance = 80;
    return Offset(
      parent.position.dx + distance * math.cos(angle),
      parent.position.dy + distance * math.sin(angle),
    );
  }

  static Offset calculateRootPosition(Offset stemPosition, int rootIndex) {
    double angle = rootIndex * 0.8;
    double distance = 120;
    return Offset(
      stemPosition.dx + distance * math.cos(angle),
      stemPosition.dy + distance * math.sin(angle),
    );
  }

  static Offset calculateSiblingPosition(
    Node selectedNode,
    Node parent,
    int siblingIndex,
    List<Node> allNodes,
    double nodeRadius,
  ) {
    double offsetDistance = 60; // Distance from the selected sibling
    double angle =
        (siblingIndex * 0.8) + 1.5; // Different angle from existing children

    Offset newPosition = Offset(
      selectedNode.position.dx + offsetDistance * math.cos(angle),
      selectedNode.position.dy + offsetDistance * math.sin(angle),
    );

    // If the position would overlap with existing nodes, try a different offset
    bool positionTaken = allNodes.any(
      (node) => (node.position - newPosition).distance < nodeRadius * 2,
    );

    if (positionTaken) {
      // Try positioning on the opposite side
      newPosition = Offset(
        selectedNode.position.dx - offsetDistance * math.cos(angle),
        selectedNode.position.dy - offsetDistance * math.sin(angle),
      );
    }

    return newPosition;
  }

  static bool shouldAvoidOverlap(
    Offset position,
    List<Node> nodes,
    double nodeRadius,
  ) {
    return nodes.any(
      (node) => (node.position - position).distance < nodeRadius * 2,
    );
  }
}
