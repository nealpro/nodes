import 'package:flutter/material.dart';
import '../models/node.dart';

class TextEditingOverlay extends StatelessWidget {
  final Node editingNode;
  final TextEditingController controller;
  final FocusNode focusNode;
  final BoxConstraints constraints;
  final VoidCallback onFinishEditing;

  const TextEditingOverlay({
    super.key,
    required this.editingNode,
    required this.controller,
    required this.focusNode,
    required this.constraints,
    required this.onFinishEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: (editingNode.position.dx - 60).clamp(0, constraints.maxWidth - 120),
      top: (editingNode.position.dy - 15).clamp(0, constraints.maxHeight - 40),
      child: Container(
        width: 120,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
          onSubmitted: (_) => onFinishEditing(),
          onTapOutside: (_) => onFinishEditing(),
        ),
      ),
    );
  }
}
