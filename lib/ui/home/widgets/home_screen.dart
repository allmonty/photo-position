import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_position/config/dependencies.dart';
import 'package:photo_position/ui/core/theme.dart';
import 'package:photo_position/ui/core/widgets/art_deco.dart';
import 'package:photo_position/ui/home/view_models/home_view_model.dart';
import 'package:photo_position/ui/home/view_models/slots_view_model.dart';
import 'package:photo_position/ui/home/view_models/style_view_model.dart';
import 'package:photo_position/ui/home/widgets/slots_section.dart';
import 'package:photo_position/ui/home/widgets/style_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.dependencies});

  final Dependencies dependencies;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeViewModel _home = widget.dependencies.createHomeViewModel();
  late final SlotsViewModel _slots = widget.dependencies.createSlotsViewModel();
  late final StyleViewModel _style = widget.dependencies
      .createStyleViewModel(onChanged: (s) => unawaited(_home.updateStyle(s)));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_slots.load());
    unawaited(_style.load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _home.dispose();
    _slots.dispose();
    _style.dispose();
    super.dispose();
  }

  // The overlay keeps saving its position while this app is in the
  // background; reload so "save to slot" copies the latest one.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_slots.load());
  }

  Future<void> _run(Future<String?> action) async {
    final String? error = await action;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), duration: const Duration(seconds: 3)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PHOTO POSITION')),
      body: Center(
        // Past the ends the content follows the finger and springs back on
        // release (instead of Android's stretch effect).
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icon/icon.png', width: 120, height: 120),
                const SizedBox(height: 24),
                Text(
                  'PHOTO POSITION OVERLAY',
                  style: GoogleFonts.poiretOne(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 28 * 0.05,
                    color: kGold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Create a positioning overlay that stays on top of other apps',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.libreFranklin(
                      fontSize: 14, color: kOnSurface),
                ),
                const SizedBox(height: 32),
                const ArtDecoDivider(),
                const SizedBox(height: 32),
                ListenableBuilder(
                  listenable: _home,
                  builder: (context, _) => _home.isOverlayActive
                      ? Column(
                          children: [
                            Text(
                              'OVERLAY ACTIVE',
                              style: GoogleFonts.poiretOne(
                                fontSize: 16,
                                letterSpacing: 16 * 0.1,
                                color: kGold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ArtDecoButton(
                              icon: Icons.stop,
                              label: 'STOP OVERLAY',
                              onPressed: () => unawaited(_run(_home.stop())),
                              filled: false,
                            ),
                          ],
                        )
                      : ArtDecoButton(
                          icon: Icons.play_arrow,
                          label: 'START OVERLAY',
                          onPressed: () => unawaited(_run(_home.start())),
                          filled: true,
                        ),
                ),
                const SizedBox(height: 32),
                const ArtDecoDivider(),
                const SizedBox(height: 24),
                const SectionTitle('SAVED POSITIONS'),
                const SizedBox(height: 12),
                SlotsSection(viewModel: _slots, onSelect: _home.moveOverlayTo),
                const SizedBox(height: 24),
                const ArtDecoDivider(),
                const SizedBox(height: 24),
                const SectionTitle('BORDER'),
                const SizedBox(height: 12),
                StyleSection(viewModel: _style),
                const SizedBox(height: 24),
                const ArtDecoDivider(),
                const SizedBox(height: 24),
                const SectionTitle('INSTRUCTIONS'),
                const SizedBox(height: 12),
                const InstructionsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
