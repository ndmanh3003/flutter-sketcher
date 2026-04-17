import 'package:flutter/material.dart';

import 'package:sketcher/drawing_page.dart';

class SketcherApp extends StatelessWidget {
  const SketcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sketcher',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DrawingPage(),
    );
  }
}
