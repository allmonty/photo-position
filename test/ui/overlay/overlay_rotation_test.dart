import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/overlay_style.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:photo_position/ui/overlay/view_models/overlay_view_model.dart';

import '../../../testing/fakes/fake_overlay_service.dart';
import '../../../testing/fakes/memory_position_repository.dart';

const portrait = Size(400, 800);
const landscape = Size(800, 400);

/// A glass spot near the phone's top-left corner.
const topLeftOnGlass = OverlayGeometry(
  left: 20,
  top: 30,
  width: 100,
  height: 100,
  shape: OverlayShape.square,
);

/// The shape's rectangle on the real screen, derived from where the fake
/// native window actually is (the shape sits at the window's top-left corner).
Rect shapeOnScreen(FakeOverlayService s, OverlayViewModel vm) {
  final g = vm.geometry!;
  return Rect.fromLTWH(
      s.visibleRect.left, s.visibleRect.top, g.width, g.height);
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeOverlayService service;
  late MemoryPositionRepository repo;
  late OverlayViewModel vm;

  void turn(int rotation, {Offset shift = Offset.zero}) {
    service.rotateTo(rotation.isOdd ? landscape : portrait,
        rotation: rotation, centreShift: shift);
  }

  Future<void> startWith(OverlayGeometry glass) async {
    repo.current = PositionSlot(geometry: glass, screen: portrait);
    await vm.start();
  }

  setUp(() {
    service = FakeOverlayService(screen: portrait);
    repo = MemoryPositionRepository();
    vm = OverlayViewModel(service: service, repository: repo);
  });

  tearDown(() => vm.dispose());

  group('pinned to the glass', () {
    test(
        'a shape near the top-left corner follows that corner when the phone turns',
        () async {
      await startWith(topLeftOnGlass);
      expect(shapeOnScreen(service, vm), const Rect.fromLTWH(20, 30, 100, 100));

      // Phone turned 90 degrees counter-clockwise: its top-left corner is now bottom-left.
      turn(1);
      await settle();
      expect(
          shapeOnScreen(service, vm), const Rect.fromLTWH(30, 280, 100, 100));

      // Upside down: top-left corner is bottom-right.
      turn(2);
      await settle();
      expect(
          shapeOnScreen(service, vm), const Rect.fromLTWH(280, 670, 100, 100));

      // 90 degrees clockwise: top-left corner is top-right.
      turn(3);
      await settle();
      expect(
          shapeOnScreen(service, vm), const Rect.fromLTWH(670, 20, 100, 100));
    });

    test('the stored glass position and shape never change by rotating',
        () async {
      await startWith(topLeftOnGlass);
      for (final r in [1, 2, 3, 0, 3, 1]) {
        turn(r);
        await settle();
      }
      expect(repo.current!.geometry, topLeftOnGlass);
    });

    for (final shape in OverlayShape.values) {
      for (final controls in [true, false]) {
        test(
            '$shape, controls=$controls: back in portrait it is exactly where it started',
            () async {
          await startWith(OverlayGeometry(
            left: 60,
            top: 120,
            width: 150,
            height: shape == OverlayShape.circle ? 150 : 90,
            shape: shape,
          ));
          if (!controls) vm.toggleControls();
          final before = shapeOnScreen(service, vm);

          turn(1);
          await settle();
          expect(vm.geometry!.shape, shape);
          turn(0);
          await settle();
          expect(shapeOnScreen(service, vm), before);
        });
      }
    }

    test(
        'a rectangle turns with the glass: width and height swap, a circle stays round',
        () async {
      await startWith(const OverlayGeometry(
        left: 60,
        top: 120,
        width: 150,
        height: 90,
        shape: OverlayShape.square,
      ));
      turn(1);
      await settle();
      expect(vm.geometry!.width, 90);
      expect(vm.geometry!.height, 150);

      await vm.toggleShape();
      final circle = vm.geometry!;
      expect(circle.shape, OverlayShape.circle);
      expect(circle.width, circle.height);
    });

    test('20 turns through every orientation never drift', () async {
      await startWith(topLeftOnGlass);
      final before = shapeOnScreen(service, vm);
      for (var i = 0; i < 20; i++) {
        turn(i % 4);
        await settle();
      }
      turn(0);
      await settle();
      expect(shapeOnScreen(service, vm), before);
    });

    test(
        'same glass spot when the navigation bar sits at the bottom, then at the side',
        () async {
      service = FakeOverlayService(
          screen: portrait, centreShift: const Offset(0, -12));
      vm = OverlayViewModel(service: service, repository: repo);
      await startWith(topLeftOnGlass);
      final before = shapeOnScreen(service, vm);

      turn(1, shift: const Offset(-12, 0));
      await settle();
      expect(
          shapeOnScreen(service, vm), const Rect.fromLTWH(30, 280, 100, 100));

      turn(0, shift: const Offset(0, -12));
      await settle();
      expect(shapeOnScreen(service, vm), before);
    });
  });

  group('editing while the phone is turned', () {
    test('a drag in landscape moves the shape along the matching glass axis',
        () async {
      await startWith(topLeftOnGlass);
      turn(1);
      await settle();

      // +x on the rotated display is +y (down) on the glass.
      service.dragBy(const Offset(50, 0));
      await vm.dragEnded();

      turn(0);
      await settle();
      expect(shapeOnScreen(service, vm), const Rect.fromLTWH(20, 80, 100, 100));
      expect(repo.current!.geometry.top, 80);
      expect(repo.current!.geometry.left, 20);
    });

    test('resizing the displayed width in landscape resizes the glass height',
        () async {
      await startWith(topLeftOnGlass);
      turn(1);
      await settle();

      vm.beginResize();
      vm.updateResize(ResizeAxis.width, 40);
      await vm.endResize();
      expect(vm.geometry!.width, 140);

      turn(0);
      await settle();
      final g = vm.geometry!;
      expect(g.width, 100);
      expect(g.height, 140);
      expect(repo.current!.geometry.height, 140);
    });

    test('the displayed top-left corner stays put while resizing in landscape',
        () async {
      await startWith(topLeftOnGlass);
      turn(1);
      await settle();
      final topLeft = shapeOnScreen(service, vm).topLeft;

      vm.beginResize();
      vm.updateResize(ResizeAxis.both, 20);
      await vm.endResize();
      expect(shapeOnScreen(service, vm).topLeft, topLeft);
    });
  });

  group('slots are glass positions', () {
    test('a slot lands on the same part of the glass in every orientation',
        () async {
      await vm.start();
      const slot = PositionSlot(geometry: topLeftOnGlass, screen: portrait);

      await vm.loadPosition(slot);
      expect(shapeOnScreen(service, vm), const Rect.fromLTWH(20, 30, 100, 100));

      turn(1);
      await settle();
      await vm.loadPosition(slot);
      expect(
          shapeOnScreen(service, vm), const Rect.fromLTWH(30, 280, 100, 100));
    });

    test('a slot from a bigger phone is pulled onto this one', () async {
      await vm.start();
      await vm.loadPosition(const PositionSlot(
        geometry: OverlayGeometry(
          left: 900,
          top: 1500,
          width: 100,
          height: 100,
          shape: OverlayShape.circle,
        ),
        screen: Size(1080, 2400),
      ));
      expect(
          shapeOnScreen(service, vm), const Rect.fromLTWH(300, 700, 100, 100));
    });
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
    await startWith(topLeftOnGlass);
    turn(1);
    await settle();
    expect(shapeOnScreen(service, vm), vm.geometry!.rect);
  });

  group('what the user sees', () {
    test('listeners are told when the phone turns, so the widget redraws',
        () async {
      await startWith(topLeftOnGlass);
      var notified = 0;
      vm.addListener(() => notified++);
      turn(1);
      await settle();
      expect(notified, greaterThan(0));
    });

    test('a shape as big as the whole glass fits in every orientation',
        () async {
      await startWith(const OverlayGeometry(
          left: 0,
          top: 0,
          width: 400,
          height: 800,
          shape: OverlayShape.square));
      expect(shapeOnScreen(service, vm), const Rect.fromLTWH(0, 0, 400, 800));
      expect(service.window, const Size(400, 800),
          reason: 'controls do not enlarge the window');

      turn(1);
      await settle();
      expect(shapeOnScreen(service, vm), const Rect.fromLTWH(0, 0, 800, 400));
      expect(service.window, const Size(800, 400));
    });

    test('the shape can be resized all the way to the screen edge, not further',
        () async {
      await startWith(topLeftOnGlass);
      vm.beginResize();
      vm.updateResize(ResizeAxis.both, 5000);
      await vm.endResize();
      expect(shapeOnScreen(service, vm), const Rect.fromLTWH(20, 30, 380, 770));
    });
  });

  group('stopping and starting again', () {
    test('after close, reopen puts the window back where it was saved',
        () async {
      await startWith(topLeftOnGlass);
      await vm.close();
      expect(vm.closed, isTrue);
      final callsBefore = service.moveCalls;
      service.offset = Offset.zero; // the plugin made a fresh, default window

      await vm.reopen();

      expect(vm.closed, isFalse);
      expect(service.moveCalls, greaterThan(callsBefore));
      expect(shapeOnScreen(service, vm), const Rect.fromLTWH(20, 30, 100, 100));
    });

    test('reopen while already open does nothing', () async {
      await startWith(topLeftOnGlass);
      final calls = service.moveCalls;
      await vm.reopen();
      expect(service.moveCalls, calls);
    });

    test('a position changed while stopped is used by the next start',
        () async {
      await startWith(topLeftOnGlass);
      await vm.close();
      repo.current = const PositionSlot(
        geometry: OverlayGeometry(
            left: 50,
            top: 60,
            width: 100,
            height: 100,
            shape: OverlayShape.circle),
        screen: portrait,
      );
      await vm.reopen();
      expect(shapeOnScreen(service, vm), const Rect.fromLTWH(50, 60, 100, 100));
    });
  });

  group('border style', () {
    test('start uses the saved style, setStyle changes it and tells listeners',
        () async {
      repo.style =
          const OverlayStyle(borderWidth: 9, borderColor: Color(0xFF34C759));
      await startWith(topLeftOnGlass);
      expect(vm.style, repo.style);

      var notified = 0;
      vm.addListener(() => notified++);
      vm.setStyle(const OverlayStyle(borderWidth: 3));
      expect(vm.style.borderWidth, 3);
      expect(notified, 1);
      vm.setStyle(const OverlayStyle(borderWidth: 3));
      expect(notified, 1, reason: 'same style: nothing to redraw');
    });

    test('a style chosen while stopped is used by the next start', () async {
      await startWith(topLeftOnGlass);
      await vm.close();
      repo.style = const OverlayStyle(borderWidth: 14);
      await vm.reopen();
      expect(vm.style.borderWidth, 14);
    });
  });
}
