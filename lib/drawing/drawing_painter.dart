import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sketcher/models/draw_shape.dart';

class DrawingPainter extends CustomPainter {
  const DrawingPainter({
    required this.shapes,
    required this.preview,
  });

  final List<DrawShape> shapes;
  final DrawShape? preview;

  @override
  void paint(Canvas canvas, Size size) {
    paintShapes(canvas, shapes);
    if (preview != null) {
      _paintShape(canvas, preview!);
    }
  }

  static void paintShapes(Canvas canvas, List<DrawShape> shapes) {
    for (final DrawShape shape in shapes) {
      _paintShape(canvas, shape);
    }
  }

  static void _paintShape(Canvas canvas, DrawShape shape) {
    final Paint stroke = Paint()
      ..color = shape.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = shape.strokeWidth;

    final Paint fill = Paint()
      ..color = shape.fillColor
      ..style = PaintingStyle.fill;

    final Rect rect = shape.rect;
    switch (shape.type) {
      case ShapeType.point:
        canvas.drawCircle(shape.start, math.max(1.5, shape.strokeWidth), fill);
      case ShapeType.line:
        canvas.drawLine(shape.start, shape.end, stroke);
      case ShapeType.ellipse:
        if (shape.filled) {
          canvas.drawOval(rect, fill);
        }
        canvas.drawOval(rect, stroke);
      case ShapeType.circle:
        final Rect r = _squareRectFrom(rect);
        if (shape.filled) {
          canvas.drawOval(r, fill);
        }
        canvas.drawOval(r, stroke);
      case ShapeType.square:
        final Rect r = _squareRectFrom(rect);
        if (shape.filled) {
          canvas.drawRect(r, fill);
        }
        canvas.drawRect(r, stroke);
      case ShapeType.rectangle:
        if (shape.filled) {
          canvas.drawRect(rect, fill);
        }
        canvas.drawRect(rect, stroke);
    }
  }

  static Rect _squareRectFrom(Rect rect) {
    final double side = math.min(rect.width.abs(), rect.height.abs());
    return Rect.fromLTWH(rect.left, rect.top, side, side);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.shapes != shapes || oldDelegate.preview != preview;
  }
}
