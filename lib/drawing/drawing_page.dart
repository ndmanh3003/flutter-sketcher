import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sketcher/drawing/drawing_painter.dart';
import 'package:sketcher/drawing/scene_codec.dart';
import 'package:sketcher/drawing/shape_hit_test.dart';
import 'package:sketcher/drawing/toolbar_tool.dart';
import 'package:sketcher/drawing/undo_entry.dart';
import 'package:sketcher/drawing/redo_entry.dart';
import 'package:sketcher/models/draw_shape.dart';

enum _Flyout { none, shape, color, stroke }

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final List<DrawShape> _shapes = <DrawShape>[];
  final List<UndoEntry> _undoStack = <UndoEntry>[];
  final List<RedoEntry> _redoStack = <RedoEntry>[];
  final List<Color> _paletteColors = <Color>[
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.black,
    Colors.white,
  ];

  ShapeType _selectedType = ShapeType.line;
  final Color _strokeColor = Colors.black;
  Color _bucketColor = Colors.blue;
  double _strokeWidth = 2;
  DrawShape? _previewShape;

  ToolbarTool _toolbarTool = ToolbarTool.draw;
  _Flyout _flyout = _Flyout.none;
  double _flyoutLeft = 0;
  double _flyoutTop = 0;

  final GlobalKey _stackKey = GlobalKey(debugLabel: 'root_stack');
  final GlobalKey _keyShapeAnchor = GlobalKey(debugLabel: 'shape_anchor');
  final GlobalKey _keyColorAnchor = GlobalKey(debugLabel: 'color_anchor');
  final GlobalKey _keyStrokeAnchor = GlobalKey(debugLabel: 'stroke_anchor');

  final ScrollController _shapeScroll = ScrollController();

  static const String _binaryFileName = 'sketcher_scene.bin';
  static const String _ellipseIconAsset = 'assets/icons/ellipse_outline.svg';

  @override
  void dispose() {
    _shapeScroll.dispose();
    super.dispose();
  }

  void _toggleFlyout(_Flyout kind, GlobalKey anchorKey) {
    final bool closing = _flyout == kind;
    setState(() {
      _flyout = closing ? _Flyout.none : kind;
    });
    if (!closing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncFlyoutToAnchor(anchorKey);
      });
    }
  }

  void _syncFlyoutToAnchor(GlobalKey anchorKey) {
    if (!mounted || _flyout == _Flyout.none) return;
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
    final double pillMaxW = _flyout == _Flyout.color
        ? math.min(340.0, stackW - toolSize - 48)
        : math.min(280.0, stackW - toolSize - 48);
    const double gap = 8;
    setState(() {
      // Keep the panel to the left of its anchor button while staying onscreen.
      final double preferredLeft = rel.dx - pillMaxW - gap;
      final double minLeft = gap;
      final double maxLeft = math.max(minLeft, stackW - pillMaxW - gap);
      _flyoutLeft = preferredLeft.clamp(minLeft, maxLeft).toDouble();
      _flyoutTop = rel.dy;
      // Clamp top so the color picker doesn't overflow the screen
      if (_flyout == _Flyout.color) {
        final double maxTop = math.min(screenH, stackH) - 480;
        if (_flyoutTop > maxTop && maxTop > 0) {
          _flyoutTop = maxTop;
        }
      }
    });
  }

  bool _dismissFlyoutIfOpen() {
    if (_flyout == _Flyout.none) return false;
    setState(() => _flyout = _Flyout.none);
    return true;
  }

  void _scrollStrip(ScrollController c, double delta) {
    if (!c.hasClients) return;
    final double next = (c.offset + delta).clamp(
      0.0,
      c.position.maxScrollExtent,
    );
    c.animateTo(
      next,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double toolSize = 52;
    final double screenW = MediaQuery.sizeOf(context).width;
    final double pillMaxWidth = _flyout == _Flyout.color
        ? math.min(340.0, screenW - toolSize - 48)
        : math.min(280.0, screenW - toolSize - 48);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: _buildCanvasArea()),
            if (_flyout != _Flyout.none)
              Positioned(
                left: _flyoutLeft,
                top: _flyoutTop,
                child: _floatingFlyoutPanel(pillMaxWidth),
              ),
            Positioned(right: 8, top: 8, child: _toolbarTopDock(toolSize)),
            Positioned(
              right: 8,
              bottom: 8,
              child: _toolbarBottomDock(toolSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            if (_dismissFlyoutIfOpen()) return;
            if (_toolbarTool != ToolbarTool.draw) return;
            _startDraw(details.localPosition);
          },
          onPanUpdate: (details) {
            if (_toolbarTool != ToolbarTool.draw) return;
            _updateDraw(details.localPosition);
          },
          onPanEnd: (_) {
            if (_toolbarTool != ToolbarTool.draw) return;
            _commitDraw();
          },
          onTapDown: (details) {
            if (_dismissFlyoutIfOpen()) return;
            if (_toolbarTool == ToolbarTool.fill) {
              _fillAt(details.localPosition);
              return;
            }
            if (_toolbarTool == ToolbarTool.draw) {
              _drawPointIfNeeded(details.localPosition);
            }
          },
          child: ColoredBox(
            color: Colors.white,
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: DrawingPainter(shapes: _shapes, preview: _previewShape),
            ),
          ),
        );
      },
    );
  }

  Widget _floatingFlyoutPanel(double pillMaxWidth) {
    return switch (_flyout) {
      _Flyout.none => const SizedBox.shrink(),
      _Flyout.shape => _pillStrip(
        maxWidth: pillMaxWidth,
        controller: _shapeScroll,
        children: ShapeType.values.map((ShapeType type) {
          final bool sel = type == _selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: sel ? Colors.black87 : Colors.white,
              elevation: sel ? 3 : 1,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _selectedType = type),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: _shapeGlyph(
                      type,
                      color: sel ? Colors.white : Colors.black87,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      _Flyout.color => _colorPickerPanel(pillMaxWidth),
      _Flyout.stroke => _strokeWidthSliderPill(pillMaxWidth),
    };
  }

  Widget _toolbarChrome({
    required double size,
    required List<Widget> children,
  }) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(size / 2 + 4),
      color: const Color(0xFFE8E8E8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _toolbarTopDock(double size) {
    return _toolbarChrome(
      size: size,
      children: [
        _roundToolButton(
          size: size,
          selected: _toolbarTool == ToolbarTool.fill,
          icon: Icons.format_color_fill,
          tooltip: _toolbarTool == ToolbarTool.fill
              ? 'Bucket fill — tap to draw'
              : 'Draw — tap for bucket fill',
          onTap: () => setState(() {
            _flyout = _Flyout.none;
            _toolbarTool = _toolbarTool == ToolbarTool.fill
                ? ToolbarTool.draw
                : ToolbarTool.fill;
          }),
        ),
        Padding(
          key: _keyShapeAnchor,
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: _roundToolButton(
            size: size,
            selected: _flyout == _Flyout.shape,
            icon: _shapeIcon(_selectedType),
            iconChild: _shapeGlyph(
              _selectedType,
              color: _flyout == _Flyout.shape ? Colors.white : Colors.black87,
              size: 24,
            ),
            tooltip: 'Shape',
            onTap: () => _toggleFlyout(_Flyout.shape, _keyShapeAnchor),
          ),
        ),
        Padding(
          key: _keyStrokeAnchor,
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: _roundToolButton(
            size: size,
            selected: _flyout == _Flyout.stroke,
            icon: Icons.line_weight,
            tooltip: 'Stroke width',
            onTap: () => _toggleFlyout(_Flyout.stroke, _keyStrokeAnchor),
          ),
        ),
        Padding(
          key: _keyColorAnchor,
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: _bucketColorAnchor(
            size: size,
            onTap: () => _toggleFlyout(_Flyout.color, _keyColorAnchor),
          ),
        ),
      ],
    );
  }

  Widget _toolbarBottomDock(double size) {
    return _toolbarChrome(
      size: size,
      children: [
        _roundToolButton(
          size: size,
          selected: false,
          icon: Icons.undo,
          tooltip: 'Undo',
          enabled: _undoStack.isNotEmpty,
          onTap: _undo,
        ),
        _roundToolButton(
          size: size,
          selected: false,
          icon: Icons.redo,
          tooltip: 'Redo',
          enabled: _redoStack.isNotEmpty,
          onTap: _redo,
        ),
        _roundToolButton(
          size: size,
          selected: false,
          icon: Icons.delete_outline,
          tooltip: 'Clear all',
          onTap: _clearCanvas,
        ),
        _roundToolButton(
          size: size,
          selected: false,
          icon: Icons.save_rounded,
          tooltip: 'Save scene',
          onTap: () {
            setState(() => _flyout = _Flyout.none);
            _saveBinary();
          },
        ),
      ],
    );
  }

  Widget _bucketColorAnchor({
    required double size,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: 'Bucket fill color',
      child: Material(
        elevation: _flyout == _Flyout.color ? 5 : 4,
        shadowColor: Colors.black45,
        shape: const CircleBorder(),
        color: _bucketColor,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 2,
                    offset: Offset(0, 1),
                    color: Color(0x33000000),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorPickerPanel(double maxWidth) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFFF5F5F5),
      child: SizedBox(
        width: maxWidth,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color picker
              ColorPicker(
                pickerColor: _bucketColor,
                onColorChanged: (Color color) {
                  setState(() => _bucketColor = color);
                },
                enableAlpha: false,
                hexInputBar: true,
                labelTypes: const [],
                pickerAreaHeightPercent: 0.7,
                portraitOnly: true,
                displayThumbColor: true,
                pickerAreaBorderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              // Quick palette row
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _paletteColors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final Color c = _paletteColors[index];
                    final bool sel = c.toARGB32() == _bucketColor.toARGB32();
                    return _paletteColorDot(c, selected: sel);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paletteColorDot(Color color, {required bool selected}) {
    return Material(
      elevation: selected ? 3 : 1,
      shadowColor: Colors.black38,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: color,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _bucketColor = color),
        child: SizedBox(
          width: 32,
          height: 32,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.black : Colors.white,
                width: selected ? 3 : 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _strokeWidthSliderPill(double maxWidth) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(28),
      color: const Color(0xFFF2F2F2),
      child: SizedBox(
        width: maxWidth,
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              min: 1,
              max: 20,
              divisions: 19,
              value: _strokeWidth.clamp(1, 20),
              onChanged: (double v) => setState(() => _strokeWidth = v),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillStrip({
    required double maxWidth,
    required ScrollController controller,
    required List<Widget> children,
  }) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(28),
      color: const Color(0xFFF2F2F2),
      child: SizedBox(
        height: 56,
        width: maxWidth,
        child: Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 48),
              icon: const Icon(Icons.chevron_left, color: Colors.black45),
              onPressed: () => _scrollStrip(controller, -72),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                children: children,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 48),
              icon: const Icon(Icons.chevron_right, color: Colors.black45),
              onPressed: () => _scrollStrip(controller, 72),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundToolButton({
    required double size,
    required bool selected,
    required IconData icon,
    Widget? iconChild,
    required VoidCallback onTap,
    bool enabled = true,
    String? tooltip,
  }) {
    final bool active = enabled;
    final Color iconColor = active
        ? (selected ? Colors.white : Colors.black87)
        : Colors.black38;
    Widget child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: active
            ? (selected ? Colors.black87 : Colors.white)
            : const Color(0xFFE0E0E0),
        elevation: selected ? 5 : 3,
        shadowColor: Colors.black45,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: active ? onTap : null,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: iconChild ?? Icon(icon, size: 24, color: iconColor),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) {
      child = Tooltip(message: tooltip, child: child);
    }
    return child;
  }

  void _fillAt(Offset p) {
    final Color solid = _opaque(_bucketColor);
    for (int i = _shapes.length - 1; i >= 0; i--) {
      final DrawShape s = _shapes[i];
      if (!ShapeHitTest.isClosedRegion(s.type)) continue;
      if (!ShapeHitTest.contains(s, p)) continue;
      if (s.filled && s.fillColor == solid) return;
      setState(() {
        _redoStack.clear();
        _undoStack.add(
          UndoFillRestore(
            shapeIndex: i,
            fillColor: s.fillColor,
            filled: s.filled,
          ),
        );
        _shapes[i] = s.copyWith(fillColor: solid, filled: true);
      });
      return;
    }
  }

  IconData _shapeIcon(ShapeType type) {
    return switch (type) {
      ShapeType.point => Icons.circle,
      ShapeType.line => Icons.horizontal_rule,
      ShapeType.ellipse =>
        Icons
            .panorama_wide_angle_outlined, // Overide by shapeGlyph with correct ellipse icon
      ShapeType.circle => Icons.circle_outlined,
      ShapeType.square => Icons.square_outlined,
      ShapeType.rectangle => Icons.rectangle_outlined,
    };
  }

  Widget _shapeGlyph(
    ShapeType type, {
    required Color color,
    required double size,
  }) {
    if (type == ShapeType.ellipse) {
      return SvgPicture.asset(
        _ellipseIconAsset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    if (type == ShapeType.line) {
      return Transform.rotate(
        angle: -math.pi / 4,
        child: Icon(Icons.horizontal_rule, color: color, size: size),
      );
    }

    if (type == ShapeType.point) {
      return Icon(Icons.circle, color: color, size: math.max(1.5, size / 2));
    }

    return Icon(_shapeIcon(type), color: color, size: size);
  }

  void _drawPointIfNeeded(Offset point) {
    if (_selectedType != ShapeType.point) return;
    setState(() {
      final Color c = _opaque(_strokeColor);
      final DrawShape shape = DrawShape(
        type: ShapeType.point,
        start: point,
        end: point,
        strokeColor: c,
        fillColor: c,
        strokeWidth: _strokeWidth,
        filled: true,
      );
      _shapes.add(shape);
      _redoStack.clear();
      _undoStack.add(UndoAddShape(shape: shape));
    });
  }

  void _startDraw(Offset point) {
    if (_selectedType == ShapeType.point) return;
    setState(() {
      _previewShape = DrawShape(
        type: _selectedType,
        start: point,
        end: point,
        strokeColor: _strokeColor,
        fillColor: Colors.transparent,
        strokeWidth: _strokeWidth,
        filled: false,
      );
    });
  }

  static Color _opaque(Color c) => c.withValues(alpha: 1);

  void _updateDraw(Offset point) {
    if (_previewShape == null) return;
    setState(() => _previewShape = _previewShape!.copyWith(end: point));
  }

  void _commitDraw() {
    if (_previewShape == null) return;
    setState(() {
      final DrawShape shape = _previewShape!;
      _shapes.add(shape);
      _redoStack.clear();
      _undoStack.add(UndoAddShape(shape: shape));
      _previewShape = null;
    });
  }

  void _clearCanvas() {
    if (_shapes.isEmpty) {
      setState(() {
        _flyout = _Flyout.none;
        _previewShape = null;
      });
      return;
    }
    setState(() {
      _flyout = _Flyout.none;
      _previewShape = null;
      _redoStack.clear();
      _undoStack.add(
        UndoClearCanvas(clearedShapes: List<DrawShape>.of(_shapes)),
      );
      _shapes.clear();
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _flyout = _Flyout.none;
      final UndoEntry e = _undoStack.removeLast();
      if (e is UndoAddShape) {
        if (_shapes.isNotEmpty) {
          final DrawShape removed = _shapes.removeLast();
          _redoStack.add(RedoAddShape(shape: removed));
        }
      } else if (e is UndoFillRestore) {
        final int i = e.shapeIndex;
        if (i >= 0 && i < _shapes.length) {
          final DrawShape s = _shapes[i];
          _redoStack.add(
            RedoFillRestore(
              shapeIndex: i,
              fillColor: s.fillColor,
              filled: s.filled,
            ),
          );
          _shapes[i] = s.copyWith(fillColor: e.fillColor, filled: e.filled);
        }
      } else if (e is UndoClearCanvas) {
        _redoStack.add(
          RedoClearCanvas(clearedShapes: List<DrawShape>.of(e.clearedShapes)),
        );
        _shapes
          ..clear()
          ..addAll(e.clearedShapes);
      }
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _flyout = _Flyout.none;
      final RedoEntry e = _redoStack.removeLast();
      if (e is RedoAddShape) {
        _shapes.add(e.shape);
        _undoStack.add(UndoAddShape(shape: e.shape));
      } else if (e is RedoFillRestore) {
        final int i = e.shapeIndex;
        if (i >= 0 && i < _shapes.length) {
          final DrawShape s = _shapes[i];
          _undoStack.add(
            UndoFillRestore(
              shapeIndex: i,
              fillColor: s.fillColor,
              filled: s.filled,
            ),
          );
          _shapes[i] = s.copyWith(fillColor: e.fillColor, filled: e.filled);
        }
      } else if (e is RedoClearCanvas) {
        _undoStack.add(
          UndoClearCanvas(clearedShapes: List<DrawShape>.of(e.clearedShapes)),
        );
        _shapes.clear();
      }
    });
  }

  Future<void> _saveBinary() async {
    try {
      final SceneCodec codec = SceneCodec();
      final Uint8List bytes = codec.encode(_shapes);
      final String path = '${Directory.current.path}/$_binaryFileName';
      await File(path).writeAsBytes(bytes, flush: true);
      _showSnack('Saved: $path');
    } catch (e) {
      _showSnack('Save failed: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
