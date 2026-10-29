import 'dart:ui';

import 'package:photo_position/domain/models/overlay_geometry.dart';

/// A saved overlay position. [screen] is the screen it was saved on, kept so
/// the thumbnail can draw the phone with the right proportions and loading
/// into a different orientation can clamp instead of guessing.
class PositionSlot {
  const PositionSlot({required this.geometry, required this.screen});

  final OverlayGeometry geometry;
  final Size screen;

  static PositionSlot? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final OverlayGeometry? geometry =
        OverlayGeometry.fromJson(json['geometry']);
    final Object? w = json['screenWidth'];
    final Object? h = json['screenHeight'];
    if (geometry == null || w is! num || h is! num || w <= 0 || h <= 0) {
      return null;
    }
    return PositionSlot(
      geometry: geometry,
      screen: Size(w.toDouble(), h.toDouble()),
    );
  }

  Map<String, Object> toJson() => {
        'geometry': geometry.toJson(),
        'screenWidth': screen.width,
        'screenHeight': screen.height,
      };

  @override
  bool operator ==(Object other) =>
      other is PositionSlot &&
      other.geometry == geometry &&
      other.screen == screen;

  @override
  int get hashCode => Object.hash(geometry, screen);
}
