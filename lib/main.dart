import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'nodes_app.dart';
import 'components/node_component.dart';

void main() {
  runApp(const Nodes());
}

class Nodes extends StatelessWidget {
  const Nodes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Node Canvas App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Home(title: 'Node Canvas'),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final NodesApp nodesApp = NodesApp();
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              nodesApp.addRootNode();
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add Root Node',
          ),
          IconButton(
            onPressed: () {
              nodesApp.addSiblingNode();
            },
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Add Sibling Node',
          ),
          IconButton(
            onPressed: () {
              nodesApp.addChildNode();
            },
            icon: const Icon(Icons.add_circle),
            tooltip: 'Add Child Node',
          ),
          IconButton(
            onPressed: () {
              nodesApp.deleteSelectedNode();
            },
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Selected Node',
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.keyN &&
                nodesApp.selectedNode != null) {
              nodesApp.addChildNode();
            } else if (event.logicalKey == LogicalKeyboardKey.keyO &&
                nodesApp.selectedNode != null) {
              nodesApp.addSiblingNode();
            } else if (event.logicalKey == LogicalKeyboardKey.keyE &&
                nodesApp.selectedNode != null) {
              // Start editing
              // For now, just print
              print('Start editing ${nodesApp.selectedNode!.text}');
            } else if (event.logicalKey == LogicalKeyboardKey.delete &&
                nodesApp.selectedNode != null) {
              nodesApp.deleteSelectedNode();
            }
            // Add more keys as needed
          }
        },
        child: GestureDetector(
          onTapDown: (details) {
            final gamePosition = Vector2(
              details.localPosition.dx,
              details.localPosition.dy,
            );
            final componentsAtTap = nodesApp
                .componentsAtPoint(gamePosition)
                .whereType<NodeComponent>();
            if (componentsAtTap.isNotEmpty) {
              final tappedNode = componentsAtTap.first.node;
              if (nodesApp.selectedNode == tappedNode) {
                nodesApp.selectedNode = null;
              } else {
                nodesApp.selectedNode = tappedNode;
              }
              // Update selection for all components
              for (final component
                  in nodesApp.children.whereType<NodeComponent>()) {
                component.updateSelection(nodesApp.selectedNode);
              }
            } else {
              nodesApp.selectedNode = null;
              for (final component
                  in nodesApp.children.whereType<NodeComponent>()) {
                component.updateSelection(null);
              }
            }
          },
          onPanStart: (details) {
            final gamePosition = Vector2(
              details.localPosition.dx,
              details.localPosition.dy,
            );
            final componentsAtDrag = nodesApp
                .componentsAtPoint(gamePosition)
                .whereType<NodeComponent>();
            if (componentsAtDrag.isNotEmpty) {
              nodesApp.draggedNode = componentsAtDrag.first.node;
            }
          },
          onPanUpdate: (details) {
            if (nodesApp.draggedNode != null) {
              final delta = Offset(details.delta.dx, details.delta.dy);
              final newPosition = nodesApp.draggedNode!.position + delta;
              nodesApp.draggedNode!.position = nodesApp
                  .constrainPositionToBounds(newPosition);
              // Update the component position
              final component = nodesApp.children
                  .whereType<NodeComponent>()
                  .firstWhere((comp) => comp.node == nodesApp.draggedNode);
              component.position = Vector2(
                nodesApp.draggedNode!.position.dx,
                nodesApp.draggedNode!.position.dy,
              );
            }
          },
          onPanEnd: (details) {
            nodesApp.draggedNode = null;
          },
          child: GameWidget(game: nodesApp),
        ),
      ),
    );
  }
}
