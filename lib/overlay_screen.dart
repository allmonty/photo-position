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
  static const double panelHeight = 150.0;
  static const double borderWidth = 5.0;
  static const double resizeHandleSize = 20.0;

  OverlayShape _overlayShape = OverlayShape.circle;
  double _overlaySize = defaultSize;
  double _overlayWidth = defaultSize;
  double _overlayHeight = defaultSize;
  bool _showControls = true;

  String? _portName;
  double _initialWidth = defaultSize;
  double _initialHeight = defaultSize;
  double _initialSize = defaultSize;
  Offset _dragStart = Offset.zero;

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

  void _startHorizontalResize(DragStartDetails details) {
    _initialWidth = _overlayWidth;
    _dragStart = details.localPosition;
  }

  void _updateHorizontalResize(DragUpdateDetails details) {
    final delta = details.localPosition.dx - _dragStart.dx;
    setState(() {
      _overlayWidth = (_initialWidth + delta * 2).clamp(minSize, maxSize);
    });
  }

  void _startVerticalResize(DragStartDetails details) {
    _initialHeight = _overlayHeight;
    _dragStart = details.localPosition;
  }

  void _updateVerticalResize(DragUpdateDetails details) {
    final delta = details.localPosition.dy - _dragStart.dy;
    setState(() {
      _overlayHeight = (_initialHeight + delta * 2).clamp(minSize, maxSize);
    });
  }

  void _startCircleResize(DragStartDetails details) {
    _initialSize = _overlaySize;
    _dragStart = details.localPosition;
  }

  void _updateCircleResize(DragUpdateDetails details) {
    final delta = details.localPosition.dy - _dragStart.dy;
    setState(() {
      _overlaySize = (_initialSize + delta * 2).clamp(minSize, maxSize);
    });
  }

  Widget _buildResizeHandle(
      {required GestureDragStartCallback onStart,
      required GestureDragUpdateCallback onUpdate,
      required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: onStart,
      onVerticalDragUpdate: onUpdate,
      child: child,
    );
  }

  Widget _buildHorizontalResizeHandle(
      {required GestureDragStartCallback onStart,
      required GestureDragUpdateCallback onUpdate,
      required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: onStart,
      onHorizontalDragUpdate: onUpdate,
      child: child,
    );
  }

  Widget _buildOverlayContent() {
    if (_overlayShape == OverlayShape.circle) {
      return SizedBox(
        width: _overlayWidth + resizeHandleSize * 2,
        height: _overlayHeight + resizeHandleSize * 2,
        child: Stack(
          children: [
            Positioned(
              left: resizeHandleSize,
              top: resizeHandleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: Container(
                  width: _overlaySize,
                  height: _overlaySize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromARGB(200, 244, 67, 54),
                      width: borderWidth,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildResizeHandle(
                    child: const SizedBox(
                        height: resizeHandleSize,
                        child: Center(
                            child: SizedBox(
                                height: 4,
                                width: 24,
                                child: Divider(
                                    color: Colors.white54, thickness: 2)))),
                    onStart: _startCircleResize,
                    onUpdate: _updateCircleResize))
          ],
        ),
      );
    }

    return SizedBox(
      width: _overlayWidth + resizeHandleSize * 2,
      height: _overlayHeight + resizeHandleSize * 2,
      child: Stack(
        children: [
          Positioned(
            left: resizeHandleSize,
            top: resizeHandleSize,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              child: Container(
                width: _overlayWidth,
                height: _overlayHeight,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(
                    color: const Color.fromARGB(200, 244, 67, 54),
                    width: borderWidth,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _buildHorizontalResizeHandle(
                  child: const SizedBox(
                      width: resizeHandleSize,
                      child: Center(
                          child: SizedBox(
                              width: 4,
                              height: 24,
                              child: VerticalDivider(
                                  color: Colors.white54, thickness: 2)))),
                  onStart: _startHorizontalResize,
                  onUpdate: _updateHorizontalResize)),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildResizeHandle(
                  child: const SizedBox(
                      height: resizeHandleSize,
                      child: Center(
                          child: SizedBox(
                              height: 4,
                              width: 24,
                              child: Divider(
                                  color: Colors.white54, thickness: 2)))),
                  onStart: _startVerticalResize,
                  onUpdate: _updateVerticalResize)),
        ],
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
                onPressed: _closeOverlay),
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

  IconButton _buildIconButton(
      {required IconData icon,
      required String tooltip,
      required VoidCallback onPressed}) {
    return IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        tooltip: tooltip);
  }

  @override
  Widget build(BuildContext context) {
    final shapeWidth =  _overlayWidth + resizeHandleSize * 2;
    final shapeHeight = _overlayHeight + resizeHandleSize * 2;

    final windowWidth = shapeWidth + panelWidth;
    final windowHeight = max(shapeHeight, panelHeight);

    FlutterOverlayWindow.resizeOverlay(
        windowWidth.toInt(), windowHeight.toInt(), true);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
              left: 0,
              top: (windowHeight - shapeHeight) / 2,
              child: _buildOverlayContent()),
          if (_showControls) _buildControlsPanel(windowHeight),
        ],
      ),
    );
  }
}
