# Developer guide

## Setup

```bash
flutter pub get
flutter analyze && flutter test
```

Android builds use Gradle 9.1 / AGP 8.13 and need a JDK Gradle supports (Android Studio's bundled JDK 25 works). An emulator with API 30+ is enough; grant overlay permission with
`adb shell appops set com.example.photo_position SYSTEM_ALERT_WINDOW allow`.

iOS: `flutter run -d <simulator-id>` shows the home screen and slots; there is no overlay on iOS. Icons: `dart run flutter_launcher_icons` after changing `assets/icon/icon.png`.

## Everyday commands

| Command | Use |
|---|---|
| `flutter test` | unit and widget tests, no device |
| `dart format lib test testing integration_test` | formatting (CI checks it) |
| `flutter test integration_test -d <id>` | rotates the real display; Android emulator or iOS simulator |
| `tool/rotation_e2e.sh` | Android: starts the real overlay, rotates through all four orientations, asserts a tall rectangle is where the glass says (within 4 px) and its gold border is really drawn there (screenshot sampling, `tool/check_border.py`) |
| `tool/restart_e2e.sh` | Android: stop and start the overlay twice; it comes back at the same frame, drawn, and still follows a drag |
| `tool/slots_e2e.sh` | Android: saves two slots, loads them, asserts the window frame returns within 2 px |

## Architecture

See [CLAUDE.md](../CLAUDE.md) for the layer map. In short: `OverlayViewModel` owns one absolute `OverlayGeometry`; `OverlayService` is the only thing that talks to the plugin; `ScreenSizeBridge.kt` tells the overlay engine the real screen size.

## Tests

| File | Covers |
|---|---|
| `test/domain/geometry_test.dart` | px <-> plugin offset round trips, glass <-> display for each rotation, JSON, clamping |
| `test/data/position_repository_test.dart` | storage, corrupt data, slots, legacy key migration |
| `test/data/overlay_service_test.dart` | screen size pushed from native |
| `test/ui/overlay/overlay_rotation_test.dart` | glass pinning: corner mapping for each rotation, circle/square, controls on/off, drag and resize while turned, 20 turns, nav bar, slots |
| `test/ui/overlay/overlay_screen_test.dart` | handles, panel, close, a tall rectangle redrawn wide after turning |
| `test/ui/home/slots_test.dart` | slots view model, section, thumbnail |
| `test/ui/home/home_view_model_test.dart` | start/stop, permission, overlay closing itself, sending a slot |
| `test/ui/home/home_screen_test.dart` | the home screen on `FakeOverlayHost` |
| `test/ui/slots_flow_test.dart` | slot save/load through the overlay view model and one repository |
| `integration_test/rotation_test.dart` | real display rotation on device/simulator |

## Adding a native-side behaviour

Anything that needs Android APIs goes through a channel on the overlay engine (`FlutterEngineCache` key `myCachedEngine`), attached by `ScreenSizeBridge.attach` after `showOverlay`. Plugin calls can fail until the overlay engine finishes starting; wrap new ones in `PluginOverlayService._whenReady`.
