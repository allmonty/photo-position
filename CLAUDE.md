# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository. Longer notes: [docs/developer-guide.md](docs/developer-guide.md); why things are the way they are: [docs/decisions.md](docs/decisions.md).

## Commands

```bash
flutter pub get                       # install dependencies
flutter analyze                       # lint (strict modes, see analysis_options.yaml)
flutter test                          # unit + widget tests
dart format --output=none --set-exit-if-changed lib test testing integration_test
flutter test integration_test -d <device-id>    # real display rotation: Android emulator or iOS simulator
tool/rotation_e2e.sh                  # Android only: real overlay window across rotations (needs adb + app installed)
tool/slots_e2e.sh                     # Android only: save two slots, load them, window returns to the saved frame
flutter run                           # run on a device/emulator
flutter build apk --release
```

Android builds need a JDK Gradle 9.1 supports (the project builds with Android Studio's JDK 25). Do not install tools or change global config without asking the user.

## Architecture

**Flutter; the overlay is Android-only, iOS runs the shared logic and home screen** (`flutter_overlay_window` is Android-only). Two Flutter engines run in one process: the main app (`main()` -> `HomeScreen`) and the overlay window (`overlayMain()` -> `OverlayScreen`, a separate entry point annotated `@pragma("vm:entry-point")`).

```
lib/
  main.dart                    the two entry points only (main, overlayMain)
  config/dependencies.dart     the one place that picks implementations (tests override them)
  domain/                      pure Dart: OverlayGeometry, PositionSlot, geometry.dart (plugin-offset maths)
  data/repositories/           PositionRepository (+ shared_preferences impl)
  data/services/               OverlayService (overlay side: window, screen size), OverlayHost (main-app side: permission, show, messages)
  ui/core/                     theme, Art Deco widgets
  ui/overlay/{view_models,widgets}/   OverlayViewModel, OverlayScreen
  ui/home/{view_models,widgets}/      HomeViewModel, SlotsViewModel, HomeScreen, SlotsSection, SlotThumbnail
testing/fakes/                 FakeOverlayService (behaves like the native window), FakeOverlayHost, MemoryPositionRepository
android/.../ScreenSizeBridge.kt, PhotoPositionApplication.kt, MainActivity.kt   native screen-size bridge
```

Dependencies point one way: widgets -> view models -> repositories/services -> domain. View models take their dependencies in the constructor so tests pass fakes. State uses `ChangeNotifier` + `ListenableBuilder` (no `provider`).

### Position model (the important part)

The overlay's position is one absolute rectangle, `OverlayGeometry` (dp from the screen's top-left). `OverlayViewModel._apply` is the only place that pushes it to the native window, via `toPluginOffset`. Rotation re-applies the same rectangle; nothing is transposed. If the rectangle no longer fits the screen it is shown clamped, but the stored value is not changed, so rotating back is exact.

Two non-obvious facts about the plugin, both verified on a device:
- The window is `Gravity.CENTER`: its x/y is the offset of the window centre from the centre of its **parent frame**, which excludes the navigation bar (`centreShift`).
- The overlay engine's `Display.size` never updates after rotation. `ScreenSizeBridge.kt` pushes (`screenChanged`) and answers (`getScreen`) the real size over channel `photo_position/screen`. Plugin calls made before its channel exists throw `MissingPluginException`; `PluginOverlayService` retries them.

### Cross-engine communication

`IsolateNameServer` port `photo_position_overlay_port` (overlay -> main: `close_overlay`; owned by `PluginOverlayHost`), `FlutterOverlayWindow.shareData` (main -> overlay: `close_overlay_and_reset`, `load_position`), and shared_preferences (the overlay writes the current position; the main app `reload()`s before reading).

### Slots

Three `PositionSlot`s (geometry + the screen size it was saved on) are copied from/to the persisted current position on the home screen. Loading a slot into a different orientation clamps it into the screen.

## Testing

| Where | What |
|---|---|
| `test/domain` | plugin-offset maths, JSON validation, clamping |
| `test/data` | repository (incl. legacy-key migration), native-bridge channel |
| `test/ui/overlay` | rotation invariance with `FakeOverlayService`, widget gestures |
| `test/ui/home` | home/slots view models, home screen, slot section, thumbnail |
| `test/ui/slots_flow_test.dart` | overlay persists -> slots copy -> loading moves the overlay (one repository) |
| `integration_test` | real display rotation on a device/simulator |
| `tool/rotation_e2e.sh`, `tool/slots_e2e.sh` | real overlay window frame before/after rotating, and after loading a slot (Android) |
