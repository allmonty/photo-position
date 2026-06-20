import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/main.dart';

// Starting/stopping the overlay from the main app -- including the
// permission-not-yet-granted path and the cross-isolate notification the
// overlay sends back when it's closed from its own UI -- had no coverage
// beyond a static "does the button render" smoke test.
void main() {
  void mockOverlayChannel(
    WidgetTester tester,
    Map<String, dynamic> Function(MethodCall) responses,
  ) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('x-slayer/overlay_channel'),
      (MethodCall call) async => responses(call)[call.method],
    );
  }

  testWidgets(
      'Starting the overlay (permission already granted) calls showOverlay '
      'and shares the port name',
      (WidgetTester tester) async {
    final log = <MethodCall>[];
    mockOverlayChannel(tester, (call) {
      log.add(call);
      return const {'checkPermission': true, 'showOverlay': true};
    });

    final sentMessages = <dynamic>[];
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'x-slayer/overlay_messenger',
      (ByteData? message) async {
        sentMessages.add(const JSONMessageCodec().decodeMessage(message));
        return const JSONMessageCodec().encodeMessage(null);
      },
    );

    await tester.pumpWidget(const PhotoPositionApp());
    await tester.tap(find.text('START OVERLAY'));
    await tester.pump();
    // Past the 500ms delay _showOverlay waits before sharing data.
    await tester.pump(const Duration(milliseconds: 600));

    expect(log.where((c) => c.method == 'showOverlay'), hasLength(1));
    expect(sentMessages, isNotEmpty);
    expect(
      (sentMessages.last as Map)['portName'],
      'photo_position_overlay_port',
    );
    expect(find.text('STOP OVERLAY'), findsOneWidget);
    expect(find.text('OVERLAY ACTIVE'), findsOneWidget);
  });

  testWidgets(
      'Starting the overlay without permission requests it instead of '
      'showing the overlay',
      (WidgetTester tester) async {
    final log = <MethodCall>[];
    mockOverlayChannel(tester, (call) {
      log.add(call);
      return const {
        'checkPermission': false,
        'requestPermission': true,
        'showOverlay': true,
      };
    });

    await tester.pumpWidget(const PhotoPositionApp());
    await tester.tap(find.text('START OVERLAY'));
    await tester.pumpAndSettle();

    expect(log.where((c) => c.method == 'requestPermission'), hasLength(1));
    expect(log.where((c) => c.method == 'showOverlay'), isEmpty,
        reason: 'Must not show the overlay in the same tap that requested '
            'permission -- the user has to tap Start Overlay again');
    expect(find.text('START OVERLAY'), findsOneWidget);
  });

  testWidgets(
      'Stopping the overlay sends the close action and returns to the '
      'idle UI',
      (WidgetTester tester) async {
    mockOverlayChannel(tester, (call) {
      return const {'checkPermission': true, 'showOverlay': true};
    });

    final sentMessages = <dynamic>[];
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'x-slayer/overlay_messenger',
      (ByteData? message) async {
        sentMessages.add(const JSONMessageCodec().decodeMessage(message));
        return const JSONMessageCodec().encodeMessage(null);
      },
    );

    await tester.pumpWidget(const PhotoPositionApp());
    await tester.tap(find.text('START OVERLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('STOP OVERLAY'), findsOneWidget);

    sentMessages.clear();
    await tester.tap(find.text('STOP OVERLAY'));
    await tester.pumpAndSettle();

    expect(sentMessages, isNotEmpty);
    expect((sentMessages.last as Map)['action'], 'close_overlay_and_reset');
    expect(find.text('START OVERLAY'), findsOneWidget);
  });

  testWidgets(
      'A close notification from the overlay itself returns the UI to '
      'idle, without the user tapping Stop Overlay',
      (WidgetTester tester) async {
    // The overlay runs in its own engine with no shared Dart state, so when
    // it's closed from its own UI it notifies this app via
    // IsolateNameServer (see HomeScreen._startBackgroundIsolate) instead.
    mockOverlayChannel(tester, (call) {
      return const {'checkPermission': true, 'showOverlay': true};
    });

    await tester.pumpWidget(const PhotoPositionApp());
    await tester.tap(find.text('START OVERLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('STOP OVERLAY'), findsOneWidget);

    final SendPort? overlayPort =
        IsolateNameServer.lookupPortByName('photo_position_overlay_port');
    expect(overlayPort, isNotNull);
    // ReceivePort/IsolateNameServer message delivery rides the VM's native
    // port mechanism, not Dart Timer/Future scheduling, so tester.pump()'s
    // fake-async clock never observes it -- runAsync lets it flow through
    // the real event loop instead.
    await tester.runAsync(() async {
      overlayPort!.send({'action': 'close_overlay'});
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.text('START OVERLAY'), findsOneWidget);
  });
}
