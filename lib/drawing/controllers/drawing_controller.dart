import 'package:flutter/material.dart';

import 'package:sketcher/drawing/redo_entry.dart';
import 'package:sketcher/drawing/save_format.dart';
import 'package:sketcher/drawing/shape_hit_test.dart';
import 'package:sketcher/drawing/toolbar_tool.dart';
import 'package:sketcher/drawing/undo_entry.dart';
import 'package:sketcher/models/draw_shape.dart';

enum FlyoutKind { none, shape, color, stroke, strokeColor, saveFormat }

class DrawingController extends ChangeNotifier {
  final List<DrawShape> shapes = <DrawShape>[];
  final List<UndoEntry> undoStack = <UndoEntry>[];
  final List<RedoEntry> redoStack = <RedoEntry>[];
  final List<Color> paletteColors = <Color>[
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.black,
    Colors.white,
  ];

  ShapeType selectedType = ShapeType.line;
  Color strokeColor = Colors.black;
  Color bucketColor = Colors.blue;
  double strokeWidth = 2;
  DrawShape? previewShape;

  ToolbarTool toolbarTool = ToolbarTool.draw;
  FlyoutKind flyout = FlyoutKind.none;
  double flyoutLeft = 0;
  double flyoutTop = 0;
  Size canvasSize = Size.zero;
  String? loadedBinaryPath;
  SaveFormat selectedSaveFormat = SaveFormat.bin;

  static Color opaque(Color c) => c.withValues(alpha: 1);

  /// Returns `true` when opening (needs position sync), `false` when closing.
  bool toggleFlyout(FlyoutKind kind) {
    final bool closing = flyout == kind;
    flyout = closing ? FlyoutKind.none : kind;
    notifyListeners();
    return !closing;
  }

  bool dismissFlyoutIfOpen() {
    if (flyout == FlyoutKind.none) return false;
    flyout = FlyoutKind.none;
    notifyListeners();
    return true;
  }

  void updateFlyoutPosition(double left, double top) {
    flyoutLeft = left;
    flyoutTop = top;
    notifyListeners();
  }

  void toggleToolbarTool() {
    flyout = FlyoutKind.none;
    toolbarTool =
        toolbarTool == ToolbarTool.fill ? ToolbarTool.draw : ToolbarTool.fill;
    notifyListeners();
  }

  // ── Drawing ────────────────────────────────────────────────────────────

  void drawPointIfNeeded(Offset point) {
    if (selectedType != ShapeType.point) return;
    final Color c = opaque(strokeColor);
    final DrawShape shape = DrawShape(
      type: ShapeType.point,
      start: point,
      end: point,
      strokeColor: c,
      fillColor: c,
      strokeWidth: strokeWidth,
      filled: true,
    );
    shapes.add(shape);
    redoStack.clear();
    undoStack.add(UndoAddShape(shape: shape));
    notifyListeners();
  }

  void startDraw(Offset point) {
    if (selectedType == ShapeType.point) return;
    previewShape = DrawShape(
      type: selectedType,
      start: point,
      end: point,
      strokeColor: strokeColor,
      fillColor: Colors.transparent,
      strokeWidth: strokeWidth,
      filled: false,
    );
    notifyListeners();
  }

  void updateDraw(Offset point) {
    if (previewShape == null) return;
    previewShape = previewShape!.copyWith(end: point);
    notifyListeners();
  }

  void commitDraw() {
    if (previewShape == null) return;
    final DrawShape shape = previewShape!;
    shapes.add(shape);
    redoStack.clear();
    undoStack.add(UndoAddShape(shape: shape));
    previewShape = null;
    notifyListeners();
  }

  // ── Fill ────────────────────────────────────────────────────────────────

