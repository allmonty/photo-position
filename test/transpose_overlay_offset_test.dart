import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/overlay_screen.dart';

void main() {
  group('transposeOverlayOffset guard conditions', () {
    test('returns null when either orientation is unknown', () {
      expect(
        transposeOverlayOffset(
          before: OrientationState.unknown,
          after: OrientationState.landscapeRight,
          offsetX: 10,
          offsetY: 10,
        ),
        isNull,
      );
      expect(
        transposeOverlayOffset(
          before: OrientationState.portraitUp,
          after: OrientationState.unknown,
          offsetX: 10,
          offsetY: 10,
        ),
        isNull,
      );
    });

    test('returns null when the orientation did not change', () {
      expect(
        transposeOverlayOffset(
          before: OrientationState.portraitUp,
          after: OrientationState.portraitUp,
          offsetX: 10,
          offsetY: 10,
        ),
        isNull,
      );
    });
  });

  group('transposeOverlayOffset rotation behavior', () {
    // The overlay is meant to stay glued to the physical device, like a
    // sticker on the glass, so the offset (from the screen center) must be
    // truly rotated by the angle the device turned -- not rescaled to stay
    // in the same logical/upright corner (that was an earlier, incorrect
    // model; see the regression test pinned to a real device measurement).

    test('a 90° turn (landscapeRight) rotates (x,y) to (-y,x)', () {
      final result = transposeOverlayOffset(
        before: OrientationState.portraitUp,
        after: OrientationState.landscapeRight,
        offsetX: 100,
        offsetY: 40,
      )!;

      expect(result, const Offset(-40, 100));
    });

    test('the opposite 90° turn (landscapeLeft) rotates the other way, '
        'to (y,-x)', () {
      final result = transposeOverlayOffset(
        before: OrientationState.portraitUp,
        after: OrientationState.landscapeLeft,
        offsetX: 100,
        offsetY: 40,
      )!;

      expect(result, const Offset(40, -100));
    });

    test('rotation direction matters: landscapeLeft and landscapeRight '
        'give different results', () {
      final viaLeft = transposeOverlayOffset(
        before: OrientationState.portraitUp,
        after: OrientationState.landscapeLeft,
        offsetX: -180,
        offsetY: -370,
      );
      final viaRight = transposeOverlayOffset(
        before: OrientationState.portraitUp,
        after: OrientationState.landscapeRight,
        offsetX: -180,
        offsetY: -370,
      );

      expect(viaLeft, isNot(equals(viaRight)));
    });

    test('a 180° flip (portraitDown) negates both axes', () {
      final result = transposeOverlayOffset(
        before: OrientationState.portraitUp,
        after: OrientationState.portraitDown,
        offsetX: 50,
        offsetY: -80,
      )!;

      expect(result, const Offset(-50, 80));
    });

    test('preserves distance from the screen center (pure rotation, no '
        'scaling)', () {
      const double x = -180, y = 370;
      final double distanceBefore = (x * x + y * y);

      final result = transposeOverlayOffset(
        before: OrientationState.portraitUp,
        after: OrientationState.landscapeRight,
        offsetX: x,
        offsetY: y,
      )!;
      final double distanceAfter =
          result.dx * result.dx + result.dy * result.dy;

      expect(distanceAfter, closeTo(distanceBefore, 4)); // rounding slack
    });

    test('four consecutive 90° turns return to the start', () {
      const Offset start = Offset(-180, -370);
      const List<OrientationState> sequence = [
        OrientationState.portraitUp,
        OrientationState.landscapeRight,
        OrientationState.portraitDown,
        OrientationState.landscapeLeft,
        OrientationState.portraitUp,
      ];

      Offset current = start;
      for (int i = 0; i < sequence.length - 1; i++) {
        current = transposeOverlayOffset(
          before: sequence[i],
          after: sequence[i + 1],
          offsetX: current.dx,
          offsetY: current.dy,
        )!;
      }

      expect(current.dx, closeTo(start.dx, 1));
      expect(current.dy, closeTo(start.dy, 1));
    });

    test('result coordinates are rounded to whole numbers', () {
      final result = transposeOverlayOffset(
        before: OrientationState.portraitUp,
        after: OrientationState.landscapeRight,
        offsetX: 33.4,
        offsetY: 0,
      )!;

      expect(result.dx, result.dx.roundToDouble());
      expect(result.dy, result.dy.roundToDouble());
    });
  });

  group('transposeWindowOffset', () {
    test('applies the same rotation after correcting for the window/content '
        'offset, then corrects back', () {
      const Offset contentOffset = Offset(-30, 0);
      const Offset windowOffset = Offset(50, 20);

      final Offset result = transposeWindowOffset(
        windowOffset: windowOffset,
        contentOffset: contentOffset,
        before: OrientationState.portraitUp,
        after: OrientationState.landscapeRight,
      )!;

      // True offset before = (50-30, 20) = (20, 20).
      // Rotated (x,y)->(-y,x) = (-20, 20).
      // Window offset after = rotated - contentOffset = (-20-(-30), 20-0)
      //                     = (10, 20).
      expect(result, const Offset(10, 20));
    });

    test('returns null when the orientation did not change', () {
      expect(
        transposeWindowOffset(
          windowOffset: const Offset(10, 10),
          contentOffset: const Offset(-30, 0),
          before: OrientationState.portraitUp,
          after: OrientationState.portraitUp,
        ),
        isNull,
      );
    });
  });

  group('overlayContentCenterOffset', () {
    test('default-sized shape (200x200) is offset left by half the panel width', () {
      // resizeHandleSize=20 -> shapeWidth/Height = 200 + 2*20 = 240.
      final result = overlayContentCenterOffset(
        shapeWidth: 240,
        shapeHeight: 240,
        panelWidth: 60,
        panelHeight: 120,
      );

      // windowWidth = 240+60=300, windowHeight = max(240,120)=240.
      // dx = 240/2 - 300/2 = 120-150 = -30. dy = 240/2-240/2 = 0.
      expect(result, const Offset(-30, 0));
    });

    test('horizontal offset only depends on panel width, not shape size', () {
      final small = overlayContentCenterOffset(
        shapeWidth: 90,
        shapeHeight: 90,
        panelWidth: 60,
        panelHeight: 120,
      );
      final large = overlayContentCenterOffset(
        shapeWidth: 540,
        shapeHeight: 540,
        panelWidth: 60,
        panelHeight: 120,
      );

      expect(small.dx, -30);
      expect(large.dx, -30);
    });

    test('vertical offset is nonzero when the panel is taller than the shape', () {
      // shapeHeight=90 < panelHeight=120 -> windowHeight=120 (panel-driven).
      final result = overlayContentCenterOffset(
        shapeWidth: 100,
        shapeHeight: 90,
        panelWidth: 60,
        panelHeight: 120,
      );

      // dy = 90/2 - 120/2 = 45-60 = -15.
      expect(result.dy, -15);
    });
  });
}
