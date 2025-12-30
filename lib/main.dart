import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nodes/debug/node_generator.dart';
import 'package:nodes/grid_painter.dart';
import 'package:nodes/node_widget.dart';
import 'package:nodes/viewport_controller.dart';
import 'package:nodes/add_node_page.dart';
import 'connection_painter.dart';
import 'node.dart';

part 'mind_map_app.dart';

void main() {
  runApp(const MindMapApp());
}
