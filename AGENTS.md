# Agent Guidelines for photo-position

This document provides guidelines for AI agents working on this Flutter project.

## Project Overview

**photo-position** is a Flutter overlay app that creates a positioning overlay (circle or square) that stays on top of other apps. It uses the `flutter_overlay_window` package for system-level overlay functionality.

## Build Commands

```bash
# Install dependencies
flutter pub get

# Run the app on connected device/emulator
flutter run

# Build APK release
flutter build apk --release

# Build appbundle for Play Store
flutter build appbundle --release

# Run on specific device
flutter run -d <device_id>
```

## Linting & Analysis

```bash
# Run Dart analyzer
flutter analyze

# Run linter with rules from analysis_options.yaml
flutter analyze

# View detailed analysis options
cat analysis_options.yaml
```

## Testing

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

**Single Test Pattern:**
```bash
flutter test -v -p test --test-randomize-ordering-seed=random
# To run a specific test, edit test/widget_test.dart and use:
flutter test test/widget_test.dart -v
```

## Code Style Guidelines

### Imports

Organize imports in the following order:
1. Dart core imports (`dart:xxx`)
2. Flutter framework imports (`package:flutter/xxx`)
3. Third-party package imports
4. Relative imports for local packages (`package:photo_position/xxx`)

```dart
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'package:photo_position/overlay_screen.dart';
```

### Formatting

- Use 2 spaces for indentation
- Maximum line length: 80 characters (recommended)
- Use trailing commas in widget trees for better formatting
- Use `const` constructors where possible
- Prefer `=>` for single-expression functions

### Types

- Use explicit types for all variable declarations
- Use `final` for variables that won't be reassigned
- Use `const` for compile-time constants
- Use `late` only when necessary (e.g., in `initState`)

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

**Classes:**
- PascalCase for all class names
- Private classes prefixed with underscore
- Use descriptive names (e.g., `OverlayScreen`, `_OverlayScreenState`)

**Variables & Functions:**
- camelCase for variables and functions
- Private members prefixed with underscore
- Use verbs for functions (e.g., `_showOverlay()`, `_closeOverlay()`)

**Constants:**
- camelCase for constants
- kPrefix for class-level constants (e.g., `kDefaultSize`)

**Enums:**
- PascalCase for enum names
- camelCase for values

```dart
enum OverlayShape { circle, square }

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});
}

class _OverlayScreenState extends State<OverlayScreen> {
  static const double minSize = 50.0;
  static const double maxSize = 500.0;
  bool _showControls = true;
}
```

### Widget Construction

- Use `const` constructors for stateless widgets
- Extract widgets into separate methods for readability
- Keep build methods clean and readable
- Use named parameters for widget properties

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Photo Position Overlay'),
    ),
    body: Center(
      child: Column(
        children: [
          _buildOverlayContent(),
          _buildControlsPanel(),
        ],
      ),
    ),
  );
}
```

### Error Handling

- Wrap async operations in try-catch blocks
- Check `mounted` before calling `setState` after async operations
- Use `SnackBar` for user feedback on errors
- Log errors appropriately

```dart
try {
  await FlutterOverlayWindow.showOverlay(
    flag: OverlayFlag.defaultFlag,
    overlayTitle: "Photo Position Overlay",
    overlayContent: "Use this overlay to position your camera",
    enableDrag: true,
    width: WindowSize.fullCover,
    height: WindowSize.fullCover,
  );
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to show overlay: $e'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

### State Management

- Use `setState` for simple local state
- Check `mounted` before calling `setState` after async operations
- Private state variables prefixed with underscore

```dart
class _HomeScreenState extends State<HomeScreen> {
  bool _isOverlayPermissionGranted = false;
  bool _isOverlayActive = false;

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}
```

### Null Safety

- Use late initialization sparingly
- Use null-aware operators where appropriate
- Use `!` only when certain a value is non-null
- Use `??` for default values

```dart
final SendPort? sendPort = IsolateNameServer.lookupPortByName(_portName!);
sendPort?.send({'action': 'close_overlay'});
final size = event['size']?.toDouble() ?? defaultSize;
```

### Documentation

- Document public APIs with dartdoc comments
- Use `///` for documentation comments
- Include parameter descriptions for complex functions
- Add comments for non-obvious logic

```dart
/// Saves the current overlay position before a resize operation.
///
/// This is used to restore the position after the resize interaction ends.
Future<void> _saveBeforeResizing() async { ... }
```

## Architecture

### Two-Instance Architecture

The app runs as **two separate Flutter instances**:

1. **Main App** (`PhotoPositionApp` → `HomeScreen`): Standard app for starting/stopping the overlay
2. **Overlay Window** (`OverlayScreen`): Separate instance showing the draggable overlay

The entry point (`main.dart`) differentiates based on mode, with `overlayMain()` serving as the VM entry point for the overlay instance.

### File Structure

- **main.dart**: App entry point, main app widget, home screen, and overlay entry point (`overlayMain()`)
- **overlay_screen.dart**: Overlay widget with shape, resize, and drag functionality
- **test/widget_test.dart**: Widget tests using flutter_test

## Key Patterns

### Overlay Communication

Uses `ReceivePort` and `IsolateNameServer` for communication between main app and overlay:

```dart
// Main app
_receivePort = ReceivePort();
IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);
_receivePort!.listen((message) { ... });

// Overlay
void _closeOverlay() {
  final SendPort? sendPort = IsolateNameServer.lookupPortByName(_portName!);
  sendPort?.send({'action': 'close_overlay'});
  FlutterOverlayWindow.closeOverlay();
}
```

### VM Entry Points

The overlay requires a `@pragma("vm:entry-point")` annotation on the `overlayMain()` function to work correctly on all platforms:

```dart
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayScreen(),
    ),
  );
}
```

## Dependencies

Key dependencies (see `pubspec.yaml`):
- `flutter`: Flutter SDK
- `flutter_overlay_window`: ^0.5.0 (for system overlay functionality)
- `flutter_test`: SDK (for testing)
- `flutter_lints`: ^2.0.0 (for linting)

## Platform-Specific Notes

### Android-Only

This app is **Android-only** because:
- Requires "Draw over other apps" permission (`SYSTEM_ALERT_WINDOW`)
- Uses `flutter_overlay_window` package (Android-only)
- iOS has strict restrictions on system overlays

### Additional Notes

- Requires "Draw over other apps" permission
- Uses Material 3 design (`useMaterial3: true`)
- Minimum SDK: Flutter 3.0.0
