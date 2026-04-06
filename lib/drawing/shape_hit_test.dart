import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sketcher/models/draw_shape.dart';

/// Hit testing for shapes (bucket fill uses closed regions only).
class ShapeHitTest {
  static bool isClosedRegion(ShapeType type) {
    return type == ShapeType.ellipse ||
        type == ShapeType.circle ||
        type == ShapeType.square ||
        type == ShapeType.rectangle;
  }

  static bool contains(DrawShape s, Offset p) {
    switch (s.type) {
      case ShapeType.point:
        final double r = math.max(3.0, s.strokeWidth) + 6;
        return (p - s.start).distance <= r;
      case ShapeType.line:
        return _distanceToSegment(p, s.start, s.end) <= s.strokeWidth / 2 + 8;
      case ShapeType.ellipse:
        return _insideOval(s.rect, p);
      case ShapeType.circle:
        return _insideOval(_squareHitRect(s.rect), p);
      case ShapeType.square:
        return _normalize(_squareHitRect(s.rect)).contains(p);
      case ShapeType.rectangle:
        return _normalize(s.rect).contains(p);
    }
  }

  static Rect _normalize(Rect r) {
    return Rect.fromLTRB(
      math.min(r.left, r.right),
      math.min(r.top, r.bottom),
      math.max(r.left, r.right),
      math.max(r.top, r.bottom),
    );
  }

  static Rect _squareHitRect(Rect rect) {
    final double side = math.min(rect.width.abs(), rect.height.abs());
    return Rect.fromLTWH(rect.left, rect.top, side, side);
  }

  static bool _insideOval(Rect r, Offset p) {
    final Rect n = _normalize(r);
    final double rx = n.width / 2;
    final double ry = n.height / 2;
    if (rx < 0.5 || ry < 0.5) return false;
    final Offset c = n.center;
    final double dx = (p.dx - c.dx) / rx;
    final double dy = (p.dy - c.dy) / ry;
    return dx * dx + dy * dy <= 1;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final Offset ab = b - a;
    final double len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 < 1e-6) {
      return (p - a).distance;
    }
    double t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    final Offset proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }
}
