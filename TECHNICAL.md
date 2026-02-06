# Photo Position App - Technical Documentation

## Architecture Overview

This Flutter app creates a system-level overlay window that displays positioning shapes (circle or square) that stay on top of all other apps, including the camera.

### Key Components

#### 1. Main App (`lib/main.dart`)
- Checks if running in overlay mode or main app mode
- **HomeScreen**: Main UI for starting/stopping the overlay
- Requests overlay permission
- Controls overlay lifecycle

#### 2. Overlay Screen (`lib/overlay_screen.dart`)
- **OverlayScreen**: The UI shown in the overlay window
- **Draggable Overlay**: Movable circle/square shape
- **Control Panel**: Buttons for shape, size, close, hide controls
- Transparent background to show underlying apps

### How Overlay Stays On Top

The app uses `flutter_overlay_window` package which creates a system-level overlay:

```
Main App (Standard Flutter)
    ↓
User Starts Overlay
    ↓
Package Creates Separate Window
    ↓
New Flutter Instance (Overlay Mode)
    ↓
Overlay Window (Above All Apps)
```

When `FlutterOverlayWindow.showOverlay()` is called:
1. Android creates a new window with `TYPE_APPLICATION_OVERLAY`
2. This window runs a separate Flutter engine
3. The window appears above all other apps
4. User can interact with both overlay and underlying apps

### Two-Instance Architecture

The app runs as **two separate Flutter instances**:

**Instance 1 - Main App:**
```dart
PhotoPositionApp
  └─ HomeScreen
      ├─ Start Overlay button
      ├─ Stop Overlay button
      └─ Instructions
```

**Instance 2 - Overlay Window:**
```dart
OverlayScreen (transparent background)
  ├─ Draggable shape (circle/square)
  └─ Control panel (right side)
      ├─ Close button
      ├─ Shape toggle
      ├─ Size +/- buttons
      └─ Hide controls button
```

The entry point (`main.dart`) differentiates based on mode:
- `main()` - Main app entry point
- `overlayMain()` - Overlay window entry point (marked with `@pragma("vm:entry-point")`)

When `FlutterOverlayWindow.showOverlay()` is called with `overlayContent: 'overlayMain'`, it launches the overlay instance.

### Features

1. **Shape Toggle**: Switch between circle and square
2. **Size Adjustment**: +/- buttons to resize (100-400 pixels)
3. **Drag to Position**: Drag overlay anywhere on screen
4. **Control Visibility**: Hide controls by tapping overlay
5. **Close Overlay**: Remove overlay from control panel or main app

### File Structure

```
lib/
  main.dart              - Entry point and main app UI
  overlay_screen.dart    - Overlay window with draggable shapes

android/
  app/
    src/main/
      AndroidManifest.xml    - Overlay permissions and service
      kotlin/                - MainActivity implementation
    build.gradle             - Android build configuration

pubspec.yaml               - Dependencies (flutter_overlay_window)
```

### Dependencies

- **flutter_overlay_window**: ^0.5.0 - System overlay package

### Platform Support

**Android**: Full support (API 23+)
- Requires "Draw over other apps" permission
- Works on Android 6.0 (Marshmallow) and above

**iOS**: Not currently supported
- `flutter_overlay_window` is Android-only
- iOS has restrictions on system overlays

### Known Limitations

- Android only (iOS doesn't support system overlays)
- Requires manual permission grant on Android 6.0+
- Limited to circle and square shapes

### Future Enhancements

Potential improvements:
- More shape options (triangle, grid, etc.)
- Color customization for overlay border
- Opacity adjustment
- Save/load preset positions and sizes
- Multiple overlays simultaneously
- Snap-to-grid positioning

