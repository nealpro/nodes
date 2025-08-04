import 'package:flutter/material.dart';
import '../models/node.dart';
import 'node_canvas_painter.dart';

class NodeCanvas extends StatefulWidget {
  const NodeCanvas({super.key});

  @override
  State<NodeCanvas> createState() => _NodeCanvasState();
}

class _NodeCanvasState extends State<NodeCanvas> {
  late NodeLinkedList nodeList;
  late Offset rootPosition;
  Node? _draggedNode;
  Node? _selectedNode;
  late Size _canvasSize;
  static const double nodeRadius = 25.0;

  @override
  void initState() {
    super.initState();
    nodeList = NodeLinkedList();
    
    // Add some sample nodes with different positions for demonstration
    nodeList.add(Node(
      id: 'node1',
      text: 'Node 1',
      position: const Offset(300, 150),
    ));
    
    nodeList.add(Node(
      id: 'node2',
      text: 'Node 2',
      position: const Offset(450, 250),
    ));
    
    nodeList.add(Node(
      id: 'node3',
      text: 'Node 3',
      position: const Offset(200, 300),
    ));
  }

  // Helper method to find which node (if any) is at the given position
  Node? _getNodeAtPosition(Offset position) {
    final nodes = nodeList.toList();
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
    final constrainedX = position.dx.clamp(nodeRadius, _canvasSize.width - nodeRadius);
    final constrainedY = position.dy.clamp(nodeRadius, _canvasSize.height - nodeRadius);
    return Offset(constrainedX, constrainedY);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Position root in the center of the available space
        rootPosition = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );

        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: GestureDetector(
            onPanStart: (details) {
              final position = details.localPosition;
              _draggedNode = _getNodeAtPosition(position);
              if (_draggedNode != null) {
                debugPrint('Started dragging ${_draggedNode!.text}');
              }
            },
            onPanUpdate: (details) {
              if (_draggedNode != null) {
                setState(() {
                  _draggedNode!.position = _constrainPositionToBounds(details.localPosition);
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
              final tapPosition = details.localPosition;
              final tappedNode = _getNodeAtPosition(tapPosition);
              
              setState(() {
                if (tappedNode != null) {
                  // Select/deselect the tapped node
                  if (_selectedNode == tappedNode) {
                    _selectedNode = null; // Deselect if already selected
                    debugPrint('Deselected ${tappedNode.text}');
                  } else {
                    _selectedNode = tappedNode; // Select the tapped node
                    debugPrint('Selected ${tappedNode.text}');
                  }
                } else {
                  // Tap on empty space - deselect any selected node
                  if (_selectedNode != null) {
                    debugPrint('Deselected ${_selectedNode!.text}');
                    _selectedNode = null;
                  }
                  debugPrint('Tapped at: ${tapPosition.dx}, ${tapPosition.dy}');
                }
              });
            },
            child: CustomPaint(
              painter: NodeCanvasPainter(
                nodeList: nodeList,
                rootPosition: rootPosition,
                selectedNode: _selectedNode,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
          ),
        );
      },
    );
  }
}
