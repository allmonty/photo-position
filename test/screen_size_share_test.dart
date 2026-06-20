import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/main.dart';
import 'package:photo_position/overlay_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The overlay is meant to stay glued to the physical device (like a sticker
// on the glass), so rotating it is a pure rotation of its offset from the
// screen center -- it doesn't need to know the screen's actual dimensions
// at all (see transposeOverlayOffset). The real screen size is still shared
// with the overlay once at startup (below), but only for the in-app debug
// label's "absolute position" display, not for correctness of the rotation
// itself -- which the second test here confirms by never sending it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Starting the overlay shares the real device screen size',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('x-slayer/overlay_channel'),
      (MethodCall call) async {
        switch (call.method) {
          case 'checkPermission':
            return true;
          case 'showOverlay':
            return true;
          case 'isOverlayActive':
            return true;
          default:
            return null;
        }
      },
    );

    final sentMessages = <dynamic>[];
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'x-slayer/overlay_messenger',
      (ByteData? message) async {
        sentMessages.add(const JSONMessageCodec().decodeMessage(message));
        return const JSONMessageCodec().encodeMessage(null);
      },
    );

    await tester.pumpWidget(const PhotoPositionApp());
    await tester.tap(find.text('Start Overlay'));
    await tester.pump();
    // Past the 500ms delay _showOverlay waits before sharing data.
    await tester.pump(const Duration(milliseconds: 600));

    expect(sentMessages, isNotEmpty,
        reason: 'Starting the overlay should share data with it');
    final Map<dynamic, dynamic> payload =
        sentMessages.last as Map<dynamic, dynamic>;
    // Logical size = 1080x2400 physical / 3.0 devicePixelRatio = 360x800.
    expect(payload['screenLongSide'], 800.0);
    expect(payload['screenShortSide'], 360.0);
  });

  testWidgets(
      'Overlay rotates correctly even without ever receiving the shared '
      'screen size',
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

    // Deliberately do NOT send a screenLongSide/screenShortSide message --
    // rotation correctness must not depend on it.
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
