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
  Offset _overlayPosition = const Offset(100, 300);
  bool _showControls = true;

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
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.02), // Almost transparent background so overlay is visible
      child: Stack(
        children: [
          // The draggable overlay shape
          Positioned(
            left: _overlayPosition.dx,
            top: _overlayPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _overlayPosition = Offset(
                    _overlayPosition.dx + details.delta.dx,
                    _overlayPosition.dy + details.delta.dy,
                  );
                });
              },
              onTap: _toggleControls,
              child: Container(
                width: _overlaySize,
                height: _overlaySize,
                decoration: BoxDecoration(
                  color: Colors.transparent, // Keep shape interior transparent
                  shape: _overlayShape == OverlayShape.circle
                      ? BoxShape.circle
                      : BoxShape.rectangle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.9), // More opaque border for better visibility
                    width: 4, // Slightly thicker for visibility
                  ),
                ),
              ),
            ),
          ),
          
          // Controls panel
          if (_showControls)
            Positioned(
              top: 40,
              right: 10,
              child: Container(
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
                      onPressed: () {
                        FlutterOverlayWindow.closeOverlay();
                      },
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
                          _overlaySize = (_overlaySize + 20).clamp(100, 400);
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
                          _overlaySize = (_overlaySize - 20).clamp(100, 400);
                        });
                      },
                      tooltip: 'Decrease size',
                    ),
                    const Divider(color: Colors.white54, height: 8),
                    // Hide controls button
                    IconButton(
                      icon: const Icon(Icons.visibility_off, color: Colors.white),
                      onPressed: _toggleControls,
                      tooltip: 'Hide controls',
                    ),
                  ],
                ),
              ),
            ),
          
          // Instruction text when controls are hidden
          if (!_showControls)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tap overlay to show controls',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
