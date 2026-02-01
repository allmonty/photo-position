# Gemini Project Context: Photo Position

## Project Overview

This is a Flutter application that creates a system overlay for positioning photos. The overlay is a draggable circle or square that stays on top of other applications, making it useful for aligning subjects when taking pictures. The app uses the `flutter_overlay_window` package to create and manage the overlay.

## Building and Running

### Prerequisites

- Flutter SDK: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)

### Commands

- **Install dependencies:**
  ```bash
  flutter pub get
  ```

- **Run the app:**
  ```bash
  flutter run
  ```

- **Build the app for Android:**
  ```bash
  flutter build apk
  ```

## Development Conventions

### Code Style

The project follows the standard Dart and Flutter coding conventions. The `analysis_options.yaml` file includes `flutter_lints` for static analysis.

### Testing

The project includes a `test` directory with a basic widget test in `test/widget_test.dart`. Tests can be run using the following command:

```bash
flutter test
```

### Architecture

The application is divided into two main parts:

1.  **Main Application (`lib/main.dart`):** This is the entry point of the application. It displays the main screen with buttons to start and stop the overlay.
2.  **Overlay Screen (`lib/overlay_screen.dart`):** This file defines the UI and logic for the overlay itself. It includes the draggable shape, control panel, and handles user interactions like toggling the shape, adjusting the size, and showing/hiding the controls.

The application uses a separate entry point for the overlay, defined in `lib/overlay_entry.dart`, which is a requirement of the `flutter_overlay_window` package.

## Troubleshooting

If the overlay is not appearing, check the following:

1.  **`showOverlay` parameters:** In `lib/main.dart`, ensure that the `showOverlay` function is called with the `overlayContent` parameter set to the name of the overlay entry point function. For example: `overlayContent: 'overlayMain'`.

2.  **Android Manifest:** The `android/app/src/main/AndroidManifest.xml` file must include the following permissions and service declaration:
    ```xml
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    
    <service
        android:name="io.flutter.plugins.flutter_overlay_window.OverlayService"
        android:exported="false"
        android:foregroundServiceType="specialUse">
        <property
            android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
            android:value="Positioning overlay for alignment" />
    </service>
    ```
