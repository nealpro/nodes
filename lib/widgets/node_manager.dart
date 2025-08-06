import 'package:flutter/material.dart';
import '../models/node.dart';
import 'node_operations.dart';
import 'node_canvas_controller.dart';

class NodeManager {
  final NodeCanvasController controller;

  NodeManager(this.controller);

  // Method to add a root node (called from main.dart)
  void addRootNode() {
    _createNewNode(null);
  }

  // Method to add a child node to the selected node
  void addChildNode() {
    if (controller.selectedNode == null) return;
    _createNewNode(controller.selectedNode!);
  }

  // Method to add a sibling node (called from main.dart)
  void addSiblingNode() {
    if (controller.selectedNode == null) return;
    _createSiblingNode(controller.selectedNode!);
  }

  // Method to create a new node (as child of selected node or as root)
  void _createNewNode(Node? parent) {
    final String nodeId = NodeOperations.generateNodeId();

    // Determine position for new node
    Offset newPosition;
    if (parent != null) {
      newPosition = NodeOperations.calculateChildPosition(
        parent,
        parent.children.length,
      );
    } else {
      newPosition = NodeOperations.calculateRootPosition(
        controller.stemPosition,
        controller.nodeTree.root?.children.length ?? 0,
      );
    }

    // Constrain to canvas bounds
    newPosition = controller.constrainPositionToBounds(newPosition);

    final newNode = Node(id: nodeId, text: 'New Node', position: newPosition);

    controller.nodeTree.addNode(newNode, parent: parent);
    controller.setSelectedNode(newNode);
  }

  // Method to create a sibling node (parallel to selected node)
  void _createSiblingNode(Node selectedNode) {
    final String nodeId = NodeOperations.generateNodeId();

    // Get the parent of the selected node
    Node? parent = selectedNode.parent;

    // If selected node is a root node, create another root node
    if (parent == null) {
      _createNewNode(null);
      return;
    }

    // Determine position for new sibling node
    Offset newPosition = NodeOperations.calculateSiblingPosition(
      selectedNode,
      parent,
      parent.children.length,
      controller.nodeTree.toList(),
      NodeCanvasController.nodeRadius,
    );

    // Constrain to canvas bounds
    newPosition = controller.constrainPositionToBounds(newPosition);

    final newNode = Node(id: nodeId, text: 'New Node', position: newPosition);

    controller.nodeTree.addNode(newNode, parent: parent);
    controller.setSelectedNode(newNode);
  }

  // Start text editing for a node
  void startTextEditing(Node node) {
    controller.setEditingNode(node);
    controller.textEditingController.text = node.text;

    // Focus and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.textEditingFocusNode.requestFocus();
      controller.textEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.textEditingController.text.length,
      );
    });
  }

  // Finish text editing
  void finishTextEditing() {
    if (controller.editingNode != null) {
      controller.editingNode!.text =
          controller.textEditingController.text.trim().isEmpty
          ? 'New Node'
          : controller.textEditingController.text.trim();
      controller.setEditingNode(null);
    }
  }

  // Delete the selected node
  void deleteSelectedNode() {
    if (controller.selectedNode == null || controller.editingNode != null) {
      return;
    }

    final nodeToDelete = controller.selectedNode!;

    // If we're deleting the selected node, clear selection first
    if (controller.selectedNode == nodeToDelete) {
      controller.setSelectedNode(null);
    }

    // Remove the node from the tree
    controller.nodeTree.removeNode(nodeToDelete.id);

    debugPrint('Deleted node: ${nodeToDelete.text}');
  }

  // Cancel text editing
  void cancelTextEditing() {
    controller.setEditingNode(null);
  }
}
