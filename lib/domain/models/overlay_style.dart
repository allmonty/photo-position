import 'dart:ui';

/// How the overlay's border looks. Chosen on the home screen, applied live
/// to a running overlay and remembered for the next start.
class OverlayStyle {
  const OverlayStyle(
      {this.borderWidth = defaultBorderWidth,
      this.borderColor = defaultBorderColor});

  static const double minBorderWidth = 1;
  static const double maxBorderWidth = 20;
  static const double defaultBorderWidth = 5;

  /// The original gold, slightly translucent so the camera image shows through.
  static const Color defaultBorderColor = Color(0xC8E9C349);

  /// Colours offered on the home screen: the default gold, then colours that
  /// stand out against typical scenes, with white and black for dark and
  /// bright ones.
  static const List<Color> palette = [
    defaultBorderColor,
    Color(0xFFFFFFFF),
    Color(0xFFFF3B30),
    Color(0xFF34C759),
    Color(0xFF32D4DE),
    Color(0xFFFF2D95),
    Color(0xFF000000),
  ];

  final double borderWidth;
  final Color borderColor;

  /// Parses untrusted stored JSON; anything malformed falls back to the
  /// default for that field, and the width is kept within its range.
  static OverlayStyle fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const OverlayStyle();
    final Object? w = json['borderWidth'];
    final Object? c = json['borderColor'];
    return OverlayStyle(
      borderWidth: w is num && w.isFinite
          ? w.toDouble().clamp(minBorderWidth, maxBorderWidth)
          : defaultBorderWidth,
      borderColor: c is int ? Color(c & 0xFFFFFFFF) : defaultBorderColor,
    );
  }

  Map<String, Object> toJson() => {
        'borderWidth': borderWidth,
        'borderColor': borderColor.toARGB32(),
      };

  OverlayStyle copyWith({double? borderWidth, Color? borderColor}) =>
      OverlayStyle(
        borderWidth: borderWidth ?? this.borderWidth,
        borderColor: borderColor ?? this.borderColor,
      );

  @override
  bool operator ==(Object other) =>
      other is OverlayStyle &&
      other.borderWidth == borderWidth &&
      other.borderColor == borderColor;

  @override
  int get hashCode => Object.hash(borderWidth, borderColor);
}
