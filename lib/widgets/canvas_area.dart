import 'package:flutter/material.dart';

import 'package:sketcher/widgets/drawing_painter.dart';
import 'package:sketcher/models/draw_shape.dart';

class CanvasArea extends StatelessWidget {
  const CanvasArea({
    super.key,
    required this.shapes,
    required this.previewShape,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onTapDown,
    required this.onCanvasSized,
  });

  final List<DrawShape> shapes;
  final DrawShape? previewShape;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final GestureTapDownCallback onTapDown;
  final ValueChanged<Size> onCanvasSized;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        onCanvasSized(Size(constraints.maxWidth, constraints.maxHeight));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onTapDown: onTapDown,
          child: ColoredBox(
            color: Colors.white,
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: DrawingPainter(shapes: shapes, preview: previewShape),
            ),
          ),
        );
      },
    );
  }
}
