import 'package:flutter_test/flutter_test.dart';
import 'package:nodes/main.dart';

void main() {
  testWidgets('MindMap app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MindMapApp());

    // Verify that the title is present.
    expect(find.text('Fast MindMap'), findsOneWidget);
  });
}
