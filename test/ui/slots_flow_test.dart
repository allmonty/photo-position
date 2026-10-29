import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/domain/geometry.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/ui/home/view_models/slots_view_model.dart';
import 'package:photo_position/ui/overlay/view_models/overlay_view_model.dart';

import '../../testing/fakes/fake_overlay_service.dart';
import '../../testing/fakes/memory_position_repository.dart';

const portrait = Size(400, 800);
const landscape = Size(800, 400);

/// The overlay and the home screen only share storage, so the slot flow is
/// tested through one repository: the overlay persists, the slots copy.
void main() {
  late FakeOverlayService service;
  late MemoryPositionRepository repo;
  late OverlayViewModel overlay;
  late SlotsViewModel slots;

  setUp(() async {
    service = FakeOverlayService(screen: portrait);
    repo = MemoryPositionRepository();
    overlay = OverlayViewModel(service: service, repository: repo);
    slots = SlotsViewModel(repository: repo, screen: () => portrait);
    await overlay.start();
  });

  tearDown(() => overlay.dispose());

  Future<void> dragTo(Offset delta) async {
    service.dragBy(delta);
    await overlay.dragEnded();
  }

  test('a dragged position is what gets saved', () async {
    await dragTo(const Offset(30, -100));
    final moved = overlay.geometry!;

    await slots.saveCurrentTo(0);

    expect(slots.slots[0]!.geometry, moved);
    expect(slots.slots[0]!.screen, portrait);
  });

  test('a resize and a shape change are saved too', () async {
    overlay.beginResize();
    overlay.updateResize(ResizeAxis.both, -50);
    await overlay.endResize();
    await overlay.toggleShape();
    await slots.saveCurrentTo(1);

    final saved = slots.slots[1]!.geometry;
    expect(saved.width, 150);
    expect(saved.shape, OverlayShape.square,
        reason: 'circle toggled to square');
  });

  test('saving one slot leaves the others untouched', () async {
    await slots.saveCurrentTo(0);
    final first = slots.slots[0];
    await dragTo(const Offset(40, 40));
    await slots.saveCurrentTo(2);

    expect(slots.slots[0], first);
    expect(slots.slots[1], isNull);
    expect(slots.slots[2], isNot(first));
  });

  test('overwriting a slot replaces it', () async {
    await slots.saveCurrentTo(0);
    await dragTo(const Offset(50, 0));
    await slots.saveCurrentTo(0);
    expect(slots.slots[0]!.geometry, overlay.geometry);
  });

  test('loading a slot moves the overlay window back to the saved pixels',
      () async {
    await dragTo(const Offset(-60, -120));
    await slots.saveCurrentTo(0);
    final savedRect = overlay.geometry!.rect;

    await dragTo(const Offset(150, 200));
    expect(overlay.geometry!.rect, isNot(savedRect));

    final slot = await slots.select(0);
    await overlay.loadPosition(slot!);

    expect(overlay.geometry!.rect, savedRect);
    expect(
        service.visibleRect.topLeft + const Offset(20, 20), savedRect.topLeft);
  });

  test(
      'a slot saved in portrait lands on the same part of the glass in landscape',
      () async {
    await dragTo(const Offset(0, 250)); // low on the portrait screen
    await slots.saveCurrentTo(0);
    final glass = slots.slots[0]!.geometry;

    service.rotateTo(landscape, rotation: 1);
    await Future<void>.delayed(Duration.zero);
    await overlay.loadPosition((await slots.select(0))!);

    expect(overlay.geometry, glassToDisplay(glass, portrait, 1));
    expect(slots.slots[0]!.geometry, glass,
        reason: 'the slot itself is unchanged');
  });

  test('slots survive restarting the overlay', () async {
    await dragTo(const Offset(20, 20));
    await slots.saveCurrentTo(1);

    final restarted = OverlayViewModel(
        service: FakeOverlayService(screen: portrait), repository: repo);
    await restarted.start();
    await restarted.loadPosition((await slots.select(1))!);

    expect(restarted.geometry, slots.slots[1]!.geometry);
    restarted.dispose();
  });
}
