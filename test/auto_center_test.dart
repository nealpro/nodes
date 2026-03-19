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

    // The translation should be negative (scrolled into the canvas)
    final tx = transform.getTranslation().x;
    final ty = transform.getTranslation().y;
    expect(tx, isNegative);
    expect(ty, isNegative);
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
