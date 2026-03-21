import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodes/main.dart';

void main() {
  testWidgets('MindMapScreen auto-centers on nodes after test mode load', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MindMapScreen(isTestMode: true)),
    );
    await tester.pumpAndSettle();

    // Access the transformation controller to verify centering happened
    final state = tester.state(find.byType(MindMapScreen));
    final dynamic dynamicState = state;
    final Matrix4 transform = dynamicState.transformationController.value;

    // After auto-centering, the transform should NOT be identity
    // (it should have translated to show the first root node)
    expect(transform, isNot(equals(Matrix4.identity())));

    // Auto-centering should move the viewport in at least one direction.
    final tx = transform.getTranslation().x;
    final ty = transform.getTranslation().y;
    expect(tx.abs() > 0.001 || ty.abs() > 0.001, isTrue);
  });

  testWidgets('Empty MindMapScreen does not auto-center', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MindMapScreen()));
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(MindMapScreen));
    final dynamic dynamicState = state;
    final Matrix4 transform = dynamicState.transformationController.value;

    // No nodes — transform stays at identity
    expect(transform, equals(Matrix4.identity()));
  });
}
