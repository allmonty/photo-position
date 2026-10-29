import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:photo_position/ui/core/theme.dart';
import 'package:photo_position/ui/overlay/view_models/overlay_view_model.dart';
import 'package:photo_position/ui/overlay/widgets/overlay_screen.dart';

import '../../../testing/fakes/fake_overlay_service.dart';
import '../../../testing/fakes/memory_position_repository.dart';

void main() {
  late FakeOverlayService service;
  late MemoryPositionRepository repo;
  late OverlayViewModel vm;

  Future<void> pumpOverlay(WidgetTester tester, OverlayShape shape) async {
    service = FakeOverlayService();
    repo = MemoryPositionRepository()
      ..current = PositionSlot(
        geometry: OverlayGeometry(
            left: 50, top: 100, width: 100, height: 100, shape: shape),
        screen: const Size(400, 800),
      );
    vm = OverlayViewModel(service: service, repository: repo);
    await tester.pumpWidget(MaterialApp(
      theme: artDecoTheme,
      home: OverlayScreen(viewModel: vm, listenForMainApp: false),
    ));
    await tester.pump();
  }

  testWidgets('dragging the square handles resizes and persists',
      (tester) async {
    await pumpOverlay(tester, OverlayShape.square);

    await tester.drag(
        find.byKey(horizontalResizeHandleKey), const Offset(40, 0));
    await tester.pump();
    await tester.drag(find.byKey(verticalResizeHandleKey), const Offset(0, 30));
    await tester.pump();

    expect(vm.geometry!.width, 140);
    expect(vm.geometry!.height, 130);
    expect(repo.current!.geometry.width, 140);
    expect(service.dragEnabled, isTrue);
  });

  testWidgets('the circle has one diagonal handle', (tester) async {
    await pumpOverlay(tester, OverlayShape.circle);

    expect(find.byKey(horizontalResizeHandleKey), findsNothing);
    await tester.drag(find.byKey(circleResizeHandleKey), const Offset(0, 50));
    await tester.pump();

    expect(vm.geometry!.width, 150);
    expect(vm.geometry!.height, 150);
  });

  testWidgets('tapping the shape hides and shows the panel', (tester) async {
    await pumpOverlay(tester, OverlayShape.square);
    expect(find.byKey(closeButtonKey), findsOneWidget);

    await tester.tap(find.byKey(overlayShapeContainerKey));
    await tester.pump();
    expect(find.byKey(closeButtonKey), findsNothing);

    await tester.tap(find.byKey(overlayShapeContainerKey));
    await tester.pump();
    expect(find.byKey(closeButtonKey), findsOneWidget);
  });

  testWidgets('the shape toggle switches circle and square', (tester) async {
    await pumpOverlay(tester, OverlayShape.square);
    await tester.tap(find.byTooltip('Toggle shape'));
    await tester.pump();
    expect(vm.geometry!.shape, OverlayShape.circle);
  });

  testWidgets('close saves the position and closes the native window',
      (tester) async {
    await pumpOverlay(tester, OverlayShape.square);
    await tester.tap(find.byKey(closeButtonKey));
    await tester.pump();
    await tester.pump();
    expect(service.closed, isTrue);
    expect(repo.current!.geometry, vm.geometry);
  });

  testWidgets(
      'a tall rectangle is drawn wide after the phone turns, in the same glass spot',
      (tester) async {
    service = FakeOverlayService();
    repo = MemoryPositionRepository()
      ..current = const PositionSlot(
        geometry: OverlayGeometry(
            left: 20,
            top: 30,
            width: 100,
            height: 300,
            shape: OverlayShape.square),
        screen: Size(400, 800),
      );
    vm = OverlayViewModel(service: service, repository: repo);
    await tester.pumpWidget(MaterialApp(
      theme: artDecoTheme,
      home: OverlayScreen(viewModel: vm, listenForMainApp: false),
    ));
    await tester.pump();
    expect(tester.getSize(find.byKey(overlayShapeContainerKey)),
        const Size(100, 300));

    service.rotateTo(const Size(800, 400), rotation: 1);
    await tester.pump();
    await tester.pump();

    expect(tester.getSize(find.byKey(overlayShapeContainerKey)),
        const Size(300, 100));
    expect(service.window.width, greaterThanOrEqualTo(300));
  });
}
