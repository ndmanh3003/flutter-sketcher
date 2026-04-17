import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:sketcher/controllers/drawing_controller.dart';
import 'package:sketcher/models/save_format.dart';
import 'package:sketcher/widgets/shape_icon_helpers.dart';
import 'package:sketcher/models/draw_shape.dart';

class FloatingFlyoutPanel extends StatelessWidget {
  const FloatingFlyoutPanel({
    super.key,
    required this.flyout,
    required this.maxWidth,
    required this.controller,
    required this.shapeScrollController,
    required this.saveFormatScrollController,
    required this.onSaveFormat,
  });

  final FlyoutKind flyout;
  final double maxWidth;
  final DrawingController controller;
  final ScrollController shapeScrollController;
  final ScrollController saveFormatScrollController;
  final Future<void> Function(SaveFormat format) onSaveFormat;

  @override
  Widget build(BuildContext context) {
    return switch (flyout) {
      FlyoutKind.none => const SizedBox.shrink(),
      FlyoutKind.shape => _ShapeStripPanel(
          maxWidth: maxWidth,
          controller: controller,
          scrollController: shapeScrollController,
        ),
      FlyoutKind.color => ColorPickerPanel(
          maxWidth: maxWidth,
          selectedColor: controller.bucketColor,
          paletteColors: controller.paletteColors,
          onColorChanged: controller.setBucketColor,
        ),
      FlyoutKind.stroke => StrokeWidthSliderPill(
          maxWidth: maxWidth,
          strokeWidth: controller.strokeWidth,
          onChanged: controller.setStrokeWidth,
        ),
      FlyoutKind.strokeColor => ColorPickerPanel(
          maxWidth: maxWidth,
          selectedColor: controller.strokeColor,
          paletteColors: controller.paletteColors,
          onColorChanged: controller.setStrokeColor,
        ),
      FlyoutKind.saveFormat => _SaveFormatPanel(
          maxWidth: maxWidth,
          controller: controller,
          scrollController: saveFormatScrollController,
          onSaveFormat: onSaveFormat,
        ),
    };
  }
}

// ── Shape strip ──────────────────────────────────────────────────────────

class _ShapeStripPanel extends StatelessWidget {
  const _ShapeStripPanel({
    required this.maxWidth,
    required this.controller,
    required this.scrollController,
  });

  final double maxWidth;
  final DrawingController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return PillStrip(
      maxWidth: maxWidth,
      controller: scrollController,
      children: ShapeType.values.map((ShapeType type) {
        final bool sel = type == controller.selectedType;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: sel ? Colors.black87 : Colors.white,
            elevation: sel ? 3 : 1,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => controller.setSelectedType(type),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: shapeGlyph(
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
    );
  }
}

// ── Save format ──────────────────────────────────────────────────────────

class _SaveFormatPanel extends StatelessWidget {
  const _SaveFormatPanel({
    required this.maxWidth,
    required this.controller,
    required this.scrollController,
    required this.onSaveFormat,
  });

  final double maxWidth;
  final DrawingController controller;
  final ScrollController scrollController;
  final Future<void> Function(SaveFormat format) onSaveFormat;

  @override
  Widget build(BuildContext context) {
    return PillStrip(
      maxWidth: maxWidth,
      controller: scrollController,
      children: SaveFormat.values.map((SaveFormat format) {
        final bool isSelected = controller.selectedSaveFormat == format;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: isSelected ? Colors.black87 : Colors.white,
            elevation: isSelected ? 3 : 1,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                controller.setSelectedSaveFormat(format);
                await onSaveFormat(format);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      format.icon,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      format.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Color picker panel ───────────────────────────────────────────────────

class ColorPickerPanel extends StatelessWidget {
  const ColorPickerPanel({
    super.key,
    required this.maxWidth,
    required this.selectedColor,
    required this.paletteColors,
    required this.onColorChanged,
  });

  final double maxWidth;
  final Color selectedColor;
  final List<Color> paletteColors;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
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
                pickerColor: selectedColor,
                onColorChanged: onColorChanged,
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
                  itemCount: paletteColors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final Color c = paletteColors[index];
                    final bool sel =
                        c.toARGB32() == selectedColor.toARGB32();
                    return _PaletteColorDot(
                      color: c,
                      selected: sel,
                      onTap: () => onColorChanged(c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Palette dot ──────────────────────────────────────────────────────────

class _PaletteColorDot extends StatelessWidget {
  const _PaletteColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: selected ? 3 : 1,
      shadowColor: Colors.black38,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: color,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
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
}

// ── Stroke width slider ─────────────────────────────────────────────────

class StrokeWidthSliderPill extends StatelessWidget {
  const StrokeWidthSliderPill({
    super.key,
    required this.maxWidth,
    required this.strokeWidth,
    required this.onChanged,
  });

  final double maxWidth;
  final double strokeWidth;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
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
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              min: 1,
              max: 20,
              divisions: 19,
              value: strokeWidth.clamp(1, 20),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pill strip (scrollable row with arrow buttons) ───────────────────────

class PillStrip extends StatelessWidget {
  const PillStrip({
    super.key,
    required this.maxWidth,
    required this.controller,
    required this.children,
  });

  final double maxWidth;
  final ScrollController controller;
  final List<Widget> children;

  void _scrollStrip(double delta) {
    if (!controller.hasClients) return;
    final double next = (controller.offset + delta).clamp(
      0.0,
      controller.position.maxScrollExtent,
    );
    controller.animateTo(
      next,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 48),
              icon:
                  const Icon(Icons.chevron_left, color: Colors.black45),
              onPressed: () => _scrollStrip(-72),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                children: children,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 48),
              icon: const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
              onPressed: () => _scrollStrip(72),
            ),
          ],
        ),
      ),
    );
  }
}
