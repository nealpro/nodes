import 'package:file_picker/file_picker.dart';
import 'package:nodes/project/database_service.dart';
import 'package:nodes/project/nodes_project.dart';
import 'package:path/path.dart' as path;

/// Result of a project operation
class ProjectResult {
  final NodesProject? project;
  final DatabaseService? database;
  final String? error;

  const ProjectResult({this.project, this.database, this.error});

  bool get isSuccess => project != null && database != null && error == null;
}

/// Service for managing project lifecycle operations.
/// Handles creating, opening, and managing Nodes projects.
class ProjectService {
  NodesProject? _currentProject;
  DatabaseService? _databaseService;

  NodesProject? get currentProject => _currentProject;
  DatabaseService? get database => _databaseService;

  /// Creates a new Nodes project at the specified directory
  Future<ProjectResult> createProject({
    required String directoryPath,
    required String projectName,
    String? description,
  }) async {
    try {
      // Create the project
      final project = await NodesProject.create(
        directoryPath: directoryPath,
        name: projectName,
        description: description,
      );

      // Initialize the database
      final database = DatabaseService(databasePath: project.databasePath);
      await database.open();

      _currentProject = project;
      _databaseService = database;

      return ProjectResult(project: project, database: database);
    } catch (e) {
      return ProjectResult(error: 'Failed to create project: $e');
    }
  }

  /// Opens an existing Nodes project from a directory
  Future<ProjectResult> openProject(String directoryPath) async {
    try {
      // Check if it's a valid project directory
      if (!await NodesProject.isValidProjectDirectory(directoryPath)) {
        return const ProjectResult(
          error:
              'The selected directory is not a valid Nodes project. '
              'No .nodes file found.',
        );
      }

      // Load the project
      final project = await NodesProject.load(directoryPath);
      if (project == null) {
        return const ProjectResult(
          error: 'Failed to load project configuration.',
        );
      }

      // Open the database
      final database = DatabaseService(databasePath: project.databasePath);
      await database.open();

      _currentProject = project;
      _databaseService = database;

      return ProjectResult(project: project, database: database);
    } catch (e) {
      return ProjectResult(error: 'Failed to open project: $e');
    }
  }

  /// Opens a directory picker and creates a new project
  Future<ProjectResult> createProjectWithPicker({
    required String projectName,
    String? description,
  }) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select location for new Nodes project',
      );

      if (result == null) {
        return const ProjectResult(error: 'No directory selected');
      }

      // Create project in a subdirectory with the project name
      final projectPath = path.join(result, projectName);

      return createProject(
        directoryPath: projectPath,
        projectName: projectName,
        description: description,
      );
    } catch (e) {
      return ProjectResult(error: 'Failed to create project: $e');
    }
  }

  /// Opens a directory picker to select an existing project
  Future<ProjectResult> openProjectWithPicker() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select a Nodes project directory',
      );

      if (result == null) {
        return const ProjectResult(error: 'No directory selected');
      }

      return openProject(result);
    } catch (e) {
      return ProjectResult(error: 'Failed to open project: $e');
    }
  }

  /// Closes the current project
  Future<void> closeProject() async {
    await _databaseService?.close();
    _databaseService = null;
    _currentProject = null;
  }

  /// Saves the current project state
  Future<void> saveProject() async {
    await _currentProject?.save();
  }
}
