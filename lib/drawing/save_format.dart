import 'package:flutter/material.dart';

enum SaveFormat { bin, png, jpeg }

extension SaveFormatMeta on SaveFormat {
  String get label {
    return switch (this) {
      SaveFormat.bin => 'BIN',
      SaveFormat.png => 'PNG',
      SaveFormat.jpeg => 'JPEG',
    };
  }

  String get extension {
    return switch (this) {
      SaveFormat.bin => 'bin',
      SaveFormat.png => 'png',
      SaveFormat.jpeg => 'jpeg',
    };
  }

  String get defaultFileName {
    return switch (this) {
      SaveFormat.bin => 'sketcher_scene.bin',
      SaveFormat.png => 'sketcher_export.png',
      SaveFormat.jpeg => 'sketcher_export.jpeg',
    };
  }

  IconData get icon {
    return switch (this) {
      SaveFormat.bin => Icons.data_object_rounded,
      SaveFormat.png => Icons.image_outlined,
      SaveFormat.jpeg => Icons.photo_outlined,
    };
  }
}
