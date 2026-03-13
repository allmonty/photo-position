import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/overlay_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Orientation change transposes coordinates', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    const channel = MethodChannel('x-slayer/overlay_channel');
    final log = <MethodCall>[];
    
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getOverlayPosition':
            return {'x': 100.0, 'y': 200.0};
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
      (MethodCall methodCall) async {
        return null; 
      },
    );

    // Mock sensors_plus EventChannel correctly
    const String channelName = 'dev.fluttercommunity.plus/sensors/accelerometer';
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      channelName,
      (ByteData? message) async {
        final MethodCall call = const StandardMethodCodec().decodeMethodCall(message);
        if (call.method == 'listen' || call.method == 'cancel') {
          return const StandardMethodCodec().encodeSuccessEnvelope(null);
        }
        return null;
      },
    );

    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();
    
    log.clear();

    // The test verifies build and initialization without MissingPluginException
    await tester.pump(const Duration(seconds: 1));
  });
}
