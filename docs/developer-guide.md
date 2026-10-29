# Developer guide

## Setup

```bash
flutter pub get
flutter analyze && flutter test
```

Android builds use Gradle 9.1 / AGP 8.13 and need a JDK Gradle supports (Android Studio's bundled JDK 25 works). An emulator with API 30+ is enough; grant overlay permission with
`adb shell appops set com.example.photo_position SYSTEM_ALERT_WINDOW allow`.

## Everyday commands

| Command | Use |
|---|---|
| `flutter test` | unit and widget tests, no device |
| `dart format lib test testing integration_test` | formatting (CI checks it) |
| `flutter test integration_test -d <id>` | rotates the real display; Android emulator or iOS simulator |
| `tool/rotation_e2e.sh` | Android: starts the real overlay, rotates, asserts the window frame moves < 2 px |

## Architecture

See [CLAUDE.md](../CLAUDE.md) for the layer map. In short: `OverlayViewModel` owns one absolute `OverlayGeometry`; `OverlayService` is the only thing that talks to the plugin; `ScreenSizeBridge.kt` tells the overlay engine the real screen size.

## Tests

| File | Covers |
|---|---|
| `test/domain/geometry_test.dart` | px <-> plugin offset round trips (portrait/landscape, nav-bar shift), JSON, clamping |
| `test/data/position_repository_test.dart` | storage, corrupt data, slots, legacy key migration |
| `test/data/overlay_service_test.dart` | screen size pushed from native |
| `test/ui/overlay/overlay_rotation_test.dart` | same pixels before/after rotating: circle/square, controls on/off, drag, resize, 20 rotations, nav bar, out-of-view shapes |
| `test/ui/overlay/overlay_screen_test.dart` | handles, panel, close |
| `test/ui/home/slots_test.dart` | slots, thumbnail, home screen |
| `test/home_screen_overlay_test.dart` | start/stop flow |
| `integration_test/rotation_test.dart` | real display rotation on device/simulator |

## Adding a native-side behaviour

Anything that needs Android APIs goes through a channel on the overlay engine (`FlutterEngineCache` key `myCachedEngine`), attached by `ScreenSizeBridge.attach` after `showOverlay`. Plugin calls can fail until the overlay engine finishes starting; wrap new ones in `PluginOverlayService._whenReady`.
