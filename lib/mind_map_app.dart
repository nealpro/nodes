part of 'main.dart';

class MindMapApp extends StatefulWidget {
  const MindMapApp({super.key});

  @override
  State<MindMapApp> createState() => _MindMapAppState();
}

class _MindMapAppState extends State<MindMapApp> {
  final ProjectService _projectService = ProjectService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nodes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    // In release mode, go directly to project selection
    if (kReleaseMode) {
      return ProjectSelectionScreen(projectService: _projectService);
    }

    // In debug/profile mode, show startup screen with options
    return StartupScreen(projectService: _projectService);
  }
}

/// Screen for editing a mind map canvas
class MindMapScreen extends StatefulWidget {
  /// Optional project for persistent storage
  final NodesProject? project;

  /// Optional database service for saving/loading nodes
  final DatabaseService? database;

  /// Whether this is test mode with temporary generated nodes
  final bool isTestMode;

  const MindMapScreen({
    super.key,
    this.project,
    this.database,
    this.isTestMode = false,
  });

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

  /// Version counter for connection repainting - increment when node positions change
  int _connectionVersion = 0;

  /// Cached visible rect for culling - updated on transform changes
  Rect? _visibleRect;
  Size? _lastConstraints;

  /// Whether the initial data load is in progress
  bool _isLoading = true;

  @override
  void dispose() {
    _saveNodesToDatabase();
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
    _initializeNodes();
    _transformationController.addListener(_onTransformationChange);
  }

  Future<void> _initializeNodes() async {
    if (widget.isTestMode) {
      // Test mode: generate temporary nodes
      generateNodes(_nodes, _canvasSize);
      _registerExistingNodes();
      setState(() {
        _isLoading = false;
      });
    } else if (widget.database != null) {
      // Project mode: load nodes from database
      try {
        final result = await widget.database!.loadAllNodes();
        setState(() {
          _nodes.addAll(result.nodes);
          _nodeCreationTimes.addAll(result.creationTimes);
          _nodeIdCounter = _nodes.length;
          _isLoading = false;
        });
      } catch (e) {
        // If loading fails, just start with empty nodes
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNodesToDatabase() async {
    if (widget.database != null && !widget.isTestMode) {
      try {
        await widget.database!.saveAllNodes(_nodes, _nodeCreationTimes);
        await widget.project?.save();
      } catch (e) {
        // Silently fail for now - could add error handling UI later
      }
    }
  }

  String _getAppBarTitle() {
    if (widget.isTestMode) {
      return 'Nodes (Test Mode)';
    }
    if (widget.project != null) {
      return widget.project!.name;
    }
    return 'Nodes';
  }

  void _onTransformationChange() {
    _viewportController.validateAndReset();
    // Update visible rect for culling
    if (_lastConstraints != null) {
      _updateVisibleRect(_lastConstraints!);
    }
  }

  /// Computes the visible rect in canvas coordinates for culling
  void _updateVisibleRect(Size viewportSize) {
    final matrix = _transformationController.value;
    final inverse = Matrix4.inverted(matrix);

    // Transform viewport corners to canvas space
    final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inverse,
      Offset(viewportSize.width, viewportSize.height),
    );

    _visibleRect = Rect.fromPoints(topLeft, bottomRight).inflate(100);
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
        newNode.position = _clampToCanvas(
          Offset(_selectedNode!.position.dx, _selectedNode!.position.dy + 80),
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
        newNode.position = _clampToCanvas(
          Offset(
            _selectedNode!.position.dx + 180,
            _selectedNode!.position.dy +
                (_selectedNode!.children.length - 1) * 80,
          ),
        );
      }
      // Otherwise, add as a new root node

      _nodes.add(newNode);
      _selectedNode = newNode;
    });

    _viewportController.centerOnNode(_selectedNode!, constraints);
  }

  Offset _clampToCanvas(Offset position) {
    return Offset(
      position.dx.clamp(0.0, _canvasSize - 120),
      position.dy.clamp(0.0, _canvasSize - 60),
    );
  }

  Offset _calculateNewNodePosition() {
    // Default position: center of canvas
    if (_nodes.isEmpty) {
      return _clampToCanvas(Offset(_canvasSize / 2 - 60, _canvasSize / 2 - 30));
    }
    // Position near the last node
    final lastNode = _nodes.last;
    return _clampToCanvas(
      Offset(lastNode.position.dx + 50, lastNode.position.dy + 80),
    );
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.project?.name ?? 'Nodes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          // Save button (only for persistent projects)
          if (widget.database != null && !widget.isTestMode)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await _saveNodesToDatabase();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Project saved'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset nodes',
            onPressed: () {
              setState(() {
                _nodes.clear();
                _nodeCreationTimes.clear();
                if (widget.isTestMode) {
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
          // Cache constraints and update visible rect for culling
          if (_lastConstraints != constraints.biggest) {
            _lastConstraints = constraints.biggest;
            _updateVisibleRect(constraints.biggest);
          }

          var stack = Stack(
            children: [
              // Background grid with culling
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: GridPainter(visibleRect: _visibleRect),
                  ),
                ),
              ),

              // Connections with version tracking and culling
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: ConnectionPainter(
                      nodes: _nodes,
                      version: _connectionVersion,
                      visibleRect: _visibleRect,
                    ),
                  ),
                ),
              ),

              // Nodes using DraggableNode for local drag state
              ..._nodes.map((node) {
                return DraggableNode(
                  key: ValueKey(node.id),
                  node: node,
                  isSelected: _selectedNode == node,
                  onTap: () => _selectNode(node),
                  clampPosition: _clampToCanvas,
                  onDragEnd: (newPosition) {
                    setState(() {
                      node.position = newPosition;
                      _connectionVersion++; // Trigger connection repaint
                    });
                  },
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
