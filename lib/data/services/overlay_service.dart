import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// The overlay window as seen by the overlay's view model: where the native
/// window is, how big it is, and how big the screen is. Abstract so the
/// rotation behaviour can be tested without a device.
///
/// All values are dp. Positions use the plugin's convention: the offset of
/// the window centre from the screen centre (see `toPluginOffset`).
abstract class OverlayService {
  /// Best-known screen size; changes are announced on [screenChanges].
  Size get screen;

  /// Parent-frame centre minus screen centre (see `toPluginOffset`).
  Offset get centreShift;
  Stream<Size> get screenChanges;

  /// Asks the native side for the current [screen]/[centreShift], which the
  /// overlay engine cannot work out itself.
  Future<void> refreshScreen();

  Future<bool> isActive();
  Future<Offset> getPosition();
  Future<void> move(Offset pluginOffset);

  /// [enableDrag] must be false while a resize handle is being dragged,
  /// otherwise the native window drags along with the handle.
  Future<void> resize(Size window, {required bool enableDrag});
  Future<void> close();
}

class PluginOverlayService implements OverlayService {
  PluginOverlayService({Size? initialScreen})
      : _screen = initialScreen ?? _displaySize() {
    _channel.setMethodCallHandler(_onCall);
  }

  /// Pushed by `ScreenSizeBridge.kt` on every configuration change, because
  /// the overlay engine's own `Display.size` stays at its first value.
  static const MethodChannel _channel = MethodChannel('photo_position/screen');

  final StreamController<Size> _changes = StreamController<Size>.broadcast();
  Size _screen;
  Offset _centreShift = Offset.zero;

  @override
  Size get screen => _screen;

  @override
  Offset get centreShift => _centreShift;

  @override
  Stream<Size> get screenChanges => _changes.stream;

  Future<void> _onCall(MethodCall call) async {
    if (call.method != 'screenChanged') return;
    _update(call.arguments as Map<Object?, Object?>);
    _changes.add(_screen);
  }

  void _update(Map<Object?, Object?> args) {
    double n(String k) => (args[k]! as num).toDouble();
    _screen = Size(n('width'), n('height'));
    _centreShift = Offset(n('shiftX'), n('shiftY'));
  }

  @override
  Future<void> refreshScreen() async {
    final Map<Object?, Object?>? reply = await _whenReady(
      () => _channel.invokeMapMethod<Object?, Object?>('getScreen'),
    );
    if (reply != null) _update(reply);
  }

  static Size _displaySize() {
    final Display d = PlatformDispatcher.instance.views.first.display;
    return d.size / d.devicePixelRatio;
  }

  /// The plugin registers its channel in the overlay engine only after
  /// `overlayMain` has started running, so early calls throw
  /// [MissingPluginException]; retry until it is there.
  static Future<T> _whenReady<T>(Future<T> Function() call) async {
    for (var i = 0;; i++) {
      try {
        return await call();
      } on MissingPluginException {
        if (i >= 30) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  @override
  Future<bool> isActive() => _whenReady(FlutterOverlayWindow.isActive);

  @override
  Future<Offset> getPosition() async {
    final OverlayPosition p =
        await _whenReady(FlutterOverlayWindow.getOverlayPosition);
    return Offset(p.x, p.y);
  }

  @override
  Future<void> move(Offset pluginOffset) async {
    await FlutterOverlayWindow.moveOverlay(
      OverlayPosition(
          pluginOffset.dx.roundToDouble(), pluginOffset.dy.roundToDouble()),
    );
  }

  @override
  Future<void> resize(Size window, {required bool enableDrag}) async {
    await FlutterOverlayWindow.resizeOverlay(
        window.width.round(), window.height.round(), enableDrag);
  }

  @override
  Future<void> close() async {
    await _whenReady(FlutterOverlayWindow.closeOverlay);
  }
}
