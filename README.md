# Photo Position

An Android app that draws a circle or square on top of other apps (for example the camera) to help you line up a photo. Place it once; it stays on the same spot of the phone's glass when you rotate the phone, and you can keep three saved positions.

## Start

```bash
flutter pub get
flutter run        # on an Android device or emulator
```

1. Tap **Start overlay** and grant "Draw over other apps" when asked.
2. Drag the shape where you want it. Drag the gold handles to resize. Tap the shape to hide or show the control panel.
3. Open your camera app; the overlay stays on top.
4. Rotating the phone carries the shape with it: same place on the glass, same shape (a rectangle turns with the phone); only the control panel is always upright.

### Saved positions

The home screen has three slots drawn as a phone with the saved shape on it. The save icon stores the overlay's current position, tapping a slot moves the overlay there (or opens it there), the cross empties it.

## Documentation

- [Developer guide](docs/developer-guide.md): setup, commands, architecture, tests
- [Decisions](docs/decisions.md): why the position model, the native bridge and the slots work the way they do

## Platform support

Android is the real target: the overlay uses `SYSTEM_ALERT_WINDOW`, which iOS does not offer. The app also builds and runs on the iOS simulator (home screen, saved positions, icon), but starting the overlay does nothing there. The position logic is plain Dart, so `flutter test` and `flutter test integration_test -d <simulator>` run on both platforms.
