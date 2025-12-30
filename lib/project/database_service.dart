import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nodes/node.dart';

/// Service for managing SQLite database operations for nodes.
/// Each project has its own database file stored in the project directory.
class DatabaseService {
  static const int _currentVersion = 1;
  static const String _nodesTable = 'nodes';

  Database? _database;
  final String databasePath;

  DatabaseService({required this.databasePath});

  /// Initializes the database factory for desktop platforms
  static void initialize() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Opens the database connection
  Future<void> open() async {
    _database = await openDatabase(
      databasePath,
      version: _currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the database schema
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_nodesTable (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        position_x REAL NOT NULL,
        position_y REAL NOT NULL,
        color INTEGER NOT NULL,
        parent_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES $_nodesTable(id) ON DELETE SET NULL
      )
    ''');

    // Index for faster parent lookups
    await db.execute('''
      CREATE INDEX idx_parent_id ON $_nodesTable(parent_id)
    ''');
  }

  /// Handles database migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations will go here
  }

  /// Closes the database connection
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Inserts a new node into the database
  Future<void> insertNode(Node node, DateTime createdAt) async {
    if (_database == null) {
      throw StateError('Database not opened');
    }

    await _database!.insert(_nodesTable, {
      'id': node.id,
      'label': node.label,
      'position_x': node.position.dx,
      'position_y': node.position.dy,
      'color': node.color.toARGB32(),
      'parent_id': node.parent?.id,
      'created_at': createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates an existing node in the database
  Future<void> updateNode(Node node) async {
    if (_database == null) {
      throw StateError('Database not opened');
    }

    await _database!.update(
      _nodesTable,
      {
        'label': node.label,
        'position_x': node.position.dx,
        'position_y': node.position.dy,
        'color': node.color.toARGB32(),
        'parent_id': node.parent?.id,
      },
      where: 'id = ?',
      whereArgs: [node.id],
    );
  }

  /// Deletes a node from the database
  Future<void> deleteNode(String nodeId) async {
    if (_database == null) {
      throw StateError('Database not opened');
    }

    await _database!.delete(_nodesTable, where: 'id = ?', whereArgs: [nodeId]);
  }

  /// Loads all nodes from the database and reconstructs the tree structure
  Future<({List<Node> nodes, Map<String, DateTime> creationTimes})>
  loadAllNodes() async {
    if (_database == null) {
      throw StateError('Database not opened');
    }

    final List<Map<String, dynamic>> rows = await _database!.query(
      _nodesTable,
      orderBy: 'created_at ASC',
    );

    final Map<String, Node> nodeMap = {};
    final Map<String, String?> parentIdMap = {};
    final Map<String, DateTime> creationTimes = {};

    // First pass: create all nodes
    for (final row in rows) {
      final node = Node(
        id: row['id'] as String,
        label: row['label'] as String,
        position: Offset(
          row['position_x'] as double,
          row['position_y'] as double,
        ),
        color: Color(row['color'] as int),
      );
      nodeMap[node.id] = node;
      parentIdMap[node.id] = row['parent_id'] as String?;
      creationTimes[node.id] = DateTime.parse(row['created_at'] as String);
    }

    // Second pass: establish parent-child relationships
    for (final entry in parentIdMap.entries) {
      final nodeId = entry.key;
      final parentId = entry.value;
      if (parentId != null && nodeMap.containsKey(parentId)) {
        final node = nodeMap[nodeId]!;
        final parent = nodeMap[parentId]!;
        node.parent = parent;
        parent.children.add(node);
      }
    }

    return (nodes: nodeMap.values.toList(), creationTimes: creationTimes);
  }

  /// Clears all nodes from the database
  Future<void> clearAllNodes() async {
    if (_database == null) {
      throw StateError('Database not opened');
    }

    await _database!.delete(_nodesTable);
  }

  /// Saves multiple nodes in a batch operation
  Future<void> saveAllNodes(
    List<Node> nodes,
    Map<String, DateTime> creationTimes,
  ) async {
    if (_database == null) {
      throw StateError('Database not opened');
    }

    await _database!.transaction((txn) async {
      // Clear existing nodes
      await txn.delete(_nodesTable);

      // Insert all nodes
      for (final node in nodes) {
        final createdAt = creationTimes[node.id] ?? DateTime.now();
        await txn.insert(_nodesTable, {
          'id': node.id,
          'label': node.label,
          'position_x': node.position.dx,
          'position_y': node.position.dy,
          'color': node.color.toARGB32(),
          'parent_id': node.parent?.id,
          'created_at': createdAt.toIso8601String(),
        });
      }
    });
  }
}
