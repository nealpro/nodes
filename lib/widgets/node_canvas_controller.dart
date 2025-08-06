import 'package:flutter/material.dart';
import '../models/node.dart';

class NodeCanvasController extends ChangeNotifier {
  late NodeTree nodeTree;
  Node? _draggedNode;
  Node? _selectedNode;
  Node? _editingNode;
  late Size _canvasSize;
  late Offset stemPosition;

  final TextEditingController textEditingController = TextEditingController();
  final FocusNode textEditingFocusNode = FocusNode();
  final FocusNode canvasFocusNode = FocusNode();

  static const double nodeRadius = 25.0;

  NodeCanvasController() {
    _initializeNodeTree();
  }

  // Getters
  Node? get draggedNode => _draggedNode;
  Node? get selectedNode => _selectedNode;
  Node? get editingNode => _editingNode;
  Size get canvasSize => _canvasSize;

  void _initializeNodeTree() {
    nodeTree = NodeTree();

    // Create a sample tree structure for demonstration
    final rootNode = Node(
      id: 'root_child1',
      text: 'Root Child 1',
      position: const Offset(300, 150),
    );

    final rootNode2 = Node(
      id: 'root_child2',
      text: 'Root Child 2',
      position: const Offset(450, 250),
    );

    final childNode1 = Node(
      id: 'child1_1',
      text: 'Child 1.1',
      position: const Offset(200, 200),
    );

    final childNode2 = Node(
      id: 'child1_2',
      text: 'Child 1.2',
      position: const Offset(350, 100),
    );

    final grandChildNode = Node(
      id: 'grandchild1',
      text: 'Grandchild 1',
      position: const Offset(150, 250),
    );

    // Build the tree structure
    nodeTree.addNode(rootNode);
    nodeTree.addNode(rootNode2);
    nodeTree.addNode(childNode1, parent: rootNode);
    nodeTree.addNode(childNode2, parent: rootNode2);
    nodeTree.addNode(grandChildNode, parent: childNode1);
  }

  void updateCanvasSize(Size size) {
    _canvasSize = size;
    stemPosition = Offset(size.width / 2, size.height / 2);
    notifyListeners();
  }

  // Helper method to find which node (if any) is at the given position
  Node? getNodeAtPosition(Offset position) {
    final nodes = nodeTree.toList();
    for (final node in nodes) {
      final distance = (node.position - position).distance;
      if (distance <= nodeRadius) {
        return node;
      }
    }
    return null;
  }

  // Helper method to constrain node position within canvas bounds
  Offset constrainPositionToBounds(Offset position) {
    final constrainedX = position.dx.clamp(
      nodeRadius,
      _canvasSize.width - nodeRadius,
    );
    final constrainedY = position.dy.clamp(
      nodeRadius,
      _canvasSize.height - nodeRadius,
    );
    return Offset(constrainedX, constrainedY);
  }

  void setSelectedNode(Node? node) {
    _selectedNode = node;
    notifyListeners();
  }

  void setEditingNode(Node? node) {
    _editingNode = node;
    notifyListeners();
  }

  void setDraggedNode(Node? node) {
    _draggedNode = node;
    notifyListeners();
  }

  void updateNodePosition(Node node, Offset position) {
    node.position = constrainPositionToBounds(position);
    notifyListeners();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    textEditingFocusNode.dispose();
    canvasFocusNode.dispose();
    super.dispose();
  }
}
