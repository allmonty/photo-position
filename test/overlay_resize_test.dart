import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/overlay_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Resizing (drag handles) and shape toggling are core interactive features
// with real logic -- clamping to [minSize, maxSize], keeping the circle's
// width/height in sync, and picking a sane size when converting a
// non-uniform square into a circle -- none of which had any coverage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void mockOverlayChannels(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('x-slayer/overlay_channel'),
      (MethodCall call) async {
        switch (call.method) {
          case 'getOverlayPosition':
            return {'x': 0.0, 'y': 0.0};
          case 'moveOverlay':
            return true;
          case 'isOverlayActive':
            return true;
          case 'resizeOverlay':
            return true;
          default:
            return null;
        }
      },
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('x-slayer/overlay'),
      (MethodCall call) async => null,
    );
    tester.binding.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/sensors/accelerometer'),
      MockStreamHandler.inline(
        onListen: (Object? arguments, MockStreamHandlerEventSink events) {},
      ),
    );
  }

  // pumpAndSettle() only flushes pending *frames*, not the bare
  // Future.delayed(600ms) inside _restoreOverlayPosition -- this advances
  // fake time far enough past it so the test doesn't end with that timer
  // still pending (which flutter_test treats as a failure).
  Future<void> settleRestoreDelay(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 1));

  testWidgets('Dragging the horizontal handle resizes the square width, '
      'clamped to [minSize, maxSize]', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'overlayShape': 'OverlayShape.square',
      'overlayWidth': 200.0,
      'overlayHeight': 200.0,
    });
    mockOverlayChannels(tester);

    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();
    await settleRestoreDelay(tester);

    await tester.drag(find.byKey(horizontalResizeHandleKey), const Offset(100, 0));
    await tester.pump();
    expect(tester.getSize(find.byKey(overlayShapeContainerKey)).width, 300);

    // Drag far past maxSize (500) -- must clamp, not overflow.
    await tester.drag(find.byKey(horizontalResizeHandleKey), const Offset(1000, 0));
    await tester.pump();
    expect(tester.getSize(find.byKey(overlayShapeContainerKey)).width, 500);

    // Drag far past minSize (50) the other way -- must clamp, not go negative.
    await tester.drag(find.byKey(horizontalResizeHandleKey), const Offset(-1000, 0));
    await tester.pump();
    expect(tester.getSize(find.byKey(overlayShapeContainerKey)).width, 50);
  });

  testWidgets('Dragging the vertical handle resizes the square height, '
      'clamped to [minSize, maxSize]', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'overlayShape': 'OverlayShape.square',
      'overlayWidth': 200.0,
      'overlayHeight': 200.0,
    });
    mockOverlayChannels(tester);

    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();
    await settleRestoreDelay(tester);

    await tester.drag(find.byKey(verticalResizeHandleKey), const Offset(0, -80));
    await tester.pump();
    expect(tester.getSize(find.byKey(overlayShapeContainerKey)).height, 120);

    await tester.drag(find.byKey(verticalResizeHandleKey), const Offset(0, 1000));
    await tester.pump();
    expect(tester.getSize(find.byKey(overlayShapeContainerKey)).height, 500);
  });

  testWidgets('Dragging the circle handle resizes it uniformly, clamped to '
      '[minSize, maxSize]', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'overlayShape': 'OverlayShape.circle',
      'overlayCircleSize': 200.0,
    });
    mockOverlayChannels(tester);

    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();
    await settleRestoreDelay(tester);

    await tester.drag(find.byKey(circleResizeHandleKey), const Offset(0, 50));
    await tester.pump();
    final Size size = tester.getSize(find.byKey(overlayShapeContainerKey));
    expect(size.width, 250);
    expect(size.height, 250); // stays uniform -- it's a circle.

    await tester.drag(find.byKey(circleResizeHandleKey), const Offset(0, -1000));
    await tester.pump();
    expect(tester.getSize(find.byKey(overlayShapeContainerKey)).width, 50);
  });

  testWidgets('Toggling shape from a non-uniform square to a circle uses '
      'the smaller dimension', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'overlayShape': 'OverlayShape.square',
      'overlayWidth': 300.0,
      'overlayHeight': 150.0,
    });
    mockOverlayChannels(tester);

    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();
    await settleRestoreDelay(tester);

    await tester.tap(find.byTooltip('Toggle shape'));
    await tester.pump();

    final Container shape =
        tester.widget<Container>(find.byKey(overlayShapeContainerKey));
    expect((shape.decoration as BoxDecoration).shape, BoxShape.circle);
    final Size size = tester.getSize(find.byKey(overlayShapeContainerKey));
    expect(size.width, 150);
    expect(size.height, 150);
  });

  testWidgets('Toggling shape back to square keeps the uniform size',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'overlayShape': 'OverlayShape.circle',
      'overlayCircleSize': 200.0,
    });
    mockOverlayChannels(tester);

    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();
    await settleRestoreDelay(tester);

    await tester.tap(find.byTooltip('Toggle shape'));
    await tester.pump();

    final Container shape =
        tester.widget<Container>(find.byKey(overlayShapeContainerKey));
    expect((shape.decoration as BoxDecoration).shape, BoxShape.rectangle);
    expect(tester.getSize(find.byKey(overlayShapeContainerKey)), const Size(200, 200));
  });
}
