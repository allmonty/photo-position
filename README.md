# Photo Position

A Flutter photography app that helps users take multiple photos with aligned elements.

## Features

- **Camera Integration**: Full camera support for taking photos
- **Alignment Overlays**: Position circle or square overlays on the camera preview to help align objects
- **Invisible Overlays**: Overlays appear only on the preview, not in the captured photos
- **Adjustable Size**: Resize the overlay using a slider to match your subject
- **Multiple Shapes**: Choose between circle, square, or no overlay

## How to Use

1. Launch the app to open the camera view
2. Select an overlay shape (Circle or Square) from the bottom controls
3. Adjust the overlay size using the slider to match your subject
4. Position your subject within the overlay
5. Tap the camera button to capture the photo
6. The overlay will NOT appear in the saved photo

## Technical Details

The app uses Flutter's camera plugin to capture photos. The overlay is rendered as a Flutter widget on top of the camera preview but is not part of the camera stream, ensuring it doesn't appear in the final image.

## Setup

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to launch the app on your device

## Permissions

The app requires camera permissions to function properly. On first launch, you'll be prompted to grant camera access.
