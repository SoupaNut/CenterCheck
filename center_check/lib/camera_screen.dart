import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Ask for camera permission
    final status = await Permission.camera.request();
    if (status.isDenied) {
      setState(() => _errorMessage = 'Camera permission denied.');
      return;
    }

    // Get available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _errorMessage = 'No cameras found.');
      return;
    }

    // Use the back camera
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    // Initialize the controller
    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _errorMessage = 'Camera error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show error if something went wrong
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    // Show loading while camera starts
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview fills the screen
        CameraPreview(_controller!),

        // Card outline overlay — helps user align the card
        _buildCardOverlay(),

        // Bottom controls
        _buildBottomBar(),
      ],
    );
  }

  // A simple rectangle overlay to guide card placement
  Widget _buildCardOverlay() {
    return CustomPaint(
      painter: CardOverlayPainter(),
    );
  }

  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Align card inside the box',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            // Capture button
            GestureDetector(
              onTap: _captureCard,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureCard() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      // For now just show a snackbar — we'll process it in Phase 3
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo captured: ${image.path}')),
        );
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }
}

// Draws a semi-transparent card-shaped guide on screen
class CardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    // Card dimensions ratio (standard trading card = 2.5 x 3.5 inches)
    final cardWidth = size.width * 0.80;
    final cardHeight = cardWidth * (3.5 / 2.5);
    final left = (size.width - cardWidth) / 2;
    final top = (size.height - cardHeight) / 2;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cardWidth, cardHeight),
      const Radius.circular(8),
    );

    // Darken everything outside the card box
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(cardRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Draw a bright border around the card guide
    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(cardRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}