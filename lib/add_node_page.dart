import 'package:flutter/material.dart';

/// Enum representing the different types of nodes that can be created.
enum NodeType {
  text('Text', Icons.text_fields);

  final String displayName;
  final IconData icon;

  const NodeType(this.displayName, this.icon);
}

/// Result object returned when a new node is created.
class NewNodeResult {
  final String label;
  final NodeType type;
  final Color color;

  const NewNodeResult({
    required this.label,
    required this.type,
    required this.color,
  });
}

/// A page for adding a new node to the mind map.
class AddNodePage extends StatefulWidget {
  /// Whether this node is being added as a child of another node.
  final bool isChild;

  /// The parent node's label (for display purposes).
  final String? parentLabel;

  const AddNodePage({super.key, this.isChild = false, this.parentLabel});

  @override
  State<AddNodePage> createState() => _AddNodePageState();
}

class _AddNodePageState extends State<AddNodePage> {
  final TextEditingController _labelController = TextEditingController();
  final FocusNode _labelFocusNode = FocusNode();
  NodeType _selectedType = NodeType.text;
  Color _selectedColor = Colors.blue;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus the label field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _labelFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _labelFocusNode.dispose();
    super.dispose();
  }

  void _createNode() {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a node label')),
      );
      return;
    }

    Navigator.of(context).pop(
      NewNodeResult(label: label, type: _selectedType, color: _selectedColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isChild ? 'Add Child Node' : 'Add Node'),
        actions: [
          TextButton.icon(
            onPressed: _createNode,
            icon: const Icon(Icons.check),
            label: const Text('Create'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isChild && widget.parentLabel != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.subdirectory_arrow_right, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Adding child to: ${widget.parentLabel}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Node Label
            TextField(
              controller: _labelController,
              focusNode: _labelFocusNode,
              decoration: const InputDecoration(
                labelText: 'Node Label',
                hintText: 'Enter a label for this node',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _createNode(),
            ),
            const SizedBox(height: 24),

            // Node Type Selection
            Text('Node Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: NodeType.values.map((type) {
                final isSelected = type == _selectedType;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type.icon, size: 18),
                      const SizedBox(width: 4),
                      Text(type.displayName),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Color Selection
            Text('Node Color', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Preview
            Text('Preview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 120,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _selectedColor, width: 2),
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
                    Text(
                      _labelController.text.isEmpty
                          ? 'Node Label'
                          : _labelController.text,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedType.icon,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedType.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
