import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photo_position/config/dependencies.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:photo_position/ui/core/theme.dart';
import 'package:photo_position/ui/home/widgets/home_screen.dart';
import 'package:photo_position/ui/home/widgets/slot_thumbnail.dart';
import 'package:photo_position/ui/overlay/view_models/overlay_view_model.dart';
import 'package:photo_position/ui/overlay/widgets/overlay_screen.dart';

import '../testing/fakes/fake_overlay_host.dart';
import '../testing/fakes/fake_overlay_service.dart';
import '../testing/fakes/memory_position_repository.dart';

/// Runs on a real device/simulator (`flutter test integration_test -d <id>`),
/// rotating the actual display. The native overlay window only exists on
/// Android, so the window side is the fake; what this checks on every
/// platform is that the shape's absolute rectangle and the widgets drawn for
/// it survive a real rotation. tool/rotation_e2e.sh covers the real window.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(
      () => SystemChrome.setPreferredOrientations(DeviceOrientation.values));

  testWidgets(
      'overlay stays on the same part of the glass across a real rotation',
      (tester) async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await tester.pumpAndSettle();
    final service = FakeOverlayService(screen: const Size(400, 800));
    const glass = OverlayGeometry(
        left: 20, top: 30, width: 120, height: 120, shape: OverlayShape.square);
    final repo = MemoryPositionRepository()
      ..current = const PositionSlot(geometry: glass, screen: Size(400, 800));
    final vm = OverlayViewModel(service: service, repository: repo);
    await tester.pumpWidget(MaterialApp(
      theme: artDecoTheme,
      home: OverlayScreen(viewModel: vm, listenForMainApp: false),
    ));
    await tester.pumpAndSettle();
    expect(service.visibleRect.topLeft, const Offset(20, 30));

    // Real device rotation, then the screen change the native bridge would report.
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft]);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    service.rotateTo(const Size(800, 400), rotation: 1);
    await tester.pumpAndSettle();

    // The glass' top-left corner is the display's bottom-left corner now.
    expect(service.visibleRect.topLeft, const Offset(30, 260));
    expect(tester.getSize(find.byKey(overlayShapeContainerKey)),
        const Size(120, 120));
    expect(repo.current!.geometry, glass);
  });

  testWidgets('home screen shows saved positions in portrait and landscape',
      (tester) async {
    final repo = MemoryPositionRepository()
      ..slots[0] = const PositionSlot(
        geometry: OverlayGeometry(
            left: 50,
            top: 80,
            width: 120,
            height: 120,
            shape: OverlayShape.square),
        screen: Size(400, 800),
      );
    for (final o in [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft
    ]) {
      await SystemChrome.setPreferredOrientations([o]);
      await tester.pumpWidget(MaterialApp(
          theme: artDecoTheme,
          home: HomeScreen(
              dependencies:
                  Dependencies(repository: repo, host: FakeOverlayHost.new))));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.scrollUntilVisible(find.byType(SlotThumbnail).first, 200);
      expect(find.byType(SlotThumbnail), findsNWidgets(3));
    }
  });
}
