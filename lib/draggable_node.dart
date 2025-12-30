import 'package:flutter/material.dart';
import 'package:nodes/node.dart';
import 'package:nodes/node_widget.dart';

/// A wrapper widget that handles node dragging with local state.
/// This prevents rebuilding the entire tree on every drag tick.
class DraggableNode extends StatefulWidget {
  final Node node;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(Offset newPosition) onDragEnd;
  final Offset Function(Offset position) clampPosition;

  const DraggableNode({
    super.key,
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.onDragEnd,
    required this.clampPosition,
  });

  @override
  State<DraggableNode> createState() => _DraggableNodeState();
}

class _DraggableNodeState extends State<DraggableNode> {
  // Local offset during drag - null when not dragging
  Offset? _dragOffset;
  bool _isDragging = false;

  Offset get _currentPosition => _dragOffset ?? widget.node.position;

  @override
  void didUpdateWidget(DraggableNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset drag state if node changed
    if (oldWidget.node.id != widget.node.id) {
      _dragOffset = null;
      _isDragging = false;
    }
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _dragOffset = widget.node.position;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset = widget.clampPosition(_dragOffset! + details.delta);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    final finalPosition = _dragOffset;
    _dragOffset = null;
    if (finalPosition != null) {
      widget.onDragEnd(finalPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentPosition.dx,
      top: _currentPosition.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: RepaintBoundary(
          child: NodeWidget(
            node: widget.node,
            isSelected: widget.isSelected,
            // Pass drag position override for coordinate display during drag
            positionOverride: _dragOffset,
          ),
        ),
      ),
    );
  }
}
