import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sketcher/controllers/drawing_controller.dart';
import 'package:sketcher/models/save_format.dart';
import 'package:sketcher/services/file_operations.dart';
import 'package:sketcher/widgets/canvas_area.dart';
import 'package:sketcher/widgets/flyout_panels.dart';
import 'package:sketcher/widgets/toolbar_widgets.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final DrawingController _ctrl = DrawingController();

  final GlobalKey _stackKey = GlobalKey(debugLabel: 'root_stack');
  final GlobalKey _keyShapeAnchor = GlobalKey(debugLabel: 'shape_anchor');
  final GlobalKey _keyColorAnchor = GlobalKey(debugLabel: 'color_anchor');
  final GlobalKey _keyStrokeAnchor = GlobalKey(debugLabel: 'stroke_anchor');
  final GlobalKey _keyStrokeColorAnchor = GlobalKey(
    debugLabel: 'stroke_color_anchor',
  );
  final GlobalKey _keySaveAnchor = GlobalKey(debugLabel: 'save_anchor');

  final ScrollController _shapeScroll = ScrollController();
  final ScrollController _saveFormatScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _ctrl.dispose();
    _shapeScroll.dispose();
    _saveFormatScroll.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // ── Flyout positioning (requires widget-tree access) ───────────────────

  void _handleToggleFlyout(FlyoutKind kind, GlobalKey anchorKey) {
    final bool opened = _ctrl.toggleFlyout(kind);
    if (opened) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncFlyoutToAnchor(anchorKey);
      });
    }
  }

  void _syncFlyoutToAnchor(GlobalKey anchorKey) {
    if (!mounted || _ctrl.flyout == FlyoutKind.none) return;
    final BuildContext? stackCtx = _stackKey.currentContext;
    final BuildContext? anchorCtx = anchorKey.currentContext;
    if (stackCtx == null || anchorCtx == null) return;
    final RenderBox? stackBox = stackCtx.findRenderObject() as RenderBox?;
    final RenderBox? anchorBox = anchorCtx.findRenderObject() as RenderBox?;
    if (stackBox == null || anchorBox == null) return;
    final Offset anchorGlobal = anchorBox.localToGlobal(Offset.zero);
    final Offset stackGlobal = stackBox.localToGlobal(Offset.zero);
    final Offset rel = anchorGlobal - stackGlobal;
    final double stackW = stackBox.size.width;
    final double stackH = stackBox.size.height;
    final double screenH = MediaQuery.sizeOf(context).height;
    const double toolSize = 52;
    final bool isColorFlyout =
        _ctrl.flyout == FlyoutKind.color ||
        _ctrl.flyout == FlyoutKind.strokeColor;
    final double pillMaxW = isColorFlyout
        ? math.min(340.0, stackW - toolSize - 48)
        : math.min(280.0, stackW - toolSize - 48);
    const double gap = 8;
    final double preferredLeft = rel.dx - pillMaxW - gap;
    final double minLeft = gap;
    final double maxLeft = math.max(minLeft, stackW - pillMaxW - gap);
    double left = preferredLeft.clamp(minLeft, maxLeft).toDouble();
    double top = rel.dy;
    if (_ctrl.flyout == FlyoutKind.color ||
        _ctrl.flyout == FlyoutKind.strokeColor) {
      final double maxTop = math.min(screenH, stackH) - 480;
      if (top > maxTop && maxTop > 0) {
        top = maxTop;
      }
    }
    _ctrl.updateFlyoutPosition(left, top);
  }

  // ── Canvas gesture routing ─────────────────────────────────────────────

  /// Convert screen-space position to canvas-space,
  /// accounting for pan offset and zoom scale.
  Offset _toCanvasSpace(Offset screen) {
    return (screen - _ctrl.panOffset) / _ctrl.zoomScale;
  }

  void _onPanStart(DragStartDetails details) {
    if (_ctrl.dismissFlyoutIfOpen()) return;
    if (_ctrl.toolbarTool == ToolbarTool.move) return;
    if (_ctrl.toolbarTool != ToolbarTool.draw) return;
    _ctrl.startDraw(_toCanvasSpace(details.localPosition));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_ctrl.toolbarTool == ToolbarTool.move) {
      _ctrl.panBy(details.delta);
      return;
    }
    if (_ctrl.toolbarTool != ToolbarTool.draw) return;
    _ctrl.updateDraw(_toCanvasSpace(details.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    if (_ctrl.toolbarTool == ToolbarTool.move) return;
    if (_ctrl.toolbarTool != ToolbarTool.draw) return;
    _ctrl.commitDraw();
  }

  void _onTapDown(TapDownDetails details) {
    if (_ctrl.dismissFlyoutIfOpen()) return;
    final Offset canvasPoint = _toCanvasSpace(details.localPosition);
    if (_ctrl.toolbarTool == ToolbarTool.fill) {
      _ctrl.fillAt(canvasPoint);
      return;
    }
    if (_ctrl.toolbarTool == ToolbarTool.draw) {
      _ctrl.drawPointIfNeeded(canvasPoint);
    }
  }

  // ── File I/O ───────────────────────────────────────────────────────────

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSaveFormat(SaveFormat format) async {
    await FileOperations.saveScene(format, _ctrl, showSnack: _showSnack);
  }

  void _handleLoadScene() {
    _ctrl.dismissFlyoutIfOpen();
    FileOperations.loadBinary(_ctrl, showSnack: _showSnack);
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const double toolSize = 52;
    const double modeBarTop = 8;
    const double topDockTop = modeBarTop + toolSize + 18;

    final MediaQueryData mq = MediaQuery.of(context);
    final EdgeInsets padding = mq.padding;
    final Size viewportSize = Size(
      mq.size.width - padding.left - padding.right,
      mq.size.height - padding.top - padding.bottom,
    );
    _ctrl.updateViewportSize(viewportSize);

    final bool isColorFlyout =
        _ctrl.flyout == FlyoutKind.color ||
        _ctrl.flyout == FlyoutKind.strokeColor;
    final double pillMaxWidth = isColorFlyout
        ? math.min(340.0, viewportSize.width - toolSize - 48)
        : math.min(280.0, viewportSize.width - toolSize - 48);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CanvasArea(
                shapes: _ctrl.shapes,
                previewShape: _ctrl.previewShape,
                canvasSize: DrawingController.canvasSize,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTapDown: _onTapDown,
                panOffset: _ctrl.panOffset,
                zoomScale: _ctrl.zoomScale,
                paintGeneration: _ctrl.paintGeneration,
                backgroundColor: _ctrl.backgroundColor,
              ),
            ),
            if (_ctrl.flyout != FlyoutKind.none)
              Positioned(
                left: _ctrl.flyoutLeft,
                top: _ctrl.flyoutTop,
                child: FloatingFlyoutPanel(
                  flyout: _ctrl.flyout,
                  maxWidth: pillMaxWidth,
                  controller: _ctrl,
                  shapeScrollController: _shapeScroll,
                  saveFormatScrollController: _saveFormatScroll,
                  onSaveFormat: _handleSaveFormat,
                ),
              ),
            Positioned(
              right: 8,
              top: modeBarTop,
              child: ToolbarModeBar(size: toolSize, controller: _ctrl),
            ),
            Positioned(
              right: 8,
              top: topDockTop,
              child: ToolbarTopDock(
                size: toolSize,
                controller: _ctrl,
                keyShapeAnchor: _keyShapeAnchor,
                keyStrokeAnchor: _keyStrokeAnchor,
                keyStrokeColorAnchor: _keyStrokeColorAnchor,
                keyColorAnchor: _keyColorAnchor,
                onToggleShapeFlyout: () =>
                    _handleToggleFlyout(FlyoutKind.shape, _keyShapeAnchor),
                onToggleStrokeFlyout: () => _handleToggleFlyout(
                  FlyoutKind.stroke,
                  _keyStrokeAnchor,
                ),
                onToggleStrokeColorFlyout: () => _handleToggleFlyout(
                  FlyoutKind.strokeColor,
                  _keyStrokeColorAnchor,
                ),
                onToggleColorFlyout: () =>
                    _handleToggleFlyout(FlyoutKind.color, _keyColorAnchor),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: ToolbarBottomDock(
                size: toolSize,
                controller: _ctrl,
                keySaveAnchor: _keySaveAnchor,
                onLoadScene: _handleLoadScene,
                onToggleSaveFlyout: () => _handleToggleFlyout(
                  FlyoutKind.saveFormat,
                  _keySaveAnchor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
