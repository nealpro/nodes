import 'package:flutter/material.dart';
import 'nodes_app.dart';

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
      body: nodesApp.buildInteractionLayer(),
    );
  }
}
