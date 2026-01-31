import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'main.dart';

enum OverlayShape { none, circle, square }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  OverlayShape _overlayShape = OverlayShape.circle;
  double _overlaySize = 200.0;
  String? _lastPhotoPath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      return;
    }

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = path.join(
        directory.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final image = await _controller!.takePicture();
      
      // Move the file to our desired location
      final tempFile = File(image.path);
      await tempFile.copy(imagePath);
      // Clean up the temporary file
      await tempFile.delete();

      setState(() {
        _lastPhotoPath = imagePath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo saved to: $imagePath'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }

  Widget _buildOverlay() {
    if (_overlayShape == OverlayShape.none) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        width: _overlaySize,
        height: _overlaySize,
        decoration: BoxDecoration(
          shape: _overlayShape == OverlayShape.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
          border: Border.all(
            color: Colors.white.withOpacity(0.7),
            width: 3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Photo Position')),
        body: const Center(
          child: Text('No camera available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Position'),
        backgroundColor: Colors.black87,
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      // Camera Preview
                      SizedBox.expand(
                        child: CameraPreview(_controller!),
                      ),
                      // Overlay shape (this will NOT appear in the photo)
                      _buildOverlay(),
                      // Controls
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Shape selector
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildShapeButton(
                                    OverlayShape.none,
                                    Icons.close,
                                    'No Overlay',
                                  ),
                                  _buildShapeButton(
                                    OverlayShape.circle,
                                    Icons.circle_outlined,
                                    'Circle',
                                  ),
                                  _buildShapeButton(
                                    OverlayShape.square,
                                    Icons.square_outlined,
                                    'Square',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Size slider
                              if (_overlayShape != OverlayShape.none)
                                Row(
                                  children: [
                                    const Icon(Icons.photo_size_select_small,
                                        color: Colors.white),
                                    Expanded(
                                      child: Slider(
                                        value: _overlaySize,
                                        min: 100,
                                        max: 400,
                                        divisions: 30,
                                        label: _overlaySize.round().toString(),
                                        onChanged: (value) {
                                          setState(() {
                                            _overlaySize = value;
                                          });
                                        },
                                      ),
                                    ),
                                    const Icon(Icons.photo_size_select_large,
                                        color: Colors.white),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              // Capture button
                              FloatingActionButton(
                                onPressed: _takePicture,
                                child: const Icon(Icons.camera_alt, size: 32),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }

  Widget _buildShapeButton(
      OverlayShape shape, IconData icon, String label) {
    final isSelected = _overlayShape == shape;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          iconSize: 32,
          color: isSelected ? Colors.blue : Colors.white,
          onPressed: () {
            setState(() {
              _overlayShape = shape;
            });
          },
        ),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
