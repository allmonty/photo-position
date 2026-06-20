import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:photo_position/theme.dart';

enum OverlayShape { circle, square }

enum OrientationState {
  portraitUp,
  portraitDown,
  landscapeLeft,
  landscapeRight,
  unknown
}

/// Degrees clockwise from portraitUp, used to compute the rotation angle
/// between two orientations.
double _orientationAngleDegrees(OrientationState o) {
  switch (o) {
    case OrientationState.portraitUp:
      return 0;
    case OrientationState.landscapeRight:
      return 90;
    case OrientationState.portraitDown:
      return 180;
    case OrientationState.landscapeLeft:
      return 270;
    case OrientationState.unknown:
      return 0;
  }
}

/// Computes the overlay's new center-relative offset after the screen
/// rotates from [before] to [after]. The overlay is meant to stay glued to
/// the physical device, like a sticker on the glass, so this rotates the
/// offset vector by the angle between the two orientations -- it does NOT
/// try to preserve the offset's position relative to the screen's own
/// (logical, upright) corners, which is a different point once the device
/// has physically turned.
///
/// [offsetX]/[offsetY] is the overlay's current offset from the screen
/// center (this is what `FlutterOverlayWindow.getOverlayPosition()` returns,
/// since the overlay window uses `Gravity.CENTER`).
///
/// Returns `null` when no repositioning is needed: an unknown or unchanged
/// orientation.
Offset? transposeOverlayOffset({
  required OrientationState before,
  required OrientationState after,
  required double offsetX,
  required double offsetY,
}) {
  if (before == OrientationState.unknown ||
      after == OrientationState.unknown ||
      before == after) {
    return null;
  }

  double deltaDegrees =
      _orientationAngleDegrees(after) - _orientationAngleDegrees(before);
  while (deltaDegrees <= -180) {
    deltaDegrees += 360;
  }
  while (deltaDegrees > 180) {
    deltaDegrees -= 360;
  }

  final double radians = deltaDegrees * pi / 180.0;
  final double cosA = cos(radians);
  final double sinA = sin(radians);

  // OverlayPosition.toMap() truncates toward zero (x.toInt()), which biases
  // negative offsets. Round here so we control the rounding ourselves and
  // avoid that truncation drift on every rotation.
  return Offset(
    (offsetX * cosA - offsetY * sinA).roundToDouble(),
    (offsetX * sinA + offsetY * cosA).roundToDouble(),
  );
}

/// The overlay window is anchored, via `Gravity.CENTER`, at its own
/// geometric center -- but the shape (square/circle) the user actually
/// sees and drags is not centered within that window, because the window
/// also reserves space for the control panel to its right (see build() /
/// _buildOverlayContent()). This returns the shape's true visual center
/// relative to the window's own center.
///
/// `transposeOverlayOffset` scales an offset *from the screen center*.
/// `getOverlayPosition()`/`moveOverlay()` only deal in the window's offset,
/// not the shape's true offset, so scaling the window's offset directly
/// is off by this constant amount -- it has to be added in before scaling
/// and subtracted back out after.
Offset overlayContentCenterOffset({
  required double shapeWidth,
  required double shapeHeight,
  required double panelWidth,
  required double panelHeight,
}) {
  final double windowWidth = shapeWidth + panelWidth;
  final double windowHeight = shapeHeight > panelHeight ? shapeHeight : panelHeight;
  return Offset(
    shapeWidth / 2 - windowWidth / 2,
    shapeHeight / 2 - windowHeight / 2,
  );
}

/// Composes [transposeOverlayOffset] with the window/content correction
/// from [overlayContentCenterOffset]: [windowOffset] (what
/// `getOverlayPosition()`/`moveOverlay()` deal in) and the shape's true
/// visual offset are not the same point, so [contentOffset] has to be
/// added in before scaling and subtracted back out after.
///
/// Returns `null` when no repositioning is needed -- see
/// [transposeOverlayOffset].
Offset? transposeWindowOffset({
  required Offset windowOffset,
  required Offset contentOffset,
  required OrientationState before,
  required OrientationState after,
}) {
  final Offset? rotatedTrueOffset = transposeOverlayOffset(
    before: before,
    after: after,
    offsetX: windowOffset.dx + contentOffset.dx,
    offsetY: windowOffset.dy + contentOffset.dy,
  );
  if (rotatedTrueOffset == null) return null;
  return Offset(
    (rotatedTrueOffset.dx - contentOffset.dx).roundToDouble(),
    (rotatedTrueOffset.dy - contentOffset.dy).roundToDouble(),
  );
}

