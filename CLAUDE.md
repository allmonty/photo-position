# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                  # install dependencies
flutter run                      # run on connected device/emulator
flutter analyze                  # lint/static analysis (rules in analysis_options.yaml)
flutter test                     # run all tests
flutter test test/overlay_position_test.dart   # run a single test file
flutter build apk --release      # build release APK
flutter build appbundle --release
```

There is no separate lint command beyond `flutter analyze`; `flutter_lints` rules are configured in `analysis_options.yaml`.

## Architecture

This is a **Flutter, Android-only** app (`flutter_overlay_window` is Android-only; iOS restricts system overlays) that draws a draggable circle/square overlay on top of other apps (e.g. camera) to help align photos.

### Two-instance model

The app runs as two separate Flutter instances within the same process, distinguished by `FlutterOverlayWindow.isActive()` in [lib/main.dart](lib/main.dart):

- **Main app** — `main()` entry point → `PhotoPositionApp` → `HomeScreen` ([lib/main.dart](lib/main.dart)). Requests `SYSTEM_ALERT_WINDOW` permission and starts/stops the overlay via `FlutterOverlayWindow.showOverlay()`.
- **Overlay window** — `overlayMain()`, a separate VM entry point annotated `@pragma("vm:entry-point")`, runs `OverlayScreen` ([lib/overlay_screen.dart](lib/overlay_screen.dart)) in its own Flutter engine, rendered above all other apps.

### Cross-isolate communication

The main app and overlay instance communicate via `ReceivePort` + `IsolateNameServer` (port name `"photo_position_overlay_port"`), not via shared Dart state — e.g. the overlay sends `{'action': 'close_overlay'}` to tell the main app it closed.

### Overlay state and persistence

`OverlayScreen` owns shape (circle/square), size, drag position, and controls-visibility state. Position/size are persisted across overlay restarts using `shared_preferences` (`SharedPreferences.getInstance()`), saved on resize/drag end and on close, and restored in `_restoreOverlayPosition()`.

### Rotation handling

`sensors_plus`' `accelerometerEventStream()` is used in [lib/overlay_screen.dart](lib/overlay_screen.dart) to detect device orientation changes, triggering `_transposeOverlayPosition()` to remap the saved overlay position/size around the screen center so the overlay stays correctly placed after a rotation (recent/active area of work — see git log for `fix rotation` commits).

### Resize/drag interactions

Resizing is implemented via three independent drag handlers in `OverlayScreen`: horizontal resize, vertical resize, and circle (diagonal) resize, each with its own start/update/end methods that mutate size state and persist via `shared_preferences` on end.
