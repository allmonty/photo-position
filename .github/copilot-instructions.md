# Copilot Instructions for Photo Position

## Project Overview

**photo-position** is a Flutter overlay app that creates a positioning overlay (circle or square) that stays on top of other apps. It uses the `flutter_overlay_window` package for system-level overlay functionality. The app is Android-only due to platform limitations.

## Build, Test, and Lint Commands

### Build & Run
```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# Build APK release
flutter build apk --release

# Build appbundle for Play Store
flutter build appbundle --release
```

### Testing
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with verbose output
flutter test -v

# Run tests with coverage
flutter test --coverage
```

### Linting
```bash
# Run Dart analyzer
flutter analyze
```

## Architecture

### Two-Instance Architecture

The app runs as **two separate Flutter instances**:

1. **Main App** (`PhotoPositionApp` → `HomeScreen`): Standard app for starting/stopping the overlay
2. **Overlay Window** (`OverlayScreen`): Separate instance showing the draggable overlay

The entry point (`main.dart`) differentiates based on mode, with `overlayMain()` serving as the VM entry point for the overlay instance.

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

### VM Entry Points

The overlay requires a `@pragma("vm:entry-point")` annotation on the `overlayMain()` function to work correctly on all platforms.

## Code Conventions

### Import Organization

1. Dart core imports (`dart:xxx`)
2. Flutter framework imports (`package:flutter/xxx`)
3. Third-party package imports
4. Relative imports for local packages (`package:photo_position/xxx`)

### Formatting

- 2 spaces for indentation
- Maximum line length: 80 characters (recommended)
- Use trailing commas in widget trees
- Use `const` constructors where possible
- Prefer `=>` for single-expression functions

### Type Safety

- Explicit types for all variable declarations
- Use `final` for variables that won't be reassigned
- Use `const` for compile-time constants
- Use `late` sparingly (only when necessary, e.g., in `initState`)
- Check `mounted` before calling `setState` after async operations

```dart
// Good
final String _portName = "photo_position_overlay_port";
bool _isOverlayActive = false;
const double defaultSize = 200.0;

// Avoid
var portName = "photo_position_overlay_port";
bool isOverlayActive = false;
final defaultSize = 200.0;
```

### Naming Conventions

- **Classes**: PascalCase (e.g., `OverlayScreen`, `_OverlayScreenState`)
- **Variables & Functions**: camelCase, private members prefixed with `_`
- **Constants**: camelCase for variables, kPrefix for class-level constants (e.g., `kDefaultSize`)
- **Enums**: PascalCase for names, camelCase for values

```dart
enum OverlayShape { circle, square }

class _OverlayScreenState extends State<OverlayScreen> {
  static const double minSize = 50.0;
  bool _showControls = true;
}
```

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

### Widget Construction

- Use `const` constructors for stateless widgets
- Extract complex widgets into separate methods for readability
- Keep build methods clean
- Use named parameters for widget properties

## Key Dependencies

- `flutter_overlay_window`: ^0.5.0 - System-level overlay functionality
- `flutter_lints`: ^2.0.0 - Linting rules

## Platform-Specific Notes

### Android-Only

This app is **Android-only** because:
- Requires "Draw over other apps" permission (`SYSTEM_ALERT_WINDOW`)
- Uses `flutter_overlay_window` package (Android-only)
- iOS has strict restrictions on system overlays

### Permissions

Required in `AndroidManifest.xml`:
- `android.permission.SYSTEM_ALERT_WINDOW` - Draw over other apps
- `android.permission.FOREGROUND_SERVICE` - Run overlay service

## Analysis Options

Custom linting rules in `analysis_options.yaml`:
- `prefer_const_constructors: true`
- `prefer_const_literals_to_create_immutables: true`
- `avoid_print: false` (debugging allowed)
