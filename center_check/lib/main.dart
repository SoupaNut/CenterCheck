import 'package:flutter/material.dart';
import 'camera_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardGraderApp());
}

class CardGraderApp extends StatelessWidget {
  const CardGraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Grader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CameraScreen(),
    );
  }
}