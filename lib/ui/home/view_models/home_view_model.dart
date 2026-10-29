import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:photo_position/data/services/overlay_host.dart';
import 'package:photo_position/domain/models/overlay_style.dart';
import 'package:photo_position/domain/models/position_slot.dart';

/// Starting and stopping the overlay from the main app. Methods that can fail
/// return a message for the user (null on success) instead of throwing.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required OverlayHost host}) : _host = host {
    _closedSub = _host.closedByOverlay.listen((_) {
      _active = false;
      notifyListeners();
    });
  }

  final OverlayHost _host;
  late final StreamSubscription<void> _closedSub;
  bool _active = false;

  bool get isOverlayActive => _active;

  Future<String?> start() async {
    try {
      if (!await _host.isPermissionGranted()) {
        // Android shows its own settings screen; the user taps Start again afterwards.
        return await _host.requestPermission()
            ? null
            : 'Overlay permission is required to use this app';
      }
      await _host.show();
      _active = true;
      notifyListeners();
      return null;
    } on Object catch (e) {
      return 'Failed to show overlay: $e';
    }
  }

  /// Asks the overlay to close itself rather than closing the window
  /// directly: only the overlay can save its latest position first.
  Future<String?> stop() async {
    try {
      await _host.send({'action': 'close_overlay_and_reset'});
      _active = false;
      notifyListeners();
      return null;
    } on Object catch (e) {
      return 'Failed to close overlay: $e';
    }
  }

  /// A slot became the current position; a running overlay moves there now,
  /// a stopped one will open there.
  Future<void> moveOverlayTo(PositionSlot slot) async {
    if (!_active) return;
    await _host.send({'action': 'load_position', 'slot': slot.toJson()});
  }

  /// The border changed on the home screen; a running overlay follows live
  /// (a stopped one reads the saved style when it starts).
  Future<void> updateStyle(OverlayStyle style) async {
    if (!_active) return;
    await _host.send({'action': 'set_style', 'style': style.toJson()});
  }

  @override
  void dispose() {
    unawaited(_closedSub.cancel());
    _host.dispose();
    super.dispose();
  }
}
