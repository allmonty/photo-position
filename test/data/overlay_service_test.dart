import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_position/data/services/overlay_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('screenChanged from the native bridge updates screen and notifies',
      () async {
    final service = PluginOverlayService(initialScreen: const Size(400, 800));
    final Future<Size> next = service.screenChanges.first;

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'photo_position/screen',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('screenChanged',
            {'width': 800.0, 'height': 400, 'shiftX': 0, 'shiftY': -12}),
      ),
      (_) {},
    );

    expect(await next, const Size(800, 400));
    expect(service.screen, const Size(800, 400));
    expect(service.centreShift, const Offset(0, -12));
  });
}
