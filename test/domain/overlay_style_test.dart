import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/domain/models/overlay_style.dart';

void main() {
  test('defaults are the original gold, 5dp border', () {
    const style = OverlayStyle();
    expect(style.borderWidth, 5);
    expect(style.borderColor, OverlayStyle.defaultBorderColor);
    expect(OverlayStyle.palette, contains(OverlayStyle.defaultBorderColor));
  });

  test('json round-trip', () {
    const style = OverlayStyle(borderWidth: 12, borderColor: Color(0xFFFF3B30));
    expect(OverlayStyle.fromJson(style.toJson()), style);
  });

  test('malformed json falls back to defaults field by field', () {
    expect(OverlayStyle.fromJson(null), const OverlayStyle());
    expect(OverlayStyle.fromJson('x'), const OverlayStyle());
    final partial = OverlayStyle.fromJson(
        {'borderWidth': 'wide', 'borderColor': 0xFF00FF00});
    expect(partial.borderWidth, OverlayStyle.defaultBorderWidth);
    expect(partial.borderColor, const Color(0xFF00FF00));
    expect(OverlayStyle.fromJson({'borderWidth': double.nan}).borderWidth, 5);
  });

  test('stored width is kept within its range', () {
    expect(OverlayStyle.fromJson({'borderWidth': 500}).borderWidth,
        OverlayStyle.maxBorderWidth);
    expect(OverlayStyle.fromJson({'borderWidth': 0}).borderWidth,
        OverlayStyle.minBorderWidth);
  });
}
