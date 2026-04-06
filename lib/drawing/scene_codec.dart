import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:sketcher/models/draw_shape.dart';

/// Binary format: magic `DRW1` + little-endian shape records.
class SceneCodec {
  static const List<int> header = <int>[0x44, 0x52, 0x57, 0x31]; // DRW1
  static const int shapeByteSize = 1 + 4 + 4 + 1 + 4 + 4 + 4 + 4 + 4;

  Uint8List encode(List<DrawShape> shapes) {
    final int total = 8 + shapes.length * shapeByteSize;
    final ByteData data = ByteData(total);
    for (int i = 0; i < 4; i++) {
      data.setUint8(i, header[i]);
    }
    data.setUint32(4, shapes.length, Endian.little);

    int o = 8;
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

  List<DrawShape> decode(Uint8List bytes) {
    final ByteData data = bytes.buffer.asByteData();
    if (bytes.lengthInBytes < 8) {
      throw const FormatException('File too short.');
    }
    for (int i = 0; i < 4; i++) {
      if (data.getUint8(i) != header[i]) {
        throw const FormatException('Invalid file header.');
      }
    }
    final int count = data.getUint32(4, Endian.little);
    final int expected = 8 + count * shapeByteSize;
    if (expected != bytes.lengthInBytes) {
      throw const FormatException('Invalid file size.');
    }

    final List<DrawShape> result = <DrawShape>[];
    int o = 8;
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

      result.add(DrawShape(
        type: type,
        start: Offset(x1, y1),
        end: Offset(x2, y2),
        strokeColor: strokeColor,
        fillColor: fillColor,
        strokeWidth: strokeWidth,
        filled: filled,
      ));
    }
    return result;
  }
}
