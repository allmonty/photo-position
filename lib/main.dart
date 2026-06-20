import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'package:photo_position/overlay_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PhotoPositionApp());
}

// @pragma("vm:entry-point") is required so flutter_overlay_window's native
// side can find and launch this function as the entry point for the
// overlay's separate Flutter engine (it isn't reachable through the normal
// main() widget tree).
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
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.purple,
        ),
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
      );
      // showOverlay() returns once the native window/Service is requested,
      // but the overlay's own Flutter engine starts up asynchronously and
      // needs time to reach initState() and register its message listener
      // (see OverlayScreen.initState/_handleOverlayMessage). shareData()
      // sent before that listener attaches is simply lost, so wait for it.
      await Future.delayed(const Duration(milliseconds: 500));
      await FlutterOverlayWindow.shareData(
        {
          "portName": _portName,
        },
      );
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
      // Ask the overlay to close itself rather than calling
      // FlutterOverlayWindow.closeOverlay() directly: the overlay needs to
      // save its current position/size to shared_preferences first (see
      // OverlayScreen._closeOverlay), which only it has access to.
      await FlutterOverlayWindow.shareData({
        "action": "close_overlay_and_reset",
      });
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

  // The overlay runs in its own Flutter engine and doesn't share Dart state
  // with this one, so when the user closes it from the overlay's own UI
  // (its close button), it has to tell this app via IsolateNameServer
  // rather than just updating shared state -- this registers the port the
  // overlay sends that notification to (see OverlayScreen._closeOverlay).
  void _startBackgroundIsolate() {
    // registerPortWithName silently fails -- leaving the previous mapping
    // in place -- if this name is already registered. That would otherwise
    // happen if this state is ever recreated (e.g. a hot reload re-running
    // initState), permanently pointing the overlay's close notifications at
    // a stale, already-disposed ReceivePort.
    IsolateNameServer.removePortNameMapping(_portName);
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.crop_square,
                  size: 100,
                  color: Colors.red,
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
      ),
    );
  }
}
