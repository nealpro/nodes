import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodes/main.dart';

void main() {
  testWidgets('MindMapScreen handles non-invertible matrix', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MindMapApp());
    await tester.pumpAndSettle();

    // Find the state
    final state = tester.state(find.byType(MindMapScreen));
    final dynamic dynamicState = state;

    // Ensure focus
    await tester.tap(find.byType(InteractiveViewer));
    await tester.pump();

    // Toggle organized mode
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();

    // Verify we are in organized mode (pan disabled)
    var interactiveViewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(interactiveViewer.panEnabled, isFalse);

    // Set a bad matrix (non-invertible)
    dynamicState.transformationController.value = Matrix4.zero();

    // Pump to process the state change
    await tester.pump();

    // The listener should have reset the matrix to identity
    expect(
      dynamicState.transformationController.value,
      equals(Matrix4.identity()),
    );

    // And reset organized mode (pan enabled)
    interactiveViewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(interactiveViewer.panEnabled, isTrue);
  });
}
