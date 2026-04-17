import 'package:flutter/material.dart';

import 'package:sketcher/drawing/controllers/drawing_controller.dart';
import 'package:sketcher/drawing/toolbar_tool.dart';
import 'package:sketcher/drawing/widgets/shape_icon_helpers.dart';

class ToolbarChrome extends StatelessWidget {
  const ToolbarChrome({
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> modeTools = controller.toolbarTool == ToolbarTool.draw
        ? <Widget>[
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
          ]
        : <Widget>[
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

    return ToolbarChrome(
      size: size,
      children: [
        RoundToolButton(
          size: size,
          selected: false,
          icon: controller.toolbarTool == ToolbarTool.fill
              ? Icons.format_color_fill
              : Icons.brush,
          tooltip: controller.toolbarTool == ToolbarTool.fill
              ? 'Fill mode - tap for draw mode'
              : 'Draw mode - tap for fill mode',
          onTap: controller.toggleToolbarTool,
        ),
        ...modeTools,
      ],
    );
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
