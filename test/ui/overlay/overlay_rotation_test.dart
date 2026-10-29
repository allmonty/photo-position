import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:photo_position/ui/overlay/view_models/overlay_view_model.dart';

import '../../../testing/fakes/fake_overlay_service.dart';
import '../../../testing/fakes/memory_position_repository.dart';

const portrait = Size(400, 800);
const landscape = Size(800, 400);

/// The shape's rectangle on the real screen, derived from where the fake
/// native window actually is (the shape sits 20dp inside the window corner).
Rect shapeOnScreen(FakeOverlayService s, OverlayViewModel vm) {
  final g = vm.geometry!;
  return Rect.fromLTWH(
    s.visibleRect.left + 20,
    s.visibleRect.top + 20,
    g.width,
    g.height,
  );
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeOverlayService service;
  late MemoryPositionRepository repo;
  late OverlayViewModel vm;

  setUp(() {
    service = FakeOverlayService(screen: portrait);
    // Fits both orientations, so "same pixels" is meaningful in the tests below.
    repo = MemoryPositionRepository()
      ..current = const PositionSlot(
        geometry: OverlayGeometry(
            left: 100,
            top: 100,
            width: 200,
            height: 200,
            shape: OverlayShape.circle),
        screen: portrait,
      );
    vm = OverlayViewModel(service: service, repository: repo);
  });

  tearDown(() => vm.dispose());

  for (final shape in OverlayShape.values) {
    for (final controls in [true, false]) {
      test('$shape, controls=$controls: same pixels before and after rotating',
          () async {
        repo.current = PositionSlot(
          geometry: OverlayGeometry(
              left: 60,
              top: 120,
              width: 150,
              height: shape == OverlayShape.circle ? 150 : 90,
              shape: shape),
          screen: portrait,
        );
        await vm.start();
        if (!controls) vm.toggleControls();
        final before = shapeOnScreen(service, vm);
        expect(before, Rect.fromLTWH(60, 120, 150, vm.geometry!.height));

        service.rotateTo(landscape);
        await settle();
        expect(shapeOnScreen(service, vm), before);

        service.rotateTo(portrait);
        await settle();
        expect(shapeOnScreen(service, vm), before);
      });
    }
  }

  test('a dragged position survives rotation', () async {
    await vm.start();
    service.dragBy(const Offset(40, -60));
    await vm.dragEnded();
    final before = shapeOnScreen(service, vm);

    service.rotateTo(landscape);
    await settle();

    expect(shapeOnScreen(service, vm), before);
    expect(repo.current!.geometry, vm.geometry);
  });

  test('a resized shape keeps its top-left and survives rotation', () async {
    await vm.start();
    final topLeft = shapeOnScreen(service, vm).topLeft;
    vm.beginResize();
    vm.updateResize(ResizeAxis.both, 100);
    await settle();
    expect(service.dragEnabled, isFalse);
    await vm.endResize();
    expect(service.dragEnabled, isTrue);

    final before = shapeOnScreen(service, vm);
    expect(before.topLeft, topLeft);
    expect(before.size, const Size(300, 300));

    service.rotateTo(landscape);
    await settle();
    expect(shapeOnScreen(service, vm), before);
  });

  test('rotating many times never drifts', () async {
    await vm.start();
    final before = shapeOnScreen(service, vm);
    for (var i = 0; i < 20; i++) {
      service.rotateTo(i.isEven ? landscape : portrait);
      await settle();
    }
    service.rotateTo(portrait);
    await settle();
    expect(shapeOnScreen(service, vm), before);
  });

  test('loading a portrait slot in landscape clamps it onto the screen',
      () async {
    await vm.start();
    service.rotateTo(landscape);
    await settle();
    await vm.loadPosition(const PositionSlot(
      geometry: OverlayGeometry(
          left: 300,
          top: 650,
          width: 100,
          height: 100,
          shape: OverlayShape.square),
      screen: portrait,
    ));
    expect(shapeOnScreen(service, vm), const Rect.fromLTWH(300, 300, 100, 100));
  });

  test('start waits for the native window before moving it', () async {
    service.active = false;
    final started = vm.start();
    await settle();
    expect(service.moveCalls, 0);
    service.active = true;
    await started;
    expect(service.moveCalls, 1);
  });

  test('a failed apply does not block the next one', () async {
    service.failNextResize = true;
    await vm.start();
    service.rotateTo(landscape);
    await settle();
    expect(shapeOnScreen(service, vm), vm.geometry!.rect);
  });

  test('same pixels when the navigation bar shifts the window centre',
      () async {
    // Portrait: nav bar at the bottom. Landscape: nav bar at the side.
    service =
        FakeOverlayService(screen: portrait, centreShift: const Offset(0, -12));
    vm = OverlayViewModel(service: service, repository: repo);
    await vm.start();
    final before = shapeOnScreen(service, vm);

    service.rotateTo(landscape, centreShift: const Offset(-12, 0));
    await settle();
    expect(shapeOnScreen(service, vm), before);

    service.rotateTo(portrait, centreShift: const Offset(0, -12));
    await settle();
    expect(shapeOnScreen(service, vm), before);
  });

  test(
      'a shape that no longer fits is pulled into view, and restored on return',
      () async {
    repo.current = const PositionSlot(
      geometry: OverlayGeometry(
          left: 100,
          top: 600,
          width: 150,
          height: 150,
          shape: OverlayShape.circle),
      screen: portrait,
    );
    await vm.start();
    final before = shapeOnScreen(service, vm);

    service.rotateTo(landscape);
    await settle();
    // Landscape is only 400 high: pulled up so it stays fully visible.
    expect(shapeOnScreen(service, vm), const Rect.fromLTWH(100, 250, 150, 150));

    service.rotateTo(portrait);
    await settle();
    expect(shapeOnScreen(service, vm), before);
  });
}
