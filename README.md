# Photo Position

A Flutter photography app that offers both custom camera with alignment overlays and native camera with full device features.

## Features

### Dual Camera Modes

**Custom Camera Mode** (Default)
- **Alignment Overlays**: Position circle or square overlays on the camera preview to help align objects
- **Invisible Overlays**: Overlays appear only on the preview, not in the captured photos
- **Adjustable Size**: Resize the overlay using a slider to match your subject
- **Multiple Shapes**: Choose between circle, square, or no overlay

**Native Camera Mode**
- **Full Native Features**: Opens the device's native camera app with all built-in features (HDR, filters, panorama, burst mode, night mode, etc.)
- **Better Quality**: Native processing and algorithms
- **Familiar Interface**: Users already know how to use their device's camera

### Easy Mode Switching
- Toggle between camera modes using the menu button in the app bar
- Switch modes based on your needs: overlays for alignment or native camera for advanced features

## How to Use

### Custom Camera Mode (with Overlays)
1. Launch the app (custom camera mode is default)
2. Grant camera permission when prompted
3. Select an overlay shape (Circle or Square) from the bottom controls
4. Adjust the overlay size using the slider to match your subject
5. Position your subject within the overlay
6. Tap the camera button to capture the photo
7. The overlay will NOT appear in the saved photo

### Native Camera Mode (all features)
1. Tap the camera icon menu in the app bar
2. Select "Native Camera (all features)"
3. Tap "Open Native Camera" button
4. Use all native camera features (HDR, filters, panorama, etc.)
5. Take photo using native camera controls
6. Photo is saved and displayed in the app

### Switching Modes
- Tap the camera/menu icon in the top right corner
- Select your preferred camera mode
- The app remembers your choice during the session

## Technical Details

The app uses a hybrid approach:
- **Custom Camera Mode**: Uses Flutter's `camera` plugin with overlay widgets rendered on top of the camera preview
- **Native Camera Mode**: Uses Flutter's `image_picker` plugin to launch the native Android camera application

This provides the best of both worlds: alignment guides when needed, and full native camera features when desired.

## Setup

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to launch the app on your device

## Permissions

The app requires camera permissions to function properly. On first launch, you'll be prompted to grant camera access.
