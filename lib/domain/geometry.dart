import 'dart:math';
import 'dart:ui';

import 'package:photo_position/domain/models/overlay_geometry.dart';

/// Space the overlay window reserves around the visible shape (resize
/// handles on every side, a control panel on the right).
const double resizeHandleSize = 20;
const double panelWidth = 60;
const double panelHeight = 120;

/// Size of the native overlay window needed to host [g]. The shape sits at
/// the window's top-left (inset by the handles), the panel to its right.
Size windowSizeFor(OverlayGeometry g) => Size(
      g.width + resizeHandleSize * 2 + panelWidth,
      max(g.height + resizeHandleSize * 2, panelHeight),
    );

/// The offset `flutter_overlay_window` expects for [g] on [screen].
///
/// The plugin's window uses `Gravity.CENTER`, so its x/y is the distance
/// from the centre of the window's *parent frame* to the window centre --
/// not from the screen corner. The parent frame excludes the navigation
/// bar, so its centre is [centreShift] away from the screen centre (always
/// zero-sized on devices without a navigation bar).
Offset toPluginOffset(
  OverlayGeometry g,
  Size screen, {
  Offset centreShift = Offset.zero,
}) {
  final Size window = windowSizeFor(g);
  final double windowLeft = g.left - resizeHandleSize;
  final double windowTop = g.top - resizeHandleSize;
  return Offset(
    windowLeft + window.width / 2 - screen.width / 2 - centreShift.dx,
    windowTop + window.height / 2 - screen.height / 2 - centreShift.dy,
  );
}

/// Inverse of [toPluginOffset]: the geometry of a [width]x[height] [shape]
/// whose window the plugin reports at [pluginOffset] on [screen].
OverlayGeometry fromPluginOffset(
  Offset pluginOffset,
  Size screen, {
  required double width,
  required double height,
  required OverlayShape shape,
  Offset centreShift = Offset.zero,
}) {
  final Size window = windowSizeFor(
    OverlayGeometry(
        left: 0, top: 0, width: width, height: height, shape: shape),
  );
  return OverlayGeometry(
    left: pluginOffset.dx +
        centreShift.dx +
        screen.width / 2 -
        window.width / 2 +
        resizeHandleSize,
    top: pluginOffset.dy +
        centreShift.dy +
        screen.height / 2 -
        window.height / 2 +
        resizeHandleSize,
    width: width,
    height: height,
    shape: shape,
  );
}

/// The screen of the phone held in its natural (portrait) orientation, given
/// the [screen] currently shown and the display [rotation].
Size naturalScreen(Size screen, int rotation) =>
    rotation.isOdd ? Size(screen.height, screen.width) : screen;

/// Where the shape sits on the glass is stored in the phone's natural
/// orientation ("glass" coordinates). [rotation] is Android's
/// `Surface.ROTATION_*` quarter turns: 0 natural, 1 phone turned 90 degrees
/// counter-clockwise, 2 upside down, 3 turned 90 degrees clockwise.
///
/// Returns the same physical spot as the display currently draws it. A
/// circle stays a circle; a rectangle swaps width and height on odd
/// rotations, exactly as the glass does when you turn the phone.
OverlayGeometry glassToDisplay(OverlayGeometry g, Size natural, int rotation) {
  final double w = natural.width;
  final double h = natural.height;
  final (double, double, double, double) r = switch (rotation % 4) {
    1 => (g.top, w - g.left - g.width, g.height, g.width),
    2 => (w - g.left - g.width, h - g.top - g.height, g.width, g.height),
    3 => (h - g.top - g.height, g.left, g.height, g.width),
    _ => (g.left, g.top, g.width, g.height),
  };
  return OverlayGeometry(
      left: r.$1, top: r.$2, width: r.$3, height: r.$4, shape: g.shape);
}

/// Inverse of [glassToDisplay]: a rectangle edited on the rotated display,
/// back to glass coordinates.
OverlayGeometry displayToGlass(OverlayGeometry d, Size natural, int rotation) {
  final double w = natural.width;
  final double h = natural.height;
  final (double, double, double, double) r = switch (rotation % 4) {
    1 => (w - d.top - d.height, d.left, d.height, d.width),
    2 => (w - d.left - d.width, h - d.top - d.height, d.width, d.height),
    3 => (d.top, h - d.left - d.width, d.height, d.width),
    _ => (d.left, d.top, d.width, d.height),
  };
  return OverlayGeometry(
      left: r.$1, top: r.$2, width: r.$3, height: r.$4, shape: d.shape);
}
