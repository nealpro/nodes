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
  final Random _random = Random();
  final double _canvasSize = 5000.0;
  final TransformationController transformationController =
      TransformationController();
  bool _isOrganized = false;
  bool _isLaserActive = false;
  late Offset _laserPosition;
  Timer? _laserTimer;
  Node? _selectedNode;

  @override
  void dispose() {
    _laserTimer?.cancel();
    transformationController.removeListener(_onTransformationChange);
    transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _laserPosition = Offset(_canvasSize / 2, _canvasSize / 2);
    _generateNodes();
    transformationController.addListener(_onTransformationChange);
  }

  void _onTransformationChange() {
    try {
      Matrix4.inverted(transformationController.value);
    } catch (e) {
      // print('Matrix error caught! Resetting. Error: $e');
      transformationController.value = Matrix4.identity();
      if (_isOrganized) {
        setState(() {
          _isOrganized = false;
        });
      }
    }
  }

  void _startLaser() {
    if (_isLaserActive) return;
    setState(() {
      _isLaserActive = true;
    });
    _laserTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateNodes();
    });
  }

  void _stopLaser() {
    if (!_isLaserActive) return;
    _laserTimer?.cancel();
    setState(() {
      _isLaserActive = false;
    });
  }

  void _updateNodes() {
    final bool isRepelling = HardwareKeyboard.instance.isShiftPressed;
    setState(() {
      for (var node in _nodes) {
        final double dx = _laserPosition.dx - node.position.dx;
        final double dy = _laserPosition.dy - node.position.dy;
        final double distance = sqrt(dx * dx + dy * dy);

        if (isRepelling) {
          double moveX = 0;
          double moveY = 0;

          // Standard repel vector (away from laser)
          if (distance > 0.1) {
            moveX = -(dx / distance) * 10;
            moveY = -(dy / distance) * 10;
          }

          // Add scatter noise inversely proportional to distance
          // This ensures nodes spread out if they are clumped near the laser
          if (distance < 100) {
            final int hash = node.id.hashCode;
            final double angle = (hash % 360) * (pi / 180);
            final double strength = (100 - distance) / 100;

            moveX += cos(angle) * 10 * strength;
            moveY += sin(angle) * 10 * strength;
          }

          // Normalize to maintain constant speed
          final double moveDist = sqrt(moveX * moveX + moveY * moveY);
          if (moveDist > 0) {
            moveX = (moveX / moveDist) * 10;
            moveY = (moveY / moveDist) * 10;
            node.position += Offset(moveX, moveY);
          }
        } else {
          if (distance > 10) {
            final double moveX = (dx / distance) * 10;
            final double moveY = (dy / distance) * 10;
            node.position += Offset(moveX, moveY);
          } else {
            node.position = _laserPosition;
          }
        }

        // Clamp
        node.position = Offset(
          node.position.dx.clamp(0.0, _canvasSize - 120),
          node.position.dy.clamp(0.0, _canvasSize - 60),
        );
      }
    });
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
          parent: parent,
        );

        _nodes.add(newNode);
        parent.children.add(newNode);
      }
      parentIndex++;
    }
  }

  void _toggleOrganizedMode(BoxConstraints constraints) {
    // print('Toggling organized mode');
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
          _centerOnNode(_selectedNode!, constraints);
        }
      } else {
        _selectedNode = null;
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

  void _centerOnNode(Node node, BoxConstraints constraints) {
    final double width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : 800;
    final double height = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : 600;
    // Node center is at (node.position.dx + 60, node.position.dy + 30)
    final double nodeCenterX = node.position.dx + 60;
    final double nodeCenterY = node.position.dy + 30;
    // We want nodeCenterX/Y to be at viewport center (width/2, height/2)
    final double x = width / 2 - nodeCenterX;
    final double y = height / 2 - nodeCenterY;
    transformationController.value = Matrix4.identity()
      ..translateByDouble(x, y, 0.0, 1.0);
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
      _centerOnNode(newSelection, constraints);
    }
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
          var container = Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: HardwareKeyboard.instance.isShiftPressed
                  ? Colors.blue
                  : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (HardwareKeyboard.instance.isShiftPressed
                              ? Colors.blue
                              : Colors.red)
                          .withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
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
                        isSelected: _isOrganized && _selectedNode == node,
                      ),
                    ),
                  ),
                );
              }),

              // Laser Pointer
              if (_isLaserActive)
                Positioned(
                  left: _laserPosition.dx - 5,
                  top: _laserPosition.dy - 5,
                  child: container,
                ),
            ],
          );
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyC): () =>
                  _centerViewport(constraints),
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
            },
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event.logicalKey == LogicalKeyboardKey.keyD) {
                  if (event is KeyDownEvent) {
                    _startLaser();
                  } else if (event is KeyUpEvent) {
                    _stopLaser();
                  }
                }
                return KeyEventResult.ignored;
              },
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
                  child: Listener(
                    onPointerDown: (event) {
                      if (_isLaserActive) {
                        setState(() {
                          _laserPosition = event.localPosition;
                        });
                      }
                    },
                    child: stack,
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
