# Nodes Project Instructions

## Project Overview
Nodes is a Flutter mind-mapping application inspired by Vim and `h-m-m`. It features an infinite canvas (5000×5000), keyboard-centric navigation, and dual freeform/organized layout modes.

## Architecture

### File Organization (using `part`/`part of`)
- `lib/main.dart` is the entry point; `lib/mind_map_app.dart` is a `part` of it.
- Import from `package:nodes/main.dart` to access both `MindMapApp` and `MindMapScreen`.

### Rendering Layers (bottom to top)
1. `GridPainter` — 50px grid background with viewport culling
2. `ConnectionPainter` — Bezier curves between parent/child nodes (version-tracked for efficient repaints)
3. `DraggableNode` wrappers containing `NodeWidget` (120×60 fixed size)

### Key Components
| File | Responsibility |
|------|----------------|
| `lib/node.dart` | `Node` data model with parent/children tree |
| `lib/viewport_controller.dart` | Viewport transformations, centering, matrix validation |
| `lib/organized_mode_screen.dart` | Separate screen for tree-layout view |
| `lib/add_node_page.dart` | Modal for creating nodes with color picker |
| `lib/draggable_node.dart` | Stateful wrapper for drag operations (local state prevents full tree rebuilds) |
| `lib/connection_painter.dart` | CustomPainter with version tracking and visibility culling |
| `lib/debug/node_generator.dart` | Generates 30 sample nodes in debug mode |

### Performance Optimizations
- `ConnectionPainter` uses a `version` counter—only increment when node positions change
- `_visibleRect` culling skips rendering nodes/connections outside viewport
- `DraggableNode` uses local state during drags to avoid rebuilding entire node list
- `RepaintBoundary` wraps grid and connections for isolated repainting

## Keyboard Shortcuts (Vim-style)

### Freeform Mode (`MindMapScreen`)
- `c` — Center on selected node (or first root by creation time)
- `Ctrl+C` — Center on canvas center
- `f` — Open organized mode
- `e` — Add adjacent/sibling node
- `x` — Add child node
- `o` — Show node content popup

### Organized Mode (`OrganizedModeScreen`)
- `h`/`j`/`k`/`l` — Navigate: parent / next sibling / prev sibling / first child
- `c` — Center on selected
- `f` or `Escape` — Exit to freeform mode
- `o` — Show node content popup

## Patterns & Conventions

### State Management
- Local `StatefulWidget` state—no external state management package.
- `_MindMapScreenState` owns the `List<Node>` and tracks `_selectedNode`.
- Node IDs: sequential strings `node_0`, `node_1`, etc.
- `_nodeCreationTimes` map tracks node creation order for "first root" logic.

### Node Position Clamping
Always clamp positions to canvas bounds when creating/moving nodes:
```dart
Offset _clampToCanvas(Offset position) {
  return Offset(
    position.dx.clamp(0.0, _canvasSize - 120), // 120 = node width
    position.dy.clamp(0.0, _canvasSize - 60),  // 60 = node height
  );
}
```

### Viewport Matrix Handling
`ViewportController.validateAndReset()` catches non-invertible matrices and resets to identity. This is called on every transform change.

### Testing Patterns
Tests access private state by casting to `dynamic`:
```dart
final state = tester.state(find.byType(MindMapScreen));
final dynamic dynamicState = state;
dynamicState.transformationController.value = Matrix4.zero();
```
Test files: `test/mind_map_test.dart`, `test/bounds_check_test.dart`, `test/overflow_test.dart`

### Debug Mode
`kDebugMode` triggers `generateNodes()` in `initState` to populate 30 sample nodes.

## Commands
```bash
flutter run -d macos    # Run on macOS
flutter test            # Run all tests
```

## Platform Support
- **Current**: macOS
- **Planned**: Windows, then iPadOS (in that priority order)

## Roadmap / Not Yet Implemented
- **File persistence**: Nodes will be backed by files (markdown by default). Canvases will map to directories on local filesystem or cloud storage.
- **Multiple canvases with pagination**: Organized mode is the foundation for this. Pagination will arrive once multi-canvas support is added.
- **Vim navigation in freeform mode**: `h`/`j`/`k`/`l` only work in organized mode currently.
