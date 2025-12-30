import 'dart:convert';
import 'dart:io';

/// Represents a Nodes project with its configuration and metadata.
/// Project information is stored in a .nodes file in the project directory.
class NodesProject {
  /// The directory path where the project is stored
  final String directoryPath;

  /// Human-readable name for the project
  final String name;

  /// When the project was created
  final DateTime createdAt;

  /// When the project was last modified
  DateTime lastModifiedAt;

  /// Project file format version for future migrations
  final int version;

  /// Optional description for the project
  String? description;

  NodesProject({
    required this.directoryPath,
    required this.name,
    required this.createdAt,
    required this.lastModifiedAt,
    this.version = 1,
    this.description,
  });

  /// The path to the .nodes configuration file
  String get configFilePath => '$directoryPath/.nodes';

  /// The path to the SQLite database file
  String get databasePath => '$directoryPath/nodes.db';

  /// Creates a NodesProject from a map (used for JSON deserialization)
  factory NodesProject.fromMap(Map<String, dynamic> map, String directoryPath) {
    return NodesProject(
      directoryPath: directoryPath,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModifiedAt: DateTime.parse(map['lastModifiedAt'] as String),
      version: map['version'] as int? ?? 1,
      description: map['description'] as String?,
    );
  }

  /// Converts this project to a map (used for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'version': version,
      'description': description,
    };
  }

  /// Loads a project from a directory containing a .nodes file
  static Future<NodesProject?> load(String directoryPath) async {
    final configFile = File('$directoryPath/.nodes');
    if (!await configFile.exists()) {
      return null;
    }

    try {
      final contents = await configFile.readAsString();
      final map = json.decode(contents) as Map<String, dynamic>;
      return NodesProject.fromMap(map, directoryPath);
    } catch (e) {
      return null;
    }
  }

  /// Saves the project configuration to the .nodes file
  Future<void> save() async {
    lastModifiedAt = DateTime.now();
    final configFile = File(configFilePath);
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(toMap()),
    );
  }

  /// Creates a new project in the specified directory
  static Future<NodesProject> create({
    required String directoryPath,
    required String name,
    String? description,
  }) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final now = DateTime.now();
    final project = NodesProject(
      directoryPath: directoryPath,
      name: name,
      createdAt: now,
      lastModifiedAt: now,
      description: description,
    );

    await project.save();
    return project;
  }

  /// Checks if a directory contains a valid Nodes project
  static Future<bool> isValidProjectDirectory(String directoryPath) async {
    final configFile = File('$directoryPath/.nodes');
    return configFile.exists();
  }
}
