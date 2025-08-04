import 'dart:ui';

class Node {
  String id;
  String text;
  Offset position;
  List<Node> children;
  Node? parent;

  Node({
    required this.id,
    required this.text,
    required this.position,
    List<Node>? children,
    this.parent,
  }) : children = children ?? [];

  // Add a child node to this node
  void addChild(Node child) {
    if (!children.contains(child)) {
      children.add(child);
      child.parent = this;
    }
  }

  // Remove a child node from this node
  void removeChild(Node child) {
    if (children.remove(child)) {
      child.parent = null;
    }
  }

  // Remove this node from its parent
  void removeFromParent() {
    parent?.removeChild(this);
  }

  // Get all descendants (children, grandchildren, etc.)
  List<Node> getAllDescendants() {
    List<Node> descendants = [];
    for (Node child in children) {
      descendants.add(child);
      descendants.addAll(child.getAllDescendants());
    }
    return descendants;
  }
}

class NodeTree {
  Node? root;
  final Map<String, Node> _nodeMap = {};

  int get length => _nodeMap.length;

  // Add a node as a child of the specified parent (or as root if no parent)
  void addNode(Node node, {Node? parent}) {
    if (_nodeMap.containsKey(node.id)) {
      // Node already exists, don't add duplicate
      return;
    }

    _nodeMap[node.id] = node;

    if (parent != null && _nodeMap.containsKey(parent.id)) {
      parent.addChild(node);
    } else {
      root ??= node;
    }
  }

  // Remove a node and all its descendants
  void removeNode(String id) {
    final node = _nodeMap[id];
    if (node == null) return;

    // Remove all descendants first
    final descendants = node.getAllDescendants();
    for (final descendant in descendants) {
      _nodeMap.remove(descendant.id);
    }

    // Remove from parent
    node.removeFromParent();

    // Remove the node itself
    _nodeMap.remove(id);

    // If removing root, promote first child if any
    if (node == root) {
      root = node.children.isNotEmpty ? node.children.first : null;
      if (root != null) {
        root!.parent = null;
      }
    }
  }

  // Find a node by ID
  Node? findById(String id) {
    return _nodeMap[id];
  }

  // Get all nodes as a flat list
  List<Node> toList() {
    return _nodeMap.values.toList();
  }

  // Get all nodes in a breadth-first order starting from root
  List<Node> toBreadthFirstList() {
    if (root == null) return [];

    List<Node> result = [];
    List<Node> queue = [root!];

    while (queue.isNotEmpty) {
      Node current = queue.removeAt(0);
      result.add(current);
      queue.addAll(current.children);
    }

    return result;
  }

  // Get all nodes in a depth-first order starting from root
  List<Node> toDepthFirstList() {
    if (root == null) return [];

    List<Node> result = [];

    void dfs(Node node) {
      result.add(node);
      for (Node child in node.children) {
        dfs(child);
      }
    }

    dfs(root!);
    return result;
  }

  // Clear all nodes
  void clear() {
    _nodeMap.clear();
    root = null;
  }
}
