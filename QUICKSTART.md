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

1. **Launch the app** - The camera view will open automatically
2. **Grant camera permission** - Allow camera access when prompted
3. **Select an overlay**:
   - Tap the circle icon for a circular overlay
   - Tap the square icon for a rectangular overlay
   - Tap the X icon to hide the overlay
4. **Adjust size** - Use the slider to resize the overlay
5. **Position your subject** - Align your subject within the overlay
6. **Capture** - Tap the large camera button at the bottom
7. **Success!** - You'll see a confirmation message with the save location

### Tips for Best Results

- **Start with a circle** - Good for aligning faces, flowers, or round objects
- **Use a square** - Better for documents, frames, or architectural elements
- **Adjust the size** - Make the overlay match your subject's size
- **Take multiple shots** - Use the same overlay position for consistent alignment
- **Check lighting** - Ensure good lighting for better photo quality

### Common Use Cases

1. **Product Photography**: Keep products in the same position across multiple shots
2. **Stop Motion**: Align objects frame-by-frame for animation
3. **Before/After**: Take comparison photos with identical framing
4. **Portraits**: Keep face positioning consistent across a series
5. **Time-Lapse**: Maintain consistent framing for time-lapse sequences

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
- Review Flutter camera plugin documentation: https://pub.dev/packages/camera
- Submit issues on GitHub: https://github.com/allmonty/photo-position/issues
