import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/overlay_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sensors_plus_platform_interface/sensors_plus_platform_interface.dart';
import 'dart:async';

class FakeSensorsPlatform extends SensorsPlatform {
  final StreamController<AccelerometerEvent> _accelerometerController = StreamController<AccelerometerEvent>.broadcast();

  void addAccelerometerEvent(AccelerometerEvent event) {
    _accelerometerController.add(event);
  }

  @override
  Stream<AccelerometerEvent> accelerometerEventStream({Duration samplingPeriod = SensorInterval.normalInterval}) {
    return _accelerometerController.stream;
  }
}

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
        return null; // Mock EventChannel setup
      },
    );

    final fakeSensors = FakeSensorsPlatform();
    SensorsPlatform.instance = fakeSensors;
    
    // Changing orientation test logic
    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 350));
    
    log.clear();

    // Send initial Portrait Accelerometer event (y > x)
    fakeSensors.addAccelerometerEvent(AccelerometerEvent(0.0, 9.8, 0.0, DateTime.now()));
    await tester.pumpAndSettle();

    // Send Landscape Accelerometer event (x > y)
    fakeSensors.addAccelerometerEvent(AccelerometerEvent(9.8, 0.0, 0.0, DateTime.now()));
    await tester.pumpAndSettle();

    final moveCalls = log.where((call) => call.method == 'moveOverlay').toList();
    expect(moveCalls.isNotEmpty, true, reason: 'moveOverlay should be called on orientation change to landscape');
  });

  testWidgets('Orientation unchanged does not transpose coordinates', (WidgetTester tester) async {
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

    final fakeSensors = FakeSensorsPlatform();
    SensorsPlatform.instance = fakeSensors;

    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 350));
    
    log.clear();

    // Send same Portrait Accelerometer event: x = 0.0, y = 9.8, z = 0.0
    fakeSensors.addAccelerometerEvent(AccelerometerEvent(0.0, 9.8, 0.0, DateTime.now()));
    
    await tester.pumpAndSettle();

    final moveCalls = log.where((call) => call.method == 'moveOverlay').toList();
    expect(moveCalls.isEmpty, true, reason: 'moveOverlay should NOT be called if orientation does not change');
  });
}
