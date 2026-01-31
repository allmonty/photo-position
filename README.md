# Photo Position

A Flutter photography app that offers both custom camera with alignment overlays and native camera with full device features.

## Features

### Dual Camera Modes

**Custom Camera Mode** (Default) - Now with Advanced Controls!
- **Alignment Overlays**: Position circle or square overlays on the camera preview to help align objects
- **Invisible Overlays**: Overlays appear only on the preview, not in the captured photos
- **Adjustable Size**: Resize the overlay using a slider to match your subject
- **Multiple Shapes**: Choose between circle, square, or no overlay
- **Zoom Control**: Pinch to zoom or use the vertical slider on the right side
- **Tap to Focus**: Tap anywhere on the preview to focus and adjust exposure
- **Exposure Adjustment**: Fine-tune brightness with the exposure slider
- **Flash Modes**: Toggle between Off, Auto, and Always On

**Native Camera Mode**
- **Full Native Features**: Opens the device's native camera app with all built-in features
- **Alternative Option**: Available when you prefer the native camera interface

### Easy Mode Switching
- Toggle between camera modes using the menu button in the app bar
- Switch modes based on your needs: overlays for alignment or native camera for advanced features

## How to Use

### Custom Camera Mode (with Overlays and Advanced Controls)
1. Launch the app (custom camera mode is default)
2. Grant camera permission when prompted
3. **Use Advanced Controls:**
   - **Zoom**: Use the vertical slider on the right (top) or pinch to zoom
   - **Exposure**: Use the vertical slider on the right (bottom) to adjust brightness
   - **Focus**: Tap anywhere on the preview to set focus point
   - **Flash**: Tap the flash button (top left) to cycle through Off → Auto → On
4. **Use Overlay Guides:**
   - Select an overlay shape (Circle or Square) from the bottom controls
   - Adjust the overlay size using the slider to match your subject
   - Position your subject within the overlay
5. Tap the camera button to capture the photo
6. The overlay will NOT appear in the saved photo

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
- **Custom Camera Mode**: Uses Flutter's `camera` plugin with overlay widgets and advanced controls:
  - Zoom control (slider and pinch gestures)
  - Tap-to-focus functionality
  - Exposure adjustment
  - Flash mode toggle (Off/Auto/On)
  - Overlays rendered on top of the camera preview
- **Native Camera Mode**: Uses Flutter's `image_picker` plugin to launch the native Android camera application

The custom camera mode now provides professional-grade controls while maintaining the overlay positioning feature.

## Setup

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to launch the app on your device

## Permissions

The app requires camera permissions to function properly. On first launch, you'll be prompted to grant camera access.
