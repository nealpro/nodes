import 'package:flutter/material.dart';
import 'package:nodes/project/project_service.dart';
import 'package:nodes/main.dart';

/// Result returned when a project is successfully selected
class ProjectSelectionResult {
  final ProjectResult projectResult;
  final bool isNewProject;

  const ProjectSelectionResult({
    required this.projectResult,
    required this.isNewProject,
  });
}

/// Screen for selecting whether to create a new project or open an existing one
class ProjectSelectionScreen extends StatefulWidget {
  final ProjectService projectService;

  const ProjectSelectionScreen({super.key, required this.projectService});

  @override
  State<ProjectSelectionScreen> createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> {
  bool _isLoading = false;
  String? _error;

  void _navigateToMindMap(ProjectResult projectResult) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MindMapScreen(
          project: projectResult.project,
          database: projectResult.database,
        ),
      ),
    );
  }

  Future<void> _createNewProject() async {
    final result = await showDialog<_NewProjectDialogResult>(
      context: context,
      builder: (context) => const _NewProjectDialog(),
    );

    if (result == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final projectResult = await widget.projectService.createProjectWithPicker(
      projectName: result.name,
      description: result.description,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (projectResult.isSuccess) {
      _navigateToMindMap(projectResult);
    } else {
      setState(() {
        _error = projectResult.error;
      });
    }
  }

  Future<void> _openExistingProject() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final projectResult = await widget.projectService.openProjectWithPicker();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (projectResult.isSuccess) {
      _navigateToMindMap(projectResult);
    } else if (projectResult.error != 'No directory selected') {
      setState(() {
        _error = projectResult.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Project')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Get Started',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new project or open an existing one',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Error message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Loading indicator
              if (_isLoading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 24),
              ],

              // Create new project button
              FilledButton.icon(
                onPressed: _isLoading ? null : _createNewProject,
                icon: const Icon(Icons.add),
                label: const Text('Create New Project'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Open existing project button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _openExistingProject,
                icon: const Icon(Icons.folder_open),
                label: const Text('Open Existing Project'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 48),

              // Info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About Nodes Projects',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A Nodes project is a directory containing:\n'
                      '• A .nodes configuration file\n'
                      '• A nodes.db SQLite database for your mind map\n\n'
                      'Your data stays local on your system.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for creating a new project
class _NewProjectDialog extends StatefulWidget {
  const _NewProjectDialog();

  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogResult {
  final String name;
  final String? description;

  const _NewProjectDialogResult({required this.name, this.description});
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(
        _NewProjectDialogResult(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Project'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'My Mind Map',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a project name';
                }
                // Check for invalid characters in directory names
                if (value.contains(RegExp(r'[<>:"/\\|?*]'))) {
                  return 'Name contains invalid characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'A brief description of this project',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
