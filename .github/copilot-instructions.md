# Nodes Project Instructions

## Project Overview
Nodes is a high-performance Flutter mind-mapping application inspired by Vim and `h-m-m`. It features an infinite canvas, keyboard-centric navigation, and hybrid freeform/organized layout modes.

## Architecture
- **Core Engine**: Built on standard Flutter widgets (`InteractiveViewer`, `Stack`, `CustomPaint`).
- **Entry Point**: `lib/main.dart` initializes `MindMapApp`.
- **Main Screen**: `MindMapScreen` (`lib/mind_map_app.dart`) manages the entire application state and UI.
- **Rendering Layers**:
  1. **Background**: `GridPainter` (`lib/grid_painter.dart`).
  2. **Connections**: `ConnectionPainter` (`lib/connection_painter.dart`) draws Bezier curves between nodes.
  3. **Nodes**: `Positioned` widgets wrapping `NodeWidget` (`lib/node_widget.dart`).

## Key Patterns & Conventions

### State Management
- **Local State**: State is currently managed within `_MindMapScreenState`.
- **Data Model**: `Node` class (`lib/node.dart`) is the primary data structure (in-memory, mutable).
- **Node ID**: Simple string generation (`node_0`, `node_1`).

### Navigation & Input
- **Vim Bindings**: The app relies heavily on keyboard shortcuts defined in `CallbackShortcuts`:
  - `h`/`j`/`k`/`l`: Navigate node selection (Parent / Next Sibling / Prev Sibling / Child).
  - `c`: Center viewport.
  - `f`: Toggle "Organized" mode (auto-layout).
  - `e`: Add adjacent node.
  - `x`: Add child node.
  - `d`: Hold to auto-organize (physics-based animation).
- **Viewport**: Managed by `ViewportController` (`lib/viewport_controller.dart`) wrapping a `TransformationController`.

### Layout System
- **Hybrid Mode**:
  - **Freeform**: Nodes can be dragged anywhere (`GestureDetector` on `NodeWidget`).
  - **Organized**: Nodes are auto-arranged using a tree layout algorithm (`_calculateTreeLayout` in `MindMapScreen`).
- **Animation**: `_stepTowardOrganized` uses a manual physics loop via `Timer.periodic` to animate nodes to their target positions.

### Testing
- **State Access**: Tests (`test/mind_map_test.dart`) may access private state members by casting the state object to `dynamic`.
  ```dart
  final state = tester.state(find.byType(MindMapScreen));
  final dynamic dynamicState = state;
  // Access private members like dynamicState.transformationController
  ```

## Critical Workflows
- **Debugging**: `kDebugMode` is used in `initState` to generate initial sample nodes (`lib/debug/node_generator.dart`).
- **Canvas**: The canvas size is fixed at `5000.0` x `5000.0`.

## Future/Missing
- **File I/O**: The README mentions "All nodes are files", but this is not yet implemented. Nodes are currently transient.
