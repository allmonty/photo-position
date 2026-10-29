import 'dart:async';

import 'package:photo_position/data/services/overlay_host.dart';

class FakeOverlayHost implements OverlayHost {
  bool permissionGranted = true;
  bool grantOnRequest = false;
  Object? showError;
  int showCalls = 0;
  int requestCalls = 0;
  bool disposed = false;
  final List<Map<String, Object?>> sent = [];
  final StreamController<void> _closed = StreamController<void>.broadcast();

  /// The overlay's own close button was tapped.
  void closeFromOverlay() => _closed.add(null);

  @override
  Stream<void> get closedByOverlay => _closed.stream;

  @override
  Future<bool> isPermissionGranted() async => permissionGranted;

  @override
  Future<bool> requestPermission() async {
    requestCalls++;
    permissionGranted = grantOnRequest;
    return grantOnRequest;
  }

  @override
  Future<void> show() async {
    showCalls++;
    if (showError != null) throw showError!;
  }

  @override
  Future<void> send(Map<String, Object?> message) async => sent.add(message);

  @override
  void dispose() => disposed = true;
}
