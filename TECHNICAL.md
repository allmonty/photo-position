# Photo Position App - Technical Documentation

## Architecture Overview

This Flutter app provides native camera functionality using the device's built-in camera application.

### Key Components

#### 1. Main App (`lib/main.dart`)
- Sets up the MaterialApp with the CameraScreen as home
- Simple entry point without camera initialization

#### 2. Camera Screen (`lib/camera_screen.dart`)
- **ImagePicker**: Launches the native camera app and receives captured images
- **Image Preview**: Displays the last captured photo
- **UI Controls**: Button to open the native camera

### How Native Camera Works

The app uses the `image_picker` package to launch the device's native camera application:

1. User taps "Open Camera" button
2. App calls `ImagePicker.pickImage(source: ImageSource.camera)`
3. Native camera app opens with all device-specific features
4. User takes photo using native camera controls
5. Photo is returned to the app
6. App saves the photo and displays it

### Features

1. **Native Camera**: Full access to all device camera features (HDR, filters, panorama, etc.)
2. **Photo Preview**: View captured photos within the app
3. **Photo Storage**: Automatic saving to device storage

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

Since this app uses the native camera, it must be tested on physical devices. Key test scenarios:

1. **Camera Launch**: Verify native camera opens correctly
2. **Photo Capture**: Confirm photos can be taken and returned to the app
3. **Photo Display**: Verify captured photos display correctly
4. **Photo Storage**: Test that photos are saved to the correct location
5. **Permissions**: Test camera permission requests on first launch

### Known Limitations

- Requires physical device with camera (won't work in emulators)
- Photos are saved to app's documents directory (not photo gallery by default)
- No overlay features (trade-off for native camera access)

### Future Enhancements

Potential improvements:
- Gallery integration to view all saved photos
- Save directly to photo gallery
- Share photos to other apps
- Delete photos from within the app
