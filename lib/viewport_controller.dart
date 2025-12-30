import 'package:flutter/material.dart';
import 'node.dart';

/// A controller that manages viewport transformations and navigation
/// for the mind map canvas.
class ViewportController {
  final TransformationController transformationController;
  final double canvasSize;

  ViewportController({
    required this.transformationController,
    required this.canvasSize,
  });

  /// Centers the viewport on the canvas.
  void center(BoxConstraints constraints) {
    final double width = _getWidth(constraints);
    final double height = _getHeight(constraints);
    final double x = -(canvasSize / 2 - width / 2);
    final double y = -(canvasSize / 2 - height / 2);
    transformationController.value = Matrix4.identity()
      ..translateByDouble(x, y, 0.0, 1.0);
  }

  /// Centers the viewport on a specific node.
  void centerOnNode(Node node, BoxConstraints constraints) {
    final double width = _getWidth(constraints);
    final double height = _getHeight(constraints);
    // Node center is at (node.position.dx + 60, node.position.dy + 30)
    final double nodeCenterX = node.position.dx + 60;
    final double nodeCenterY = node.position.dy + 30;
    // We want nodeCenterX/Y to be at viewport center (width/2, height/2)
    final double x = width / 2 - nodeCenterX;
    final double y = height / 2 - nodeCenterY;
    transformationController.value = Matrix4.identity()
      ..translateByDouble(x, y, 0.0, 1.0);
  }

  /// Resets the viewport to the identity matrix.
  void reset() {
    transformationController.value = Matrix4.identity();
  }

  /// Gets the current scale factor of the viewport.
  double get scale {
    final matrix = transformationController.value;
    return matrix.getMaxScaleOnAxis();
  }

  /// Gets the current translation offset of the viewport.
  Offset get translation {
    final matrix = transformationController.value;
    return Offset(matrix.getTranslation().x, matrix.getTranslation().y);
  }

  /// Validates the current transformation matrix and resets if invalid.
  /// Returns true if the matrix was valid, false if it was reset.
  bool validateAndReset() {
    try {
      Matrix4.inverted(transformationController.value);
      return true;
    } catch (e) {
      reset();
      return false;
    }
  }

  double _getWidth(BoxConstraints constraints) {
    return constraints.hasBoundedWidth ? constraints.maxWidth : 800;
  }

  double _getHeight(BoxConstraints constraints) {
    return constraints.hasBoundedHeight ? constraints.maxHeight : 600;
  }

  void dispose() {
    // Note: The caller is responsible for disposing the TransformationController
  }
}
