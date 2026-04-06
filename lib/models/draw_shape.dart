import 'package:flutter/material.dart';

enum ShapeType { point, line, ellipse, circle, square, rectangle }

class DrawShape {
  DrawShape({
    required this.type,
    required this.start,
    required this.end,
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.filled,
  });

  final ShapeType type;
  final Offset start;
  final Offset end;
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final bool filled;

  Rect get rect => Rect.fromPoints(start, end);

  DrawShape copyWith({
    ShapeType? type,
    Offset? start,
    Offset? end,
    Color? strokeColor,
    Color? fillColor,
    double? strokeWidth,
    bool? filled,
  }) {
    return DrawShape(
      type: type ?? this.type,
      start: start ?? this.start,
      end: end ?? this.end,
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: fillColor ?? this.fillColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      filled: filled ?? this.filled,
    );
  }
}