  void fillAt(Offset p) {
    final Color solid = opaque(bucketColor);
    for (int i = shapes.length - 1; i >= 0; i--) {
      final DrawShape s = shapes[i];
      if (!ShapeHitTest.isClosedRegion(s.type)) continue;
      if (!ShapeHitTest.contains(s, p)) continue;
      if (s.filled && s.fillColor == solid) return;
      redoStack.clear();
      undoStack.add(
        UndoFillRestore(
          shapeIndex: i,
          fillColor: s.fillColor,
          filled: s.filled,
        ),
      );
      shapes[i] = s.copyWith(fillColor: solid, filled: true);
      notifyListeners();
      return;
    }
  }

  // ── Undo / Redo / Clear ────────────────────────────────────────────────

  void clearCanvas() {
    if (shapes.isEmpty) {
      flyout = FlyoutKind.none;
      previewShape = null;
      notifyListeners();
      return;
    }
    flyout = FlyoutKind.none;
    previewShape = null;
    redoStack.clear();
    undoStack.add(
      UndoClearCanvas(clearedShapes: List<DrawShape>.of(shapes)),
    );
    shapes.clear();
    notifyListeners();
  }

  void undo() {
    if (undoStack.isEmpty) return;
    flyout = FlyoutKind.none;
    final UndoEntry e = undoStack.removeLast();
    if (e is UndoAddShape) {
      if (shapes.isNotEmpty) {
        final DrawShape removed = shapes.removeLast();
        redoStack.add(RedoAddShape(shape: removed));
      }
    } else if (e is UndoFillRestore) {
      final int i = e.shapeIndex;
      if (i >= 0 && i < shapes.length) {
        final DrawShape s = shapes[i];
        redoStack.add(
          RedoFillRestore(
            shapeIndex: i,
            fillColor: s.fillColor,
            filled: s.filled,
          ),
        );
        shapes[i] = s.copyWith(fillColor: e.fillColor, filled: e.filled);
      }
    } else if (e is UndoClearCanvas) {
      redoStack.add(
        RedoClearCanvas(clearedShapes: List<DrawShape>.of(e.clearedShapes)),
      );
      shapes
        ..clear()
        ..addAll(e.clearedShapes);
    }
    notifyListeners();
  }

  void redo() {
    if (redoStack.isEmpty) return;
    flyout = FlyoutKind.none;
    final RedoEntry e = redoStack.removeLast();
    if (e is RedoAddShape) {
      shapes.add(e.shape);
      undoStack.add(UndoAddShape(shape: e.shape));
    } else if (e is RedoFillRestore) {
      final int i = e.shapeIndex;
      if (i >= 0 && i < shapes.length) {
        final DrawShape s = shapes[i];
        undoStack.add(
          UndoFillRestore(
            shapeIndex: i,
            fillColor: s.fillColor,
            filled: s.filled,
          ),
        );
        shapes[i] = s.copyWith(fillColor: e.fillColor, filled: e.filled);
      }
    } else if (e is RedoClearCanvas) {
      undoStack.add(
        UndoClearCanvas(clearedShapes: List<DrawShape>.of(e.clearedShapes)),
      );
      shapes.clear();
    }
    notifyListeners();
  }

  // ── Setters that notify ────────────────────────────────────────────────

  void setSelectedType(ShapeType type) {
    selectedType = type;
    notifyListeners();
  }

  void setStrokeColor(Color color) {
    strokeColor = color;
    notifyListeners();
  }

  void setBucketColor(Color color) {
    bucketColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    strokeWidth = width;
    notifyListeners();
  }

  void setSelectedSaveFormat(SaveFormat format) {
    selectedSaveFormat = format;
    flyout = FlyoutKind.none;
    notifyListeners();
  }

  void loadScene(List<DrawShape> loadedShapes, String? path) {
    flyout = FlyoutKind.none;
    previewShape = null;
    shapes
      ..clear()
      ..addAll(loadedShapes);
    undoStack.clear();
    redoStack.clear();
    loadedBinaryPath = path;
    notifyListeners();
  }
}
