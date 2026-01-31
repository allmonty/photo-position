# Quick Start Guide

## Prerequisites

- Flutter SDK installed (https://flutter.dev/docs/get-started/install)
- A physical Android or iOS device (emulators don't support camera)
- USB debugging enabled (Android) or developer mode (iOS)

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
   - For iOS: Connect via USB and trust the computer

4. **Verify device connection**
   ```bash
   flutter devices
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Using the App

### Taking Your First Photo

1. **Launch the app** - You'll see the main screen with an "Open Camera" button
2. **Grant camera permission** - Allow camera access when prompted
3. **Tap "Open Camera"** - The native camera app will launch
4. **Use native features** - Access all your device's camera features:
   - HDR mode
   - Filters and effects
   - Panorama mode
   - Burst mode
   - Flash settings
   - And all other device-specific features
5. **Capture** - Take the photo using the native camera's shutter button
6. **Success!** - The photo will be displayed in the app with a confirmation message

### Tips for Best Results

- **Explore native features** - Take advantage of HDR, night mode, and other advanced features
- **Use device filters** - Apply filters directly in the native camera for better results
- **Adjust settings** - Use your device's camera settings for optimal quality
- **Check lighting** - Ensure good lighting for better photo quality
- **Preview in app** - View your captured photo in the app after taking it

### Common Use Cases

1. **Professional Photos**: Use HDR and other advanced features for high-quality shots
2. **Quick Capture**: Access the native camera quickly with one tap
3. **Filtered Photos**: Apply native filters directly during capture
4. **Panoramas**: Use panorama mode for wide-angle shots
5. **Low-Light**: Use night mode or flash for low-light photography

## Troubleshooting

### Camera not working
- Ensure you're using a physical device (not an emulator)
- Check that camera permissions are granted
- Try restarting the app

### App won't run
- Run `flutter doctor` to check your Flutter installation
- Ensure all dependencies are installed: `flutter pub get`
- Check that your device is connected: `flutter devices`

### Build errors
- Clean and rebuild: `flutter clean && flutter pub get`
- Check that you're using a compatible Flutter version
- Ensure Android SDK/Xcode is properly configured

## Building for Release

### Android APK
```bash
flutter build apk --release
```
The APK will be in `build/app/outputs/flutter-apk/app-release.apk`

### iOS IPA
```bash
flutter build ios --release
```
Then archive and export from Xcode.

## Support

For issues or questions:
- Check the TECHNICAL.md file for implementation details
- Review Flutter image_picker plugin documentation: https://pub.dev/packages/image_picker
- Submit issues on GitHub: https://github.com/allmonty/photo-position/issues
