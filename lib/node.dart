import 'package:flutter/material.dart';

class Node {
  final String id;
  Offset position;
  Offset? savedPosition;
  final String label;
  final Color color;
  final List<Node> children;
  Node? parent;

  Node({
    required this.id,
    required this.position,
    required this.label,
    required this.color,
    List<Node>? children,
    this.parent,
  }) : children = children ?? [];
}
