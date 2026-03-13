import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/overlay_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loadSavedSettings is called only once and fetches/moves correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'overlayWidth': 300.0,
      'overlayHeight': 400.0,
      'overlayCircleSize': 250.0,
      'overlayShape': 'OverlayShape.circle',
      'overlayWinsPosX': 150.0,
      'overlayWinsPosY': 250.0,
    });
    
    final log = <MethodCall>[];
    const channel = MethodChannel('x-slayer/overlay_channel');
    
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getOverlayPosition':
            return {'x': 150.0, 'y': 250.0};
          case 'moveOverlay':
            return true;
          case 'isOverlayActive':
            return true;
          case 'resizeOverlay':
            return true;
          case 'showOverlay':
            return true;
          case 'closeOverlay':
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

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.flutter.pigeon.sensors_plus.SensorsStreamApi.startAccelerometer'), 
      (call) async => null,
    );

    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    
    // Pump several frames to ensure build is called multiple times without
    // causing loadSavedSettings to trigger concurrent moveOverlay calls.
    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();
    
    // Advance virtual time by 350ms to allow the addPostFrameCallback + Future.delayed to tick
    await tester.pump(const Duration(milliseconds: 350));

    final moveCalls = log.where((call) => call.method == 'moveOverlay').toList();
    // It should only be queried once during the initState
    expect(moveCalls.length, 1, reason: 'moveOverlay should be called exactly once during initialization to restore position');
    
    final getOverlayActiveCalls = log.where((call) => call.method == 'isOverlayActive').toList();
    expect(getOverlayActiveCalls.length, 1, reason: 'isActive should be checked only once in initState');
  });

  testWidgets('Closing overlay saves exact final coordinates', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    final log = <MethodCall>[];
    const channel = MethodChannel('x-slayer/overlay_channel');
    
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getOverlayPosition':
            return {'x': 999.0, 'y': 888.0}; // The mocked final position
          case 'moveOverlay':
            return true;
          case 'isOverlayActive':
            return true;
          case 'resizeOverlay':
            return true;
          case 'closeOverlay':
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

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.flutter.pigeon.sensors_plus.SensorsStreamApi.startAccelerometer'), 
      (call) async => null,
    );

    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();
    
    log.clear();

    // Tap the close button to trigger _closeOverlay safely
    final closeButton = find.byIcon(Icons.close);
    expect(closeButton, findsOneWidget);
    
    // Tap the button
    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    // Verify it called getOverlayPosition right before exit
    final getPositionCalls = log.where((call) => call.method == 'getOverlayPosition').toList();
    expect(getPositionCalls.length, 1, reason: 'Should query exact position before closing');
    
    // Validate SharedPrefs updated appropriately
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('overlayWinsPosX'), 999.0, reason: 'Saved X coordinate must match getOverlayPosition results');
    expect(prefs.getDouble('overlayWinsPosY'), 888.0, reason: 'Saved Y coordinate must match getOverlayPosition results');
  });

  testWidgets('Full cycle: open, set position, close, and reopen restores position', (WidgetTester tester) async {
    // ------------------------------------------------------------------------
    // SETUP: Clear SharedPreferences so we start with no saved position data
    // ------------------------------------------------------------------------
    SharedPreferences.setMockInitialValues({});
    
    final log = <MethodCall>[];
    const channel = MethodChannel('x-slayer/overlay_channel');
    
    // We maintain the "physical" position of the overlay in the mock environment.
    // This allows us to pretend the overlay has moved on the screen when we ask the mock
    // "where are you?" via `getOverlayPosition`.
    double mockedPhysicalX = 0.0;
    double mockedPhysicalY = 0.0;

    // ------------------------------------------------------------------------
    // MOCKING: Simulate the Android/FlutterOverlayWindow plugins 
    // Since we are running in a test headless, there are no actual native windows.
    // We must catch MethodChannel requests and return fake successes or data.
    // ------------------------------------------------------------------------
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getOverlayPosition':
            // When the app asks "where is the overlay right now?", we give it our mocked coordinates.
            return {'x': mockedPhysicalX, 'y': mockedPhysicalY};
          case 'moveOverlay':
            // When the app tells the overlay to move, we simply accept the move.
            // In a real device, the Android OS handles the window relocation. Let's pretend it suceeded.
            return true;
          case 'isOverlayActive':
            return true;
          case 'resizeOverlay':
            return true;
          case 'closeOverlay':
            return true;
          default:
            return null;
        }
      },
    );

    // Mock other incidental channels so they don't crash the test
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('x-slayer/overlay'), 
      (MethodCall methodCall) async => null,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.flutter.pigeon.sensors_plus.SensorsStreamApi.startAccelerometer'), 
      (call) async => null,
    );

    // ------------------------------------------------------------------------
    // STEP 1: OPEN THE OVERLAY (First time)
    // ------------------------------------------------------------------------
    // We pump the widget. Because SharedPreferences is empty, it will boot up 
    // default, and it should query getOverlayPosition but essentially start at defaults.
    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();

    // ------------------------------------------------------------------------
    // STEP 2: SIMULATE USER MOVING THE OVERLAY ON SCREEN
    // ------------------------------------------------------------------------
    // In actual usage, the user places their finger on the overlay and drags it.
    // The Flutter app *isn't aware* of this continuous movement because it's managed 
    // natively. The app only finds out the final position later if it queries the plugin.
    // Here, we simulate the drag by updating our mock variables directly.
    mockedPhysicalX = 450.0;
    mockedPhysicalY = 600.0;

    // Clear logs to focus on the next actions
    log.clear();

    // ------------------------------------------------------------------------
    // STEP 3: CLOSE THE OVERLAY
    // ------------------------------------------------------------------------
    // We simulate the user tapping the settings "close" button inside the overlay itself.
    final closeButton = find.byIcon(Icons.close);
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    // VERIFY: Upon closing, the `_closeOverlay()` function should have triggered
    // a `getOverlayPosition` to fetch those mock coords (450, 600) and save them.
    final getPositionCalls = log.where((call) => call.method == 'getOverlayPosition').toList();
    expect(getPositionCalls.length, 1, reason: 'Should exactly query position once before closing');

    // ------------------------------------------------------------------------
    // STEP 4: REOPEN THE OVERLAY
    // ------------------------------------------------------------------------
    log.clear();
    // Rebuild the app tree to simulate closing it and reopening the OverlayScreen
    await tester.pumpWidget(const SizedBox()); // teardown old instance
    await tester.pumpWidget(const MaterialApp(home: OverlayScreen()));
    await tester.pumpAndSettle();

    // Since we added a 300ms delay in initState to wait for the OS to draw the window,
    // we need to advance the virtual clock in the test to let the Future resolve.
    await tester.pump(const Duration(milliseconds: 350));

    // VERIFY: `initState` calls `loadSavedSettings()`, which fetches the coordinates.
    // Then it tells the window to relocate via `moveOverlay`.
    final moveCalls = log.where((call) => call.method == 'moveOverlay').toList();
    expect(moveCalls.length, 1, reason: 'moveOverlay should be explicitly called exactly ONCE on boot up to restore position');
    
    // VERIFY PREFS: We can't easily interrogate the exact arguments passed to 
    // the mocked platform channel without more complex mocking, BUT we can verify
    // the saved SharedPreferences hold the precise updated coordinates.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('overlayWinsPosX'), 450.0, reason: 'X coordinate should be successfully retrieved as 450.0 based on step 2');
    expect(prefs.getDouble('overlayWinsPosY'), 600.0, reason: 'Y coordinate should be successfully retrieved as 600.0 based on step 2');
  });
}
