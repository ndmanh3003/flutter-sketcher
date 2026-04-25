import 'package:flutter/material.dart';
import 'package:sketcher/models/draw_shape.dart';

abstract class RedoEntry {}

class RedoAddShape extends RedoEntry {
  RedoAddShape({required this.shape});

  final DrawShape shape;
}

class RedoDeleteShape extends RedoEntry {
  RedoDeleteShape({required this.shapeIndex, required this.shape});

  final int shapeIndex;
  final DrawShape shape;
}

class RedoFillRestore extends RedoEntry {
  RedoFillRestore({
    required this.shapeIndex,
    required this.fillColor,
    required this.filled,
  });

  final int shapeIndex;
  final Color fillColor;
  final bool filled;
}

class RedoClearCanvas extends RedoEntry {
  RedoClearCanvas({
    required this.clearedShapes,
    required this.previousBackgroundColor,
  });

  final List<DrawShape> clearedShapes;
  final Color previousBackgroundColor;
}

class RedoBackgroundFill extends RedoEntry {
  RedoBackgroundFill({required this.newColor});

  final Color newColor;
}

class RedoLoadScene extends RedoEntry {
  RedoLoadScene({
    required this.beforeShapes,
    required this.afterShapes,
    required this.beforePath,
    required this.afterPath,
    required this.beforeBackgroundColor,
    required this.afterBackgroundColor,
  });

  final List<DrawShape> beforeShapes;
  final List<DrawShape> afterShapes;
  final String? beforePath;
  final String? afterPath;
  final Color beforeBackgroundColor;
  final Color afterBackgroundColor;
}
