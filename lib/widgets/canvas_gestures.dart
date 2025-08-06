import 'package:flutter/material.dart';
import '../models/node.dart';
import 'node_canvas_controller.dart';

class CanvasGestures extends StatelessWidget {
  final NodeCanvasController controller;
  final VoidCallback onFinishTextEditing;
  final Function(Node) onStartTextEditing;
  final Function(Node) onCreateChild;
  final Widget child;

  const CanvasGestures({
    super.key,
    required this.controller,
    required this.onFinishTextEditing,
    required this.onStartTextEditing,
    required this.onCreateChild,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        if (controller.editingNode != null) {
          onFinishTextEditing();
          return;
        }
        final position = details.localPosition;
        final draggedNode = controller.getNodeAtPosition(position);
        controller.setDraggedNode(draggedNode);
        if (draggedNode != null) {
          debugPrint('Started dragging ${draggedNode.text}');
        }
      },
      onPanUpdate: (details) {
        if (controller.draggedNode != null) {
          controller.updateNodePosition(
            controller.draggedNode!,
            details.localPosition,
          );
        }
      },
      onPanEnd: (details) {
        if (controller.draggedNode != null) {
          debugPrint('Finished dragging ${controller.draggedNode!.text}');
          controller.setDraggedNode(null);
        }
      },
      onTapDown: (details) {
        if (controller.editingNode != null) {
          onFinishTextEditing();
          return;
        }

        final tapPosition = details.localPosition;
        final tappedNode = controller.getNodeAtPosition(tapPosition);

        if (tappedNode != null) {
          // Select/deselect the tapped node
          if (controller.selectedNode == tappedNode) {
            controller.setSelectedNode(null); // Deselect if already selected
            debugPrint('Deselected ${tappedNode.text}');
          } else {
            controller.setSelectedNode(tappedNode); // Select the tapped node
            debugPrint('Selected ${tappedNode.text}');
          }
        } else {
          // Tap on empty space - deselect any selected node
          if (controller.selectedNode != null) {
            debugPrint('Deselected ${controller.selectedNode!.text}');
            controller.setSelectedNode(null);
          }
          debugPrint('Tapped at: ${tapPosition.dx}, ${tapPosition.dy}');
        }

        // Ensure canvas has focus for keyboard shortcuts
        controller.canvasFocusNode.requestFocus();
      },
      onLongPressStart: (details) {
        if (controller.editingNode != null) return;

        final longPressPosition = details.localPosition;
        final longPressedNode = controller.getNodeAtPosition(longPressPosition);

        if (longPressedNode != null) {
          // Long press on node - create child node (mobile)
          controller.setSelectedNode(longPressedNode);
          onCreateChild(longPressedNode);
          debugPrint('Long pressed ${longPressedNode.text} - creating child');
        }
      },
      onDoubleTap: () {
        // Double tap to edit selected node (mobile only)
        if (controller.selectedNode != null && controller.editingNode == null) {
          onStartTextEditing(controller.selectedNode!);
        }
      },
      child: child,
    );
  }
}
