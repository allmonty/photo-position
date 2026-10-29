import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:photo_position/data/repositories/position_repository.dart';
import 'package:photo_position/data/services/overlay_service.dart';
import 'package:photo_position/domain/geometry.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/position_slot.dart';

enum ResizeAxis { width, height, both }

/// State and behaviour of the overlay window.
///
/// The shape is pinned to the phone's glass: its rectangle is stored in the
/// phone's natural orientation ("glass" coordinates) and never changes when
/// the phone turns. [geometry] is that same physical spot as the rotated
/// display draws it. Every change -- start, resize, rotation, loading a
/// slot -- goes through [_apply], which pushes size and position of
/// [geometry] to the native window.
class OverlayViewModel extends ChangeNotifier {
  OverlayViewModel({
    required OverlayService service,
    required PositionRepository repository,
    this.activePollInterval = const Duration(milliseconds: 500),
  })  : _service = service,
        _repository = repository {
    _screenSub = _service.screenChanges.listen(_onScreenChanged);
  }

  final OverlayService _service;
  final PositionRepository _repository;
  final Duration activePollInterval;
  late final StreamSubscription<Size> _screenSub;

  OverlayGeometry? _stored;
  bool _showControls = true;
  bool _isResizing = false;
  bool _closed = false;
  OverlayGeometry? _resizeStart;
  Future<void> _pending = Future<void>.value();

  Size get _natural => naturalScreen(_service.screen, _service.rotation);

  /// The shape as the display draws it now (screen dp, rotated from the
  /// glass position). Null until [start] has loaded or created one.
  OverlayGeometry? get geometry {
    final OverlayGeometry? g = _stored;
    if (g == null) return null;
    return glassToDisplay(g, _natural, _service.rotation)
        .clampedTo(_service.screen);
  }

  /// Edits happen on the rotated display; keep the result in glass coordinates.
  void _setDisplay(OverlayGeometry d) {
    _stored = displayToGlass(d, _natural, _service.rotation);
  }

  bool get showControls => _showControls;
  bool get isResizing => _isResizing;
  bool get closed => _closed;

  Future<void> start() async {
    try {
      await _service.refreshScreen();
    } on Object catch (e) {
      debugPrint('Using the engine\'s own screen size: $e');
    }
    final PositionSlot? saved =
        await _repository.loadCurrent(screen: _service.screen);
    if (saved != null) {
      _stored = saved.geometry.clampedTo(_natural);
    } else {
      _setDisplay(OverlayGeometry(
        left: (_service.screen.width - 200) / 2,
        top: (_service.screen.height - 200) / 2,
        width: 200,
        height: 200,
        shape: OverlayShape.circle,
      ));
    }
    notifyListeners();
    // The native window is created asynchronously by the main app.
    while (!await _service.isActive()) {
      await Future<void>.delayed(activePollInterval);
    }
    await _apply();
  }

  Future<void> _onScreenChanged(Size screen) => _apply();

  /// Serialised so a rotation arriving mid-resize cannot interleave with it.
  Future<void> _apply() => _pending = _pending.then((_) async {
        final OverlayGeometry? g = geometry;
        if (g == null || _closed) return;
        try {
          await _service.resize(windowSizeFor(g), enableDrag: !_isResizing);
          await _service.move(toPluginOffset(g, _service.screen,
              centreShift: _service.centreShift));
        } on Object catch (e) {
          // Must not escape: a failed future would poison every later apply.
          debugPrint('Applying overlay geometry failed: $e');
        }
      });

  Future<void> _persist() async {
    final OverlayGeometry? g = _stored;
    if (g != null) {
      await _repository
          .saveCurrent(PositionSlot(geometry: g, screen: _natural));
    }
  }

  /// Call when a native drag ends: the plugin moved the window, so read the
  /// new position back into [geometry].
  Future<void> dragEnded() async {
    if (_stored == null || _closed) return;
    await _pending;
    final Offset pos = await _service.getPosition();
    // Re-read after the awaits: a tap on the shape toggle also ends with a
    // pointer-up, and must not be overwritten with the shape from before it.
    final OverlayGeometry g = geometry!;
    _setDisplay(fromPluginOffset(
      pos,
      _service.screen,
      centreShift: _service.centreShift,
      width: g.width,
      height: g.height,
      shape: g.shape,
    ));
    notifyListeners();
    await _persist();
  }

  void beginResize() {
    _resizeStart = geometry;
    _isResizing = true;
    notifyListeners();
    unawaited(_apply());
  }

  /// [delta] is the total drag distance since [beginResize]. The top-left
  /// corner stays put, so the shape grows right/down like the handles imply.
  void updateResize(ResizeAxis axis, double delta) {
    final OverlayGeometry? s = _resizeStart;
    if (s == null) return;
    double clamp(double v) =>
        v.clamp(OverlayGeometry.minSize, OverlayGeometry.maxSize);
    _setDisplay(OverlayGeometry(
      left: s.left,
      top: s.top,
      width: axis == ResizeAxis.height ? s.width : clamp(s.width + delta),
      height: axis == ResizeAxis.width ? s.height : clamp(s.height + delta),
      shape: s.shape,
    ));
    notifyListeners();
    unawaited(_apply());
  }

  Future<void> endResize() async {
    _isResizing = false;
    _resizeStart = null;
    notifyListeners();
    await _apply();
    await _persist();
  }

  Future<void> toggleShape() async {
    final OverlayGeometry g = geometry!;
    final bool toCircle = g.shape == OverlayShape.square;
    final double side = min(g.width, g.height);
    _setDisplay(OverlayGeometry(
      left: g.left,
      top: g.top,
      width: toCircle ? side : g.width,
      height: toCircle ? side : g.height,
      shape: toCircle ? OverlayShape.circle : OverlayShape.square,
    ));
    notifyListeners();
    await _apply();
    await _persist();
  }

  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  /// Moves the overlay to a saved spot on the glass. Slots are in glass
  /// coordinates, so the current rotation does not matter; only a slot from
  /// a different phone is clamped onto this one.
  Future<void> loadPosition(PositionSlot slot) async {
    _stored = slot.geometry.clampedTo(_natural);
    notifyListeners();
    await _apply();
    await _persist();
  }

  Future<void> close() async {
    if (_closed) return;
    await _pending;
    await _persist();
    _closed = true;
    notifyListeners();
    await _service.close();
  }

  @override
  void dispose() {
    unawaited(_screenSub.cancel());
    super.dispose();
  }
}
