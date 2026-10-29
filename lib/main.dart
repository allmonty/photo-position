import 'package:flutter/material.dart';
import 'package:photo_position/config/dependencies.dart';
import 'package:photo_position/ui/core/theme.dart';
import 'package:photo_position/ui/home/widgets/home_screen.dart';
import 'package:photo_position/ui/overlay/widgets/overlay_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PhotoPositionApp(dependencies: Dependencies()));
}

// @pragma("vm:entry-point") is required so flutter_overlay_window's native
// side can find and launch this function as the entry point for the
// overlay's separate Flutter engine (it isn't reachable through the normal
// main() widget tree).
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: artDecoTheme,
      home: OverlayScreen(viewModel: Dependencies().createOverlayViewModel()),
    ),
  );
}

class PhotoPositionApp extends StatelessWidget {
  const PhotoPositionApp({super.key, required this.dependencies});

  final Dependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Position Overlay',
      theme: artDecoTheme,
      home: HomeScreen(dependencies: dependencies),
    );
  }
}
