import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class CanvasKeyboardHandler {
  static bool isDesktop() {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  static bool isMobile() {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static void handleKeyPress(
    KeyEvent event, {
    required bool hasSelectedNode,
    required bool isEditing,
    required VoidCallback onCreateChild,
    required VoidCallback onCreateSibling,
    required VoidCallback onStartEditing,
    required VoidCallback onDeleteNode,
    required VoidCallback onCancelEditing,
    required VoidCallback onFinishEditing,
    required VoidCallback onToggleHelp,
    required VoidCallback onToggleFullHelp,
  }) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyH && isDesktop()) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          onToggleFullHelp();
        } else {
          onToggleHelp();
        }
        return; // Prevent other actions when 'H' is pressed
      }

      if (event.logicalKey == LogicalKeyboardKey.keyN &&
          hasSelectedNode &&
          !isEditing) {
        // Create child node when 'N' is pressed and a node is selected
        onCreateChild();
      } else if (event.logicalKey == LogicalKeyboardKey.keyO &&
          hasSelectedNode &&
          !isEditing) {
        // Create sibling node when 'O' is pressed and a node is selected
        onCreateSibling();
      } else if (event.logicalKey == LogicalKeyboardKey.keyE &&
          hasSelectedNode &&
          !isEditing &&
          isDesktop()) {
        // Edit node when 'E' is pressed on desktop platforms
        onStartEditing();
      } else if ((event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) &&
          hasSelectedNode &&
          !isEditing) {
        // Delete node when Delete or Backspace is pressed
        onDeleteNode();
      } else if (event.logicalKey == LogicalKeyboardKey.escape && isEditing) {
        // Cancel text editing on Escape
        onCancelEditing();
      } else if (event.logicalKey == LogicalKeyboardKey.enter && isEditing) {
        // Finish text editing on Enter
        onFinishEditing();
      }
    }
  }
}
