import 'dart:ui';

enum OverlayShape { circle, square }

/// Where the overlay shape sits on screen, in logical pixels (dp) measured
/// from the screen's top-left corner.
///
/// Stored as an absolute rectangle instead of the plugin's centre-relative
/// offset: that offset is reinterpreted by Android when the screen
/// dimensions swap on rotation, which is what made the overlay jump. An
/// absolute rectangle never changes by itself, so it is re-applied instead
/// of being "transposed". [width]/[height] are the visible shape only;
/// resize handles and the control panel are not part of it.
class OverlayGeometry {
  const OverlayGeometry({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.shape,
  });

  static const double minSize = 50;
  static const double maxSize = 500;

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

  /// Moves the shape so it lies fully inside [screen] (e.g. a slot saved in
  /// portrait loaded in landscape). Size is kept, shrunk only if the screen
  /// is smaller than the shape.
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
