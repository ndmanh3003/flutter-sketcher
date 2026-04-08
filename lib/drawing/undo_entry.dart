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
  UndoClearCanvas({required this.clearedShapes});

  final List<DrawShape> clearedShapes;
}
