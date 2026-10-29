import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/domain/geometry.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';

void main() {
  const portrait = Size(400, 800);
  const landscape = Size(800, 400);
  const g = OverlayGeometry(
    left: 100,
    top: 150,
    width: 200,
    height: 120,
    shape: OverlayShape.square,
  );

  group('plugin offset', () {
    test('round-trips for portrait and landscape screens', () {
      for (final screen in [portrait, landscape]) {
        final back = fromPluginOffset(
          toPluginOffset(g, screen),
          screen,
          width: g.width,
          height: g.height,
          shape: g.shape,
        );
        expect(back, g);
      }
    });

    test(
        'same absolute geometry yields a different plugin offset after '
        'the screen swaps, which is what must be re-sent on rotation', () {
      expect(toPluginOffset(g, portrait), isNot(toPluginOffset(g, landscape)));
      // Window is 300x160; centre at (100-20+150, 150-20+80) = (230, 210).
      expect(toPluginOffset(g, portrait), const Offset(30, -190));
      expect(toPluginOffset(g, landscape), const Offset(-170, 10));
    });

    test('window is at least as tall as the control panel', () {
      const small = OverlayGeometry(
          left: 0, top: 0, width: 50, height: 50, shape: OverlayShape.circle);
      expect(windowSizeFor(small).height, panelHeight);
    });
  });

  group('OverlayGeometry', () {
    test('json round-trip', () {
      expect(OverlayGeometry.fromJson(g.toJson()), g);
    });

    test('rejects malformed json', () {
      expect(OverlayGeometry.fromJson(null), isNull);
      expect(OverlayGeometry.fromJson({'left': 1}), isNull);
      expect(
          OverlayGeometry.fromJson({...g.toJson(), 'shape': 'star'}), isNull);
      expect(OverlayGeometry.fromJson({...g.toJson(), 'left': double.nan}),
          isNull);
    });

    test('clamps stored sizes to the allowed range', () {
      final parsed =
          OverlayGeometry.fromJson({...g.toJson(), 'width': 9999, 'height': 1});
      expect(parsed!.width, OverlayGeometry.maxSize);
      expect(parsed.height, OverlayGeometry.minSize);
    });

    test('clampedTo pulls a portrait geometry into a landscape screen', () {
      const tall = OverlayGeometry(
          left: 300,
          top: 600,
          width: 100,
          height: 100,
          shape: OverlayShape.circle);
      expect(tall.clampedTo(landscape).rect,
          const Rect.fromLTWH(300, 300, 100, 100));
    });
  });

  test('the parent-frame centre shift is subtracted and added back', () {
    const shift = Offset(0, -12);
    final offset = toPluginOffset(g, portrait, centreShift: shift);
    expect(offset, toPluginOffset(g, portrait) - shift);
    expect(
      fromPluginOffset(offset, portrait,
          centreShift: shift, width: g.width, height: g.height, shape: g.shape),
      g,
    );
  });

  group('glass <-> display', () {
    const natural = Size(400, 800);
    const g = OverlayGeometry(
        left: 20, top: 30, width: 100, height: 60, shape: OverlayShape.square);

    test('rotation 0 is the identity', () {
      expect(glassToDisplay(g, natural, 0), g);
    });

    test(
        'a quarter turn counter-clockwise puts the glass top-left at the bottom-left',
        () {
      final d = glassToDisplay(g, natural, 1);
      expect(d.rect, const Rect.fromLTWH(30, 280, 60, 100));
    });

    test(
        'half a turn mirrors both axes; three quarters sends it to the top-right',
        () {
      expect(glassToDisplay(g, natural, 2).rect,
          const Rect.fromLTWH(280, 710, 100, 60));
      expect(glassToDisplay(g, natural, 3).rect,
          const Rect.fromLTWH(710, 20, 60, 100));
    });

    test('displayToGlass inverts it for every rotation', () {
      for (final r in [0, 1, 2, 3]) {
        expect(displayToGlass(glassToDisplay(g, natural, r), natural, r), g);
      }
    });

    test('naturalScreen undoes the rotation of the screen size', () {
      expect(naturalScreen(const Size(800, 400), 1), natural);
      expect(naturalScreen(const Size(800, 400), 3), natural);
      expect(naturalScreen(natural, 2), natural);
    });
  });
}
