import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:photo_position/main.dart';
import 'package:photo_position/theme.dart';
import 'package:photo_position/ui/home/view_models/slots_view_model.dart';
import 'package:photo_position/ui/home/widgets/slot_thumbnail.dart';
import 'package:photo_position/ui/home/widgets/slots_section.dart';

import '../../../testing/fakes/memory_position_repository.dart';

const screen = Size(400, 800);
const current = PositionSlot(
  geometry: OverlayGeometry(
      left: 100, top: 200, width: 150, height: 150, shape: OverlayShape.circle),
  screen: screen,
);

void main() {
  late MemoryPositionRepository repo;
  late SlotsViewModel vm;

  setUp(() {
    repo = MemoryPositionRepository();
    vm = SlotsViewModel(repository: repo, screen: () => screen);
  });

  test('saving before the overlay was positioned does nothing', () async {
    await vm.load();
    await vm.saveCurrentTo(0);
    expect(vm.slots, [null, null, null]);
  });

  test('save, select and clear', () async {
    repo.current = current;
    await vm.load();
    await vm.saveCurrentTo(1);
    expect(vm.slots, [null, current, null]);

    repo.current = null;
    expect(await vm.select(1), current);
    expect(repo.current, current, reason: 'a new overlay opens at the slot');
    expect(await vm.select(0), isNull);

    await vm.clear(1);
    expect(vm.slots, [null, null, null]);
  });

  testWidgets('section shows three slots; tapping a filled one selects it',
      (tester) async {
    repo.current = current;
    await vm.load();
    await vm.saveCurrentTo(2);
    PositionSlot? picked;

    await tester.pumpWidget(MaterialApp(
      theme: artDecoTheme,
      home: Scaffold(
        body: SlotsSection(viewModel: vm, onSelect: (s) => picked = s),
      ),
    ));

    expect(find.byType(SlotThumbnail), findsNWidgets(3));
    await tester.tap(find.byKey(const ValueKey('slot0')));
    await tester.pump();
    expect(picked, isNull, reason: 'empty slot does nothing');

    await tester.tap(find.byKey(const ValueKey('slot2')));
    await tester.pump();
    expect(picked, current);

    await tester.tap(find.byKey(const ValueKey('saveSlot0')));
    await tester.pump();
    expect(vm.slots[0], current);
    await tester.tap(find.byKey(const ValueKey('clearSlot2')));
    await tester.pump();
    expect(vm.slots[2], isNull);
  });

  testWidgets('thumbnail has the phone proportions of its saved screen',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: SlotThumbnail(slot: current, height: 200)),
    ));
    expect(tester.getSize(find.byType(SlotThumbnail)), const Size(100, 200));
  });

  testWidgets('home screen shows the saved positions', (tester) async {
    repo.slots[1] = current;
    await tester.pumpWidget(MaterialApp(
      theme: artDecoTheme,
      home: HomeScreen(repository: repo),
    ));
    await tester.pump();
    await tester.dragUntilVisible(
      find.byType(SlotThumbnail).first,
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    expect(find.byType(SlotThumbnail), findsNWidgets(3));
    expect(find.text('SAVED POSITIONS'), findsOneWidget);
  });
}
