# Photo Position

A Flutter photography app that uses the native Android camera with all its features.

## Features

- **Native Camera Integration**: Opens the device's native camera app with all built-in features (HDR, filters, panorama, burst mode, etc.)
- **Photo Preview**: View the last captured photo in the app
- **Photo Storage**: Photos are automatically saved to the app's documents directory

## How to Use

1. Launch the app
2. Tap the "Open Camera" button to launch the native camera
3. Use all the native camera features available on your device
4. Take a photo using the native camera app
5. The photo will be saved and displayed in the app

## Technical Details

The app uses Flutter's `image_picker` plugin to launch the native Android camera application. This provides access to all the device's camera features without needing to implement them separately.

## Setup

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to launch the app on your device

## Permissions

The app requires camera permissions to function properly. On first launch, you'll be prompted to grant camera access.
