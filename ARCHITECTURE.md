# App Structure Visualization

## UI Layout - Main App

```
┌─────────────────────────────────────────┐
│    Photo Position Overlay               │  ← AppBar
├─────────────────────────────────────────┤
│                                         │
│            ╭────────╮                   │
│            │   □    │                   │
│            ╰────────╯                   │
│                                         │
│      Position Overlay App               │
│                                         │
│   Create a positioning overlay that     │
│   stays on top of other apps            │
│                                         │
│                                         │
│        ╭─────────────────╮              │
│        │  ▶ Start Overlay │              │
│        ╰─────────────────╯              │
│                                         │
│  ────────────────────────────           │
│                                         │
│  Instructions:                          │
│  1. Tap "Start Overlay"                 │
│  2. Drag circle/square to position      │
│  3. Use controls to change shape/size   │
│  4. Open camera app to use overlay      │
│  5. Tap overlay to toggle controls      │
│  6. Close from controls or this app     │
│                                         │
└─────────────────────────────────────────┘
```

## Overlay Window View

```
┌─────────────────────────────────────────┐
│                                         │ ← Any app (e.g., Camera)
│                                         │
│            ╭─────────╮  ┌─────┐        │
│            │         │  │  ×  │        │  ← Controls panel
│            │    ○    │  │ ═══ │        │     (closable)
│            │         │  │  ○  │        │
│            ╰─────────╯  │  +  │        │
│       (Draggable)       │ 200 │        │
│                         │  −  │        │
│                         │ ═══ │        │
│                         │ 👁‍🗨 │        │
│                         └─────┘        │
│                                         │
│  [Tap overlay to show controls]         │
│                                         │
└─────────────────────────────────────────┘
```

## Component Stack Layers (Overlay Mode)

```
Layer 2: Control Panel (X, shape, size)  ← Overlay controls
         ↑
Layer 1: Shape Overlay (Circle/Square)   ← Draggable
         ↑
Layer 0: Other Apps (Camera, etc.)       ← Underneath
```

## Data Flow

```
App Start
    ↓
Main App Launches
    ↓
User Taps "Start Overlay"
    ↓
Request Overlay Permission
    ├─→ Denied → Show Error
    ↓
    Granted
    ↓
Create Overlay Window
    ↓
Overlay Appears Over All Apps
    ↓
User Drags Overlay → Update Position
    ↓
User Toggles Shape → Update Shape (Circle ↔ Square)
    ↓
User Adjusts Size → Update Size (+/- buttons)
    ↓
User Opens Camera App → Overlay Stays On Top
    ↓
User Positions Subject Within Overlay
    ↓
User Takes Photo (with camera app)
    ↓
User Closes Overlay → Overlay Removed
```

## File Organization

```
photo_position/
│
├── lib/
│   ├── main.dart              ← Entry point, main app UI
│   └── overlay_screen.dart    ← Overlay window UI with controls
│
├── android/                   ← Android platform config
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml  ← Overlay permissions
│   │   │   └── kotlin/MainActivity.kt
│   │   └── build.gradle
│   └── build.gradle
│
├── pubspec.yaml               ← Dependencies (flutter_overlay_window)
├── analysis_options.yaml      ← Linter config
│
├── README.md                  ← User documentation
├── TECHNICAL.md               ← Technical details
└── ARCHITECTURE.md            ← This file
```

## Key Implementation Details

### How Overlay Stays On Top

The app uses the `flutter_overlay_window` package which:

1. Creates a system-level window with `SYSTEM_ALERT_WINDOW` permission
2. Runs a separate Flutter instance for the overlay
3. Displays above all other apps including camera

```dart
FlutterOverlayWindow.showOverlay(
  enableDrag: false,            // We handle dragging manually
  width: WindowSize.matchParent, // Full screen transparent
  height: WindowSize.matchParent,
  ...
)
```

### Two Flutter Instances

The app runs in two modes:
- **Main App**: Standard app for starting/stopping overlay
- **Overlay Window**: Separate instance showing the overlay

```dart
if (await FlutterOverlayWindow.isActive()) {
  // Running in overlay mode
  runApp(MaterialApp(home: OverlayScreen()));
} else {
  // Running in main app mode
  runApp(PhotoPositionApp());
}
```

### State Management

**Main App:**
- `_isOverlayActive`: Whether overlay is running

**Overlay Window:**
- `_overlayShape`: Circle or square
- `_overlaySize`: Size in pixels (100-400)
- `_overlayPosition`: X/Y coordinates
- `_showControls`: Controls panel visibility

### Permissions Flow

```
First App Launch
    ↓
Request Overlay Permission
    ↓
┌──────────────────┐
│   User Choice    │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
  Allow     Deny
    │         │
    │    Permission Required
    │         │
    │    Show Error
    ↓
Overlay Can Be Created
    ↓
User Taps "Start Overlay"
    ↓
Overlay Window Appears
    ↓
App Functions Normally
```

