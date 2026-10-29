import 'dart:async';
import 'dart:ui';

import 'package:photo_position/data/services/overlay_service.dart';

/// Behaves like the native window: it keeps the plugin's centre-relative
/// offset and size, and [visibleRect] reports where that really is on the
/// current screen. Rotating changes the screen but, like Android, leaves the
/// stored offset alone -- which is exactly the situation that used to make
/// the overlay jump.
class FakeOverlayService implements OverlayService {
  FakeOverlayService({Size screen = const Size(400, 800)}) : _screen = screen;

  Size _screen;
  final StreamController<Size> _changes = StreamController<Size>.broadcast();

  bool active = true;
  bool closed = false;
  Offset offset = Offset.zero;
  Size window = const Size(300, 300);
  bool dragEnabled = true;
  int moveCalls = 0;

  /// Makes the next [resize] throw, like the plugin before its channel exists.
  bool failNextResize = false;

  @override
  Size get screen => _screen;

  @override
  Stream<Size> get screenChanges => _changes.stream;

  /// Rotate the phone: new screen size, same native window params.
  void rotateTo(Size screen) {
    _screen = screen;
    _changes.add(screen);
  }

  /// The window's top-left on screen, as the WindowManager would place it.
  Rect get visibleRect => Rect.fromLTWH(
        offset.dx + _screen.width / 2 - window.width / 2,
        offset.dy + _screen.height / 2 - window.height / 2,
        window.width,
        window.height,
      );

  /// Simulates the user dragging the window natively by [delta].
  void dragBy(Offset delta) => offset += delta;

  @override
  Future<bool> isActive() async => active;

  @override
  Future<Offset> getPosition() async => offset;

  @override
  Future<void> move(Offset pluginOffset) async {
    moveCalls++;
    offset = pluginOffset;
  }

  @override
  Future<void> resize(Size window, {required bool enableDrag}) async {
    if (failNextResize) {
      failNextResize = false;
      throw StateError('plugin not ready');
    }
    this.window = window;
    dragEnabled = enableDrag;
  }

  @override
  Future<void> close() async => closed = true;
}
