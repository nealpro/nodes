import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodes/node.dart';
import 'package:nodes/node_widget.dart';

void main() {
  testWidgets('NodeWidget has ellipsis overflow', (WidgetTester tester) async {
    final node = Node(
      id: '1',
      position: Offset.zero,
      label: 'Very long text that should overflow',
      color: Colors.red,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NodeWidget(node: node)),
      ),
    );

    final textFinder = find.text('Very long text that should overflow');
    expect(textFinder, findsOneWidget);

    final Text textWidget = tester.widget(textFinder);
    expect(textWidget.overflow, TextOverflow.ellipsis);
    expect(textWidget.maxLines, 1);
  });
}
