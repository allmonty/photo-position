# Photo Position

A Flutter overlay app that creates a positioning overlay (circle or square) that stays on top of other apps.

## Features

- **System Overlay**: Creates a transparent overlay that stays on top of all apps
- **Shape Options**: Toggle between circle and square shapes
- **Adjustable Size**: Increase or decrease the overlay size
- **Draggable**: Move the overlay anywhere on the screen
- **Camera Compatible**: Works perfectly over the camera app for photo alignment
- **Toggle Controls**: Show/hide controls by tapping the overlay

## How to Use

1. Launch the app
2. Tap "Start Overlay" to create the overlay (you'll be asked to grant overlay permission)
3. The overlay will appear on your screen with controls on the right
4. Drag the circle/square to position it anywhere
5. Use the control panel to:
   - Toggle between circle and square shapes
   - Adjust size with +/- buttons
   - Hide controls (tap overlay to show again)
   - Close the overlay
6. Open your camera app - the overlay will stay on top
7. Position your subject within the overlay for perfect alignment
8. Return to the app or use the overlay controls to stop the overlay

## Technical Details

The app uses the `flutter_overlay_window` package to create a system-level overlay that can stay on top of other applications. The overlay is fully interactive and can be positioned anywhere on the screen.

## Setup

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to launch the app on your device

## Permissions

The app requires "Draw over other apps" permission (SYSTEM_ALERT_WINDOW) to function properly. On first use, you'll be prompted to grant this permission.

## Platform Support

Currently supports Android devices. The overlay permission must be granted manually on Android 6.0 (Marshmallow) and above.

