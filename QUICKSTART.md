# Quick Start Guide

## Prerequisites

- Flutter SDK installed (https://flutter.dev/docs/get-started/install)
- An Android device (Android 6.0 or higher)
- USB debugging enabled (Android)

## Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/allmonty/photo-position.git
   cd photo-position
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Connect your device**
   - For Android: Enable USB debugging and connect via USB

4. **Verify device connection**
   ```bash
   flutter devices
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Using the App

### Creating Your First Overlay

1. **Launch the app** - The home screen will open
2. **Tap "Start Overlay"** - You'll be prompted to grant overlay permission
3. **Grant permission** - Enable "Draw over other apps" in system settings
4. **Overlay appears** - A transparent overlay with a circle will appear
5. **See the controls** - Control panel is on the right side

### Using the Overlay

1. **Drag to position**:
   - Tap and drag the circle/square to move it anywhere on screen

2. **Toggle shape**:
   - Tap the shape icon (○/□) in the control panel to switch

3. **Adjust size**:
   - Tap the + button to increase size
   - Tap the − button to decrease size
   - Size range: 100-400 pixels

4. **Hide controls**:
   - Tap the eye icon to hide the control panel
   - Tap the overlay shape to show controls again

5. **Use with camera**:
   - Open your device's camera app
   - The overlay will stay on top
   - Position your subject within the overlay
   - Take photos with the camera app

6. **Close overlay**:
   - Tap the × button in the control panel
   - Or return to the Photo Position app and tap "Stop Overlay"

### Tips for Best Results

- **Start with a circle** - Good for aligning faces, flowers, or round objects
- **Use a square** - Better for documents, frames, or architectural elements
- **Adjust the size** - Make the overlay match your subject's size
- **Hide controls** - For unobstructed view when taking photos
- **Take multiple shots** - Use the same overlay position for consistent alignment

### Common Use Cases

1. **Product Photography**: Keep products in the same position across multiple shots
2. **Selfie Alignment**: Maintain consistent face positioning
3. **Before/After**: Take comparison photos with identical framing
4. **ID Photos**: Align face in same position for passport/ID photos
5. **Real Estate**: Consistent framing for property photos

## Troubleshooting

### Overlay permission denied
- Go to Settings → Apps → Photo Position → Draw over other apps
- Enable the permission manually
- Return to the app and tap "Start Overlay" again

### Overlay not appearing
- Check that permission is granted
- Try restarting the app
- Ensure you're running Android 6.0 or higher

### App won't run
- Run `flutter doctor` to check your Flutter installation
- Ensure all dependencies are installed: `flutter pub get`
- Check that your device is connected: `flutter devices`

### Build errors
- Clean and rebuild: `flutter clean && flutter pub get`
- Check that you're using a compatible Flutter version
- Ensure Android SDK is properly configured

## Building for Release

### Android APK
```bash
flutter build apk --release
```
The APK will be in `build/app/outputs/flutter-apk/app-release.apk`

### Install on Device
```bash
flutter install
```

## Platform Support

- ✅ **Android**: Fully supported (Android 6.0+)
- ❌ **iOS**: Not supported (iOS doesn't allow system overlays)

## Support

For issues or questions:
- Check the TECHNICAL.md file for implementation details
- Review flutter_overlay_window documentation: https://pub.dev/packages/flutter_overlay_window
- Submit issues on GitHub: https://github.com/allmonty/photo-position/issues

