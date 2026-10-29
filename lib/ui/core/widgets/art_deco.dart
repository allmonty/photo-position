import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_position/ui/core/theme.dart';

/// Gold rule with a diamond in the middle, used between home screen sections.
class ArtDecoDivider extends StatelessWidget {
  const ArtDecoDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: kGold, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Transform.rotate(
            angle: 0.7854, // 45 degrees — diamond motif
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                border: Border.all(color: kGold, width: 1.5),
              ),
            ),
          ),
        ),
        const Expanded(child: Divider(color: kGold, thickness: 1)),
      ],
    );
  }
}

class ArtDecoButton extends StatelessWidget {
  const ArtDecoButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// true = cream fill (primary action), false = outlined (secondary action)
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fgColor = filled ? kCrimson : kGold;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: fgColor),
      label: Text(
        label,
        style: GoogleFonts.poiretOne(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 16 * 0.05,
          color: fgColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: filled ? kCream : kCrimsonMid,
        foregroundColor: fgColor,
        side: BorderSide(color: kGold, width: filled ? 2 : 1),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }
}

/// Small gold heading for a home screen section.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poiretOne(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 14 * 0.1,
        color: kGold,
      ),
    );
  }
}

class InstructionsList extends StatelessWidget {
  const InstructionsList({super.key});

  static const _steps = [
    'Tap "Start Overlay" to create the overlay',
    'Drag the circle / square to position it',
    'Use controls to change shape and size',
    'Open your camera app to use the overlay',
    'Tap the overlay to toggle controls visibility',
    'Close overlay from controls or this app',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: GoogleFonts.poiretOne(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kGold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _steps[i],
                    style: GoogleFonts.libreFranklin(
                      fontSize: 14,
                      color: kOnSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
