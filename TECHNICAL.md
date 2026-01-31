# Photo Position App - Technical Documentation

## Architecture Overview

This Flutter app provides a hybrid camera solution with both custom camera functionality (with positioning overlays) and native camera integration.

### Key Components

#### 1. Main App (`lib/main.dart`)
- Initializes available cameras on app startup for custom camera mode
- Sets up the MaterialApp with the CameraScreen as home

#### 2. Camera Screen (`lib/camera_screen.dart`)
- **Dual Mode System**: Supports both Custom and Native camera modes
- **CameraController**: Manages custom camera functionality with overlays
- **ImagePicker**: Launches native camera app for full feature access
- **Overlay System**: Renders shapes (circle/square) on custom camera preview
- **UI Controls**: Mode switcher, overlay controls, and camera buttons

### How the Hybrid System Works

The app offers two distinct camera modes that users can toggle between:

#### Custom Camera Mode (Default)
```
Stack
├── CameraPreview (layer 0 - actual camera feed)
├── Overlay Widget (layer 1 - UI only, not in camera stream)
└── Controls (layer 2 - UI buttons and sliders)
```

When `takePicture()` is called on the `CameraController`, it captures only the camera stream data (layer 0), which does not include the Flutter widgets rendered on top. This ensures the overlay appears for alignment but not in the saved photo.

#### Native Camera Mode
```
App Screen
    ↓
User taps "Open Native Camera"
    ↓
ImagePicker.pickImage(source: ImageSource.camera)
    ↓
Native Camera App Launches
    ↓
User takes photo with all native features
    ↓
Photo returned to app
    ↓
Photo displayed and saved
```

### Features

1. **Mode Switching**: Toggle between Custom and Native camera modes via AppBar menu
2. **Custom Camera Features**:
   - **Overlay System**:
     - Shape Selection: Toggle between no overlay, circle, or square
     - Size Adjustment: Slider to resize overlay from 100 to 400 pixels
     - Visual Feedback: Selected shape is highlighted in blue
   - **Advanced Camera Controls**:
     - **Zoom**: Vertical slider or pinch gesture (supports device's full zoom range)
     - **Tap to Focus**: Tap anywhere to set focus and exposure point
     - **Exposure**: Vertical slider for brightness adjustment
     - **Flash**: Toggle button cycling through Off → Auto → Always
3. **Native Camera Features**:
   - Full access to all device camera features (HDR, filters, panorama, etc.)
   - Native camera controls and processing
   - Manufacturer optimizations

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

- **camera**: ^0.10.5+5 - Custom camera with preview and controls
- **image_picker**: ^1.0.7 - Native camera and gallery access
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

Since this app uses camera hardware, it must be tested on physical devices. Key test scenarios:

1. **Mode Switching**: Verify toggling between Custom and Native modes works correctly
2. **Custom Camera Mode**:
   - **Overlays**:
     - Verify overlays appear on preview
     - Confirm overlays don't appear in saved photos
     - Test all three overlay options (none, circle, square)
     - Verify slider changes overlay size
   - **Camera Controls**:
     - Test zoom slider and verify zoom level changes
     - Test tap-to-focus on different parts of the preview
     - Test exposure adjustment slider
     - Test flash mode cycling (off → auto → on → off)
     - Verify all controls work simultaneously with overlays
3. **Native Camera Mode**:
   - Verify native camera launches correctly
   - Confirm photos can be taken and returned to the app
   - Test that all native camera features are accessible
4. **Permissions**: Test camera permission requests on first launch
5. **Photo Storage**: Verify photos are saved to the correct location in both modes

### Known Limitations

- Requires physical device with camera (won't work in emulators)
- Photos are saved to app's documents directory (not photo gallery by default)
- Cannot use overlays with native camera (mutually exclusive features)

### Future Enhancements

Potential improvements:
- Gallery integration to view all saved photos
- Save directly to photo gallery
- Share photos to other apps
- Delete photos from within the app
- Front/back camera switching in custom mode
- Flash/torch controls in custom mode
- Grid overlay option (rule of thirds)
