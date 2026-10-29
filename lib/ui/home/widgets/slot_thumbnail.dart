import 'package:flutter/material.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:photo_position/theme.dart';

/// A phone-shaped rectangle (the aspect of the screen the position was saved
/// on) with the saved shape drawn where it sits on that screen.
class SlotThumbnail extends StatelessWidget {
  const SlotThumbnail({super.key, required this.slot, this.height = 120});

  final PositionSlot? slot;
  final double height;

  @override
  Widget build(BuildContext context) {
    final PositionSlot? s = slot;
    final double aspect =
        s == null ? 9 / 19.5 : s.screen.width / s.screen.height;
    return SizedBox(
      width: height * aspect,
      height: height,
      child: CustomPaint(painter: _SlotPainter(s)),
    );
  }
}

class _SlotPainter extends CustomPainter {
  _SlotPainter(this.slot);

  final PositionSlot? slot;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect phone =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8));
    canvas.drawRRect(phone, Paint()..color = kCrimsonDark);
    canvas.drawRRect(
      phone,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = slot == null ? kGold.withAlpha(90) : kGold,
    );
    final PositionSlot? s = slot;
    if (s == null) return;

    final double k = size.width / s.screen.width;
    final Rect r = Rect.fromLTWH(
      s.geometry.left * k,
      s.geometry.top * k,
      s.geometry.width * k,
      s.geometry.height * k,
    );
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = kGold.withAlpha(220);
    if (s.geometry.shape == OverlayShape.circle) {
      canvas.drawOval(r, stroke);
    } else {
      canvas.drawRect(r, stroke);
    }
  }

  @override
  bool shouldRepaint(_SlotPainter old) => old.slot != slot;
}
