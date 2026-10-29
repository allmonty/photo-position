import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/config/dependencies.dart';
import 'package:photo_position/main.dart';

import '../../../testing/fakes/fake_overlay_host.dart';
import '../../../testing/fakes/memory_position_repository.dart';

void main() {
  late FakeOverlayHost host;

  Future<void> pumpApp(WidgetTester tester, {bool permission = true}) async {
    host = FakeOverlayHost()..permissionGranted = permission;
    await tester.pumpWidget(PhotoPositionApp(
      dependencies: Dependencies(
        repository: MemoryPositionRepository(),
        host: () => host,
      ),
    ));
    await tester.pump();
  }

  testWidgets('shows the title, start button and instructions', (tester) async {
    await pumpApp(tester);
    expect(find.text('START OVERLAY'), findsOneWidget);
    expect(find.text('PHOTO POSITION OVERLAY'), findsOneWidget);
    expect(find.text('SAVED POSITIONS'), findsOneWidget);
    expect(find.textContaining('Drag the circle / square'), findsOneWidget);
  });

  testWidgets('start swaps to stop, stop swaps back', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('START OVERLAY'));
    await tester.pump();
    expect(find.text('STOP OVERLAY'), findsOneWidget);
    expect(find.text('OVERLAY ACTIVE'), findsOneWidget);

    await tester.tap(find.text('STOP OVERLAY'));
    await tester.pump();
    expect(find.text('START OVERLAY'), findsOneWidget);
  });

  testWidgets('closing from the overlay itself returns to idle',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('START OVERLAY'));
    await tester.pump();

    host.closeFromOverlay();
    await tester.pump();
    expect(find.text('START OVERLAY'), findsOneWidget);
  });

  testWidgets('denied permission shows a message and does not start',
      (tester) async {
    await pumpApp(tester, permission: false);
    await tester.tap(find.text('START OVERLAY'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('permission is required'), findsOneWidget);
    expect(find.text('START OVERLAY'), findsOneWidget);
  });
}
