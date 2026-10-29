import 'package:flutter/material.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:photo_position/ui/core/theme.dart';
import 'package:photo_position/ui/home/view_models/slots_view_model.dart';
import 'package:photo_position/ui/home/widgets/slot_thumbnail.dart';

/// Three saved positions: tap a thumbnail to move the overlay there, the
/// save icon stores the overlay's current position, the cross empties it.
class SlotsSection extends StatelessWidget {
  const SlotsSection(
      {super.key, required this.viewModel, required this.onSelect});

  final SlotsViewModel viewModel;

  /// Called with the chosen slot after it became the current position.
  final void Function(PositionSlot slot) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < viewModel.slots.length; i++) _slot(context, i),
        ],
      ),
    );
  }

  Widget _slot(BuildContext context, int i) {
    final PositionSlot? slot = viewModel.slots[i];
    return Column(
      children: [
        GestureDetector(
          key: ValueKey('slot$i'),
          onTap: slot == null
              ? null
              : () async {
                  final PositionSlot? chosen = await viewModel.select(i);
                  if (chosen != null) onSelect(chosen);
                },
          child: SlotThumbnail(slot: slot),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey('saveSlot$i'),
              icon: const Icon(Icons.save_outlined, color: kGold),
              tooltip: 'Save current position to slot ${i + 1}',
              onPressed: () => viewModel.saveCurrentTo(i),
            ),
            IconButton(
              key: ValueKey('clearSlot$i'),
              icon: Icon(Icons.close,
                  color: kGold.withAlpha(slot == null ? 60 : 255)),
              tooltip: 'Empty slot ${i + 1}',
              onPressed: slot == null ? null : () => viewModel.clear(i),
            ),
          ],
        ),
      ],
    );
  }
}
