import 'dart:ui';

import 'package:photo_position/data/repositories/position_repository.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/position_slot.dart';

class MemoryPositionRepository implements PositionRepository {
  OverlayGeometry? current;
  final List<PositionSlot?> slots =
      List<PositionSlot?>.filled(PositionRepository.slotCount, null);

  @override
  Future<OverlayGeometry?> loadCurrent({required Size screen}) async => current;

  @override
  Future<void> saveCurrent(OverlayGeometry geometry) async =>
      current = geometry;

  @override
  Future<List<PositionSlot?>> loadSlots() async => List.of(slots);

  @override
  Future<void> saveSlot(int index, PositionSlot? slot) async =>
      slots[index] = slot;
}
