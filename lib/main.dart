import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'package:photo_position/overlay_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PhotoPositionApp());
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayScreen(),
    ),
  );
}

class PhotoPositionApp extends StatelessWidget {
  const PhotoPositionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Position Overlay',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOverlayPermissionGranted = false;
  bool _isOverlayActive = false;

  final String _portName = "photo_position_overlay_port";
  ReceivePort? _receivePort;

  Future<void> _requestOverlayPermission() async {
    final status = await FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      final granted = await FlutterOverlayWindow.requestPermission();
      if (granted! && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Overlay permission is required to use this app'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showOverlay() async {
    if (!_isOverlayPermissionGranted) {
      final status = await FlutterOverlayWindow.isPermissionGranted();
      setState(() {
        _isOverlayPermissionGranted = status;
      });
      if (!status) {
        await _requestOverlayPermission();
        return;
      }
    }

    try {
      await FlutterOverlayWindow.showOverlay(
        flag: OverlayFlag.defaultFlag,
        overlayTitle: "Photo Position Overlay",
        overlayContent: "Use this overlay to position your camera",
        enableDrag: true,
        width: WindowSize.fullCover,
        height: WindowSize.fullCover,
      );

      //vsend message to overlay to initialize
      await Future.delayed(const Duration(milliseconds: 500));
      await FlutterOverlayWindow.shareData(
        {
          "shape": "square",
          "size": 200,
          "portName": _portName,
        },
      );

      // Update state after a short delay to allow overlay to initialize
      if (mounted) {
        setState(() {
          _isOverlayActive = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to show overlay: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _closeOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
      if (mounted) {
        setState(() {
          _isOverlayActive = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close overlay: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _startBackgroundIsolate();
  }

  void _startBackgroundIsolate() {
    // Set up ReceivePort to get messages from overlay
    // 1. Create a ReceivePort
    _receivePort = ReceivePort();
    // 2. Register the SendPort with a name
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);
    // 3. Listen for messages
    _receivePort!.listen((message) {
      setState(() {
        if (message is Map) {
          if (message['action'] == 'close_overlay') {
            _isOverlayActive = false;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Position Overlay'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.crop_square,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Position Overlay App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create a positioning overlay that stays on top of other apps',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              if (!_isOverlayActive)
                ElevatedButton.icon(
                  onPressed: _showOverlay,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Overlay'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                )
              else
                Column(
                  children: [
                    const Text(
                      'Overlay is active!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _closeOverlay,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Overlay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Instructions:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Tap "Start Overlay" to create the overlay\n'
                '2. Drag the circle/square to position it\n'
                '3. Use controls to change shape and size\n'
                '4. Open your camera app to use the overlay\n'
                '5. Tap the overlay to toggle controls visibility\n'
                '6. Close overlay from controls or this app',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
