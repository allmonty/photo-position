import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:photo_position/data/repositories/position_repository.dart';
import 'package:photo_position/domain/models/position_slot.dart';

/// The three saved positions shown on the home screen.
///
/// "Current" is whatever the overlay last persisted (it saves after every
/// drag, resize and shape change), so saving a slot is a plain copy.
class SlotsViewModel extends ChangeNotifier {
  SlotsViewModel(
      {required PositionRepository repository, required Size Function() screen})
      : _repository = repository,
        _screen = screen;

  final PositionRepository _repository;
  final Size Function() _screen;
  List<PositionSlot?> _slots =
      List<PositionSlot?>.filled(PositionRepository.slotCount, null);
  bool _hasCurrent = false;

  List<PositionSlot?> get slots => _slots;

  /// False until the overlay has been positioned at least once.
  bool get canSave => _hasCurrent;

  Future<void> load() async {
    _slots = await _repository.loadSlots();
    _hasCurrent = await _repository.loadCurrent(screen: _screen()) != null;
    notifyListeners();
  }

  /// Copies the overlay's current position into slot [index].
  Future<void> saveCurrentTo(int index) async {
    final PositionSlot? current =
        await _repository.loadCurrent(screen: _screen());
    if (current == null) return;
    await _repository.saveSlot(index, current);
    await load();
  }

  Future<void> clear(int index) async {
    await _repository.saveSlot(index, null);
    await load();
  }

  /// Makes slot [index] the current position (what a freshly started overlay
  /// opens at) and returns it so a running overlay can be told to move.
  Future<PositionSlot?> select(int index) async {
    final PositionSlot? slot = _slots[index];
    if (slot != null) await _repository.saveCurrent(slot);
    return slot;
  }
}
