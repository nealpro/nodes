import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodes/main.dart';
import 'package:nodes/project/project_service.dart';
import 'package:nodes/screens/project_selection_screen.dart';
import 'package:nodes/screens/startup_screen.dart';

class _CountingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  testWidgets('Startup screen ignores rapid repeated navigation taps', (
    WidgetTester tester,
  ) async {
    final observer = _CountingNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: StartupScreen(projectService: ProjectService()),
      ),
    );

    final testNodesCard = find.ancestor(
      of: find.text('Generate Test Nodes'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(testNodesCard);
    await tester.tap(testNodesCard, warnIfMissed: false);
    await tester.tap(testNodesCard, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(MindMapScreen), findsOneWidget);
    expect(observer.pushCount, 2);
  });

  testWidgets(
    'Project selection shows only one new-project dialog on double tap',
    (WidgetTester tester) async {
      final observer = _CountingNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: ProjectSelectionScreen(projectService: ProjectService()),
        ),
      );

      final createButton = find.widgetWithText(
        FilledButton,
        'Create New Project',
      );
      await tester.tap(createButton, warnIfMissed: false);
      await tester.tap(createButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('New Project'), findsOneWidget);
      expect(observer.pushCount, 2);
    },
  );

  testWidgets(
    'Mind map add-node shortcut stays single-flight under rapid input',
    (WidgetTester tester) async {
      final observer = _CountingNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: const MindMapScreen(isTestMode: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();

      expect(find.text('Add Node'), findsOneWidget);
      expect(observer.pushCount, 2);
    },
  );
}
