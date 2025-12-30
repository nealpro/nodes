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
    await tester.pumpWidget(const MindMapApp());
    await tester.pumpAndSettle();

    // Add a node using 'E' key
    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    await tester.pumpAndSettle();

    // We should be in AddNodePage
    expect(find.byType(AddNodePage), findsOneWidget);

    // Enter label and submit
    await tester.enterText(find.byType(TextField), 'Test Node');
    await tester.tap(find.text('Add Node'));
    await tester.pumpAndSettle();

    // Verify node is added
    expect(find.text('Test Node'), findsOneWidget);

    // Find the DraggableNode that wraps the node
    final draggableNodeFinder = find.byType(DraggableNode).first;

    // Drag the node to the top-left beyond bounds
    // Canvas is 5000x5000. Node is likely at center.
    // Drag by -3000, -3000
    await tester.drag(draggableNodeFinder, const Offset(-3000, -3000));
    await tester.pumpAndSettle();

    // Verify position text
    // NodeWidget displays position: '(${node.position.dx.toInt()}, ${node.position.dy.toInt()})'
    // It should be (0, 0)
    expect(find.text('(0, 0)'), findsOneWidget);

    // Drag to bottom-right beyond bounds
    // Canvas size is 5000. Node size is 120x60.
    // Max x = 5000 - 120 = 4880
    // Max y = 5000 - 60 = 4940
    await tester.drag(draggableNodeFinder, const Offset(6000, 6000));
    await tester.pumpAndSettle();

    expect(find.text('(4880, 4940)'), findsOneWidget);
  });
}
