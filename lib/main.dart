import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nodes/debug/node_generator.dart';
import 'package:nodes/draggable_node.dart';
import 'package:nodes/grid_painter.dart';
import 'package:nodes/viewport_controller.dart';
import 'package:nodes/add_node_page.dart';
import 'package:nodes/screens/organized_mode_screen.dart';
import 'package:nodes/project/database_service.dart';
import 'package:nodes/project/nodes_project.dart';
import 'package:nodes/project/project_service.dart';
import 'package:nodes/screens/project_selection_screen.dart';
import 'package:nodes/screens/startup_screen.dart';
import 'connection_painter.dart';
import 'node.dart';

part 'mind_map_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseService.initialize();
  runApp(const MindMapApp());
}
