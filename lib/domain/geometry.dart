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
