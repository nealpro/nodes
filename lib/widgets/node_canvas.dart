import 'package:flutter/material.dart';
import 'node_canvas_painter.dart';
import 'node_canvas_controller.dart';
import 'node_manager.dart';
import 'canvas_keyboard_handler.dart';
import 'canvas_help_text.dart';
import 'text_editing_overlay.dart';
import 'help_text_overlay.dart';
import 'canvas_gestures.dart';

class NodeCanvas extends StatefulWidget {
  const NodeCanvas({super.key});

  @override
  State<NodeCanvas> createState() => NodeCanvasState();
}

class NodeCanvasState extends State<NodeCanvas> {
  late NodeCanvasController _controller;
  late NodeManager _nodeManager;

  @override
  void initState() {
    super.initState();
    _controller = NodeCanvasController();
    _nodeManager = NodeManager(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Method to add a root node (called from main.dart)
  void addRootNode() {
    _nodeManager.addRootNode();
    _nodeManager.startTextEditing(_controller.selectedNode!);
  }

  // Method to add a sibling node (called from main.dart)
  void addSiblingNode() {
    _nodeManager.addSiblingNode();
    if (_controller.selectedNode != null) {
      _nodeManager.startTextEditing(_controller.selectedNode!);
    }
  }

  void _handleKeyPress(KeyEvent event) {
    CanvasKeyboardHandler.handleKeyPress(
      event,
      hasSelectedNode: _controller.selectedNode != null,
      isEditing: _controller.editingNode != null,
      onCreateChild: () {
        _nodeManager.addChildNode();
        if (_controller.selectedNode != null) {
          _nodeManager.startTextEditing(_controller.selectedNode!);
        }
      },
      onCreateSibling: () {
        _nodeManager.addSiblingNode();
        if (_controller.selectedNode != null) {
          _nodeManager.startTextEditing(_controller.selectedNode!);
        }
      },
      onStartEditing: () {
        if (_controller.selectedNode != null) {
          _nodeManager.startTextEditing(_controller.selectedNode!);
        }
      },
      onDeleteNode: _nodeManager.deleteSelectedNode,
      onCancelEditing: _nodeManager.cancelTextEditing,
      onFinishEditing: _nodeManager.finishTextEditing,
    );
  }

  String _getHelpText() {
    if (_controller.selectedNode != null && _controller.editingNode == null) {
      return CanvasHelpText.getSelectedNodeHelpText();
    } else if (_controller.editingNode != null) {
      return CanvasHelpText.getEditingHelpText();
    } else {
      return CanvasHelpText.getDefaultHelpText();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _controller.updateCanvasSize(
          Size(constraints.maxWidth, constraints.maxHeight),
        );

        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return KeyboardListener(
              focusNode: _controller.canvasFocusNode,
              autofocus: true,
              onKeyEvent: _handleKeyPress,
              child: GestureDetector(
                onTap: () {
                  // Ensure keyboard focus is maintained for shortcuts
                  _controller.canvasFocusNode.requestFocus();
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
                      CanvasGestures(
                        controller: _controller,
                        onFinishTextEditing: _nodeManager.finishTextEditing,
                        onStartTextEditing: (node) {
                          if (CanvasKeyboardHandler.isMobile()) {
                            _nodeManager.startTextEditing(node);
                          }
                        },
                        onCreateChild: (node) {
                          // Create child and start editing
                          _controller.setSelectedNode(node);
                          _nodeManager.addChildNode();
                          if (_controller.selectedNode != null) {
                            _nodeManager.startTextEditing(
                              _controller.selectedNode!,
                            );
                          }
                        },
                        child: CustomPaint(
                          painter: NodeCanvasPainter(
                            nodeTree: _controller.nodeTree,
                            stemPosition: _controller.stemPosition,
                            selectedNode: _controller.selectedNode,
                          ),
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                        ),
                      ),
                      // Text editing overlay
                      if (_controller.editingNode != null)
                        TextEditingOverlay(
                          editingNode: _controller.editingNode!,
                          controller: _controller.textEditingController,
                          focusNode: _controller.textEditingFocusNode,
                          constraints: constraints,
                          onFinishEditing: _nodeManager.finishTextEditing,
                        ),
                      // Help text overlay
                      HelpTextOverlay(helpText: _getHelpText()),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
