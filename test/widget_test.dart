import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodes/main.dart';

void main() {
  testWidgets('MindMap app smoke test', (WidgetTester tester) async {
    // Create MindMapScreen directly in test mode to bypass startup screen
    await tester.pumpWidget(
      const MaterialApp(
        home: MindMapScreen(isTestMode: true),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that we're on the MindMapScreen by checking for the app bar title
    expect(find.text('Nodes (Test Mode)'), findsOneWidget);
  });
}
