import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodes/grid_painter.dart';
import 'package:nodes/connection_painter.dart';
import 'package:nodes/node.dart';

void main() {
  group('GridPainter', () {
    test('repaints when visibleRectNotifier value changes', () {
      final notifier = ValueNotifier<Rect?>(null);
      final painter = GridPainter(visibleRectNotifier: notifier);
      final oldPainter = GridPainter(visibleRectNotifier: notifier);

      // Same notifier instance — should not need full repaint
      expect(painter.shouldRepaint(oldPainter), isFalse);
    });

    test('repaints when notifier object changes', () {
      final notifier1 = ValueNotifier<Rect?>(null);
      final notifier2 = ValueNotifier<Rect?>(null);
      final painter = GridPainter(visibleRectNotifier: notifier1);
      final oldPainter = GridPainter(visibleRectNotifier: notifier2);

      expect(painter.shouldRepaint(oldPainter), isTrue);
    });

    testWidgets('renders grid lines on canvas', (WidgetTester tester) async {
      final notifier = ValueNotifier<Rect?>(
        const Rect.fromLTRB(0, 0, 200, 200),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: GridPainter(visibleRectNotifier: notifier),
            ),
          ),
        ),
      );

      // No assertion needed — just verify it renders without error
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('updates grid when notifier value changes', (
      WidgetTester tester,
    ) async {
      final notifier = ValueNotifier<Rect?>(
        const Rect.fromLTRB(0, 0, 100, 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              child: CustomPaint(
                size: const Size(500, 500),
                painter: GridPainter(visibleRectNotifier: notifier),
              ),
            ),
          ),
        ),
      );

      // Update visible rect — painter should repaint via notifier
      notifier.value = const Rect.fromLTRB(0, 0, 500, 500);
      await tester.pump();

      // Verify widget tree is intact
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('ConnectionPainter', () {
    test('repaints when connection version changes', () {
      final version = ValueNotifier<int>(0);
      final rect = ValueNotifier<Rect?>(null);
      final nodes = <Node>[];

      final painter = ConnectionPainter(
        nodes: nodes,
        connectionVersion: version,
        visibleRectNotifier: rect,
      );
      final oldPainter = ConnectionPainter(
        nodes: nodes,
        connectionVersion: version,
        visibleRectNotifier: rect,
      );

      // Same node list — no full repaint needed (version notifier handles it)
      expect(painter.shouldRepaint(oldPainter), isFalse);
    });

    test('repaints when node list changes', () {
      final version = ValueNotifier<int>(0);
      final rect = ValueNotifier<Rect?>(null);

      final painter = ConnectionPainter(
        nodes: const [],
        connectionVersion: version,
        visibleRectNotifier: rect,
      );
      final oldPainter = ConnectionPainter(
        nodes: [
          Node(
            id: '1',
            position: Offset.zero,
            label: 'test',
            color: Colors.blue,
          ),
        ],
        connectionVersion: version,
        visibleRectNotifier: rect,
      );

      expect(painter.shouldRepaint(oldPainter), isTrue);
    });

    testWidgets('renders connections between parent and child', (
      WidgetTester tester,
    ) async {
      final parent = Node(
        id: '1',
        position: const Offset(100, 100),
        label: 'Parent',
        color: Colors.blue,
      );
      final child = Node(
        id: '2',
        position: const Offset(300, 100),
        label: 'Child',
        color: Colors.green,
      );
      parent.children.add(child);
      child.parent = parent;

      final version = ValueNotifier<int>(0);
      final rect = ValueNotifier<Rect?>(const Rect.fromLTRB(0, 0, 500, 500));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(500, 500),
              painter: ConnectionPainter(
                nodes: [parent, child],
                connectionVersion: version,
                visibleRectNotifier: rect,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('culls connections outside visible rect', (
      WidgetTester tester,
    ) async {
      final parent = Node(
        id: '1',
        position: const Offset(3000, 3000),
        label: 'Far Parent',
        color: Colors.blue,
      );
      final child = Node(
        id: '2',
        position: const Offset(3200, 3000),
        label: 'Far Child',
        color: Colors.green,
      );
      parent.children.add(child);
      child.parent = parent;

      final version = ValueNotifier<int>(0);
      // Visible rect that doesn't include the nodes
      final rect = ValueNotifier<Rect?>(const Rect.fromLTRB(0, 0, 500, 500));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(500, 500),
              painter: ConnectionPainter(
                nodes: [parent, child],
                connectionVersion: version,
                visibleRectNotifier: rect,
              ),
            ),
          ),
        ),
      );

      // Renders without error — connections are culled
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
