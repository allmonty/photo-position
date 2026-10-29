import 'dart:ui';

import 'package:photo_position/data/repositories/position_repository.dart';
import 'package:photo_position/data/services/overlay_host.dart';
import 'package:photo_position/data/services/overlay_service.dart';
import 'package:photo_position/ui/home/view_models/home_view_model.dart';
import 'package:photo_position/ui/home/view_models/slots_view_model.dart';
import 'package:photo_position/ui/overlay/view_models/overlay_view_model.dart';

/// The only place that decides which implementations the app uses. Both
/// entry points (`main` and `overlayMain`) build view models here, and tests
/// override any piece with a fake.
class Dependencies {
  Dependencies({
    PositionRepository? repository,
    OverlayHost Function()? host,
    OverlayService Function()? service,
  })  : repository = repository ?? SharedPreferencesPositionRepository(),
        _host = host ?? PluginOverlayHost.new,
        _service = service ?? PluginOverlayService.new;

  final PositionRepository repository;
  final OverlayHost Function() _host;
  final OverlayService Function() _service;

  HomeViewModel createHomeViewModel() => HomeViewModel(host: _host());

  SlotsViewModel createSlotsViewModel() => SlotsViewModel(
        repository: repository,
        screen: () {
          final FlutterView v = PlatformDispatcher.instance.views.first;
          return v.physicalSize / v.devicePixelRatio;
        },
      );

  OverlayViewModel createOverlayViewModel() =>
      OverlayViewModel(service: _service(), repository: repository);
}
