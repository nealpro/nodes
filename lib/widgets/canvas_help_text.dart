import 'package:flutter/foundation.dart';

class CanvasHelpText {
  static bool _isDesktop() {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  static String getSelectedNodeHelpText() {
    if (_isDesktop()) {
      return 'Press N to add child • Press O to add sibling • Press E to edit • Press Delete to remove • Long press (mobile) to add child';
    } else {
      return 'Press N to add child • Double-tap to edit • Long press to add child • Use sibling button in top bar';
    }
  }

  static String getDefaultHelpText() {
    if (_isDesktop()) {
      return 'Select a node first • Use + button to add root node • Press E to edit nodes on desktop';
    } else {
      return 'Select a node first • Use + button to add root node • Double-tap nodes to edit';
    }
  }

  static String getEditingHelpText() {
    return 'Press Enter to save • Press Escape to cancel • Tap outside to save';
  }

  static String getFullHelpText() {
    if (_isDesktop()) {
      return '''
**Canvas Controls:**
- Pan: Click and drag, or use arrow keys.
- Zoom: Scroll wheel.

**Node Actions (with a node selected):**
- N: Add a new child node.
- O: Add a new sibling node.
- E: Edit the selected node's text.
- Delete/Backspace: Remove the selected node and its children.

**General:**
- H: Toggle this help text.
- Shift + H: Toggle full help.
- + Button: Add a new root node if the canvas is empty.
''';
    } else {
      // No full help for mobile yet
      return '';
    }
  }
}