// Keys for widgets that tests need to find and drive directly (e.g.
// simulating a drag on a resize handle); not used for any production logic.
const Key overlayShapeContainerKey = ValueKey('overlayShapeContainer');
const Key horizontalResizeHandleKey = ValueKey('horizontalResizeHandle');
const Key verticalResizeHandleKey = ValueKey('verticalResizeHandle');
const Key circleResizeHandleKey = ValueKey('circleResizeHandle');

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
  bool _restoredPosition = false;
  OrientationState _currentOrientation = OrientationState.unknown;
  OrientationState? _pendingOrientation;
  Timer? _orientationDebounce;
  bool _isTransposing = false;
  StreamSubscription? _overlaySubscription;
  StreamSubscription? _orientationSub;

  // resizeOverlay's third argument is enableDrag, hence !isResizing: while a
  // resize handle is being dragged, window-level drag must be disabled so
  // it doesn't also move the whole window; it's re-enabled once the resize
  // gesture ends.
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

  // Three independent drag handlers below: horizontal (square width),
  // vertical (square height), and circle (uniform diagonal size). They only
  // mutate in-memory state for live feedback while dragging; the result is
  // persisted to shared_preferences when the overlay closes (_closeOverlay),
  // not after each individual resize gesture.
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

  // portName arrives once, right after the main app starts the overlay
  // (see HomeScreen._showOverlay) -- it's used here as the signal that the
  // cross-isolate connection is up, which is why restoring the saved
  // position is gated on it rather than running unconditionally.
  void _handleOverlayMessage(dynamic event) {
    if (event is! Map) return;
    setState(() {
      if (event['portName'] != null) {
        _portName = event['portName'];
      }
      if (event['action'] == "close_overlay_and_reset") {
        _closeOverlay();
      }
    });

    if (event['portName'] != null) {
      _restoreOverlayPosition();
    }
  }

  Future<void> _restoreOverlayPosition() async {
    // Both loadSavedSettings() and _handleOverlayMessage() call this -- the
    // latter fires when portName arrives, which in production happens while
    // the former's restore (triggered from initState) is typically still
    // polling. Without this guard both would race to read prefs and call
    // moveOverlay(), and if an orientation change writes new prefs in
    // between, the second call can snap the overlay back to a stale
    // pre-rotation position.
    if (!mounted || _restoredPosition) return;
    _restoredPosition = true;

    final prefs = await SharedPreferences.getInstance();
    final double savedX = prefs.getDouble('overlayWinsPosX') ?? 0;
    final double savedY = prefs.getDouble('overlayWinsPosY') ?? 0;

    print('Restoring overlay position to ($savedX, $savedY)');

    // Poll until the native window is completely active and ready.
    for (int i = 0; i < 20; i++) {
      if (!mounted) return;
      final isWindowActive = await FlutterOverlayWindow.isActive();
      if (isWindowActive) {
        // Wait for OS layout to settle
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          await FlutterOverlayWindow.moveOverlay(
            OverlayPosition(savedX, savedY),
          );
          print('Overlay moved to ($savedX, $savedY)');
        }
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _toggleShape() {
    setState(() {
      _overlayShape = _overlayShape == OverlayShape.circle
          ? OverlayShape.square
          : OverlayShape.circle;
      if (_overlayShape == OverlayShape.circle) {
        // A square resized to a non-uniform width/height can't become a
        // circle of the same footprint; use the smaller dimension so it
        // fits within whatever area the square occupied.
        _overlayCircleSize = min(_overlayWidth, _overlayHeight);
      }
      _overlayWidth = _overlayCircleSize;
      _overlayHeight = _overlayCircleSize;
    });
  }

  Widget _buildResizeHandle({
    Key? key,
    required GestureDragStartCallback onStart,
    required GestureDragUpdateCallback onUpdate,
    required GestureDragEndCallback onEnd,
    required Widget child,
  }) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: onStart,
      onVerticalDragUpdate: onUpdate,
      onVerticalDragEnd: onEnd,
      child: child,
    );
  }

  Widget _buildHorizontalResizeHandle({
    Key? key,
    required GestureDragStartCallback onStart,
    required GestureDragUpdateCallback onUpdate,
    required GestureDragEndCallback onEnd,
    required Widget child,
  }) {
    return GestureDetector(
      key: key,
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
                  key: overlayShapeContainerKey,
                  width: _overlayCircleSize,
                  height: _overlayCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kGold.withAlpha(200),
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
                key: circleResizeHandleKey,
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
                key: overlayShapeContainerKey,
                width: _overlayWidth,
                height: _overlayHeight,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(
                    color: kGold.withAlpha(200),
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
              key: horizontalResizeHandleKey,
              child: const SizedBox(
                width: resizeHandleSize,
                child: Center(
                  child: SizedBox(
                    width: 4,
                    height: 24,
                    child: VerticalDivider(color: kGold, thickness: 2),
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
              key: verticalResizeHandleKey,
              child: const SizedBox(
                height: resizeHandleSize,
                child: Center(
                  child: SizedBox(
                    height: 4,
                    width: 24,
                    child: Divider(color: kGold, thickness: 2),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: kCrimsonDark.withAlpha(230),
          border: Border.all(color: kGold.withAlpha(150), width: 1),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconButton(
                icon: Icons.close,
                tooltip: 'Close overlay',
                onPressed: _closeOverlay),
            Divider(color: kGold.withAlpha(120), height: 8),
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
        icon: Icon(icon, color: kGold),
        onPressed: onPressed,
        tooltip: tooltip);
  }

  Future<void> _closeOverlay() async {
    print('Closing overlay and saving position...');
    try {
      final position = await FlutterOverlayWindow.getOverlayPosition();
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setDouble('overlayWidth', _overlayWidth),
        prefs.setDouble('overlayHeight', _overlayHeight),
        prefs.setDouble('overlayCircleSize', _overlayCircleSize),
        prefs.setString('overlayShape', _overlayShape.toString()),
        prefs.setDouble('overlayWinsPosX', position.x),
        prefs.setDouble('overlayWinsPosY', position.y),
      ]);
      print('Position saved: (${position.x}, ${position.y})');
    } catch (e) {
      print('Failed to save position on close: $e');
    }

    if (_portName != null) {
      try {
        final SendPort? sendPort =
            IsolateNameServer.lookupPortByName(_portName!);
        sendPort?.send({'action': 'close_overlay'});
      } catch (e) {
        print('Error sending close message: $e');
      }
    }

    // Small delay to ensure preferences are flushed and message is sent
    await Future.delayed(const Duration(milliseconds: 100));
    await FlutterOverlayWindow.closeOverlay();
  }

  // _loadedSettings guards against running this twice (e.g. a second
  // initState during hot reload), which would otherwise re-trigger
  // _restoreOverlayPosition and risk a duplicate/conflicting moveOverlay
  // call while the first restore is still polling for the window to be
  // active.
  void loadSavedSettings() async {
    if (_loadedSettings) return;

    final prefs = await SharedPreferences.getInstance();
    final double savedWidth = prefs.getDouble('overlayWidth') ?? defaultSize;
    final double savedHeight = prefs.getDouble('overlayHeight') ?? defaultSize;
    final double savedCircleSize =
        prefs.getDouble('overlayCircleSize') ?? defaultSize;
    final String? shapeStr = prefs.getString('overlayShape');

    if (!mounted) return;

    setState(() {
      _overlayWidth = savedWidth;
      _overlayHeight = savedHeight;
      _overlayCircleSize = savedCircleSize;
      if (shapeStr == 'OverlayShape.circle') {
        _overlayShape = OverlayShape.circle;
      } else {
        _overlayShape = OverlayShape.square;
      }
      _loadedSettings = true;
    });

    _restoreOverlayPosition();
  }

  @override
  void initState() {
    super.initState();
    try {
      _overlaySubscription =
          FlutterOverlayWindow.overlayListener.listen(_handleOverlayMessage);
    } catch (e) {
      print('Caught listener error: $e');
    }
    loadSavedSettings();

    try {
      _orientationSub = accelerometerEventStream().listen((AccelerometerEvent event) {
        final double x = event.x;
        final double y = event.y;

        OrientationState orientation = OrientationState.unknown;

        // Classify orientation from which axis gravity is dominantly
        // pulling on. The 7.0 m/s^2 threshold (gravity is ~9.8 m/s^2) means
        // the device has to be held reasonably upright in that orientation,
        // not just tilted slightly, before a reading counts.
        if (y > 7.0) {
          orientation = OrientationState.portraitUp;
        } else if (y < -7.0) {
          orientation = OrientationState.portraitDown;
        } else if (x > 7.0) {
          orientation = OrientationState.landscapeLeft;
        } else if (x < -7.0) {
          orientation = OrientationState.landscapeRight;
        }

        if (orientation == OrientationState.unknown) return;

        if (_currentOrientation == OrientationState.unknown) {
          // First reading: adopt it directly, nothing to transpose yet.
          _currentOrientation = orientation;
          _pendingOrientation = null;
          _orientationDebounce?.cancel();
          return;
        }

        if (orientation == _currentOrientation) {
          // Sensor settled back to the already-applied orientation;
          // cancel any pending (now stale) transpose.
          _pendingOrientation = null;
          _orientationDebounce?.cancel();
          return;
        }

        // Debounce: rotation gestures fire many transient accelerometer
        // readings while the phone is turning (and the emulator's rotate
        // animation does the same). Only act once the reported orientation
        // has held steady for a short period, and never let two transpose
        // calls race each other reading/writing the overlay position.
        //
        // Only (re)start the timer when the candidate target actually
        // changes -- the accelerometer keeps emitting matching readings
        // long after the phone has settled, and restarting the timer on
        // every one of those would mean it never fires.
        if (_pendingOrientation == orientation) return;
        _pendingOrientation = orientation;
        _orientationDebounce?.cancel();
        _orientationDebounce =
            Timer(const Duration(milliseconds: 250), () {
          final target = _pendingOrientation;
          if (target == null || target == _currentOrientation) return;
          _applyOrientationChange(target);
        });
      });
    } catch (e) {
      print('Orientation listener error: $e');
    }
  }

  // Guards _transposeOverlayPosition's read-then-write of the overlay
  // position against overlapping calls: without _isTransposing, a second
  // orientation change arriving while the first transpose is still
  // in-flight could read a stale position and stomp on the first call's
  // result. Anything that arrives while busy is picked up via
  // _pendingOrientation once the current transpose finishes.
  Future<void> _applyOrientationChange(OrientationState target) async {
    if (_isTransposing) return;
    _isTransposing = true;
    try {
      final OrientationState before = _currentOrientation;
      await _transposeOverlayPosition(before, target);
      _currentOrientation = target;
    } finally {
      _isTransposing = false;
    }
    // If another orientation arrived while we were transposing, apply it now.
    final OrientationState? next = _pendingOrientation;
    if (next != null && next != _currentOrientation) {
      await _applyOrientationChange(next);
    }
  }

  @override
  void dispose() {
    _overlaySubscription?.cancel();
    _orientationSub?.cancel();
    _orientationDebounce?.cancel();
    super.dispose();
  }

  Future<void> _transposeOverlayPosition(
    OrientationState before,
    OrientationState after,
  ) async {
    try {
      final position = await FlutterOverlayWindow.getOverlayPosition();

      // getOverlayPosition()/moveOverlay() only deal in the window's
      // gravity-center offset, not the shape's true visual offset -- those
      // two differ by a constant amount because the window also reserves
      // space for the control panel. transposeWindowOffset corrects for
      // that (see overlayContentCenterOffset).
      final Offset contentOffset = overlayContentCenterOffset(
        shapeWidth: _overlayWidth + resizeHandleSize * 2,
        shapeHeight: _overlayHeight + resizeHandleSize * 2,
        panelWidth: panelWidth,
        panelHeight: panelHeight,
      );

      final Offset? newOffset = transposeWindowOffset(
        windowOffset: Offset(position.x, position.y),
        contentOffset: contentOffset,
        before: before,
        after: after,
      );
      if (newOffset == null) return;

      await FlutterOverlayWindow.moveOverlay(
          OverlayPosition(newOffset.dx, newOffset.dy));

      print("Transposed from $before to $after. "
          "Pos: (${position.x}, ${position.y}) -> "
          "(${newOffset.dx}, ${newOffset.dy})");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('overlayWinsPosX', newOffset.dx);
      await prefs.setDouble('overlayWinsPosY', newOffset.dy);
    } catch (e) {
      print('Error in _transpose: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shapeWidth = _overlayWidth + resizeHandleSize * 2;
    final shapeHeight = _overlayHeight + resizeHandleSize * 2;
    final windowWidth = shapeWidth + panelWidth;
    final windowHeight = max(shapeHeight, panelHeight);

    // Called on every build (not just on resize end) so the native overlay
    // window's actual size stays in sync with whatever the current
    // shape/size state computes it to be -- e.g. right after a saved size
    // is restored, before any resize gesture has happened.
    _fitWindowSize(
        width: windowWidth, height: windowHeight, isResizing: _isResizing);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: windowWidth,
        height: windowHeight,
        child: Stack(
          children: [
            _buildOverlayContent(),
            if (_showControls) _buildControlsPanel(windowHeight),
          ],
        ),
      ),
    );
  }
}
