import 'package:flutter/material.dart';
import 'package:sketcher/models/draw_shape.dart';

abstract class RedoEntry {}

class RedoAddShape extends RedoEntry {
  RedoAddShape({required this.shape});

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
  RedoClearCanvas({required this.clearedShapes});

  final List<DrawShape> clearedShapes;
}
