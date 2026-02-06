# Gemini Project Context: Photo Position

## Project Overview

**photo-position** is a Flutter overlay app that creates a positioning overlay (circle or square) that stays on top of other apps. It uses the `flutter_overlay_window` package for system-level overlay functionality. The app is **Android-only** due to platform limitations.

## Building and Running

### Prerequisites

- Flutter SDK: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)

### Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on specific device
flutter run -d <device_id>

# Build APK release
flutter build apk --release

# Build appbundle for Play Store
flutter build appbundle --release

# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with verbose output
flutter test -v

# Run Dart analyzer
flutter analyze
```

## Architecture

### Two-Instance Architecture

The app runs as **two separate Flutter instances**:

1.  **Main App** (`PhotoPositionApp` → `HomeScreen`): Standard app for starting/stopping the overlay
2.  **Overlay Window** (`OverlayScreen`): Separate instance showing the draggable overlay

The entry point (`lib/main.dart`) differentiates based on mode, with `overlayMain()` marked with `@pragma("vm:entry-point")` serving as the VM entry point for the overlay instance.

### File Structure

- **lib/main.dart**: App entry point, main app widget, home screen, and overlay entry point (`overlayMain()`)
- **lib/overlay_screen.dart**: Overlay widget with shape, resize, and drag functionality
- **test/widget_test.dart**: Widget tests

### Overlay Communication

Uses `ReceivePort` and `IsolateNameServer` for inter-isolate communication between main app and overlay:

```dart
// Main app - register port
_receivePort = ReceivePort();
IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);
_receivePort!.listen((message) { ... });

// Overlay - send message
final SendPort? sendPort = IsolateNameServer.lookupPortByName(_portName!);
sendPort?.send({'action': 'close_overlay'});
```

## Development Conventions

### Code Style

- Follow standard Dart and Flutter coding conventions
- Use `analysis_options.yaml` with `flutter_lints` for static analysis
- 2 spaces for indentation
- Maximum line length: 80 characters (recommended)
- Use `const` constructors where possible
- Prefer `=>` for single-expression functions

### Import Organization

1. Dart core imports (`dart:xxx`)
2. Flutter framework imports (`package:flutter/xxx`)
3. Third-party package imports
4. Relative imports for local packages (`package:photo_position/xxx`)

### Type Safety

- Explicit types for all variable declarations
- Use `final` for variables that won't be reassigned
- Use `const` for compile-time constants
- Use `late` sparingly (only when necessary)
- Check `mounted` before calling `setState` after async operations

### Error Handling

- Wrap async operations in try-catch blocks
- Check `mounted` before calling `setState` after async operations
- Use `SnackBar` for user feedback on errors

```dart
try {
  await FlutterOverlayWindow.showOverlay(...);
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to show overlay: $e')),
    );
  }
}
```

## Key Dependencies

- `flutter_overlay_window`: ^0.5.0 - System-level overlay functionality
- `flutter_lints`: ^2.0.0 - Linting rules

## Platform-Specific Notes

### Android-Only

This app is **Android-only** because:
- Requires "Draw over other apps" permission (`SYSTEM_ALERT_WINDOW`)
- Uses `flutter_overlay_window` package (Android-only)
- iOS has strict restrictions on system overlays

### Required Permissions

The `android/app/src/main/AndroidManifest.xml` file must include:

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

<service
    android:name="io.flutter.plugins.flutter_overlay_window.OverlayService"
    android:exported="false"
    android:foregroundServiceType="specialUse">
    <property
        android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
        android:value="Positioning overlay for alignment" />
</service>
```

## Troubleshooting

### Overlay not appearing
- Check that overlay permission is granted
- Verify `overlayContent: 'overlayMain'` in `FlutterOverlayWindow.showOverlay()`
- Ensure `@pragma("vm:entry-point")` is present on `overlayMain()` function
- Verify Android permissions in AndroidManifest.xml

### Build errors
- Run `flutter clean && flutter pub get`
- Check Flutter version compatibility
- Ensure Android SDK is properly configured
