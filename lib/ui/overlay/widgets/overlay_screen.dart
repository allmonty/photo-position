import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:photo_position/data/services/overlay_host.dart';
import 'package:photo_position/domain/geometry.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:photo_position/ui/core/theme.dart';
import 'package:photo_position/ui/overlay/view_models/overlay_view_model.dart';

// Keys for widgets that tests need to find and drive directly.
const Key overlayShapeContainerKey = ValueKey('overlayShapeContainer');
const Key horizontalResizeHandleKey = ValueKey('horizontalResizeHandle');
const Key verticalResizeHandleKey = ValueKey('verticalResizeHandle');
const Key circleResizeHandleKey = ValueKey('circleResizeHandle');
const Key closeButtonKey = ValueKey('closeOverlayButton');

const double _borderWidth = 5;

/// The shape, its resize handles and the control panel, drawn inside the
/// native overlay window. All sizing and positioning lives in
/// [OverlayViewModel]; this widget only reports gestures to it.
class OverlayScreen extends StatefulWidget {
  const OverlayScreen(
      {super.key, required this.viewModel, this.listenForMainApp = true});

  final OverlayViewModel viewModel;

  /// Subscribes to messages from the main app; off in widget tests, where the
  /// plugin's single-subscription stream is unavailable.
  final bool listenForMainApp;

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  StreamSubscription<dynamic>? _messages;
  Offset _dragStart = Offset.zero;

  OverlayViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    unawaited(_vm.start());
    if (widget.listenForMainApp) {
      _messages = FlutterOverlayWindow.overlayListener.listen((dynamic event) {
        if (event is! Map) return;
        if (event['action'] == 'close_overlay_and_reset') {
          unawaited(_close());
        } else if (event['action'] == 'load_position') {
          final PositionSlot? slot = PositionSlot.fromJson(
            Map<String, dynamic>.from(event['slot'] as Map<Object?, Object?>),
          );
          if (slot != null) unawaited(_vm.loadPosition(slot));
        }
      });
    }
  }

  @override
  void dispose() {
    unawaited(_messages?.cancel());
    super.dispose();
  }

  Future<void> _close() async {
    await _vm.close();
    IsolateNameServer.lookupPortByName(overlayPortName)
        ?.send({'action': 'close_overlay'});
  }

  Widget _handle(Key key, ResizeAxis axis,
      {required bool horizontal, required Widget child}) {
    double delta(Offset p) =>
        axis == ResizeAxis.width ? (p - _dragStart).dx : (p - _dragStart).dy;
    void start(DragStartDetails d) {
      _dragStart = d.globalPosition;
      _vm.beginResize();
    }

    void update(DragUpdateDetails d) =>
        _vm.updateResize(axis, delta(d.globalPosition));
    void end(DragEndDetails _) => unawaited(_vm.endResize());
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: horizontal ? start : null,
      onHorizontalDragUpdate: horizontal ? update : null,
      onHorizontalDragEnd: horizontal ? end : null,
      onVerticalDragStart: horizontal ? null : start,
      onVerticalDragUpdate: horizontal ? null : update,
      onVerticalDragEnd: horizontal ? null : end,
      child: child,
    );
  }

  Widget _grip({required bool vertical}) => SizedBox(
        width: vertical ? resizeHandleSize : null,
        height: vertical ? null : resizeHandleSize,
        child: Center(
          child: SizedBox(
            width: vertical ? 4 : 24,
            height: vertical ? 24 : 4,
            child: vertical
                ? const VerticalDivider(color: kGold, thickness: 2)
                : const Divider(color: kGold, thickness: 2),
          ),
        ),
      );

  Widget _shape(OverlayGeometry g) => Positioned(
        left: resizeHandleSize,
        top: resizeHandleSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _vm.toggleControls,
          child: Container(
            key: overlayShapeContainerKey,
            width: g.width,
            height: g.height,
            decoration: BoxDecoration(
              shape: g.shape == OverlayShape.circle
                  ? BoxShape.circle
                  : BoxShape.rectangle,
              border:
                  Border.all(color: kGold.withAlpha(200), width: _borderWidth),
            ),
          ),
        ),
      );

  Widget _content(OverlayGeometry g) {
    final bool circle = g.shape == OverlayShape.circle;
    return SizedBox(
      width: g.width + resizeHandleSize * 2,
      height: g.height + resizeHandleSize * 2,
      child: Stack(
        children: [
          _shape(g),
          if (!circle)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _handle(
                horizontalResizeHandleKey,
                ResizeAxis.width,
                horizontal: true,
                child: _grip(vertical: true),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _handle(
              circle ? circleResizeHandleKey : verticalResizeHandleKey,
              circle ? ResizeAxis.both : ResizeAxis.height,
              horizontal: false,
              child: _grip(vertical: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(double windowHeight, OverlayGeometry g) => Positioned(
        top: (windowHeight - panelHeight) / 2,
        right: 0,
        child: Container(
          width: panelWidth,
          height: panelHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: kCrimsonDark.withAlpha(230),
            border: Border.all(color: kGold.withAlpha(150)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: closeButtonKey,
                icon: const Icon(Icons.close, color: kGold),
                tooltip: 'Close overlay',
                onPressed: () => unawaited(_close()),
              ),
              Divider(color: kGold.withAlpha(120), height: 8),
              IconButton(
                icon: Icon(
                  g.shape == OverlayShape.circle
                      ? Icons.circle_outlined
                      : Icons.square_outlined,
                  color: kGold,
                ),
                tooltip: 'Toggle shape',
                onPressed: () => unawaited(_vm.toggleShape()),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final OverlayGeometry? g = _vm.geometry;
        if (g == null) return const SizedBox.shrink();
        final Size window = windowSizeFor(g);
        // Pointer-up after a native window drag is the only signal that the
        // window moved; read the new position back and persist it.
        return Listener(
          onPointerUp: (_) => unawaited(_vm.dragEnded()),
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: window.width,
              height: window.height,
              child: Stack(
                children: [
                  _content(g),
                  if (_vm.showControls) _panel(window.height, g)
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
