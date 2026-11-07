import 'dart:async';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

class AppToastOverlay extends StatefulWidget {
  const AppToastOverlay({
    super.key,
    required this.message,
    required this.type,
    required this.leftInset,
    required this.onDismissed,
  });

  final String message;
  final GlassToastType type;
  final double leftInset;
  final VoidCallback onDismissed;

  @override
  State<AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<AppToastOverlay>
    with SingleTickerProviderStateMixin {
  static const _maxWidth = 560.0;
  static const _visibleFor = Duration(seconds: 3);

  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Timer _timer;
  var _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _slide = Tween(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _timer = Timer(_visibleFor, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    _timer.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 16;

    return Positioned(
      left: widget.leftInset + 16,
      right: 16,
      bottom: bottom,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: FadeTransition(
            opacity: _controller,
            child: SlideTransition(
              position: _slide,
              child: GlassToast(
                message: widget.message,
                type: widget.type,
                onDismissed: _dismiss,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
