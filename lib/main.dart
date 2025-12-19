import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MindMapApp());
}

class MindMapApp extends StatelessWidget {
  const MindMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fast MindMap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MindMapScreen(),
    );
  }
}

class Node {
  final String id;
  Offset position;
  Offset? savedPosition;
  final String label;
  final Color color;
  final List<Node> children;

  Node({
    required this.id,
    required this.position,
    required this.label,
    required this.color,
    List<Node>? children,
  }) : children = children ?? [];
}

class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  final List<Node> _nodes = [];
  final Random _random = Random();
  final double _canvasSize = 5000.0;
  final TransformationController transformationController =
      TransformationController();
  bool _isOrganized = false;

  @override
  void dispose() {
    transformationController.removeListener(_onTransformationChange);
    transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _generateNodes();
    transformationController.addListener(_onTransformationChange);
  }

  void _onTransformationChange() {
    try {
      Matrix4.inverted(transformationController.value);
    } catch (e) {
      print('Matrix error caught! Resetting. Error: $e');
      transformationController.value = Matrix4.identity();
      if (_isOrganized) {
        setState(() {
          _isOrganized = false;
        });
      }
    }
  }

  void _generateNodes() {
    const int totalNodes = 30;

    _nodes.clear();

    // Create root node
    _nodes.add(
      Node(
        id: 'node_0',
        position: Offset(
          _random.nextDouble() * (_canvasSize - 150),
          _random.nextDouble() * (_canvasSize - 100),
        ),
        label: 'Node 0',
        color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
      ),
    );

    int parentIndex = 0;
    while (_nodes.length < totalNodes) {
      // Safety check, though logic ensures we shouldn't run out of parents before hitting totalNodes
      if (parentIndex >= _nodes.length) break;

      final parent = _nodes[parentIndex];

      // Add up to 3 children for this parent
      for (int i = 0; i < 3; i++) {
        if (_nodes.length >= totalNodes) break;

        final newNode = Node(
          id: 'node_${_nodes.length}',
          position: Offset(
            _random.nextDouble() * (_canvasSize - 150),
            _random.nextDouble() * (_canvasSize - 100),
          ),
          label: 'Node ${_nodes.length}',
          color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        );

        _nodes.add(newNode);
        parent.children.add(newNode);
      }
      parentIndex++;
    }
  }

  void _toggleOrganizedMode(BoxConstraints constraints) {
    print('Toggling organized mode');
    setState(() {
      _isOrganized = !_isOrganized;
      if (_isOrganized) {
        // Save positions
        for (var node in _nodes) {
          node.savedPosition = node.position;
        }
        _organizeNodes();
        // Center viewport to left center (where root is)
        // Root is at (100, _canvasSize / 2) approx
        // We want that point to be at the left center of the viewport.
        // Viewport center is (constraints.maxWidth / 2, constraints.maxHeight / 2)
        // We want (100, _canvasSize/2) to be at (padding, constraints.maxHeight/2)
        // So translate:
        // tx = padding - 100
        // ty = constraints.maxHeight/2 - _canvasSize/2
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 800;
        final double x = 50 - 100; // 50 padding
        final double y = height / 2 - _canvasSize / 2;
        print('Setting matrix translation: x=$x, y=$y');
        transformationController.value = Matrix4.identity()
          ..translateByDouble(x, y, 0.0, 1.0);
      } else {
        // Restore positions
        for (var node in _nodes) {
          if (node.savedPosition != null) {
            node.position = node.savedPosition!;
          }
        }
      }
    });
  }

  void _organizeNodes() {
    if (_nodes.isEmpty) return;
    final root = _nodes[0];
    _layoutTree(root, 100, _canvasSize / 2);
  }

  double _layoutTree(Node node, double x, double y) {
    const double nodeWidth = 120;
    const double nodeHeight = 60;
    const double horizontalGap = 50;
    const double verticalGap = 20;

    // Calculate total height of children
    double childrenHeight = 0;
    for (var child in node.children) {
      childrenHeight += _getSubtreeHeight(child, nodeHeight, verticalGap);
    }

    // Position current node
    node.position = Offset(x, y - nodeHeight / 2);

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
    return childrenHeight;
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

  void _centerViewport(BoxConstraints constraints) {
    final double width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : 800;
    final double height = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : 600;
    final double x = -(_canvasSize / 2 - width / 2);
    final double y = -(_canvasSize / 2 - height / 2);
    transformationController.value = Matrix4.identity()
      ..translateByDouble(x, y, 0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast MindMap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _nodes.clear();
                _generateNodes();
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyC): () =>
                  _centerViewport(constraints),
              const SingleActivator(LogicalKeyboardKey.keyF): () =>
                  _toggleOrganizedMode(constraints),
            },
            child: Focus(
              autofocus: true,
              child: InteractiveViewer(
                transformationController: transformationController,
                panEnabled: !_isOrganized,
                scaleEnabled: !_isOrganized,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 5.0,
                constrained: false, // Infinite canvas
                child: SizedBox(
                  width: _canvasSize,
                  height: _canvasSize,
                  child: Stack(
                    children: [
                      // Background grid
                      Positioned.fill(
                        child: CustomPaint(painter: GridPainter()),
                      ),

                      // Nodes
                      ..._nodes.map((node) {
                        return Positioned(
                          key: ValueKey(node.id),
                          left: node.position.dx,
                          top: node.position.dy,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _nodes.remove(node);
                                _nodes.add(node);
                              });
                            },
                            onPanUpdate: _isOrganized
                                ? null
                                : (details) {
                                    setState(() {
                                      final newPosition =
                                          node.position + details.delta;
                                      node.position = Offset(
                                        newPosition.dx.clamp(
                                          0.0,
                                          _canvasSize - 120,
                                        ),
                                        newPosition.dy.clamp(
                                          0.0,
                                          _canvasSize - 60,
                                        ),
                                      );
                                    });
                                  },
                            child: RepaintBoundary(
                              child: NodeWidget(node: node),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NodeWidget extends StatelessWidget {
  final Node node;

  const NodeWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: node.color, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(node.label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '(${node.position.dx.toInt()}, ${node.position.dy.toInt()})',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    const double gridSize = 50;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
