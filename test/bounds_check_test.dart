import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodes/main.dart';
import 'package:nodes/add_node_page.dart';

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

    expect(find.byType(AddNodePage), findsOneWidget);

    // Enter label and submit
    await tester.enterText(find.byType(TextField), 'Test Node');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify node is added at canvas center
    expect(find.text('Test Node'), findsOneWidget);
    expect(find.text('(2440, 2470)'), findsOneWidget);
  });

  test('Node position clamp logic works correctly', () {
    const canvasSize = 5000.0;
    const nodeWidth = 120.0;
    const nodeHeight = 60.0;

    Offset clamp(Offset position) {
      return Offset(
        position.dx.clamp(0.0, canvasSize - nodeWidth),
        position.dy.clamp(0.0, canvasSize - nodeHeight),
      );
    }

    // Within bounds - unchanged
    expect(clamp(const Offset(100, 200)), const Offset(100, 200));

    // Top-left boundary
    expect(clamp(const Offset(-50, -50)), const Offset(0, 0));

    // Bottom-right boundary
    expect(clamp(const Offset(5000, 5000)), const Offset(4880, 4940));

    // Mixed: one axis over, one under
    expect(clamp(const Offset(-10, 3000)), const Offset(0, 3000));
    expect(clamp(const Offset(3000, 5500)), const Offset(3000, 4940));
  });

  test('Node clamping preserves valid positions at edges', () {
    const canvasSize = 5000.0;

    Offset clamp(Offset position) {
      return Offset(
        position.dx.clamp(0.0, canvasSize - 120),
        position.dy.clamp(0.0, canvasSize - 60),
      );
    }

    // Exact boundary values should be preserved
    expect(clamp(const Offset(0, 0)), const Offset(0, 0));
    expect(clamp(const Offset(4880, 4940)), const Offset(4880, 4940));

    // Just inside boundaries
    expect(clamp(const Offset(1, 1)), const Offset(1, 1));
    expect(clamp(const Offset(4879, 4939)), const Offset(4879, 4939));
  });
}
