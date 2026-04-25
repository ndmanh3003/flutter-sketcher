import 'package:flutter/material.dart';

import 'package:sketcher/widgets/drawing_painter.dart';
import 'package:sketcher/models/draw_shape.dart';

class CanvasArea extends StatelessWidget {
  const CanvasArea({
    super.key,
    required this.shapes,
    required this.previewShape,
    required this.canvasSize,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onTapDown,
    required this.paintGeneration,
    required this.backgroundColor,
    this.panOffset = Offset.zero,
    this.zoomScale = 1.0,
  });

  final List<DrawShape> shapes;
  final DrawShape? previewShape;
  final Size canvasSize;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final GestureTapDownCallback onTapDown;
  final int paintGeneration;
  final Color backgroundColor;
  final Offset panOffset;
  final double zoomScale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onTapDown: onTapDown,
      child: ClipRect(
        child: SizedBox.expand(
          child: ColoredBox(
            color: const Color(0xFFD0D0D0),
            child: Transform(
              transform:
                  Matrix4.translationValues(panOffset.dx, panOffset.dy, 0) *
                  Matrix4.diagonal3Values(zoomScale, zoomScale, 1),
              // OverflowBox breaks tight parent constraints so the
              // SizedBox inside can enforce the fixed canvas dimensions.
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                minHeight: 0,
                maxHeight: double.infinity,
                child: ClipRect(
                  child: SizedBox(
                    width: canvasSize.width,
                    height: canvasSize.height,
                    child: ColoredBox(
                      color: backgroundColor,
                      child: CustomPaint(
                        size: canvasSize,
                        painter: DrawingPainter(
                          shapes: shapes,
                          preview: previewShape,
                          paintGeneration: paintGeneration,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
