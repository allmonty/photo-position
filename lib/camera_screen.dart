import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'main.dart';

enum CameraMode { custom, native }
enum OverlayShape { none, circle, square }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // Custom camera variables
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  OverlayShape _overlayShape = OverlayShape.circle;
  double _overlaySize = 200.0;
  
  // Native camera variables
  final ImagePicker _picker = ImagePicker();
  
  // Shared variables
  String? _lastPhotoPath;
  File? _imageFile;
  CameraMode _cameraMode = CameraMode.custom;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      return;
    }

    // Select back camera by default, fallback to first camera
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras[0],
    );

    _controller = CameraController(
      backCamera,
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

  Future<void> _takePictureCustom() async {
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
      try {
        await tempFile.delete();
      } catch (e) {
        debugPrint('Failed to delete temporary file: $e');
      }

      setState(() {
        _lastPhotoPath = imagePath;
        _imageFile = File(imagePath);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved successfully'),
            duration: Duration(seconds: 2),
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

  Future<void> _takePictureNative() async {
    try {
      // Launch the native camera app
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        // Get the app's documents directory
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = path.join(
          directory.path,
          '${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        // Copy the image to our desired location
        final File imageFile = File(photo.path);
        await imageFile.copy(imagePath);

        setState(() {
          _lastPhotoPath = imagePath;
          _imageFile = File(imagePath);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo saved successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
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

  Widget _buildShapeButton(OverlayShape shape, IconData icon, String label) {
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

  Widget _buildCustomCameraView() {
    if (cameras.isEmpty) {
      return const Center(
        child: Text('No camera available'),
      );
    }

    return _controller == null
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
                              onPressed: _takePictureCustom,
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
          );
  }

  Widget _buildNativeCameraView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_imageFile != null) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Photo saved successfully',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const Icon(
              Icons.camera_alt,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Native Camera Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to open\nthe native camera with all features',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Position'),
        backgroundColor: Colors.black87,
        actions: [
          // Camera mode toggle
          PopupMenuButton<CameraMode>(
            icon: Icon(
              _cameraMode == CameraMode.custom
                  ? Icons.camera
                  : Icons.camera_enhance,
            ),
            tooltip: 'Camera Mode',
            onSelected: (CameraMode mode) {
              setState(() {
                _cameraMode = mode;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<CameraMode>>[
              PopupMenuItem<CameraMode>(
                value: CameraMode.custom,
                child: Row(
                  children: [
                    Icon(
                      Icons.camera,
                      color: _cameraMode == CameraMode.custom
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Custom Camera (with overlay)'),
                  ],
                ),
              ),
              PopupMenuItem<CameraMode>(
                value: CameraMode.native,
                child: Row(
                  children: [
                    Icon(
                      Icons.camera_enhance,
                      color: _cameraMode == CameraMode.native
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Native Camera (all features)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _cameraMode == CameraMode.custom
          ? _buildCustomCameraView()
          : _buildNativeCameraView(),
      floatingActionButton: _cameraMode == CameraMode.native
          ? FloatingActionButton.extended(
              onPressed: _takePictureNative,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Native Camera'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
