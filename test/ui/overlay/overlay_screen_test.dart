import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/overlay_style.dart';
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
      home:
          OverlayScreen(viewModel: vm, messages: const Stream<dynamic>.empty()),
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
      home:
          OverlayScreen(viewModel: vm, messages: const Stream<dynamic>.empty()),
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

  group('messages from the main app', () {
    late StreamController<dynamic> messages;

    Future<void> pumpWithMessages(WidgetTester tester) async {
      service = FakeOverlayService();
      repo = MemoryPositionRepository()
        ..current = const PositionSlot(
          geometry: OverlayGeometry(
              left: 20,
              top: 30,
              width: 150,
              height: 150,
              shape: OverlayShape.square),
          screen: Size(400, 800),
        );
      vm = OverlayViewModel(service: service, repository: repo);
      messages = StreamController<dynamic>();
      await tester.pumpWidget(MaterialApp(
        theme: artDecoTheme,
        home: OverlayScreen(viewModel: vm, messages: messages.stream),
      ));
      await tester.pump();
    }

    testWidgets('close_overlay_and_reset closes, open starts it again',
        (tester) async {
      await pumpWithMessages(tester);

      messages.add({'action': 'close_overlay_and_reset'});
      await tester.pump();
      await tester.pump();
      expect(service.closed, isTrue);
      expect(vm.closed, isTrue);

      service.offset = Offset.zero; // fresh default window from the plugin
      messages.add({'action': 'open'});
      await tester.pump();
      await tester.pump();
      expect(vm.closed, isFalse);
      expect(service.visibleRect.topLeft, const Offset(20, 30));
    });

    testWidgets('load_position moves the shape', (tester) async {
      await pumpWithMessages(tester);
      const slot = PositionSlot(
        geometry: OverlayGeometry(
            left: 100,
            top: 200,
            width: 150,
            height: 150,
            shape: OverlayShape.square),
        screen: Size(400, 800),
      );
      messages.add({'action': 'load_position', 'slot': slot.toJson()});
      await tester.pump();
      await tester.pump();
      expect(service.visibleRect.topLeft, const Offset(100, 200));
    });

    testWidgets('set_style redraws the border with the new colour and width',
        (tester) async {
      await pumpWithMessages(tester);
      BoxDecoration border() => tester
          .widget<Container>(find.byKey(overlayShapeContainerKey))
          .decoration! as BoxDecoration;
      expect(border().border!.top.width, 5);

      const style =
          OverlayStyle(borderWidth: 12, borderColor: Color(0xFFFF3B30));
      messages.add({'action': 'set_style', 'style': style.toJson()});
      await tester.pump();
      await tester.pump();

      expect(border().border!.top.width, 12);
      expect(border().border!.top.color, const Color(0xFFFF3B30));
    });

    testWidgets('unknown or malformed messages are ignored', (tester) async {
      await pumpWithMessages(tester);
      messages.add('not a map');
      messages.add({'action': 'nope'});
      await tester.pump();
      expect(vm.closed, isFalse);
    });
  });
}
