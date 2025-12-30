import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../node.dart';
import '../node_widget.dart';
import '../grid_painter.dart';

/// Result data returned when exiting organized mode
class OrganizedModeResult {
  final Node? selectedNode;

  OrganizedModeResult({this.selectedNode});
}

/// A separate screen for organized (tree layout) mode.
/// This screen displays nodes in a clean tree layout and supports
/// only H/J/K/L navigation keybinds.
class OrganizedModeScreen extends StatefulWidget {
  final List<Node> nodes;
  final Node? initialSelectedNode;

  const OrganizedModeScreen({
    super.key,
    required this.nodes,
    this.initialSelectedNode,
  });

  @override
  State<OrganizedModeScreen> createState() => _OrganizedModeScreenState();
}

class _OrganizedModeScreenState extends State<OrganizedModeScreen> {
  final double _canvasSize = 5000.0;
  final TransformationController _transformationController =
      TransformationController();

  Node? _selectedNode;

  // Organized positions for tree layout (separate from original positions)
  final Map<String, Offset> _organizedPositions = {};

  @override
  void initState() {
    super.initState();
    _selectedNode = widget.initialSelectedNode ?? _findRootNode();
    _calculateTreeLayout();

    // Center on selected node after layout is calculated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedNode != null) {
        _centerOnNode(_selectedNode!);
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Node? _findRootNode() {
    if (widget.nodes.isEmpty) return null;
    // Find a node with no parent (root node)
    for (var node in widget.nodes) {
      if (node.parent == null) {
        return node;
      }
    }
    return widget.nodes.first;
  }

  void _calculateTreeLayout() {
    _organizedPositions.clear();

    // Find all root nodes and lay them out
    final rootNodes = widget.nodes.where((n) => n.parent == null).toList();

    if (rootNodes.isEmpty) return;

    // Start layout from a reasonable position
    double currentY = _canvasSize / 2;
    const double verticalSpaceBetweenTrees = 200;

    for (var root in rootNodes) {
      final treeHeight = _layoutTree(root, 100, currentY);
      currentY += treeHeight + verticalSpaceBetweenTrees;
    }
  }

  double _layoutTree(Node node, double x, double y) {
    const double nodeWidth = 120;
    const double nodeHeight = 60;
    const double horizontalGap = 100;
    const double verticalGap = 40;

    // Calculate total height of children
    double childrenHeight = 0;
    for (var child in node.children) {
      childrenHeight += _getSubtreeHeight(child, nodeHeight, verticalGap);
    }

    // Use at least the node's own height
    final double effectiveHeight = childrenHeight > 0
        ? childrenHeight
        : nodeHeight + verticalGap;

    // Position current node - store in organized positions map
    _organizedPositions[node.id] = Offset(x, y - nodeHeight / 2);

    // Position children
    if (node.children.isNotEmpty) {
      double currentY = y - childrenHeight / 2;
      for (var child in node.children) {
        final childSubtreeHeight = _getSubtreeHeight(
          child,
          nodeHeight,
          verticalGap,
        );
        _layoutTree(
          child,
          x + nodeWidth + horizontalGap,
          currentY + childSubtreeHeight / 2,
        );
        currentY += childSubtreeHeight;
      }
    }

    return effectiveHeight;
  }

  double _getSubtreeHeight(Node node, double nodeHeight, double verticalGap) {
    if (node.children.isEmpty) {
      return nodeHeight + verticalGap;
    }
    double height = 0;
    for (var child in node.children) {
      height += _getSubtreeHeight(child, nodeHeight, verticalGap);
    }
    return height;
  }

  void _centerOnNode(Node node) {
    final position = _organizedPositions[node.id];
    if (position == null) return;

    final size = MediaQuery.of(context).size;
    final appBarHeight =
        AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    final viewportHeight = size.height - appBarHeight;
    final viewportWidth = size.width;

    // Node center is at (position.dx + 60, position.dy + 30)
    final double nodeCenterX = position.dx + 60;
    final double nodeCenterY = position.dy + 30;

    // We want nodeCenterX/Y to be at viewport center
    final double x = viewportWidth / 2 - nodeCenterX;
    final double y = viewportHeight / 2 - nodeCenterY;

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(x, y, 0.0, 1.0);
  }

  void _navigateSelection(String direction) {
    if (_selectedNode == null) return;

    Node? newSelection;
    switch (direction) {
      case 'h': // Left - go to parent
        newSelection = _selectedNode!.parent;
        break;
      case 'l': // Right - go to first child
        if (_selectedNode!.children.isNotEmpty) {
          newSelection = _selectedNode!.children.first;
        }
        break;
      case 'j': // Down - go to next sibling
        final parent = _selectedNode!.parent;
        if (parent != null) {
          final siblings = parent.children;
          final currentIndex = siblings.indexOf(_selectedNode!);
          if (currentIndex < siblings.length - 1) {
            newSelection = siblings[currentIndex + 1];
          }
        }
        break;
      case 'k': // Up - go to previous sibling
        final parent = _selectedNode!.parent;
        if (parent != null) {
          final siblings = parent.children;
          final currentIndex = siblings.indexOf(_selectedNode!);
          if (currentIndex > 0) {
            newSelection = siblings[currentIndex - 1];
          }
        }
        break;
    }

    if (newSelection != null) {
      setState(() {
        _selectedNode = newSelection;
      });
      _centerOnNode(newSelection);
    }
  }

  void _selectNode(Node node) {
    setState(() {
      _selectedNode = node;
    });
    _centerOnNode(node);
  }

  void _showNodeContentPopup(Node node) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.label,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _exitOrganizedMode() {
    Navigator.of(context).pop(OrganizedModeResult(selectedNode: _selectedNode));
  }

  @override
  Widget build(BuildContext context) {
    // Build nodes with organized positions
    final nodeWidgets = widget.nodes.map((node) {
      final position = _organizedPositions[node.id];
      if (position == null) return const SizedBox.shrink();

      return Positioned(
        key: ValueKey('organized_${node.id}'),
        left: position.dx,
        top: position.dy,
        child: GestureDetector(
          onTap: () => _selectNode(node),
          child: RepaintBoundary(
            child: NodeWidget(node: node, isSelected: _selectedNode == node),
          ),
        ),
      );
    }).toList();

    final stack = Stack(
      children: [
        // Background grid
        Positioned.fill(child: CustomPaint(painter: GridPainter())),

        // Connections - using organized positions
        Positioned.fill(
          child: CustomPaint(
            painter: _OrganizedConnectionPainter(
              nodes: widget.nodes,
              positions: _organizedPositions,
            ),
          ),
        ),

        // Nodes
        ...nodeWidgets,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organized View'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _exitOrganizedMode,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Center on selected',
            onPressed: () {
              if (_selectedNode != null) {
                _centerOnNode(_selectedNode!);
              }
            },
          ),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          // Navigation keybinds (H, J, K, L)
          const SingleActivator(LogicalKeyboardKey.keyH): () =>
              _navigateSelection('h'),
          const SingleActivator(LogicalKeyboardKey.keyJ): () =>
              _navigateSelection('j'),
          const SingleActivator(LogicalKeyboardKey.keyK): () =>
              _navigateSelection('k'),
          const SingleActivator(LogicalKeyboardKey.keyL): () =>
              _navigateSelection('l'),
          // F or Escape to exit organized mode
          const SingleActivator(LogicalKeyboardKey.keyF): _exitOrganizedMode,
          const SingleActivator(LogicalKeyboardKey.escape): _exitOrganizedMode,
          // O to show node content popup
          const SingleActivator(LogicalKeyboardKey.keyO): () {
            if (_selectedNode != null) {
              _showNodeContentPopup(_selectedNode!);
            }
          },
          // C to center on selected node
          const SingleActivator(LogicalKeyboardKey.keyC): () {
            if (_selectedNode != null) {
              _centerOnNode(_selectedNode!);
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 5.0,
            constrained: false,
            child: SizedBox(
              width: _canvasSize,
              height: _canvasSize,
              child: stack,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom connection painter that uses organized positions instead of node.position
class _OrganizedConnectionPainter extends CustomPainter {
  final List<Node> nodes;
  final Map<String, Offset> positions;

  _OrganizedConnectionPainter({required this.nodes, required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (var node in nodes) {
      final nodePos = positions[node.id];
      if (nodePos == null) continue;

      for (var child in node.children) {
        final childPos = positions[child.id];
        if (childPos == null) continue;

        // Start from the right center of the parent node
        final start = nodePos + const Offset(120, 30);
        // End at the left center of the child node
        final end = childPos + const Offset(0, 30);

        // Draw a cubic bezier curve
        final controlPoint1 = start + const Offset(50, 0);
        final controlPoint2 = end - const Offset(50, 0);

        path.moveTo(start.dx, start.dy);
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          end.dx,
          end.dy,
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OrganizedConnectionPainter oldDelegate) {
    return true;
  }
}
