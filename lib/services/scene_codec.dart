import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:sketcher/models/draw_shape.dart';

/// Binary format: magic `DRW2` + background color (4 bytes) + little-endian shape records.
/// Backward compatibility with `DRW1` is maintained.
class SceneCodec {
  static const List<int> headerDRW1 = <int>[0x44, 0x52, 0x57, 0x31]; // DRW1
  static const List<int> headerDRW2 = <int>[0x44, 0x52, 0x57, 0x32]; // DRW2
  static const int shapeByteSize = 1 + 4 + 4 + 1 + 4 + 4 + 4 + 4 + 4;

  Uint8List encode(List<DrawShape> shapes, Color backgroundColor) {
    final int total = 8 + 4 + shapes.length * shapeByteSize;
    final ByteData data = ByteData(total);
    for (int i = 0; i < 4; i++) {
      data.setUint8(i, headerDRW2[i]);
    }
    data.setUint32(4, shapes.length, Endian.little);
    data.setUint32(8, backgroundColor.toARGB32(), Endian.little);

    int o = 12;
    for (final DrawShape s in shapes) {
      data.setUint8(o, s.type.index);
      o += 1;
      data.setFloat32(o, s.strokeWidth, Endian.little);
      o += 4;
      data.setUint32(o, s.strokeColor.toARGB32(), Endian.little);
      o += 4;
      data.setUint8(o, s.filled ? 1 : 0);
      o += 1;
      data.setUint32(o, s.fillColor.toARGB32(), Endian.little);
      o += 4;
      data.setFloat32(o, s.start.dx, Endian.little);
      o += 4;
      data.setFloat32(o, s.start.dy, Endian.little);
      o += 4;
      data.setFloat32(o, s.end.dx, Endian.little);
      o += 4;
      data.setFloat32(o, s.end.dy, Endian.little);
      o += 4;
    }
    return data.buffer.asUint8List();
  }

  (List<DrawShape> shapes, Color backgroundColor) decode(Uint8List bytes) {
    final ByteData data = bytes.buffer.asByteData(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    if (bytes.lengthInBytes < 8) {
      throw const FormatException('File too short.');
    }
    
    bool isDRW1 = true;
    for (int i = 0; i < 4; i++) {
      if (data.getUint8(i) != headerDRW1[i]) {
        isDRW1 = false;
        break;
      }
    }
    
    bool isDRW2 = false;
    if (!isDRW1) {
      isDRW2 = true;
      for (int i = 0; i < 4; i++) {
        if (data.getUint8(i) != headerDRW2[i]) {
          isDRW2 = false;
          break;
        }
      }
    }

    if (!isDRW1 && !isDRW2) {
      throw const FormatException('Invalid file header.');
    }

    final int count = data.getUint32(4, Endian.little);
    final int expected = (isDRW1 ? 8 : 12) + count * shapeByteSize;
    if (expected != bytes.lengthInBytes) {
      throw const FormatException('Invalid file size.');
    }

    Color backgroundColor = Colors.white;
    int o = 8;
    if (isDRW2) {
      backgroundColor = Color(data.getUint32(8, Endian.little));
      o = 12;
    }

    final List<DrawShape> result = <DrawShape>[];
    for (int i = 0; i < count; i++) {
      final ShapeType type = ShapeType.values[data.getUint8(o)];
      o += 1;
      final double strokeWidth = data.getFloat32(o, Endian.little);
      o += 4;
      final Color strokeColor = Color(data.getUint32(o, Endian.little));
      o += 4;
      final bool filled = data.getUint8(o) == 1;
      o += 1;
      final Color fillColor = Color(data.getUint32(o, Endian.little));
      o += 4;
      final double x1 = data.getFloat32(o, Endian.little);
      o += 4;
      final double y1 = data.getFloat32(o, Endian.little);
      o += 4;
      final double x2 = data.getFloat32(o, Endian.little);
      o += 4;
      final double y2 = data.getFloat32(o, Endian.little);
      o += 4;

      result.add(
        DrawShape(
          type: type,
          start: Offset(x1, y1),
          end: Offset(x2, y2),
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          filled: filled,
        ),
      );
    }
    return (result, backgroundColor);
  }
}
