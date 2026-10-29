import 'dart:ui';

enum OverlayShape { circle, square }

/// A shape's rectangle in logical pixels (dp) from a screen's top-left.
///
/// The overlay is pinned to the phone's glass, so what is stored and saved in
/// slots is this rectangle in the phone's *natural* orientation ("glass
/// coordinates"); it never changes when the phone rotates. The rectangle the
/// rotated display draws is derived from it with `glassToDisplay`.
/// [width]/[height] are the visible shape only; resize handles and the
/// control panel are not part of it.
class OverlayGeometry {
  const OverlayGeometry({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.shape,
  });

  static const double minSize = 50;

  /// A sanity bound for stored values; on screen the size is limited by the
  /// screen itself.
  static const double maxSize = 4000;

  final double left;
  final double top;
  final double width;
  final double height;
  final OverlayShape shape;

  Rect get rect => Rect.fromLTWH(left, top, width, height);

  /// Parses untrusted stored JSON; returns null for anything malformed so
  /// callers fall back to defaults instead of crashing on a corrupt value.
  static OverlayGeometry? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final Object? shapeName = json['shape'];
    final OverlayShape? shape =
        OverlayShape.values.where((s) => s.name == shapeName).firstOrNull;
    final List<double?> n = [
      for (final k in ['left', 'top', 'width', 'height'])
        json[k] is num && (json[k] as num).isFinite
            ? (json[k] as num).toDouble()
            : null,
    ];
    if (shape == null || n.contains(null)) return null;
    return OverlayGeometry(
      left: n[0]!,
      top: n[1]!,
      width: n[2]!.clamp(minSize, maxSize),
      height: n[3]!.clamp(minSize, maxSize),
      shape: shape,
    );
  }

  Map<String, Object> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        'shape': shape.name,
      };

  /// Moves the shape so it lies fully inside [screen]. Size is kept, shrunk
  /// only if the screen is smaller than the shape. Only the shape is kept in
  /// view, never its control panel: the shape's place on the glass is exact.
  OverlayGeometry clampedTo(Size screen) {
    final double w = width.clamp(0, screen.width);
    final double h = height.clamp(0, screen.height);
    return OverlayGeometry(
      left: left.clamp(0, screen.width - w),
      top: top.clamp(0, screen.height - h),
      width: w,
      height: h,
      shape: shape,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OverlayGeometry &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height &&
      other.shape == shape;

  @override
  int get hashCode => Object.hash(left, top, width, height, shape);
}
