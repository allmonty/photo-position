import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/overlay_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The overlay is meant to stay glued to the physical device (like a sticker
// on the glass), so rotating it is a pure rotation of its offset from the
// screen center -- it doesn't need to know the screen's actual dimensions
// at all (see transposeOverlayOffset). This test drives the full
// accelerometer -> debounce -> transpose -> moveOverlay pipeline through
// OverlayScreen's public widget surface, rather than calling the pure
// functions directly, to catch wiring regressions the unit tests can't.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Rotating the device transposes the overlay position',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final overlayChannelLog = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('x-slayer/overlay_channel'),
      (MethodCall call) async {
        overlayChannelLog.add(call);
        switch (call.method) {
          case 'getOverlayPosition':
            return {'x': -180.0, 'y': -370.0};
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

    MockStreamHandlerEventSink? accelerometerSink;
    tester.binding.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/sensors/accelerometer'),
      MockStreamHandler.inline(
        onListen: (Object? arguments, MockStreamHandlerEventSink events) {
          accelerometerSink = events;
        },
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();

    expect(accelerometerSink, isNotNull,
        reason: 'OverlayScreen should subscribe to the accelerometer stream');
    overlayChannelLog.clear();

    void emit(double x, double y) {
      accelerometerSink!.success(<double>[
        x,
        y,
        0.0,
        DateTime.now().microsecondsSinceEpoch.toDouble(),
      ]);
    }

    // Settle on portraitUp first (no transpose expected for the first
    // reading), then rotate to landscapeRight.
    emit(0.0, 9.8);
    await tester.pump(const Duration(milliseconds: 300));
    emit(-9.8, 0.0);
    await tester.pump(const Duration(milliseconds: 300));

    final moveCalls =
        overlayChannelLog.where((c) => c.method == 'moveOverlay').toList();
    expect(moveCalls, isNotEmpty,
        reason: 'Rotating should reposition the overlay');

    // Expected result computed by the same production composition
    // _transposeOverlayPosition uses. OverlayScreen() defaults to a 200x200
    // shape with no saved settings in this test; see
    // overlayContentCenterOffset for why the window's gravity-anchored
    // center isn't the same point as the shape's true visual center.
    final Offset contentOffset = overlayContentCenterOffset(
      shapeWidth: 200 + 20 * 2, // _overlayWidth + resizeHandleSize*2
      shapeHeight: 200 + 20 * 2,
      panelWidth: 60,
      panelHeight: 120,
    );
    final Offset expected = transposeWindowOffset(
      windowOffset: const Offset(-180.0, -370.0),
      contentOffset: contentOffset,
      before: OrientationState.portraitUp,
      after: OrientationState.landscapeRight,
    )!;

    final args = moveCalls.last.arguments as Map;
    expect(args['x'], expected.dx.toInt());
    expect(args['y'], expected.dy.toInt());
  });
}
