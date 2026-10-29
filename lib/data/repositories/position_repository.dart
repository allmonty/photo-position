import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/overlay_style.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the live overlay geometry, the saved position slots and the
/// overlay's border style.
///
/// Abstract so view models can be tested against an in-memory fake.
abstract class PositionRepository {
  static const int slotCount = 3;

  /// Last overlay position with the screen it was on, or null if none was
  /// ever saved. The screen is what lets a slot taken from it draw the phone
  /// with the right proportions. [screen] is only used to migrate the
  /// pre-slots storage format.
  Future<PositionSlot?> loadCurrent({required Size screen});
  Future<void> saveCurrent(PositionSlot position);

  /// Always [slotCount] entries; null means empty.
  Future<List<PositionSlot?>> loadSlots();
  Future<void> saveSlot(int index, PositionSlot? slot);

  /// The border style; the default when none was ever chosen.
  Future<OverlayStyle> loadStyle();
  Future<void> saveStyle(OverlayStyle style);
}

class SharedPreferencesPositionRepository implements PositionRepository {
  static const _currentKey = 'overlayGeometry';
  static const _styleKey = 'overlayStyle';
  static String _slotKey(int i) => 'positionSlot$i';

  @override
  Future<PositionSlot?> loadCurrent({required Size screen}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // The overlay writes from another Flutter engine; drop this isolate's cache.
    await prefs.reload();
    return _decode<PositionSlot>(
          prefs.getString(_currentKey),
          PositionSlot.fromJson,
        ) ??
        _migrateLegacy(prefs, screen);
  }

  @override
  Future<void> saveCurrent(PositionSlot position) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentKey, jsonEncode(position.toJson()));
  }

  @override
  Future<List<PositionSlot?>> loadSlots() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return [
      for (var i = 0; i < PositionRepository.slotCount; i++)
        _decode<PositionSlot>(
            prefs.getString(_slotKey(i)), PositionSlot.fromJson),
    ];
  }

  @override
  Future<void> saveSlot(int index, PositionSlot? slot) async {
    RangeError.checkValidIndex(
        index, List<void>.filled(PositionRepository.slotCount, null));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (slot == null) {
      await prefs.remove(_slotKey(index));
    } else {
      await prefs.setString(_slotKey(index), jsonEncode(slot.toJson()));
    }
  }

  @override
  Future<OverlayStyle> loadStyle() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Written by the main app, read by the overlay engine: drop its cache.
    await prefs.reload();
    return _decode<OverlayStyle>(
            prefs.getString(_styleKey), OverlayStyle.fromJson) ??
        const OverlayStyle();
  }

  @override
  Future<void> saveStyle(OverlayStyle style) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_styleKey, jsonEncode(style.toJson()));
  }

  static T? _decode<T>(String? raw, T? Function(Object?) parse) {
    if (raw == null) return null;
    try {
      return parse(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  /// Old format: centre-relative window offset (`overlayWinsPosX/Y`) plus
  /// separate size/shape keys. Converted once to the absolute rectangle.
  static PositionSlot? _migrateLegacy(SharedPreferences prefs, Size screen) {
    final double? x = prefs.getDouble('overlayWinsPosX');
    final double? y = prefs.getDouble('overlayWinsPosY');
    if (x == null || y == null) return null;
    final bool circle =
        prefs.getString('overlayShape') == 'OverlayShape.circle';
    final double size = prefs.getDouble('overlayCircleSize') ?? 200;
    final double w = circle ? size : prefs.getDouble('overlayWidth') ?? 200;
    final double h = circle ? size : prefs.getDouble('overlayHeight') ?? 200;
    final double cw = w.clamp(OverlayGeometry.minSize, OverlayGeometry.maxSize);
    final double ch = h.clamp(OverlayGeometry.minSize, OverlayGeometry.maxSize);
    // The old window was the shape plus a 20dp handle margin on every side
    // and a 60dp panel on the right; the shape sat 20dp inside its corner.
    final double windowW = cw + 40 + 60;
    final double windowH = max(ch + 40, 120.0);
    return PositionSlot(
      geometry: OverlayGeometry(
        left: x + screen.width / 2 - windowW / 2 + 20,
        top: y + screen.height / 2 - windowH / 2 + 20,
        width: cw,
        height: ch,
        shape: circle ? OverlayShape.circle : OverlayShape.square,
      ),
      screen: screen,
    );
  }
}
