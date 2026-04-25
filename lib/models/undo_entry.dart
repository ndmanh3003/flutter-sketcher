import 'package:flutter/material.dart';
import 'package:sketcher/models/draw_shape.dart';

abstract class UndoEntry {}

class UndoAddShape extends UndoEntry {
  UndoAddShape({required this.shape});

  final DrawShape shape;
}

class UndoFillRestore extends UndoEntry {
  UndoFillRestore({
    required this.shapeIndex,
    required this.fillColor,
    required this.filled,
  });
  final int shapeIndex;
  final Color fillColor;
  final bool filled;
}

class UndoClearCanvas extends UndoEntry {
  UndoClearCanvas({
    required this.clearedShapes,
    required this.previousBackgroundColor,
  });

  final List<DrawShape> clearedShapes;
  final Color previousBackgroundColor;
}

class UndoBackgroundFill extends UndoEntry {
  UndoBackgroundFill({required this.previousColor});

  final Color previousColor;
}

class UndoLoadScene extends UndoEntry {
  UndoLoadScene({
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
