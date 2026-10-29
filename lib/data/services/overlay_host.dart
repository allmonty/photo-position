import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Port the main app listens on; the overlay tells it when it has closed.
const String overlayPortName = 'photo_position_overlay_port';

/// The main app's side of the overlay: permission, start, and messages to and
/// from the overlay engine. Abstract so the home screen can be tested without
/// platform channels. (The overlay's own side is `OverlayService`.)
abstract class OverlayHost {
  Future<bool> isPermissionGranted();
  Future<bool> requestPermission();
  Future<void> show();

  /// Sends a message to the running overlay (see `OverlayScreen`).
  Future<void> send(Map<String, Object?> message);

  /// Fires when the overlay closed itself (its own close button).
  Stream<void> get closedByOverlay;
  void dispose();
}

class PluginOverlayHost implements OverlayHost {
  PluginOverlayHost() {
    // registerPortWithName silently fails -- leaving the previous mapping in
    // place -- if the name is taken (e.g. after a hot reload), which would
    // point the overlay's notifications at a disposed port.
    IsolateNameServer.removePortNameMapping(overlayPortName);
    IsolateNameServer.registerPortWithName(_port.sendPort, overlayPortName);
    _port.listen((Object? message) {
      if (message is Map && message['action'] == 'close_overlay') {
        _closed.add(null);
      }
    });
  }

  final ReceivePort _port = ReceivePort();
  final StreamController<void> _closed = StreamController<void>.broadcast();

  @override
  Stream<void> get closedByOverlay => _closed.stream;

  @override
  Future<bool> isPermissionGranted() =>
      FlutterOverlayWindow.isPermissionGranted();

  @override
  Future<bool> requestPermission() async =>
      await FlutterOverlayWindow.requestPermission() ?? false;

  @override
  Future<void> show() async {
    await FlutterOverlayWindow.showOverlay(
      flag: OverlayFlag.defaultFlag,
      overlayTitle: 'Photo Position Overlay',
      overlayContent: 'Use this overlay to position your camera',
      enableDrag: true,
    );
    // The overlay engine now exists; let it pull the real screen geometry.
    try {
      await const MethodChannel('photo_position/host')
          .invokeMethod<void>('attachScreenBridge');
    } on MissingPluginException {
      // Not running on Android: nothing to attach.
    }
    // On a second start the overlay engine and its Dart state are still
    // alive from the first (only the window was closed), so tell it to open.
    // On the first start nobody listens yet; initState starts it then.
    await send({'action': 'open'});
  }

  @override
  Future<void> send(Map<String, Object?> message) =>
      FlutterOverlayWindow.shareData(message);

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping(overlayPortName);
    _port.close();
    unawaited(_closed.close());
  }
}
