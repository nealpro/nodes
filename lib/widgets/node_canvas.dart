import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/node.dart';
import 'node_canvas_painter.dart';

class NodeCanvas extends StatefulWidget {
  const NodeCanvas({super.key});

  @override
  State<NodeCanvas> createState() => NodeCanvasState();
}

class NodeCanvasState extends State<NodeCanvas> {
  late NodeTree nodeTree;
  late Offset stemPosition;
  Node? _draggedNode;
  Node? _selectedNode;
  Node? _editingNode;
  late Size _canvasSize;
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _textEditingFocusNode = FocusNode();
  final FocusNode _canvasFocusNode = FocusNode();
  static const double nodeRadius = 25.0;

  @override
  void dispose() {
    _textEditingController.dispose();
    _textEditingFocusNode.dispose();
    _canvasFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
    nodeTree.addNode(rootNode); // First node becomes root
    nodeTree.addNode(rootNode2); // Second node also connects to root
    nodeTree.addNode(childNode1, parent: rootNode); // Child of first root node
    nodeTree.addNode(
      childNode2,
      parent: rootNode2,
    ); // Another child of first root node
    nodeTree.addNode(grandChildNode, parent: childNode1); // Grandchild
  }

  // Helper method to find which node (if any) is at the given position
  Node? _getNodeAtPosition(Offset position) {
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
  Offset _constrainPositionToBounds(Offset position) {
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

  // Method to add a root node (called from main.dart)
  void addRootNode() {
    _createNewNode(null);
  }

  // Method to add a sibling node (called from main.dart)
  void addSiblingNode() {
    if (_selectedNode == null) return;
    _createSiblingNode(_selectedNode!);
  }

  // Method to create a new node (as child of selected node or as root)
  void _createNewNode(Node? parent) {
    final String nodeId = 'node_${DateTime.now().millisecondsSinceEpoch}';

    // Determine position for new node
    Offset newPosition;
    if (parent != null) {
      // Position child node nearby the parent, trying to avoid overlaps
      double angle =
          parent.children.length * 0.5; // Spread children around parent
      double distance = 80;
      newPosition = Offset(
        parent.position.dx + distance * math.cos(angle),
        parent.position.dy + distance * math.sin(angle),
      );
    } else {
      // Position root node near the stem
      final rootChildren = nodeTree.root?.children.length ?? 0;
      double angle = rootChildren * 0.8;
      double distance = 120;
      newPosition = Offset(
        stemPosition.dx + distance * math.cos(angle),
        stemPosition.dy + distance * math.sin(angle),
      );
    }

    // Constrain to canvas bounds
    newPosition = _constrainPositionToBounds(newPosition);

    final newNode = Node(id: nodeId, text: 'New Node', position: newPosition);

    setState(() {
      nodeTree.addNode(newNode, parent: parent);
      _selectedNode = newNode;
      _startTextEditing(newNode);
    });
  }

  // Method to create a sibling node (parallel to selected node)
  void _createSiblingNode(Node selectedNode) {
    final String nodeId = 'node_${DateTime.now().millisecondsSinceEpoch}';

    // Get the parent of the selected node
    Node? parent = selectedNode.parent;

    // If selected node is a root node, create another root node
    if (parent == null) {
      _createNewNode(null);
      return;
    }

    // Determine position for new sibling node
    // Position it near the selected node but slightly offset
    double offsetDistance = 60; // Distance from the selected sibling
    double angle =
        (parent.children.length * 0.8) +
        1.5; // Different angle from existing children

    Offset newPosition = Offset(
      selectedNode.position.dx + offsetDistance * math.cos(angle),
      selectedNode.position.dy + offsetDistance * math.sin(angle),
    );

    // If the position would overlap with existing nodes, try a different offset
    final nodes = nodeTree.toList();
    bool positionTaken = nodes.any(
      (node) => (node.position - newPosition).distance < nodeRadius * 2,
    );

    if (positionTaken) {
      // Try positioning on the opposite side
      newPosition = Offset(
        selectedNode.position.dx - offsetDistance * math.cos(angle),
        selectedNode.position.dy - offsetDistance * math.sin(angle),
      );
    }

    // Constrain to canvas bounds
    newPosition = _constrainPositionToBounds(newPosition);

    final newNode = Node(id: nodeId, text: 'New Node', position: newPosition);

    setState(() {
      nodeTree.addNode(newNode, parent: parent);
      _selectedNode = newNode;
      _startTextEditing(newNode);
    });
  }

  // Start text editing for a node
  void _startTextEditing(Node node) {
    setState(() {
      _editingNode = node;
      _textEditingController.text = node.text;
    });

    // Focus and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textEditingFocusNode.requestFocus();
      _textEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textEditingController.text.length,
      );
    });
  }

  // Finish text editing
  void _finishTextEditing() {
    if (_editingNode != null) {
      setState(() {
        _editingNode!.text = _textEditingController.text.trim().isEmpty
            ? 'New Node'
            : _textEditingController.text.trim();
        _editingNode = null;
      });
    }
  }

  // Delete the selected node
  void _deleteSelectedNode() {
    if (_selectedNode == null || _editingNode != null) return;

    final nodeToDelete = _selectedNode!;
    setState(() {
      // If we're deleting the selected node, clear selection first
      if (_selectedNode == nodeToDelete) {
        _selectedNode = null;
      }

      // Remove the node from the tree
      nodeTree.removeNode(nodeToDelete.id);

      debugPrint('Deleted node: ${nodeToDelete.text}');
    });
  }

  // Get help text for when a node is selected
  String _getSelectedNodeHelpText() {
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isDesktop) {
      return 'Press N to add child • Press O to add sibling • Press E to edit • Press Delete to remove • Long press (mobile) to add child';
    } else {
      return 'Press N to add child • Double-tap to edit • Long press to add child • Use sibling button in top bar';
    }
  }

  // Get default help text for when no node is selected
  String _getDefaultHelpText() {
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isDesktop) {
      return 'Select a node first • Use + button to add root node • Press E to edit nodes on desktop';
    } else {
      return 'Select a node first • Use + button to add root node • Double-tap nodes to edit';
    }
  }

  // Handle keyboard input
  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyN &&
          _selectedNode != null &&
          _editingNode == null) {
        // Create child node when 'N' is pressed and a node is selected
        _createNewNode(_selectedNode);
      } else if (event.logicalKey == LogicalKeyboardKey.keyO &&
          _selectedNode != null &&
          _editingNode == null) {
        // Create sibling node when 'O' is pressed and a node is selected
        _createSiblingNode(_selectedNode!);
      } else if (event.logicalKey == LogicalKeyboardKey.keyE &&
          _selectedNode != null &&
          _editingNode == null &&
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        // Edit node when 'E' is pressed on desktop platforms
        _startTextEditing(_selectedNode!);
      } else if ((event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) &&
          _selectedNode != null &&
          _editingNode == null) {
        // Delete node when Delete or Backspace is pressed
        _deleteSelectedNode();
      } else if (event.logicalKey == LogicalKeyboardKey.escape &&
          _editingNode != null) {
        // Cancel text editing on Escape
        setState(() {
          _editingNode = null;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter &&
          _editingNode != null) {
        // Finish text editing on Enter
        _finishTextEditing();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Position stem in the center of the available space
        stemPosition = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );

        return KeyboardListener(
          focusNode: _canvasFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyPress,
          child: GestureDetector(
            onTap: () {
              // Ensure keyboard focus is maintained for shortcuts
              _canvasFocusNode.requestFocus();
            },
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                children: [
                  GestureDetector(
                    onPanStart: (details) {
                      if (_editingNode != null) {
                        _finishTextEditing();
                        return;
                      }
                      final position = details.localPosition;
                      _draggedNode = _getNodeAtPosition(position);
                      if (_draggedNode != null) {
                        debugPrint('Started dragging ${_draggedNode!.text}');
                      }
                    },
                    onPanUpdate: (details) {
                      if (_draggedNode != null) {
                        setState(() {
                          _draggedNode!.position = _constrainPositionToBounds(
                            details.localPosition,
                          );
                        });
                      }
                    },
                    onPanEnd: (details) {
                      if (_draggedNode != null) {
                        debugPrint('Finished dragging ${_draggedNode!.text}');
                        _draggedNode = null;
                      }
                    },
                    onTapDown: (details) {
                      if (_editingNode != null) {
                        _finishTextEditing();
                        return;
                      }

                      final tapPosition = details.localPosition;
                      final tappedNode = _getNodeAtPosition(tapPosition);

                      setState(() {
                        if (tappedNode != null) {
                          // Select/deselect the tapped node
                          if (_selectedNode == tappedNode) {
                            _selectedNode =
                                null; // Deselect if already selected
                            debugPrint('Deselected ${tappedNode.text}');
                          } else {
                            _selectedNode =
                                tappedNode; // Select the tapped node
                            debugPrint('Selected ${tappedNode.text}');
                          }
                        } else {
                          // Tap on empty space - deselect any selected node
                          if (_selectedNode != null) {
                            debugPrint('Deselected ${_selectedNode!.text}');
                            _selectedNode = null;
                          }
                          debugPrint(
                            'Tapped at: ${tapPosition.dx}, ${tapPosition.dy}',
                          );
                        }
                      });

                      // Ensure canvas has focus for keyboard shortcuts
                      _canvasFocusNode.requestFocus();
                    },
                    onLongPressStart: (details) {
                      if (_editingNode != null) return;

                      final longPressPosition = details.localPosition;
                      final longPressedNode = _getNodeAtPosition(
                        longPressPosition,
                      );

                      if (longPressedNode != null) {
                        // Long press on node - create child node (mobile)
                        setState(() {
                          _selectedNode = longPressedNode;
                        });
                        _createNewNode(longPressedNode);
                        debugPrint(
                          'Long pressed ${longPressedNode.text} - creating child',
                        );
                      }
                    },
                    onDoubleTap: () {
                      // Double tap to edit selected node (mobile only)
                      if (_selectedNode != null &&
                          _editingNode == null &&
                          (kIsWeb ||
                              defaultTargetPlatform == TargetPlatform.android ||
                              defaultTargetPlatform == TargetPlatform.iOS)) {
                        _startTextEditing(_selectedNode!);
                      }
                    },
                    child: CustomPaint(
                      painter: NodeCanvasPainter(
                        nodeTree: nodeTree,
                        stemPosition: stemPosition,
                        selectedNode: _selectedNode,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  ),
                  // Text editing overlay
                  if (_editingNode != null)
                    Positioned(
                      left: (_editingNode!.position.dx - 60).clamp(
                        0,
                        constraints.maxWidth - 120,
                      ),
                      top: (_editingNode!.position.dy - 15).clamp(
                        0,
                        constraints.maxHeight - 40,
                      ),
                      child: Container(
                        width: 120,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _textEditingController,
                          focusNode: _textEditingFocusNode,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _finishTextEditing(),
                          onTapOutside: (_) => _finishTextEditing(),
                        ),
                      ),
                    ),
                  // Help text overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedNode != null && _editingNode == null
                            ? _getSelectedNodeHelpText()
                            : _editingNode != null
                            ? 'Press Enter to save • Press Escape to cancel • Tap outside to save'
                            : _getDefaultHelpText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
