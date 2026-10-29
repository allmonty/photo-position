import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_position/domain/models/overlay_style.dart';
import 'package:photo_position/ui/core/theme.dart';
import 'package:photo_position/ui/home/view_models/style_view_model.dart';

/// Border size slider and colour swatches for the overlay.
class StyleSection extends StatelessWidget {
  const StyleSection({super.key, required this.viewModel});

  final StyleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final OverlayStyle style = viewModel.style;
        return Column(
          children: [
            Row(
              children: [
                Text('SIZE', style: _label),
                Expanded(
                  child: Semantics(
                    label: 'Border size',
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: kGold,
                        inactiveTrackColor: kGold.withAlpha(70),
                        thumbColor: kGold,
                        overlayColor: kGold.withAlpha(40),
                        activeTickMarkColor: kCrimson,
                        inactiveTickMarkColor: kGold.withAlpha(120),
                        valueIndicatorColor: kGold,
                        valueIndicatorTextStyle:
                            const TextStyle(color: kCrimson),
                      ),
                      child: Slider(
                        key: const ValueKey('borderWidthSlider'),
                        min: OverlayStyle.minBorderWidth,
                        max: OverlayStyle.maxBorderWidth,
                        divisions: (OverlayStyle.maxBorderWidth -
                                OverlayStyle.minBorderWidth)
                            .round(),
                        value: style.borderWidth,
                        label: '${style.borderWidth.round()}',
                        onChanged: viewModel.previewBorderWidth,
                        onChangeEnd: (_) =>
                            unawaited(viewModel.commitBorderWidth()),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text('${style.borderWidth.round()}',
                      style: _label, textAlign: TextAlign.end),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('COLOR', style: _label),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final Color c in OverlayStyle.palette)
                        _Swatch(
                          color: c,
                          selected: c == style.borderColor,
                          onTap: () => unawaited(viewModel.setBorderColor(c)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  TextStyle get _label => GoogleFonts.poiretOne(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 14 * 0.1,
        color: kGold,
      );
}

class _Swatch extends StatelessWidget {
  const _Swatch(
      {required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Border color ${color.toARGB32().toRadixString(16)}',
      button: true,
      selected: selected,
      child: GestureDetector(
        key: ValueKey('swatch${color.toARGB32().toRadixString(16)}'),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: selected ? kCream : kGold.withAlpha(90),
                width: selected ? 3 : 1),
          ),
        ),
      ),
    );
  }
}
