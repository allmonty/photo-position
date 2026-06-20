import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/overlay_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kept in its own file: FlutterOverlayWindow.overlayListener wraps a
// static, single-subscription StreamController, which can only ever be
// listened to once per test process. Sharing a file with another test that
// also pumps OverlayScreen() would make this test's listener registration
// silently fail (see the "Bad state: Stream has already been listened to"
// catch in OverlayScreen.initState).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Regression: square dragged to top-left in portrait should land '
      'near top-right after turning right',
      (WidgetTester tester) async {
    // User-reported requirement, measured via the in-app debug label
    // (_updateDebugAbsolutePosition) on a 1080x2400 @ 420dpi device: with
    // the square placed at absolute (100,125) in portrait, turning the
    // phone right should land it at absolute (790,100) -- i.e. the square
    // stays glued to the physical device (like a sticker on the glass)
    // rather than staying in the same logical/upright corner.
    const double devicePixelRatio = 420 / 160; // hw.lcd.density=420
    final double shortSide = 1080 / devicePixelRatio; // ~411.43
    final double longSide = 2400 / devicePixelRatio; // ~914.29

    const Offset desiredPortraitAbsolute = Offset(100, 125);
    const Offset desiredLandscapeAbsolute = Offset(790, 100);

    tester.view.physicalSize = const Size(100, 100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});

    // OverlayScreen() defaults to a 200x200 shape with no saved settings.
    final Offset contentOffset = overlayContentCenterOffset(
      shapeWidth: 200 + 20 * 2,
      shapeHeight: 200 + 20 * 2,
      panelWidth: 60,
      panelHeight: 120,
    );
    // getOverlayPosition()/moveOverlay() deal in the window's offset from
    // the screen center, not the absolute position shown by the debug
    // label -- convert the desired portrait absolute back to that.
    final Offset windowOffsetPortrait = Offset(
      desiredPortraitAbsolute.dx - shortSide / 2 - contentOffset.dx,
      desiredPortraitAbsolute.dy - longSide / 2 - contentOffset.dy,
    );

    final overlayChannelLog = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('x-slayer/overlay_channel'),
      (MethodCall call) async {
        overlayChannelLog.add(call);
        switch (call.method) {
          case 'getOverlayPosition':
            return {'x': windowOffsetPortrait.dx, 'y': windowOffsetPortrait.dy};
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

    expect(accelerometerSink, isNotNull);
    overlayChannelLog.clear();

    void emit(double x, double y) {
      accelerometerSink!.success(<double>[
        x,
        y,
        0.0,
        DateTime.now().microsecondsSinceEpoch.toDouble(),
      ]);
    }

    emit(0.0, 9.8); // settle on portraitUp
    await tester.pump(const Duration(milliseconds: 300));
    emit(-9.8, 0.0); // turn right -> landscapeRight
    await tester.pump(const Duration(milliseconds: 300));

    final moveCalls =
        overlayChannelLog.where((c) => c.method == 'moveOverlay').toList();
    expect(moveCalls, isNotEmpty,
        reason: 'Rotating should reposition the overlay');

    final args = moveCalls.last.arguments as Map;
    final Offset resultingAbsolute = Offset(
      longSide / 2 + (args['x'] as num) + contentOffset.dx,
      shortSide / 2 + (args['y'] as num) + contentOffset.dy,
    );

    expect(resultingAbsolute.dx, closeTo(desiredLandscapeAbsolute.dx, 2));
    expect(resultingAbsolute.dy, closeTo(desiredLandscapeAbsolute.dy, 2));
  });
}
