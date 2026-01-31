# App Structure Visualization

## UI Layout

```
┌─────────────────────────────────────────┐
│         Photo Position                  │  ← AppBar
├─────────────────────────────────────────┤
│                                         │
│                                         │
│         [Last Photo Preview]            │  ← Shows captured photo
│              or                         │     OR
│         [Camera Icon]                   │  ← No photo yet state
│      "No photos taken yet"              │
│                                         │
│                                         │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│      [ 📷 Open Camera Button ]          │  ← Opens native camera
│                                         │
└─────────────────────────────────────────┘
```

## Component Stack Layers

```
Layer 1: FloatingActionButton (Open Camera)  ← Always on top
         ↑
Layer 0: Content (Photo Preview or Empty State)
```

## Data Flow

```
App Start
    ↓
Display Main Screen
    ↓
User Taps "Open Camera" Button
    ↓
Launch Native Camera App
    ↓
User Takes Photo (using native camera features)
    ↓
Native Camera Returns Photo
    ↓
Save Photo to App Directory
    ↓
Display Photo Preview
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

### How Native Camera Integration Works

The app uses the `image_picker` package to launch the device's native camera application:

1. User taps the "Open Camera" button
2. App calls `ImagePicker.pickImage(source: ImageSource.camera)`
3. Flutter launches the native camera intent on Android
4. User uses all native camera features (HDR, filters, panorama, etc.)
5. Photo is captured using native camera controls
6. Native camera returns the photo to Flutter
7. Flutter saves and displays the photo

```dart
final ImagePicker _picker = ImagePicker();

Future<void> _takePicture() async {
  final XFile? photo = await _picker.pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.rear,
  );
  
  if (photo != null) {
    // Save and display the photo
  }
}
```

### State Management

The app uses simple `setState()` for state management:
- `_imageFile`: The last captured photo file
- `_lastPhotoPath`: Path to the last saved photo

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
