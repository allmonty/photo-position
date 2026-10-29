# Decisions

Append-only. A later entry that replaces an earlier one says so.

| # | Date | Decision | Why |
|---|---|---|---|
| 1 | 2026-10-29 | The position is an absolute rectangle (dp from the screen's top-left), pushed to the native window on every change and rotation. | The plugin stores a centre-relative offset that Android reinterprets when the screen dimensions swap; transposing it after the fact (accelerometer, 250 ms late, rounded) made the overlay jump. |
| 2 | 2026-10-29 | After rotation the shape keeps the same screen pixels and size (not "stuck to the phone body"). | Chosen by the user. |
| 3 | 2026-10-29 | Native `ScreenSizeBridge` pushes the real screen size and the parent-frame centre shift to the overlay engine. | Measured on an API 36 emulator: `didChangeMetrics` fires in the overlay engine but `Display.size` stays at its first value; the plugin centres its window in a frame that excludes the navigation bar. |
| 4 | 2026-10-29 | A shape that no longer fits after rotation is shown clamped; the stored rectangle is untouched. | A shape placed low in portrait would be off-screen in the shorter landscape screen; rotating back must restore it exactly. |
| 5 | 2026-10-29 | No full-screen `match_parent` overlay window. | A Flutter view cannot pass touches through transparent areas, so the camera app underneath would stop receiving touches. |
| 6 | 2026-10-29 | Three slots, managed on the home screen only; each stores the screen it was saved on. | Chosen by the user; the screen size lets the thumbnail draw the right phone and loading in another orientation clamp. |
| 7 | 2026-10-29 | `ChangeNotifier` + `ListenableBuilder`, no `provider`. | Two small view models; a dependency is not worth it. |
| 8 | 2026-10-29 | Gradle 9.1.0 / AGP 8.13.0. | Android Studio's JDK is 25, which Gradle 8.14 does not support. |
| 9 | 2026-10-29 | The overlay window is not tested on iOS. | `flutter_overlay_window` is Android-only; only the shared Dart logic and UI could run there, and the project has no `ios/` folder yet. |
