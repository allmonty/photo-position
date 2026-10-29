import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:photo_position/data/repositories/position_repository.dart';
import 'package:photo_position/domain/models/overlay_style.dart';

/// The border width and colour chosen on the home screen. Changes reach a
/// running overlay at once through [onChanged]; they are saved when a
/// slider drag ends or a colour is picked, for the next start.
class StyleViewModel extends ChangeNotifier {
  StyleViewModel({required PositionRepository repository, this.onChanged})
      : _repository = repository;

  final PositionRepository _repository;

  /// Told after every change so a running overlay can follow along.
  final void Function(OverlayStyle style)? onChanged;

  OverlayStyle _style = const OverlayStyle();

  OverlayStyle get style => _style;

  Future<void> load() async {
    _style = await _repository.loadStyle();
    notifyListeners();
  }

  /// While dragging the slider: shows live, saves with [commitBorderWidth].
  void previewBorderWidth(double width) => _change(
        _style.copyWith(
          borderWidth: width.clamp(
              OverlayStyle.minBorderWidth, OverlayStyle.maxBorderWidth),
        ),
      );

  Future<void> commitBorderWidth() => _repository.saveStyle(_style);

  Future<void> setBorderColor(Color color) {
    _change(_style.copyWith(borderColor: color));
    return _repository.saveStyle(_style);
  }

  void _change(OverlayStyle style) {
    _style = style;
    notifyListeners();
    onChanged?.call(style);
  }
}
