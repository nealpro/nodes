part of 'main.dart';

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

class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  final List<Node> _nodes = [];
  final double _canvasSize = 5000.0;
  final TransformationController _transformationController =
      TransformationController();

  @visibleForTesting
  TransformationController get transformationController =>
      _transformationController;

  late final ViewportController _viewportController;
  bool _isOrganized = false;
  bool _isAutoOrganizing = false;
  Timer? _autoOrganizeTimer;
  Node? _selectedNode;
  final Map<String, Offset> _targetPositions = {};
  int _nodeIdCounter = 0;

  @override
  void dispose() {
    _autoOrganizeTimer?.cancel();
    _transformationController.removeListener(_onTransformationChange);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _viewportController = ViewportController(
      transformationController: _transformationController,
      canvasSize: _canvasSize,
    );
    if (kDebugMode) {
      generateNodes(_nodes, _canvasSize);
      _nodeIdCounter = _nodes.length;
    }
    _transformationController.addListener(_onTransformationChange);
  }

  void _onTransformationChange() {
    if (!_viewportController.validateAndReset()) {
      if (_isOrganized) {
        setState(() {
          _isOrganized = false;
        });
      }
    }
  }

  void _startAutoOrganize() {
    if (_isAutoOrganizing || _isOrganized) return;
    // Calculate target positions using the same layout algorithm
    _calculateTargetPositions();
    setState(() {
      _isAutoOrganizing = true;
    });
    _autoOrganizeTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      _stepTowardOrganized();
    });
  }

  void _stopAutoOrganize() {
    if (!_isAutoOrganizing) return;
    _autoOrganizeTimer?.cancel();
    setState(() {
      _isAutoOrganizing = false;
    });
  }

  void _calculateTargetPositions() {
    if (_nodes.isEmpty) return;
    _targetPositions.clear();
    final root = _nodes[0];
    _calculateTreeLayout(root, 100, _canvasSize / 2);
  }

  double _calculateTreeLayout(Node node, double x, double y) {
    const double nodeWidth = 120;
    const double nodeHeight = 60;
    const double horizontalGap = 100;
    const double verticalGap = 40;

    double childrenHeight = 0;
    for (var child in node.children) {
      childrenHeight += _getSubtreeHeight(child, nodeHeight, verticalGap);
    }

    // Store target position
    _targetPositions[node.id] = Offset(x, y - nodeHeight / 2);

    if (node.children.isNotEmpty) {
      double currentY = y - childrenHeight / 2;
      for (var child in node.children) {
        final childSubtreeHeight = _getSubtreeHeight(
          child,
          nodeHeight,
          verticalGap,
        );
        _calculateTreeLayout(
          child,
          x + nodeWidth + horizontalGap,
          currentY + childSubtreeHeight / 2,
        );
        currentY += childSubtreeHeight;
      }
    }
    return childrenHeight;
  }

  void _stepTowardOrganized() {
    const double speed = 5.0; // Pixels per frame
    const double snapThreshold = 2.0; // Snap to target when this close

    bool allAtTarget = true;

    setState(() {
      for (var node in _nodes) {
        final target = _targetPositions[node.id];
        if (target == null) continue;

        final double dx = target.dx - node.position.dx;
        final double dy = target.dy - node.position.dy;
        final double distance = sqrt(dx * dx + dy * dy);

        if (distance > snapThreshold) {
          allAtTarget = false;
          // Move toward target
          final double moveX = (dx / distance) * min(speed, distance);
          final double moveY = (dy / distance) * min(speed, distance);
          node.position += Offset(moveX, moveY);
        } else {
          // Snap to target
          node.position = target;
        }

        // Clamp to canvas bounds
        node.position = Offset(
          node.position.dx.clamp(0.0, _canvasSize - 120),
          node.position.dy.clamp(0.0, _canvasSize - 60),
        );
      }
    });

    // Auto-stop when all nodes reach their targets
    if (allAtTarget) {
      _stopAutoOrganize();
    }
  }

  void _toggleOrganizedMode(BoxConstraints constraints) {
    setState(() {
      _isOrganized = !_isOrganized;
      if (_isOrganized) {
        // Save positions
        for (var node in _nodes) {
          node.savedPosition = node.position;
        }
        _organizeNodes();
        // Select root node and center on it
        if (_nodes.isNotEmpty) {
          _selectedNode = _nodes[0];
          _viewportController.centerOnNode(_selectedNode!, constraints);
        }
      } else {
        // Keep selection when exiting organized mode
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
    const double horizontalGap = 100;
    const double verticalGap = 40;

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

  void _selectNode(Node node) {
    setState(() {
      if (_selectedNode == node) {
        _selectedNode = null; // Deselect if clicking the same node
      } else {
        _selectedNode = node;
        // Bring node to front
        _nodes.remove(node);
        _nodes.add(node);
      }
    });
  }

  String _generateNodeId() {
    return 'node_${_nodeIdCounter++}';
  }

  Future<void> _addAdjacentNode(BoxConstraints constraints) async {
    final result = await Navigator.of(context).push<NewNodeResult>(
      MaterialPageRoute(
        builder: (context) => AddNodePage(
          isChild: false,
          parentLabel: _selectedNode?.parent?.label,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      final newNode = Node(
        id: _generateNodeId(),
        position: _calculateNewNodePosition(),
        label: result.label,
        color: result.color,
      );

      // If a node is selected and it has a parent, add as sibling
      if (_selectedNode != null && _selectedNode!.parent != null) {
        final parent = _selectedNode!.parent!;
        newNode.parent = parent;
        parent.children.add(newNode);
        // Position near the selected node
        newNode.position = Offset(
          _selectedNode!.position.dx,
          _selectedNode!.position.dy + 80,
        );
      }
      // Otherwise, add as a new root node

      _nodes.add(newNode);
      _selectedNode = newNode;
    });

    _viewportController.centerOnNode(_selectedNode!, constraints);
  }

  Future<void> _addChildNode(BoxConstraints constraints) async {
    final result = await Navigator.of(context).push<NewNodeResult>(
      MaterialPageRoute(
        builder: (context) =>
            AddNodePage(isChild: true, parentLabel: _selectedNode?.label),
      ),
    );

    if (result == null) return;

    setState(() {
      final newNode = Node(
        id: _generateNodeId(),
        position: _calculateNewNodePosition(),
        label: result.label,
        color: result.color,
      );

      // If a node is selected, add as child
      if (_selectedNode != null) {
        newNode.parent = _selectedNode;
        _selectedNode!.children.add(newNode);
        // Position to the right of the parent
        newNode.position = Offset(
          _selectedNode!.position.dx + 180,
          _selectedNode!.position.dy +
              (_selectedNode!.children.length - 1) * 80,
        );
      }
      // Otherwise, add as a new root node

      _nodes.add(newNode);
      _selectedNode = newNode;
    });

    _viewportController.centerOnNode(_selectedNode!, constraints);
  }

  Offset _calculateNewNodePosition() {
    // Default position: center of canvas
    if (_nodes.isEmpty) {
      return Offset(_canvasSize / 2 - 60, _canvasSize / 2 - 30);
    }
    // Position near the last node
    final lastNode = _nodes.last;
    return Offset(lastNode.position.dx + 50, lastNode.position.dy + 80);
  }

  void _navigateSelection(String direction, BoxConstraints constraints) {
    if (!_isOrganized || _selectedNode == null) return;

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
      _viewportController.centerOnNode(newSelection, constraints);
    }
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
                if (kDebugMode) {
                  generateNodes(_nodes, _canvasSize);
                }
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          var stack = Stack(
            children: [
              // Background grid
              Positioned.fill(child: CustomPaint(painter: GridPainter())),

              // Connections
              Positioned.fill(
                child: CustomPaint(painter: ConnectionPainter(nodes: _nodes)),
              ),

              // Nodes
              ..._nodes.map((node) {
                return Positioned(
                  key: ValueKey(node.id),
                  left: node.position.dx,
                  top: node.position.dy,
                  child: GestureDetector(
                    onTap: () => _selectNode(node),
                    onPanUpdate: _isOrganized
                        ? null
                        : (details) {
                            setState(() {
                              final newPosition = node.position + details.delta;
                              node.position = Offset(
                                newPosition.dx.clamp(0.0, _canvasSize - 120),
                                newPosition.dy.clamp(0.0, _canvasSize - 60),
                              );
                            });
                          },
                    child: RepaintBoundary(
                      child: NodeWidget(
                        node: node,
                        isSelected: _selectedNode == node,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyC): () =>
                  _viewportController.center(constraints),
              const SingleActivator(LogicalKeyboardKey.keyF): () =>
                  _toggleOrganizedMode(constraints),
              const SingleActivator(LogicalKeyboardKey.keyH): () =>
                  _navigateSelection('h', constraints),
              const SingleActivator(LogicalKeyboardKey.keyJ): () =>
                  _navigateSelection('j', constraints),
              const SingleActivator(LogicalKeyboardKey.keyK): () =>
                  _navigateSelection('k', constraints),
              const SingleActivator(LogicalKeyboardKey.keyL): () =>
                  _navigateSelection('l', constraints),
              const SingleActivator(LogicalKeyboardKey.keyE): () =>
                  _addAdjacentNode(constraints),
              const SingleActivator(LogicalKeyboardKey.keyX): () =>
                  _addChildNode(constraints),
              const SingleActivator(LogicalKeyboardKey.keyO): () {
                if (_selectedNode != null) {
                  _showNodeContentPopup(_selectedNode!);
                }
              },
            },
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event.logicalKey == LogicalKeyboardKey.keyD) {
                  if (event is KeyDownEvent) {
                    _startAutoOrganize();
                  } else if (event is KeyUpEvent) {
                    _stopAutoOrganize();
                  }
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                panEnabled: !_isOrganized,
                scaleEnabled: !_isOrganized,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 5.0,
                constrained: false, // Infinite canvas
                child: SizedBox(
                  width: _canvasSize,
                  height: _canvasSize,
                  child: stack,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
