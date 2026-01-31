# Photo Position App - Technical Documentation

## Architecture Overview

This Flutter app provides camera functionality with positioning overlays to help users take aligned photos.

### Key Components

#### 1. Main App (`lib/main.dart`)
- Initializes available cameras on app startup
- Sets up the MaterialApp with the CameraScreen as home

#### 2. Camera Screen (`lib/camera_screen.dart`)
- **CameraController**: Manages camera functionality
- **Overlay System**: Renders shapes (circle/square) on top of camera preview
- **UI Controls**: Buttons for shape selection and size adjustment

### How Overlays Don't Appear in Photos

The overlay system uses Flutter's widget layering with a `Stack`:

```
Stack
├── CameraPreview (layer 0 - actual camera feed)
├── Overlay Widget (layer 1 - UI only, not in camera stream)
└── Controls (layer 2 - UI buttons and sliders)
```

When `takePicture()` is called on the `CameraController`, it captures only the camera stream data (layer 0), which does not include the Flutter widgets rendered on top. This ensures the overlay appears for alignment but not in the saved photo.

### Features

1. **Shape Selection**: Toggle between no overlay, circle, or square
2. **Size Adjustment**: Slider to resize overlay from 100 to 400 pixels
3. **Visual Feedback**: Selected shape is highlighted in blue
4. **Photo Capture**: Standard camera capture that saves to device storage

### File Structure

```
lib/
  main.dart           - App entry point and camera initialization
  camera_screen.dart  - Main camera UI with overlay functionality

android/
  app/
    src/main/
      AndroidManifest.xml  - Camera permissions for Android
      kotlin/              - MainActivity implementation
    build.gradle           - Android build configuration

ios/
  Runner/
    Info.plist           - Camera permissions for iOS

pubspec.yaml           - Dependencies (camera, path_provider, path)
```

### Dependencies

- **camera**: ^0.10.5+5 - Camera plugin for Flutter
- **path_provider**: ^2.1.1 - Get device directories for saving photos
- **path**: ^1.8.3 - Path manipulation utilities

### Permissions

#### Android (AndroidManifest.xml)
- `android.permission.CAMERA` - Required to access camera
- `android.permission.WRITE_EXTERNAL_STORAGE` - Save photos
- `android.permission.READ_EXTERNAL_STORAGE` - Access saved photos

#### iOS (Info.plist)
- `NSCameraUsageDescription` - Camera access explanation
- `NSMicrophoneUsageDescription` - For potential video recording
- `NSPhotoLibraryUsageDescription` - Photo library access

### Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run on a physical device (camera won't work in emulators):
   ```bash
   flutter run
   ```

3. Or build for release:
   ```bash
   flutter build apk        # Android
   flutter build ios        # iOS
   ```

### Testing

Since this app requires camera hardware, it must be tested on physical devices. Key test scenarios:

1. **Overlay Visibility**: Verify overlays appear on preview
2. **Photo Capture**: Confirm overlays don't appear in saved photos
3. **Shape Switching**: Test all three overlay options (none, circle, square)
4. **Size Adjustment**: Verify slider changes overlay size
5. **Permissions**: Test camera permission requests on first launch

### Known Limitations

- Requires physical device with camera (won't work in emulators)
- Photos are saved to app's documents directory (not photo gallery by default)
- Front/back camera switching not implemented (uses default camera)
- Flash controls not implemented

### Future Enhancements

Potential improvements:
- Gallery integration to view saved photos
- Camera switching (front/back)
- Flash/torch controls
- Grid overlay option (rule of thirds)
- Save directly to photo gallery
- Multiple overlay colors
- Opacity adjustment for overlays
