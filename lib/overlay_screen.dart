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
  static const double minSize = 50.0;
  static const double maxSize = 500.0;
  static const double defaultSize = 200.0;
  static const double panelWidth = 60.0;
  static const double panelHeight = 120.0;
  static const double borderWidth = 5.0;

  OverlayShape _overlayShape = OverlayShape.circle;
  double _overlaySize = defaultSize;
  double _overlayWidth = defaultSize;
  double _overlayHeight = defaultSize;
  bool _showControls = true;

  String? _portName;
  double _initialWidth = defaultSize;
  double _initialHeight = defaultSize;
  double _initialSize = defaultSize;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen(_handleOverlayMessage);
  }

  void _handleOverlayMessage(dynamic event) {
    if (event is! Map) return;
    setState(() {
      if (event['shape'] != null) {
        _overlayShape = event['shape'] == 'circle'
            ? OverlayShape.circle
            : OverlayShape.square;
      }
      if (event['size'] != null) {
        final size = event['size'].toDouble();
        _overlaySize = size;
        _overlayWidth = size;
        _overlayHeight = size;
      }
      if (event['portName'] != null) {
        _portName = event['portName'];
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _closeOverlay() {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(_portName!);
    sendPort?.send({'action': 'close_overlay'});
    FlutterOverlayWindow.closeOverlay();
  }

  void _toggleShape() {
    setState(() {
      _overlayShape = _overlayShape == OverlayShape.circle
          ? OverlayShape.square
          : OverlayShape.circle;
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _initialWidth = _overlayWidth;
    _initialHeight = _overlayHeight;
    _initialSize = _overlaySize;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (_overlayShape == OverlayShape.circle) {
        _overlaySize = (_initialSize * details.scale).clamp(minSize, maxSize);
      } else {
        _overlayWidth =
            (_initialWidth * details.horizontalScale).clamp(minSize, maxSize);
        _overlayHeight =
            (_initialHeight * details.verticalScale).clamp(minSize, maxSize);
      }
    });
  }

  Widget _buildOverlayShape() {
    return Container(
      width:
          _overlayShape == OverlayShape.circle ? _overlaySize : _overlayWidth,
      height:
          _overlayShape == OverlayShape.circle ? _overlaySize : _overlayHeight,
      decoration: BoxDecoration(
        shape: _overlayShape == OverlayShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        border: Border.all(
          color: const Color.fromARGB(200, 244, 67, 54),
          width: borderWidth,
        ),
      ),
    );
  }

  Widget _buildControlsPanel(double windowHeight) {
    return Positioned(
      top: (windowHeight - panelHeight) / 2,
      right: 0,
      child: Container(
        width: panelWidth,
        height: panelHeight,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconButton(
              icon: Icons.close,
              tooltip: 'Close overlay',
              onPressed: _closeOverlay,
            ),
            const Divider(color: Colors.white54, height: 8),
            _buildIconButton(
              icon: _overlayShape == OverlayShape.circle
                  ? Icons.circle_outlined
                  : Icons.square_outlined,
              tooltip: 'Toggle shape',
              onPressed: _toggleShape,
            ),
          ],
        ),
      ),
    );
  }

  IconButton _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCircle = _overlayShape == OverlayShape.circle;
    final shapeWidth = isCircle ? _overlaySize : _overlayWidth;
    final shapeHeight = isCircle ? _overlaySize : _overlayHeight;

    final windowWidth = shapeWidth + panelWidth;
    final windowHeight = max(shapeHeight, panelWidth);

    FlutterOverlayWindow.resizeOverlay(
      windowWidth.toInt(),
      windowHeight.toInt(),
      true,
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: (windowHeight - shapeHeight) / 2,
            child: GestureDetector(
              onTap: _toggleControls,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              child: _buildOverlayShape(),
            ),
          ),
          if (_showControls) _buildControlsPanel(windowHeight),
        ],
      ),
    );
  }
}
