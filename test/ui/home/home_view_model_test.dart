import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:photo_position/ui/home/view_models/home_view_model.dart';

import '../../../testing/fakes/fake_overlay_host.dart';

const slot = PositionSlot(
  geometry: OverlayGeometry(
      left: 10, top: 20, width: 100, height: 100, shape: OverlayShape.square),
  screen: Size(400, 800),
);

void main() {
  late FakeOverlayHost host;
  late HomeViewModel vm;

  setUp(() {
    host = FakeOverlayHost();
    vm = HomeViewModel(host: host);
  });

  tearDown(() => vm.dispose());

  test('start shows the overlay and marks it active', () async {
    expect(await vm.start(), isNull);
    expect(host.showCalls, 1);
    expect(vm.isOverlayActive, isTrue);
  });

  test('without permission it asks, and does not start until asked again',
      () async {
    host.permissionGranted = false;
    expect(await vm.start(), contains('permission'));
    expect(host.requestCalls, 1);
    expect(host.showCalls, 0);
    expect(vm.isOverlayActive, isFalse);

    host.grantOnRequest = true;
    expect(await vm.start(), isNull, reason: 'granted in settings: no error');
    expect(host.showCalls, 0, reason: 'the user taps Start again');
    expect(await vm.start(), isNull);
    expect(host.showCalls, 1);
  });

  test('a failing show reports the error and stays inactive', () async {
    host.showError = StateError('no service');
    expect(await vm.start(), contains('no service'));
    expect(vm.isOverlayActive, isFalse);
  });

  test('stop asks the overlay to save and close itself', () async {
    await vm.start();
    expect(await vm.stop(), isNull);
    expect(host.sent, [
      {'action': 'close_overlay_and_reset'}
    ]);
    expect(vm.isOverlayActive, isFalse);
  });

  test('the overlay closing itself returns to idle', () async {
    await vm.start();
    host.closeFromOverlay();
    await Future<void>.delayed(Duration.zero);
    expect(vm.isOverlayActive, isFalse);
  });

  test('a slot is sent to a running overlay, and ignored when stopped',
      () async {
    await vm.moveOverlayTo(slot);
    expect(host.sent, isEmpty);

    await vm.start();
    await vm.moveOverlayTo(slot);
    expect(host.sent.single['action'], 'load_position');
    expect(PositionSlot.fromJson(host.sent.single['slot']), slot);
  });

  test('dispose releases the host', () {
    vm.dispose();
    expect(host.disposed, isTrue);
    vm = HomeViewModel(host: FakeOverlayHost()); // for tearDown
  });
}
