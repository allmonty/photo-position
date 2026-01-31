# App Structure Visualization

## UI Layout

```
┌─────────────────────────────────────────┐
│         Photo Position App              │  ← AppBar
├─────────────────────────────────────────┤
│                                         │
│         [Camera Preview]                │
│                                         │
│            ╭───────╮                    │  ← Overlay (Circle)
│            │       │                    │     OR
│            │   O   │                    │  ┌─────────┐
│            │       │                    │  │         │ (Square)
│            ╰───────╯                    │  │    ▢    │
│                                         │  │         │
│                                         │  └─────────┘
│                                         │
├─────────────────────────────────────────┤
│  Controls Panel (Black background)      │
│                                         │
│  [No]   [Circle]   [Square]            │  ← Shape Buttons
│                                         │
│  [▁▁▁▁▁●▁▁▁▁▁▁▁]  Size: 200px          │  ← Size Slider
│                                         │
│          ( Camera Button )              │  ← Capture Button
│                                         │
└─────────────────────────────────────────┘
```

## Component Stack Layers

```
Layer 3: Controls (Buttons, Slider)  ← Always on top
         ↑
Layer 2: Overlay (Circle/Square)     ← UI only, NOT in photo
         ↑
Layer 1: Camera Preview              ← Actual camera feed
         ↑
Layer 0: Background
```

## Data Flow

```
App Start
    ↓
Initialize Cameras
    ↓
Create CameraController
    ↓
Display Camera Preview
    ↓
User Selects Overlay Shape → Update UI State
    ↓
User Adjusts Size → Update Overlay Size
    ↓
User Taps Capture Button
    ↓
CameraController.takePicture()
    ↓
Save Image (WITHOUT overlay)
    ↓
Show Success Message
```

## File Organization

```
photo_position/
│
├── lib/
│   ├── main.dart              ← Entry point, camera init
│   └── camera_screen.dart     ← UI, overlay, capture logic
│
├── android/                   ← Android platform config
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml  ← Permissions
│   │   │   └── kotlin/MainActivity.kt
│   │   └── build.gradle
│   └── build.gradle
│
├── ios/                       ← iOS platform config
│   └── Runner/
│       └── Info.plist         ← Permissions
│
├── pubspec.yaml               ← Dependencies
├── analysis_options.yaml      ← Linter config
│
├── README.md                  ← User documentation
├── TECHNICAL.md               ← Technical details
└── QUICKSTART.md              ← Setup guide
```

## Key Implementation Details

### Why Overlays Don't Appear in Photos

The overlay is a Flutter `Container` widget positioned in a `Stack` on top of the `CameraPreview` widget. When `CameraController.takePicture()` is called:

1. It captures data directly from the camera hardware
2. This data doesn't include Flutter's widget tree
3. Therefore, the overlay (which is just a widget) is not captured

```dart
Stack(
  children: [
    CameraPreview(_controller),    // ← Camera stream (captured)
    _buildOverlay(),               // ← Flutter widget (NOT captured)
    _buildControls(),              // ← Flutter widget (NOT captured)
  ],
)
```

### State Management

The app uses simple `setState()` for state management:
- `_overlayShape`: Current shape (none/circle/square)
- `_overlaySize`: Size in pixels (100-400)
- `_controller`: CameraController instance
- `_lastPhotoPath`: Path to last saved photo

### Permissions Flow

```
First App Launch
    ↓
Request Camera Permission
    ↓
┌─────────────┐
│ User Choice │
└──────┬──────┘
       │
   ┌───┴────┐
   │        │
Allow    Deny
   │        │
   │    Camera Unavailable
   │        │
   │    Show Error
   ↓
Camera Active
   ↓
App Functions Normally
```
