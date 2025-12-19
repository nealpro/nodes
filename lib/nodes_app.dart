import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'models/node.dart';
import 'widgets/node_operations.dart';
import 'components/node_component.dart';
import 'components/stem_component.dart';
import 'components/connection_component.dart';
import 'package:flutter/services.dart';

class NodesApp extends FlameGame {
  // Keyboard and gesture handling moved from main.dart
  Widget buildInteractionLayer() {
    final focusNode = FocusNode();
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyN &&
              selectedNode != null) {
            addChildNode();
          } else if (event.logicalKey == LogicalKeyboardKey.keyO &&
              selectedNode != null) {
            addSiblingNode();
          } else if (event.logicalKey == LogicalKeyboardKey.keyE &&
              selectedNode != null) {
            // Start editing
            // For now, just print
            print('Start editing [32m${selectedNode!.text}[0m');
          } else if (event.logicalKey == LogicalKeyboardKey.delete &&
              selectedNode != null) {
            deleteSelectedNode();
          }
          // Add more keys as needed
        }
      },
      child: GestureDetector(
        onTapDown: (details) {
          final gamePosition = Vector2(
            details.localPosition.dx,
            details.localPosition.dy,
          );
          final componentsAtTap = componentsAtPoint(
            gamePosition,
          ).whereType<NodeComponent>();
          if (componentsAtTap.isNotEmpty) {
            final tappedNode = componentsAtTap.first.node;
            if (selectedNode == tappedNode) {
              selectedNode = null;
            } else {
              selectedNode = tappedNode;
            }
            // Update selection for all components
            for (final component in children.whereType<NodeComponent>()) {
              component.updateSelection(selectedNode);
            }
          } else {
            selectedNode = null;
            for (final component in children.whereType<NodeComponent>()) {
              component.updateSelection(null);
            }
          }
        },
        onPanStart: (details) {
          final gamePosition = Vector2(
            details.localPosition.dx,
            details.localPosition.dy,
          );
          final componentsAtDrag = componentsAtPoint(
            gamePosition,
          ).whereType<NodeComponent>();
          if (componentsAtDrag.isNotEmpty) {
            draggedNode = componentsAtDrag.first.node;
          }
        },
        onPanUpdate: (details) {
          if (draggedNode != null) {
            final delta = Offset(details.delta.dx, details.delta.dy);
            final newPosition = draggedNode!.position + delta;
            draggedNode!.position = constrainPositionToBounds(newPosition);
            // Update the component position
            final component = children.whereType<NodeComponent>().firstWhere(
              (comp) => comp.node == draggedNode,
            );
            component.position = Vector2(
              draggedNode!.position.dx,
              draggedNode!.position.dy,
            );
          }
        },
        onPanEnd: (details) {
          draggedNode = null;
        },
        child: GameWidget(game: this),
      ),
    );
  }

  late NodeTree nodeTree;
  Node? selectedNode;
  Node? draggedNode;
  late Vector2 stemPosition;
  static const double stemRadius = 40.0;
  static const double nodeRadius = 25.0;

  @override
  Future<void> onLoad() async {
    // Set up viewport
    camera.viewport = FixedResolutionViewport(resolution: Vector2(800, 600));

    // Initialize stem position
    stemPosition = Vector2(400, 300); // Center of 800x600 viewport

    // Initialize node tree
    _initializeNodeTree();

    // Add components
    _addComponents();
  }

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

  void _addComponents() {
    // Add connection component (rendered first, behind everything)
    add(ConnectionComponent(this));

    // Add stem component
    add(StemComponent(stemPosition));

    // Add node components
    for (final node in nodeTree.toList()) {
      add(NodeComponent(node, this));
    }
  }

  // Public methods for UI actions
  void addRootNode() {
    _createNewNode(null);
  }

  void addSiblingNode() {
    if (selectedNode == null) return;
    _createSiblingNode(selectedNode!);
  }

  void addChildNode() {
    if (selectedNode == null) return;
    _createNewNode(selectedNode!);
  }

  void deleteSelectedNode() {
    if (selectedNode == null) return;

    final nodeToDelete = selectedNode!;
    selectedNode = null;

    // Remove from tree
    nodeTree.removeNode(nodeToDelete.id);

    // Remove component
    final component = children.whereType<NodeComponent>().firstWhere(
      (comp) => comp.node == nodeToDelete,
    );
    remove(component);
  }

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
        Offset(stemPosition.x, stemPosition.y),
        nodeTree.root?.children.length ?? 0,
      );
    }

    // Constrain to bounds
    newPosition = constrainPositionToBounds(newPosition);

    final newNode = Node(id: nodeId, text: 'New Node', position: newPosition);

    nodeTree.addNode(newNode, parent: parent);
    selectedNode = newNode;

    // Add component
    add(NodeComponent(newNode, this));

    // Update selection for all components
    for (final component in children.whereType<NodeComponent>()) {
      component.updateSelection(selectedNode);
    }
  }

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
      nodeTree.toList(),
      nodeRadius,
    );

    // Constrain to bounds
    newPosition = constrainPositionToBounds(newPosition);

    final newNode = Node(id: nodeId, text: 'New Node', position: newPosition);

    nodeTree.addNode(newNode, parent: parent);
    this.selectedNode = newNode;

    // Add component
    add(NodeComponent(newNode, this));

    // Update selection for all components
    for (final component in children.whereType<NodeComponent>()) {
      component.updateSelection(this.selectedNode);
    }
  }

  Offset constrainPositionToBounds(Offset position) {
    final viewport = camera.viewport;
    final size = viewport.size;
    final constrainedX = position.dx.clamp(nodeRadius, size.x - nodeRadius);
    final constrainedY = position.dy.clamp(nodeRadius, size.y - nodeRadius);
    return Offset(constrainedX, constrainedY);
  }
}
