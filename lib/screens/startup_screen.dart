import 'package:flutter/material.dart';
import 'package:nodes/main.dart';
import 'package:nodes/project/project_service.dart';
import 'package:nodes/screens/project_selection_screen.dart';

/// Screen shown at startup in debug/profile mode.
/// Allows the user to choose between using the project workflow
/// or generating temporary test nodes.
class StartupScreen extends StatelessWidget {
  /// Project service for managing projects
  final ProjectService projectService;

  const StartupScreen({super.key, required this.projectService});

  void _onUseProjectWorkflow(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            ProjectSelectionScreen(projectService: projectService),
      ),
    );
  }

  void _onGenerateTestNodes(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MindMapScreen(isTestMode: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App icon/logo area
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hub,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Nodes',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Mind Mapping for Developers',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Debug/Profile mode indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bug_report, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Debug / Profile Mode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Option 1: Project workflow
                _OptionCard(
                  icon: Icons.folder_open,
                  title: 'Open or Create Project',
                  description:
                      'Use the standard workflow to create or open a Nodes project directory.',
                  onTap: () => _onUseProjectWorkflow(context),
                ),
                const SizedBox(height: 16),

                // Option 2: Test nodes
                _OptionCard(
                  icon: Icons.science,
                  title: 'Generate Test Nodes',
                  description:
                      'Create temporary test nodes for development. Data will not be saved.',
                  onTap: () => _onGenerateTestNodes(context),
                  isSecondary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isSecondary;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSecondary
          ? colorScheme.surfaceContainerHighest
          : colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSecondary
                      ? colorScheme.surface
                      : colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSecondary
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSecondary
                            ? colorScheme.onSurface
                            : colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSecondary
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isSecondary
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
