import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

enum OverlayShape { circle, square }

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  OverlayShape _overlayShape = OverlayShape.circle;
  double _overlaySize = 200.0;
  // Offset _overlayPosition = const Offset(0, 0);
  bool _showControls = true;

  String? _portName;

  double _overlayWindowHeight = 300.0;

  final double _panelHeight = 300.0;
  final double _panelWidth = 50.0;

  @override
  void initState() {
    super.initState();
    // Listen for messages from the main app
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        setState(() {
          if (event['shape'] != null) {
            _overlayShape = event['shape'] == 'circle'
                ? OverlayShape.circle
                : OverlayShape.square;
          }
          if (event['size'] != null) {
            _overlaySize = event['size'].toDouble();
          }
          if (event['portName'] != null) {
            _portName = event['portName'];
          }
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _closeOverlay() {
    // Notify main app before closing
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(_portName!);
    sendPort?.send({"action": "close_overlay"});
    // Close the overlay
    FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      _overlayWindowHeight = max(_panelHeight, _overlaySize);
    });
    FlutterOverlayWindow.resizeOverlay(
      (_overlaySize + _panelWidth).toInt(),
      _overlayWindowHeight.toInt(),
      true,
    );
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Full screen tap area to make it obvious overlay is active
          // Positioned.fill(
          //   child: GestureDetector(
          //     onTap: _toggleControls,
          //     child: Container(
          //       color: Colors.transparent,
          //     ),
          //   ),
          // ),

          // The draggable overlay shape
          Positioned(
            left: 0,
            top: (_overlayWindowHeight - _overlaySize) / 2,
            child: GestureDetector(
              onPanUpdate: (details) {
                // setState(() {
                //   _overlayPosition = Offset(
                //     _overlayPosition.dx + details.delta.dx,
                //     _overlayPosition.dy + details.delta.dy,
                //   );
                // });
              },
              onTap: _toggleControls,
              child: Container(
                width: _overlaySize,
                height: _overlaySize,
                decoration: BoxDecoration(
                  shape: _overlayShape == OverlayShape.circle
                      ? BoxShape.circle
                      : BoxShape.rectangle,
                  border: Border.all(
                    color: const Color.fromARGB(155, 244, 67,
                        54), // Bright red border for maximum visibility
                    width: 5, // Thicker border
                  ),
                ),
              ),
            ),
          ),

          // Controls panel
          if (_showControls)
            Positioned(
              top: (_overlayWindowHeight - _panelHeight) / 2,
              right: 0,
              child: Container(
                width: _panelWidth,
                height: _panelHeight,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => _closeOverlay(),
                      tooltip: 'Close overlay',
                    ),
                    const Divider(color: Colors.white54, height: 8),
                    // Shape toggle
                    IconButton(
                      icon: Icon(
                        _overlayShape == OverlayShape.circle
                            ? Icons.circle_outlined
                            : Icons.square_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _overlayShape = _overlayShape == OverlayShape.circle
                              ? OverlayShape.square
                              : OverlayShape.circle;
                        });
                      },
                      tooltip: 'Toggle shape',
                    ),
                    const SizedBox(height: 8),
                    // Size controls
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _overlaySize = (_overlaySize + 20).clamp(50, 500);
                        });
                      },
                      tooltip: 'Increase size',
                    ),
                    Text(
                      '${_overlaySize.round()}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _overlaySize = (_overlaySize - 20).clamp(50, 500);
                        });
                      },
                      tooltip: 'Decrease size',
                    ),
                    const Divider(color: Colors.white54, height: 8),
                    // Hide controls button
                    IconButton(
                      icon:
                          const Icon(Icons.visibility_off, color: Colors.white),
                      onPressed: _toggleControls,
                      tooltip: 'Hide controls',
                    ),
                  ],
                ),
              ),
            ),

          // Instruction text when controls are hidden
          // if (!_showControls)
          //   Positioned(
          //     top: 50,
          //     left: 0,
          //     right: 0,
          //     child: Center(
          //       child: Container(
          //         padding:
          //             const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //         decoration: BoxDecoration(
          //           color: Colors.black.withOpacity(0.7),
          //           borderRadius: BorderRadius.circular(8),
          //         ),
          //         child: const Text(
          //           'Tap overlay to show controls',
          //           style: TextStyle(color: Colors.white, fontSize: 12),
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}
