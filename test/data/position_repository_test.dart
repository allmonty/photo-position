import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/data/repositories/position_repository.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const screen = Size(400, 800);
  const g = OverlayGeometry(
      left: 100, top: 150, width: 200, height: 120, shape: OverlayShape.circle);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('current geometry round-trips; empty storage gives null', () async {
    final repo = SharedPreferencesPositionRepository();
    expect(await repo.loadCurrent(screen: screen), isNull);
    const saved = PositionSlot(geometry: g, screen: screen);
    await repo.saveCurrent(saved);
    expect(await repo.loadCurrent(screen: screen), saved);
  });

  test('corrupt stored json is ignored', () async {
    SharedPreferences.setMockInitialValues({
      'overlayGeometry': '{not json',
      'positionSlot1': '{"geometry": 3}',
    });
    final repo = SharedPreferencesPositionRepository();
    expect(await repo.loadCurrent(screen: screen), isNull);
    expect(await repo.loadSlots(), [null, null, null]);
  });

  test('slots save, load and clear independently', () async {
    final repo = SharedPreferencesPositionRepository();
    const slot = PositionSlot(geometry: g, screen: screen);
    await repo.saveSlot(1, slot);
    expect(await repo.loadSlots(), [null, slot, null]);
    await repo.saveSlot(1, null);
    expect(await repo.loadSlots(), [null, null, null]);
    expect(() => repo.saveSlot(3, slot), throwsRangeError);
  });

  test('migrates the legacy centre-offset keys', () async {
    SharedPreferences.setMockInitialValues({
      'overlayWinsPosX': 30.0,
      'overlayWinsPosY': -190.0,
      'overlayWidth': 200.0,
      'overlayHeight': 120.0,
      'overlayShape': 'OverlayShape.square',
    });
    final migrated =
        await SharedPreferencesPositionRepository().loadCurrent(screen: screen);
    expect(
      migrated?.geometry,
      const OverlayGeometry(
          left: 100,
          top: 150,
          width: 200,
          height: 120,
          shape: OverlayShape.square),
    );
  });
}
