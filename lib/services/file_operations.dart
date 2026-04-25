import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'package:sketcher/controllers/drawing_controller.dart';
import 'package:sketcher/widgets/drawing_painter.dart';
import 'package:sketcher/models/save_format.dart';
import 'package:sketcher/services/scene_codec.dart';
import 'package:sketcher/models/draw_shape.dart';

class FileOperations {
  FileOperations._();

  static const List<String> _sceneExtensions = <String>['bin'];

  static Future<void> saveScene(
    SaveFormat format,
    DrawingController controller, {
    required void Function(String message) showSnack,
  }) async {
    if (format == SaveFormat.bin) {
      await _saveAsBinary(controller, showSnack: showSnack);
      return;
    }
    await _saveAsImage(format, controller, showSnack: showSnack);
  }

  static Future<void> _saveAsBinary(
    DrawingController controller, {
    required void Function(String message) showSnack,
  }) async {
    try {
      final Uint8List bytes = SceneCodec().encode(controller.shapes, controller.backgroundColor);

      if (!kIsWeb && controller.loadedBinaryPath != null) {
        final XFile file = XFile.fromData(
          bytes,
          name: SaveFormat.bin.defaultFileName,
          mimeType: 'application/octet-stream',
        );
        await file.saveTo(controller.loadedBinaryPath!);
        showSnack('Saved: ${controller.loadedBinaryPath}');
        return;
      }

      final String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Save drawing scene',
        fileName: SaveFormat.bin.defaultFileName,
        type: FileType.custom,
        allowedExtensions: _sceneExtensions,
        bytes: bytes,
      );

      if (kIsWeb) {
        showSnack('Downloaded: ${SaveFormat.bin.defaultFileName}');
        return;
      }
      if (outputPath == null) {
        showSnack('Save canceled.');
        return;
      }
      controller.loadedBinaryPath = outputPath;
      showSnack('Saved: $outputPath');
    } catch (e) {
      showSnack('Save failed: $e');
    }
  }

  static Future<void> loadBinary(
    DrawingController controller, {
    required void Function(String message) showSnack,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'Open drawing scene',
        type: FileType.custom,
        allowedExtensions: _sceneExtensions,
        allowMultiple: false,
        withData: true,
      );
      if (result == null) {
        showSnack('Load canceled.');
        return;
      }

      final PlatformFile pickedFile = result.files.single;
      final Uint8List bytes =
          pickedFile.bytes ?? await pickedFile.xFile.readAsBytes();
      final (List<DrawShape> loadedShapes, Color loadedBackgroundColor) =
          SceneCodec().decode(bytes);

      controller.loadScene(
        loadedShapes,
        loadedBackgroundColor,
        kIsWeb ? null : pickedFile.path,
      );
      showSnack(
        'Loaded ${loadedShapes.length} shapes from ${pickedFile.name}',
      );
    } catch (e) {
      showSnack('Load failed: $e');
    }
  }

  static Future<void> _saveAsImage(
    SaveFormat format,
    DrawingController controller, {
    required void Function(String message) showSnack,
  }) async {
    if (DrawingController.canvasSize.width <= 0 ||
        DrawingController.canvasSize.height <= 0) {
      showSnack('Save failed: invalid canvas size.');
      return;
    }

    try {
      final int width = DrawingController.canvasSize.width.round();
      final int height = DrawingController.canvasSize.height.round();
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = controller.backgroundColor,
      );
      DrawingPainter(
        shapes: controller.shapes,
        preview: null,
        paintGeneration: controller.paintGeneration,
        backgroundColor: controller.backgroundColor,
      ).paint(canvas, Size(width.toDouble(), height.toDouble()));

      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(width, height);
      final Uint8List bytes = await _encodeImage(image, format);
      image.dispose();
      picture.dispose();

      final String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Save drawing image',
        fileName: format.defaultFileName,
        type: FileType.custom,
        allowedExtensions: <String>[format.extension],
        bytes: bytes,
      );

      if (kIsWeb) {
        showSnack('Downloaded: ${format.defaultFileName}');
        return;
      }
      if (outputPath == null) {
        showSnack('Save canceled.');
        return;
      }
      showSnack('Saved: $outputPath');
    } catch (e) {
      showSnack('Save failed: $e');
    }
  }

  static Future<Uint8List> _encodeImage(
    ui.Image image,
    SaveFormat format,
  ) async {
    if (format == SaveFormat.png) {
      final ByteData? pngData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (pngData == null) {
        throw StateError('Failed to encode PNG.');
      }
      return pngData.buffer.asUint8List();
    }

    final ByteData? rgbaData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (rgbaData == null) {
      throw StateError('Failed to encode RGBA buffer for JPEG.');
    }

    final img.Image jpegImage = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: rgbaData.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return Uint8List.fromList(img.encodeJpg(jpegImage, quality: 92));
  }
}
