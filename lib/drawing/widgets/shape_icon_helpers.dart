import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sketcher/models/draw_shape.dart';

const String _ellipseIconAsset = 'assets/icons/ellipse_outline.svg';

IconData shapeIcon(ShapeType type) {
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

Widget shapeGlyph(
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

  return Icon(shapeIcon(type), color: color, size: size);
}
