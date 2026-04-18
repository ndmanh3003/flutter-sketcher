import 'package:flutter/material.dart';

import 'package:sketcher/controllers/drawing_controller.dart';
import 'package:sketcher/widgets/shape_icon_helpers.dart';

class _ToolbarModeVisual {
  const _ToolbarModeVisual({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;
}

const Map<ToolbarTool, _ToolbarModeVisual> _toolbarModeVisuals =
    <ToolbarTool, _ToolbarModeVisual>{
      ToolbarTool.draw: _ToolbarModeVisual(
        icon: Icons.brush,
        tooltip: 'Draw mode',
      ),
      ToolbarTool.fill: _ToolbarModeVisual(
        icon: Icons.format_color_fill,
        tooltip: 'Fill mode',
      ),
      ToolbarTool.move: _ToolbarModeVisual(
        icon: Icons.open_with_outlined,
        tooltip: 'Move mode',
      ),
    };

class ToolbarChrome extends StatelessWidget {
  const ToolbarChrome({super.key, required this.size, required this.children});

  final double size;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
}

class ToolbarRowChrome extends StatelessWidget {
  const ToolbarRowChrome({
    super.key,
    required this.size,
    required this.children,
  });

  final double size;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(size / 2 + 4),
      color: const Color(0xFFE8E8E8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

class RoundToolButton extends StatelessWidget {
  const RoundToolButton({
    super.key,
    required this.size,
    required this.selected,
    required this.icon,
    this.iconChild,
    required this.onTap,
    this.enabled = true,
    this.tooltip,
  });

  final double size;
  final bool selected;
  final IconData icon;
  final Widget? iconChild;
  final VoidCallback onTap;
  final bool enabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
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
      child = Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

class ToolbarModeBar extends StatelessWidget {
  const ToolbarModeBar({
    super.key,
    required this.size,
    required this.controller,
  });

  final double size;
  final DrawingController controller;

  IconData _iconForMode(ToolbarTool mode) {
    return _toolbarModeVisuals[mode]?.icon ?? Icons.extension_outlined;
  }

  String _tooltipForMode(ToolbarTool mode) {
    return _toolbarModeVisuals[mode]?.tooltip ?? 'Mode';
  }

  @override
  Widget build(BuildContext context) {
    return ToolbarRowChrome(
      size: size,
      children: [
        for (final ToolbarTool mode in DrawingController.availableToolbarTools)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: RoundToolButton(
              size: size,
              selected: controller.toolbarTool == mode,
              icon: _iconForMode(mode),
              tooltip: _tooltipForMode(mode),
              onTap: () => controller.setToolbarTool(mode),
            ),
          ),
      ],
    );
  }
}

class ToolbarTopDock extends StatelessWidget {
  const ToolbarTopDock({
    super.key,
    required this.size,
    required this.controller,
    required this.keyShapeAnchor,
    required this.keyStrokeAnchor,
    required this.keyStrokeColorAnchor,
    required this.keyColorAnchor,
    required this.onToggleShapeFlyout,
    required this.onToggleStrokeFlyout,
    required this.onToggleStrokeColorFlyout,
    required this.onToggleColorFlyout,
  });

  final double size;
  final DrawingController controller;
  final GlobalKey keyShapeAnchor;
  final GlobalKey keyStrokeAnchor;
  final GlobalKey keyStrokeColorAnchor;
  final GlobalKey keyColorAnchor;
  final VoidCallback onToggleShapeFlyout;
  final VoidCallback onToggleStrokeFlyout;
  final VoidCallback onToggleStrokeColorFlyout;
  final VoidCallback onToggleColorFlyout;

  List<Widget> _buildDrawModeTools() {
    return <Widget>[
      Padding(
        key: keyShapeAnchor,
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: RoundToolButton(
          size: size,
          selected: controller.flyout == FlyoutKind.shape,
          icon: shapeIcon(controller.selectedType),
          iconChild: shapeGlyph(
            controller.selectedType,
            color: controller.flyout == FlyoutKind.shape
                ? Colors.white
                : Colors.black87,
            size: 24,
          ),
          tooltip: 'Shape',
          onTap: onToggleShapeFlyout,
        ),
      ),
      Padding(
        key: keyStrokeAnchor,
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: RoundToolButton(
          size: size,
          selected: controller.flyout == FlyoutKind.stroke,
          icon: Icons.line_weight,
          tooltip: 'Stroke width',
          onTap: onToggleStrokeFlyout,
        ),
      ),
      Padding(
        key: keyStrokeColorAnchor,
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: StrokeColorAnchor(
          size: size,
          strokeColor: controller.strokeColor,
          isSelected: controller.flyout == FlyoutKind.strokeColor,
          onTap: onToggleStrokeColorFlyout,
        ),
      ),
    ];
  }

  List<Widget> _buildFillModeTools() {
    return <Widget>[
      Padding(
        key: keyColorAnchor,
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: BucketColorAnchor(
          size: size,
          bucketColor: controller.bucketColor,
          isSelected: controller.flyout == FlyoutKind.color,
          onTap: onToggleColorFlyout,
        ),
      ),
    ];
  }

  List<Widget> _buildMoveModeTools() {
    final String zoomLabel = '${(controller.zoomScale * 100).round()}%';
    return <Widget>[
      RoundToolButton(
        size: size,
        selected: false,
        icon: Icons.zoom_in,
        tooltip: 'Zoom in',
        onTap: controller.zoomIn,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: size,
          height: 22,
          child: Center(
            child: Text(
              zoomLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ),
      RoundToolButton(
        size: size,
        selected: false,
        icon: Icons.zoom_out,
        tooltip: 'Zoom out',
        onTap: controller.zoomOut,
      ),
      RoundToolButton(
        size: size,
        selected: false,
        icon: Icons.fit_screen_outlined,
        tooltip: 'Reset view',
        onTap: controller.resetView,
      ),
    ];
  }

  List<Widget> _buildFallbackModeTools() {
    return <Widget>[
      RoundToolButton(
        size: size,
        selected: false,
        enabled: false,
        icon: Icons.build_circle_outlined,
        tooltip: 'Mode tools unavailable',
        onTap: () {},
      ),
    ];
  }

  List<Widget> _buildToolsForCurrentMode() {
    if (controller.toolbarTool == ToolbarTool.draw) {
      return _buildDrawModeTools();
    }
    if (controller.toolbarTool == ToolbarTool.fill) {
      return _buildFillModeTools();
    }
    if (controller.toolbarTool == ToolbarTool.move) {
      return _buildMoveModeTools();
    }
    return _buildFallbackModeTools();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> modeTools = _buildToolsForCurrentMode();

    return ToolbarChrome(size: size, children: modeTools);
  }
}

class ToolbarBottomDock extends StatelessWidget {
  const ToolbarBottomDock({
    super.key,
    required this.size,
    required this.controller,
    required this.keySaveAnchor,
    required this.onLoadScene,
    required this.onToggleSaveFlyout,
  });

  final double size;
  final DrawingController controller;
  final GlobalKey keySaveAnchor;
  final VoidCallback onLoadScene;
  final VoidCallback onToggleSaveFlyout;

  @override
  Widget build(BuildContext context) {
    return ToolbarChrome(
      size: size,
      children: [
        RoundToolButton(
          size: size,
          selected: false,
          icon: Icons.undo,
          tooltip: 'Undo',
          enabled: controller.undoStack.isNotEmpty,
          onTap: controller.undo,
        ),
        RoundToolButton(
          size: size,
          selected: false,
          icon: Icons.redo,
          tooltip: 'Redo',
          enabled: controller.redoStack.isNotEmpty,
          onTap: controller.redo,
        ),
        RoundToolButton(
          size: size,
          selected: false,
          icon: Icons.delete_outline,
          tooltip: 'Clear all',
          onTap: controller.clearCanvas,
        ),
        RoundToolButton(
          size: size,
          selected: false,
          icon: Icons.drive_folder_upload_rounded,
          tooltip: 'Load scene',
          onTap: onLoadScene,
        ),
        Padding(
          key: keySaveAnchor,
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: RoundToolButton(
            size: size,
            selected: controller.flyout == FlyoutKind.saveFormat,
            icon: Icons.save_rounded,
            tooltip: 'Save scene',
            onTap: onToggleSaveFlyout,
          ),
        ),
      ],
    );
  }
}

class BucketColorAnchor extends StatelessWidget {
  const BucketColorAnchor({
    super.key,
    required this.size,
    required this.bucketColor,
    required this.isSelected,
    required this.onTap,
  });

  final double size;
  final Color bucketColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Bucket fill color',
      child: Material(
        elevation: isSelected ? 5 : 4,
        shadowColor: Colors.black45,
        shape: const CircleBorder(),
        color: bucketColor,
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
}

class StrokeColorAnchor extends StatelessWidget {
  const StrokeColorAnchor({
    super.key,
    required this.size,
    required this.strokeColor,
    required this.isSelected,
    required this.onTap,
  });

  final double size;
  final Color strokeColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Stroke color',
      child: Material(
        elevation: isSelected ? 5 : 4,
        shadowColor: Colors.black45,
        shape: const CircleBorder(),
        color: strokeColor,
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
}
