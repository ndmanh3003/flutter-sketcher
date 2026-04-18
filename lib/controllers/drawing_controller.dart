import 'package:flutter/material.dart';

import 'package:sketcher/models/redo_entry.dart';
import 'package:sketcher/models/save_format.dart';
import 'package:sketcher/services/shape_hit_test.dart';
import 'package:sketcher/models/undo_entry.dart';
import 'package:sketcher/models/draw_shape.dart';

enum FlyoutKind { none, shape, color, stroke, strokeColor, saveFormat }

enum ToolbarTool { draw, fill, move }

class DrawingController extends ChangeNotifier {
  static const List<ToolbarTool> availableToolbarTools = <ToolbarTool>[
    ToolbarTool.draw,
    ToolbarTool.fill,
    ToolbarTool.move,
  ];

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
  int paintGeneration = 0;

  ToolbarTool toolbarTool = ToolbarTool.draw;
  FlyoutKind flyout = FlyoutKind.none;
  double flyoutLeft = 0;
  double flyoutTop = 0;
  String? loadedBinaryPath;
  SaveFormat selectedSaveFormat = SaveFormat.bin;

  // ── Canvas / Viewport ───────────────────────────────────────────────────

  /// Fixed canvas size, identical on every device.
  static const Size canvasSize = Size(1280, 720);

  /// Actual screen (viewport) size – updated by LayoutBuilder.
  Size viewportSize = Size.zero;

  /// Called once the viewport dimensions are known (or change).
  /// This is invoked inside LayoutBuilder, so we must NOT call
  /// notifyListeners synchronously (it would trigger setState during build).
  void updateViewportSize(Size size) {
    if (viewportSize == size) return;
    final bool firstTime = viewportSize == Size.zero;
    viewportSize = size;
    if (firstTime) {
      // Centre the canvas in the viewport on startup.
      panOffset = _centredPanOffset();
    } else {
      _clampPanOffset();
    }
  }

  /// Pan offset that places the canvas centre at the viewport centre.
  Offset _centredPanOffset() {
    return Offset(
      (viewportSize.width - canvasSize.width * zoomScale) / 2,
      (viewportSize.height - canvasSize.height * zoomScale) / 2,
    );
  }

  // ── Pan / Zoom ──────────────────────────────────────────────────────────

  Offset panOffset = Offset.zero;
  double zoomScale = 1.0;
  static const double _minZoom = 0.3;
  static const double _maxZoom = 2.0;
  static const double _zoomStep = 0.1;

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

  void setToolbarTool(ToolbarTool tool) {
    bool shouldNotify = false;
    if (flyout != FlyoutKind.none) {
      flyout = FlyoutKind.none;
      shouldNotify = true;
    }
    if (toolbarTool != tool) {
      toolbarTool = tool;
      shouldNotify = true;
    }
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void toggleToolbarTool() {
    final List<ToolbarTool> modes = availableToolbarTools;
    if (modes.isEmpty) return;
    final int currentIndex = modes.indexOf(toolbarTool);
    final int nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % modes.length;
    setToolbarTool(modes[nextIndex]);
  }

  // ── Pan / Zoom actions ─────────────────────────────────────────────────

  /// Movable area = 1.5× canvas in each dimension, canvas centred.
  /// That gives 0.25 × canvasSize × zoomScale margin on each side.
  void _clampPanOffset() {
    final double scaledW = canvasSize.width * zoomScale;
    final double scaledH = canvasSize.height * zoomScale;
    final double marginX = canvasSize.width * 0.25 * zoomScale;
    final double marginY = canvasSize.height * 0.25 * zoomScale;

    // Default offset that centres the canvas.
    final double centreX = (viewportSize.width - scaledW) / 2;
    final double centreY = (viewportSize.height - scaledH) / 2;

    panOffset = Offset(
      panOffset.dx.clamp(centreX - marginX, centreX + marginX),
      panOffset.dy.clamp(centreY - marginY, centreY + marginY),
    );
  }

  void panBy(Offset delta) {
    panOffset += delta;
    _clampPanOffset();
    notifyListeners();
  }

  /// Zoom keeping the viewport-centre point fixed on the canvas.
  void _zoomAroundCenter(double delta) {
    final double oldZoom = zoomScale;
    final double newZoom = (zoomScale + delta).clamp(_minZoom, _maxZoom);
    if (newZoom == oldZoom) return;

    // Viewport centre in screen space
    final double cx = viewportSize.width / 2;
    final double cy = viewportSize.height / 2;

    // Canvas-space point currently at viewport centre
    final double canvasX = (cx - panOffset.dx) / oldZoom;
    final double canvasY = (cy - panOffset.dy) / oldZoom;

    // Adjust pan so the same canvas point stays at viewport centre
    panOffset = Offset(cx - canvasX * newZoom, cy - canvasY * newZoom);
    zoomScale = newZoom;
    _clampPanOffset();
    notifyListeners();
  }

  void zoomIn() => _zoomAroundCenter(_zoomStep);

  void zoomOut() => _zoomAroundCenter(-_zoomStep);

  void resetView() {
    zoomScale = 1.0;
    panOffset = _centredPanOffset();
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
    paintGeneration++;
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
    paintGeneration++;
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
      paintGeneration++;
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
    undoStack.add(UndoClearCanvas(clearedShapes: List<DrawShape>.of(shapes)));
    shapes.clear();
    paintGeneration++;
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
    } else if (e is UndoLoadScene) {
      redoStack.add(
        RedoLoadScene(
          beforeShapes: List<DrawShape>.of(e.beforeShapes),
          afterShapes: List<DrawShape>.of(e.afterShapes),
          beforePath: e.beforePath,
          afterPath: e.afterPath,
        ),
      );
      shapes
        ..clear()
        ..addAll(e.beforeShapes);
      loadedBinaryPath = e.beforePath;
    }
    paintGeneration++;
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
    } else if (e is RedoLoadScene) {
      undoStack.add(
        UndoLoadScene(
          beforeShapes: List<DrawShape>.of(e.beforeShapes),
          afterShapes: List<DrawShape>.of(e.afterShapes),
          beforePath: e.beforePath,
          afterPath: e.afterPath,
        ),
      );
      shapes
        ..clear()
        ..addAll(e.afterShapes);
      loadedBinaryPath = e.afterPath;
    }
    paintGeneration++;
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
    final List<DrawShape> previousShapes = List<DrawShape>.of(shapes);
    final List<DrawShape> nextShapes = List<DrawShape>.of(loadedShapes);
    final String? previousPath = loadedBinaryPath;
    redoStack.clear();
    undoStack.add(
      UndoLoadScene(
        beforeShapes: previousShapes,
        afterShapes: nextShapes,
        beforePath: previousPath,
        afterPath: path,
      ),
    );
    shapes
      ..clear()
      ..addAll(nextShapes);
    loadedBinaryPath = path;
    paintGeneration++;
    notifyListeners();
  }
}
