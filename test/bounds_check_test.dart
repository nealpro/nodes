import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodes/main.dart';
import 'package:nodes/add_node_page.dart';
import 'package:nodes/draggable_node.dart';

void main() {
  testWidgets('MindMapScreen clamps node position to canvas bounds', (
    WidgetTester tester,
  ) async {
    // Create MindMapScreen directly without test mode (no pre-generated nodes)
    await tester.pumpWidget(const MaterialApp(home: MindMapScreen()));
    await tester.pumpAndSettle();

    // Add a node using 'E' key
    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    await tester.pumpAndSettle();

    // We should be in AddNodePage
    expect(find.byType(AddNodePage), findsOneWidget);

    // Enter label and submit
    await tester.enterText(find.byType(TextField), 'Test Node');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify node is added
    expect(find.text('Test Node'), findsOneWidget);

    // Debug: Check transform before manual center
    final state = tester.state(find.byType(MindMapScreen));
    final dynamic dynamicState = state;
    print(
      'Transform before C: \n${dynamicState.transformationController.value}',
    );

    // Center on the node to ensure it is visible on screen for dragging
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.pumpAndSettle();

    print(
      'Transform after C: \n${dynamicState.transformationController.value}',
    );

    // Find the DraggableNode that wraps the node
    final draggableNodeFinder = find.byType(DraggableNode).first;

    // Drag the node slightly to verify dragging works
    // Node is at (2440, 2470). Dragging by (-100, -100) should move it to (2340, 2370).
    await tester.drag(draggableNodeFinder, const Offset(-100, -100));
    await tester.pumpAndSettle();

    // Verify position changed
    expect(find.text('(2340, 2370)'), findsOneWidget);

    // Now drag to the top-left boundary (0,0)
    // We need to drag by approx -2400.
    // Since the viewport is small, a single large drag might go off-screen and be ignored/clipped.
    // We can drag in multiple steps or zoom out.
    // Let's try dragging in steps.

    for (int i = 0; i < 5; i++) {
      await tester.drag(draggableNodeFinder, const Offset(-500, -500));
      await tester.pumpAndSettle();
      // Re-center to keep it on screen?
      // If we drag the node, it moves on the canvas. The viewport stays put.
      // So the node moves away from the center of the viewport.
      // Eventually it goes off screen.
      // So we need to follow it.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.pumpAndSettle();
    }

    // Verify position text
    // NodeWidget displays position: '(${node.position.dx.toInt()}, ${node.position.dy.toInt()})'
    // It should be (0, 0)
    expect(find.text('(0, 0)'), findsOneWidget);

    // Drag to bottom-right beyond bounds
    // ...

    // Drag to bottom-right beyond bounds
    // Canvas size is 5000. Node size is 120x60.
    // Max x = 5000 - 120 = 4880
    // Max y = 5000 - 60 = 4940
    await tester.drag(draggableNodeFinder, const Offset(6000, 6000));
    await tester.pumpAndSettle();

    expect(find.text('(4880, 4940)'), findsOneWidget);
  });
}
