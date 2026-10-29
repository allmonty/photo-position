import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:photo_position/data/services/overlay_host.dart';
import 'package:photo_position/domain/geometry.dart';
import 'package:photo_position/domain/models/overlay_geometry.dart';
import 'package:photo_position/domain/models/overlay_style.dart';
import 'package:photo_position/domain/models/position_slot.dart';
import 'package:photo_position/ui/core/theme.dart';
import 'package:photo_position/ui/overlay/view_models/overlay_view_model.dart';

// Keys for widgets that tests need to find and drive directly.
const Key overlayShapeContainerKey = ValueKey('overlayShapeContainer');
const Key horizontalResizeHandleKey = ValueKey('horizontalResizeHandle');
const Key verticalResizeHandleKey = ValueKey('verticalResizeHandle');
const Key circleResizeHandleKey = ValueKey('circleResizeHandle');
const Key closeButtonKey = ValueKey('closeOverlayButton');

/// The shape, its resize handles and the control panel, drawn inside the
/// native overlay window. All sizing and positioning lives in
/// [OverlayViewModel]; this widget only reports gestures to it.
class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key, required this.viewModel, this.messages});

  final OverlayViewModel viewModel;

  /// Messages from the main app. Defaults to the plugin's listener; tests
  /// pass their own stream because the plugin's is not available off-device.
  final Stream<dynamic>? messages;

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
    _messages = (widget.messages ?? FlutterOverlayWindow.overlayListener)
        .listen(_onMessage);
  }

  /// The overlay engine outlives the overlay window: closing it leaves this
  /// widget and its view model alive, so starting the overlay again does not
  /// run `initState` again. The main app sends `open` after every start and
  /// the view model picks up from the last saved position.
  void _onMessage(dynamic event) {
    if (event is! Map) return;
    switch (event['action']) {
      case 'close_overlay_and_reset':
        unawaited(_close());
      case 'open':
        unawaited(_vm.reopen());
      case 'set_style':
        _vm.setStyle(OverlayStyle.fromJson(
          Map<String, dynamic>.from(event['style'] as Map<Object?, Object?>),
        ));
      case 'load_position':
        final PositionSlot? slot = PositionSlot.fromJson(
          Map<String, dynamic>.from(event['slot'] as Map<Object?, Object?>),
        );
        if (slot != null) unawaited(_vm.loadPosition(slot));
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

  Widget _grip({required bool vertical}) => Center(
        child: SizedBox(
          width: vertical ? 4 : 24,
          height: vertical ? 24 : 4,
          child: vertical
              ? const VerticalDivider(color: kGold, thickness: 2)
              : const Divider(color: kGold, thickness: 2),
        ),
      );

  Widget _shape(OverlayGeometry g) => Positioned(
        left: 0,
        top: 0,
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
              border: Border.all(
                  color: _vm.style.borderColor, width: _vm.style.borderWidth),
            ),
          ),
        ),
      );

  /// The resize handles sit on the inside of the shape's edge, so the shape
  /// can grow to the screen edge: a rectangle has one on its right and one
  /// on its bottom edge, a circle one at the bottom.
  List<Widget> _handles(OverlayGeometry g) {
    final bool circle = g.shape == OverlayShape.circle;
    return [
      if (!circle)
        Positioned(
          left: g.width - resizeHandleSize,
          top: 0,
          width: resizeHandleSize,
          height: g.height,
          child: _handle(
            horizontalResizeHandleKey,
            ResizeAxis.width,
            horizontal: true,
            child: _grip(vertical: true),
          ),
        ),
      Positioned(
        left: circle ? g.width / 2 - 30 : 0,
        top: g.height - resizeHandleSize,
        width: circle ? 60 : g.width,
        height: resizeHandleSize,
        child: _handle(
          circle ? circleResizeHandleKey : verticalResizeHandleKey,
          circle ? ResizeAxis.both : ResizeAxis.height,
          horizontal: false,
          child: _grip(vertical: false),
        ),
      ),
    ];
  }

  /// Inside the shape, clear of the right and bottom handle strips, when it
  /// fits; otherwise beside the shape (the window is wider then).
  Widget _panel(Size window, OverlayGeometry g) => Positioned(
        top: panelFitsInside(g)
            ? (window.height - resizeHandleSize - panelHeight) / 2
            : (window.height - panelHeight) / 2,
        left: panelFitsInside(g)
            ? window.width - resizeHandleSize - panelWidth
            : g.width,
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
                  _shape(g),
                  ..._handles(g),
                  if (_vm.showControls) _panel(window, g),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
