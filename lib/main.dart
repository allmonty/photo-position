import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:photo_position/overlay_screen.dart';
import 'package:photo_position/theme.dart';

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
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: artDecoTheme,
      home: const OverlayScreen(),
    ),
  );
}

class PhotoPositionApp extends StatelessWidget {
  const PhotoPositionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Position Overlay',
      theme: artDecoTheme,
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
      if (granted != true && mounted) {
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
        title: const Text('PHOTO POSITION'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icon/icon.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                Text(
                  'PHOTO POSITION OVERLAY',
                  style: GoogleFonts.poiretOne(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 28 * 0.05,
                    color: kGold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Create a positioning overlay that stays on top of other apps',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.libreFranklin(
                    fontSize: 14,
                    color: kOnSurface,
                  ),
                ),
                const SizedBox(height: 32),
                const _ArtDecoDivider(),
                const SizedBox(height: 32),
                if (!_isOverlayActive)
                  _ArtDecoButton(
                    icon: Icons.play_arrow,
                    label: 'START OVERLAY',
                    onPressed: _showOverlay,
                    filled: true,
                  )
                else
                  Column(
                    children: [
                      Text(
                        'OVERLAY ACTIVE',
                        style: GoogleFonts.poiretOne(
                          fontSize: 16,
                          letterSpacing: 16 * 0.1,
                          color: kGold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ArtDecoButton(
                        icon: Icons.stop,
                        label: 'STOP OVERLAY',
                        onPressed: _closeOverlay,
                        filled: false,
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                const _ArtDecoDivider(),
                const SizedBox(height: 24),
                Text(
                  'INSTRUCTIONS',
                  style: GoogleFonts.poiretOne(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 14 * 0.1,
                    color: kGold,
                  ),
                ),
                const SizedBox(height: 12),
                const _InstructionsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtDecoDivider extends StatelessWidget {
  const _ArtDecoDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: kGold, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Transform.rotate(
            angle: 0.7854, // 45 degrees — diamond motif
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                border: Border.all(color: kGold, width: 1.5),
              ),
            ),
          ),
        ),
        const Expanded(child: Divider(color: kGold, thickness: 1)),
      ],
    );
  }
}

class _ArtDecoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  // true = cream fill (primary action), false = outlined (secondary action)
  final bool filled;

  const _ArtDecoButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = filled ? kCrimson : kGold;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: fgColor),
      label: Text(
        label,
        style: GoogleFonts.poiretOne(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 16 * 0.05,
          color: fgColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: filled ? kCream : kCrimsonMid,
        foregroundColor: fgColor,
        side: BorderSide(color: kGold, width: filled ? 2 : 1),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }
}

class _InstructionsList extends StatelessWidget {
  const _InstructionsList();

  static const _steps = [
    'Tap "Start Overlay" to create the overlay',
    'Drag the circle / square to position it',
    'Use controls to change shape and size',
    'Open your camera app to use the overlay',
    'Tap the overlay to toggle controls visibility',
    'Close overlay from controls or this app',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: GoogleFonts.poiretOne(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kGold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _steps[i],
                    style: GoogleFonts.libreFranklin(
                      fontSize: 14,
                      color: kOnSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
