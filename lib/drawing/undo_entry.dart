import 'package:flutter/material.dart';

abstract class UndoEntry {}

class UndoAddShape extends UndoEntry {}

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
