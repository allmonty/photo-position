import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const double resizeHandleSize = 20.0;
  static const double panelWidth = 60.0;
  static const double panelHeight = 120.0;

  static const double borderWidth = 5.0;

  OverlayShape _overlayShape = OverlayShape.circle;
  double _overlayCircleSize = defaultSize;
  double _overlayWidth = defaultSize;
  double _overlayHeight = defaultSize;
  bool _showControls = true;

  Offset _dragStart = Offset.zero;
  double _initialWidth = defaultSize;
  double _initialHeight = defaultSize;
  double _initialSize = defaultSize;

  String? _portName;
  bool _isResizing = false;
  bool _loadedSettings = false;

  Future<void> _fitWindowSize(
      {double width = defaultSize,
      double height = defaultSize,
      bool isResizing = false}) async {
    try {
      await FlutterOverlayWindow.resizeOverlay(
          width.toInt(), height.toInt(), !isResizing);
    } catch (e) {
      // Overlay service may not be ready yet; retry after a short delay.
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      try {
        await FlutterOverlayWindow.resizeOverlay(
            width.toInt(), height.toInt(), !isResizing);
      } catch (_) {}
    }
  }

  void _startHorizontalResize(DragStartDetails details) {
    _initialWidth = _overlayWidth;
    _dragStart = details.globalPosition;
    setState(() {
      _isResizing = true;
    });
  }

  void _updateHorizontalResize(DragUpdateDetails details) {
    final delta = (details.globalPosition - _dragStart).dx;
    setState(() {
      _overlayWidth = (_initialWidth + delta).clamp(minSize, maxSize);
    });
  }

  void _endHorizontalResize(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
  }

  void _startVerticalResize(DragStartDetails details) {
    _initialHeight = _overlayHeight;
    _dragStart = details.globalPosition;
    setState(() {
      _isResizing = true;
    });
  }

  void _updateVerticalResize(DragUpdateDetails details) {
    final delta = (details.globalPosition - _dragStart).dy;
    setState(() {
      _overlayHeight = (_initialHeight + delta).clamp(minSize, maxSize);
    });
  }

  void _endVerticalResize(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
    // _resizeBack();
  }

  void _startCircleResize(DragStartDetails details) {
    _initialSize = _overlayCircleSize;
    _dragStart = details.globalPosition;
    setState(() {
      _isResizing = true;
    });
  }

  void _updateCircleResize(DragUpdateDetails details) {
    final delta = (details.globalPosition - _dragStart).dy;
    setState(() {
      _overlayCircleSize = (_initialSize + delta).clamp(minSize, maxSize);
      _overlayWidth = _overlayCircleSize;
      _overlayHeight = _overlayCircleSize;
    });
  }

  void _endCircleResize(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
  }

  void _handleOverlayMessage(dynamic event) {
    if (event is! Map) return;
    setState(() {
      if (event['portName'] != null) {
        _portName = event['portName'];
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _closeOverlay() async {
    OverlayPosition position = await FlutterOverlayWindow.getOverlayPosition();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('overlayWidth', _overlayWidth);
    await prefs.setDouble('overlayHeight', _overlayHeight);
    await prefs.setDouble('overlayCircleSize', _overlayCircleSize);
    await prefs.setString('overlayShape', _overlayShape.toString());
    await prefs.setDouble('overlayWinsPosX', position.x);
    await prefs.setDouble('overlayWinsPosY', position.y);

    setState(() {
      _loadedSettings = false;
    });

    final SendPort? sendPort = IsolateNameServer.lookupPortByName(_portName!);
    sendPort?.send({'action': 'close_overlay'});
    FlutterOverlayWindow.closeOverlay();
  }

  void _toggleShape() {
    setState(() {
      _overlayShape = _overlayShape == OverlayShape.circle
          ? OverlayShape.square
          : OverlayShape.circle;
      if (_overlayShape == OverlayShape.circle) {
        _overlayCircleSize = min(_overlayWidth, _overlayHeight);
      }
      _overlayWidth = _overlayCircleSize;
      _overlayHeight = _overlayCircleSize;
    });
  }

  Widget _buildResizeHandle({
    required GestureDragStartCallback onStart,
    required GestureDragUpdateCallback onUpdate,
    required GestureDragEndCallback onEnd,
    required Widget child,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: onStart,
      onVerticalDragUpdate: onUpdate,
      onVerticalDragEnd: onEnd,
      child: child,
    );
  }

  Widget _buildHorizontalResizeHandle({
    required GestureDragStartCallback onStart,
    required GestureDragUpdateCallback onUpdate,
    required GestureDragEndCallback onEnd,
    required Widget child,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: onStart,
      onHorizontalDragUpdate: onUpdate,
      onHorizontalDragEnd: onEnd,
      child: child,
    );
  }

  Widget _buildOverlayContent() {
    if (_overlayShape == OverlayShape.circle) {
      return SizedBox(
        width: _overlayCircleSize + resizeHandleSize * 2,
        height: _overlayCircleSize + resizeHandleSize * 2,
        child: Stack(
          children: [
            Positioned(
              left: resizeHandleSize,
              top: resizeHandleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: Container(
                  width: _overlayCircleSize,
                  height: _overlayCircleSize,
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
                      child: Divider(color: Colors.white54, thickness: 2),
                    ),
                  ),
                ),
                onStart: _startCircleResize,
                onUpdate: _updateCircleResize,
                onEnd: _endCircleResize,
              ),
            ),
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
                    child: VerticalDivider(color: Colors.white54, thickness: 2),
                  ),
                ),
              ),
              onStart: _startHorizontalResize,
              onUpdate: _updateHorizontalResize,
              onEnd: _endHorizontalResize,
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
                    child: Divider(color: Colors.white54, thickness: 2),
                  ),
                ),
              ),
              onStart: _startVerticalResize,
              onUpdate: _updateVerticalResize,
              onEnd: _endVerticalResize,
            ),
          ),
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

  IconButton _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        tooltip: tooltip);
  }

  void loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _overlayWidth = prefs.getDouble('overlayWidth') ?? defaultSize;
      _overlayHeight = prefs.getDouble('overlayHeight') ?? defaultSize;
      _overlayCircleSize = prefs.getDouble('overlayCircleSize') ?? defaultSize;
      String? shapeStr = prefs.getString('overlayShape');
      if (shapeStr != null) {
        _overlayShape = shapeStr == 'OverlayShape.circle'
            ? OverlayShape.circle
            : OverlayShape.square;
      }
      final overlayWinsPosX = prefs.getDouble('overlayWinsPosX') ?? 0;
      final overlayWinsPosY = prefs.getDouble('overlayWinsPosY') ?? 0;
      print("{$overlayWinsPosX} {$overlayWinsPosY}");
      FlutterOverlayWindow.moveOverlay(
        OverlayPosition(
          overlayWinsPosX,
          overlayWinsPosY,
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen(_handleOverlayMessage);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedSettings) {
      loadSavedSettings();
      setState(() {
        _loadedSettings = true;
      });
    }

    final shapeWidth = _overlayWidth + resizeHandleSize * 2;
    final shapeHeight = _overlayHeight + resizeHandleSize * 2;
    final windowWidth = shapeWidth + panelWidth;
    final windowHeight = max(shapeHeight, panelHeight);

    _fitWindowSize(
        width: windowWidth, height: windowHeight, isResizing: _isResizing);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: windowWidth,
        height: windowHeight,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: _buildOverlayContent(),
            ),
            if (_showControls) _buildControlsPanel(windowHeight),
          ],
        ),
      ),
    );
  }
}
