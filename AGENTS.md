# AGENTS.md - Photo Position Flutter App

This document provides guidelines and instructions for AI agents working on the Photo Position codebase.

## Project Overview

Photo Position is a Flutter overlay app that creates positioning overlays (circle/square) that stay on top of other apps. The app uses `flutter_overlay_window` for system-level overlay functionality.

## Build Commands

### Install Dependencies
```bash
flutter pub get
```

### Run the App
```bash
flutter run
```

### Build Release APK
```bash
flutter build apk --release
```

### Build App Bundle
```bash
flutter build appbundle --release
```

## Linting

### Run Linter
```bash
flutter analyze
```

### Apply Fixes
```bash
flutter analyze --fix
```

The project uses `flutter_lints` with additional rules configured in `analysis_options.yaml`:
- `prefer_const_constructors: true`
- `prefer_const_literals_to_create_immutables: true`
- `avoid_print: false`

## Testing

### Run All Tests
```bash
flutter test
```

### Run a Single Test File
```bash
flutter test test/widget_test.dart
```

### Run a Specific Test
```bash
flutter test -t "App shows start overlay button"
```

### Run Tests with Verbose Output
```bash
flutter test -v
```

## Code Style Guidelines

### Imports

Order imports by category with blank lines between groups:
1. Dart core imports (`dart:xxx`)
2. Flutter framework imports (`package:flutter/xxx`)
3. Third-party package imports
4. Local application imports (`package:photo_position/xxx`)

```dart
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'package:photo_position/overlay_screen.dart';
```

### Formatting

- Use 2 spaces for indentation
- Use trailing commas for multi-line collections and parameter lists
- Keep lines under 80 characters when possible
- Use consistent spacing around operators and after commas

### Types

- Prefer explicit types over `var` for clarity
- Use `double` for numeric values (sizes, positions, offsets)
- Use `int` for counts and indices
- Use `String?` for nullable strings

### Naming Conventions

- **Classes & Enums**: `PascalCase` (e.g., `OverlayScreen`, `OverlayShape`)
- **Variables & Functions**: `snake_case` (e.g., `_isOverlayActive`, `_showOverlay()`)
- **Private Members**: Prefix with underscore (e.g., `_receivePort`, `_startBackgroundIsolate()`)
- **Constants**: `camelCase` with `k` prefix (e.g., `kDefaultSize`)
- **Booleans**: Prefix with `is`, `has`, or similar (e.g., `_isOverlayPermissionGranted`, `_showControls`)

### Widgets

- Use `const` constructors for widgets whenever possible
- Keep widget build methods focused and readable
- Extract reusable widget components into separate classes
- Use `super.key` in widget constructors

```dart
class PhotoPositionApp extends StatelessWidget {
  const PhotoPositionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Position Overlay',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

### State Management

- Use `StatefulWidget` for state that changes during widget lifetime
- Always check `mounted` before calling `setState()` after async operations
- Initialize state in `initState()` and clean up in `dispose()`

```dart
if (mounted) {
  setState(() {
    _isOverlayActive = true;
  });
}
```

### Error Handling

- Wrap async operations in try-catch blocks
- Show errors to users via `ScaffoldMessenger.of(context).showSnackBar()`
- Handle nullable results explicitly

```dart
try {
  await FlutterOverlayWindow.showOverlay(
    flag: OverlayFlag.defaultFlag,
    overlayTitle: "Photo Position Overlay",
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

### Async/Await

- Use `async/await` over raw Futures for readability
- Always handle or propagate errors
- Use `const Duration` for fixed duration values

### Enums

Use enums for related constants:

```dart
enum OverlayShape { circle, square }
```

### Constants

Define magic numbers as constants:

```dart
static const Duration defaultDuration = Duration(seconds: 3);
final double minOverlaySize = 50.0;
```

### Comments

- Use comments sparingly; let code be self-documenting
- Use `//` for single-line comments
- Remove commented-out code before submitting
- Add comments only for non-obvious logic

### Null Safety

- Enable strict null safety (Dart 2.12+)
- Use `?` for nullable types
- Use `!` only when you're certain a value is non-null
- Provide default values where appropriate

### File Structure

- One public class per file (exception: closely related small classes)
- File name matches class name in `snake_case`
- Main entry point: `lib/main.dart`
- Keep files under 300 lines when possible

### File Header

No copyright header required. Start files directly with imports.

### Widget Testing

Follow Flutter testing conventions:

```dart
void main() {
  testWidgets('App shows start overlay button', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotoPositionApp());
    expect(find.text('Start Overlay'), findsOneWidget);
  });
}
```

## Key Packages

- `flutter_overlay_window: ^0.5.0` - For creating system overlays
- `flutter_test` - For widget testing
- `flutter_lints: ^2.0.0` - For linting rules

## Platform-Specific Notes

- This app targets Android only
- Overlay permission must be handled explicitly for Android 6.0+
- Use `FlutterOverlayWindow.isPermissionGranted()` and `requestPermission()`
