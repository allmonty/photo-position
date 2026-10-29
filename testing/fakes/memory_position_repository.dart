import 'dart:ui';

import 'package:photo_position/data/repositories/position_repository.dart';
import 'package:photo_position/domain/models/overlay_style.dart';
import 'package:photo_position/domain/models/position_slot.dart';

class MemoryPositionRepository implements PositionRepository {
  PositionSlot? current;
  OverlayStyle style = const OverlayStyle();
  final List<PositionSlot?> slots =
      List<PositionSlot?>.filled(PositionRepository.slotCount, null);

  @override
  Future<PositionSlot?> loadCurrent({required Size screen}) async => current;

  @override
  Future<void> saveCurrent(PositionSlot position) async => current = position;

  @override
  Future<List<PositionSlot?>> loadSlots() async => List.of(slots);

  @override
  Future<OverlayStyle> loadStyle() async => style;

  @override
  Future<void> saveStyle(OverlayStyle style) async => this.style = style;

  @override
  Future<void> saveSlot(int index, PositionSlot? slot) async =>
      slots[index] = slot;
}
