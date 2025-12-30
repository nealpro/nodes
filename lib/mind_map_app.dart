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
  Node? _selectedNode;
  final Map<String, DateTime> _nodeCreationTimes = {};
  int _nodeIdCounter = 0;

  @override
  void dispose() {
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
      _registerExistingNodes();
    }
    _transformationController.addListener(_onTransformationChange);
  }

  void _onTransformationChange() {
    _viewportController.validateAndReset();
  }

  Future<void> _openOrganizedMode() async {
    if (_nodes.isEmpty) return;

    final result = await Navigator.of(context).push<OrganizedModeResult>(
      MaterialPageRoute(
        builder: (context) => OrganizedModeScreen(
          nodes: _nodes,
          initialSelectedNode: _selectedNode,
        ),
      ),
    );

    // Update selection based on what was selected in organized mode
    if (result != null && result.selectedNode != null) {
      setState(() {
        _selectedNode = result.selectedNode;
      });
    }
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

  Node _createNode({
    required Offset position,
    required String label,
    required Color color,
    Node? parent,
  }) {
    final id = _generateNodeId();
    final node = Node(
      id: id,
      position: position,
      label: label,
      color: color,
      parent: parent,
    );
    _nodeCreationTimes[id] = DateTime.now();
    return node;
  }

  void _registerExistingNodes() {
    // Register creation times for nodes generated externally (e.g., debug nodes)
    // Uses current time but maintains relative order based on list position
    final baseTime = DateTime.now();
    for (var i = 0; i < _nodes.length; i++) {
      _nodeCreationTimes[_nodes[i].id] = baseTime.add(
        Duration(microseconds: i),
      );
    }
    _nodeIdCounter = _nodes.length;
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
      final newNode = _createNode(
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
      final newNode = _createNode(
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

  Node? _findFirstCreatedRootNode() {
    if (_nodes.isEmpty) return null;
    Node? firstRoot;
    DateTime? earliestTime;

    for (var node in _nodes) {
      if (node.parent == null) {
        final creationTime = _nodeCreationTimes[node.id];
        if (creationTime != null) {
          if (earliestTime == null || creationTime.isBefore(earliestTime)) {
            earliestTime = creationTime;
            firstRoot = node;
          }
        }
      }
    }
    return firstRoot;
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
                _nodeCreationTimes.clear();
                if (kDebugMode) {
                  generateNodes(_nodes, _canvasSize);
                  _registerExistingNodes();
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
                    onPanUpdate: (details) {
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
              // C - center on selected node, or first root node if none selected
              const SingleActivator(LogicalKeyboardKey.keyC): () {
                final node = _selectedNode ?? _findFirstCreatedRootNode();
                if (node != null) {
                  _viewportController.centerOnNode(node, constraints);
                }
              },
              // Ctrl+C - center on canvas
              const SingleActivator(
                LogicalKeyboardKey.keyC,
                control: true,
              ): () =>
                  _viewportController.center(constraints),
              // F - open organized mode
              const SingleActivator(LogicalKeyboardKey.keyF):
                  _openOrganizedMode,
              // E - add adjacent node
              const SingleActivator(LogicalKeyboardKey.keyE): () =>
                  _addAdjacentNode(constraints),
              // X - add child node
              const SingleActivator(LogicalKeyboardKey.keyX): () =>
                  _addChildNode(constraints),
              // O - show node content popup
              const SingleActivator(LogicalKeyboardKey.keyO): () {
                if (_selectedNode != null) {
                  _showNodeContentPopup(_selectedNode!);
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
