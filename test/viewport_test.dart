import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodes/viewport_controller.dart';
import 'package:nodes/node.dart';

void main() {
  group('ViewportController', () {
    late TransformationController transformationController;
    late ViewportController viewportController;

    setUp(() {
      transformationController = TransformationController();
      viewportController = ViewportController(
        transformationController: transformationController,
        canvasSize: 5000.0,
      );
    });

    tearDown(() {
      transformationController.dispose();
    });

    test('center places viewport at canvas center', () {
      final constraints = BoxConstraints.tight(const Size(800, 600));
      viewportController.center(constraints);

      final translation = viewportController.translation;
      // Canvas center = 2500, viewport center = 400 (800/2)
      // Expected x = -(2500 - 400) = -2100
      expect(translation.dx, closeTo(-2100, 0.1));
      // Canvas center = 2500, viewport center = 300 (600/2)
      // Expected y = -(2500 - 300) = -2200
      expect(translation.dy, closeTo(-2200, 0.1));
    });

    test('centerOnNode places node at viewport center', () {
      final node = Node(
        id: '1',
        position: const Offset(1000, 2000),
        label: 'Test',
        color: Colors.blue,
      );
      final constraints = BoxConstraints.tight(const Size(800, 600));
      viewportController.centerOnNode(node, constraints);

      final translation = viewportController.translation;
      // Node center = (1060, 2030), viewport center = (400, 300)
      // Expected x = 400 - 1060 = -660
      expect(translation.dx, closeTo(-660, 0.1));
      // Expected y = 300 - 2030 = -1730
      expect(translation.dy, closeTo(-1730, 0.1));
    });

    test('validateAndReset returns true for valid matrix', () {
      expect(viewportController.validateAndReset(), isTrue);
    });

    test('validateAndReset resets non-invertible matrix', () {
      transformationController.value = Matrix4.zero();
      expect(viewportController.validateAndReset(), isFalse);
      expect(transformationController.value, equals(Matrix4.identity()));
    });

    test('scale returns correct zoom level', () {
      // Identity matrix has scale 1.0
      expect(viewportController.scale, closeTo(1.0, 0.01));

      // Apply 2x zoom
      transformationController.value = Matrix4.identity()..scale(2.0);
      expect(viewportController.scale, closeTo(2.0, 0.01));
    });

    test('reset returns to identity', () {
      final constraints = BoxConstraints.tight(const Size(800, 600));
      viewportController.center(constraints);

      // Verify we're not at identity
      expect(viewportController.translation.dx, isNot(0));

      viewportController.reset();
      expect(transformationController.value, equals(Matrix4.identity()));
    });
  });

  group('ViewportController with unbounded constraints', () {
    test('handles unbounded width gracefully', () {
      final tc = TransformationController();
      final vc = ViewportController(
        transformationController: tc,
        canvasSize: 5000.0,
      );

      // Unbounded constraints — should fallback to 800x600
      const constraints = BoxConstraints();
      vc.center(constraints);

      final translation = vc.translation;
      expect(translation.dx, closeTo(-2100, 0.1)); // (800/2 - 2500)
      expect(translation.dy, closeTo(-2200, 0.1)); // (600/2 - 2500)

      tc.dispose();
    });
  });
}
