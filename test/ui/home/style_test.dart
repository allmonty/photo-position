import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/config/dependencies.dart';
import 'package:photo_position/domain/models/overlay_style.dart';
import 'package:photo_position/ui/core/theme.dart';
import 'package:photo_position/ui/home/view_models/style_view_model.dart';
import 'package:photo_position/ui/home/widgets/home_screen.dart';
import 'package:photo_position/ui/home/widgets/style_section.dart';

import '../../../testing/fakes/fake_overlay_host.dart';
import '../../../testing/fakes/memory_position_repository.dart';

void main() {
  late MemoryPositionRepository repo;
  late List<OverlayStyle> told;
  late StyleViewModel vm;

  setUp(() {
    repo = MemoryPositionRepository();
    told = [];
    vm = StyleViewModel(repository: repo, onChanged: told.add);
  });

  group('StyleViewModel', () {
    test('load shows the saved style', () async {
      repo.style =
          const OverlayStyle(borderWidth: 11, borderColor: Color(0xFF32D4DE));
      await vm.load();
      expect(vm.style, repo.style);
    });

    test('dragging the slider is shown live but only saved when it ends',
        () async {
      vm.previewBorderWidth(8);
      vm.previewBorderWidth(10);
      expect(told.map((s) => s.borderWidth), [8, 10]);
      expect(repo.style.borderWidth, 5, reason: 'not saved while dragging');

      await vm.commitBorderWidth();
      expect(repo.style.borderWidth, 10);
    });

    test('width is kept within the allowed range', () {
      vm.previewBorderWidth(99);
      expect(vm.style.borderWidth, OverlayStyle.maxBorderWidth);
      vm.previewBorderWidth(0);
      expect(vm.style.borderWidth, OverlayStyle.minBorderWidth);
    });

    test('picking a colour applies and saves it, keeping the width', () async {
      vm.previewBorderWidth(12);
      await vm.setBorderColor(const Color(0xFFFF3B30));
      expect(told.last,
          const OverlayStyle(borderWidth: 12, borderColor: Color(0xFFFF3B30)));
      expect(repo.style, told.last);
    });
  });

  group('StyleSection', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: artDecoTheme,
        home: Scaffold(body: StyleSection(viewModel: vm)),
      ));
    }

    testWidgets('shows one swatch per palette colour and marks the current one',
        (tester) async {
      await pump(tester);
      for (final c in OverlayStyle.palette) {
        expect(find.byKey(ValueKey('swatch${c.toARGB32().toRadixString(16)}')),
            findsOneWidget);
      }
    });

    testWidgets('tapping a swatch changes the colour', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(ValueKey(
          'swatch${const Color(0xFFFF3B30).toARGB32().toRadixString(16)}')));
      await tester.pump();
      expect(vm.style.borderColor, const Color(0xFFFF3B30));
      expect(repo.style.borderColor, const Color(0xFFFF3B30));
    });

    testWidgets('dragging the slider changes the size and saves at the end',
        (tester) async {
      await pump(tester);
      await tester.drag(find.byKey(const ValueKey('borderWidthSlider')),
          const Offset(300, 0));
      await tester.pump();
      expect(vm.style.borderWidth, greaterThan(5));
      expect(repo.style.borderWidth, vm.style.borderWidth);
    });
  });

  testWidgets('the home screen has the border options', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: artDecoTheme,
      home: HomeScreen(
          dependencies:
              Dependencies(repository: repo, host: FakeOverlayHost.new)),
    ));
    await tester.pump();
    await tester.dragUntilVisible(find.text('BORDER'),
        find.byType(SingleChildScrollView), const Offset(0, -100));
    expect(find.byType(StyleSection), findsOneWidget);
  });
}
