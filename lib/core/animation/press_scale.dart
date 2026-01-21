import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final Duration duration;
  final String? semanticLabel; // For accessibility
  final bool enableHaptic;

  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.semanticLabel,
    this.enableHaptic = true,
  }) : assert(scale > 0.1 && scale <= 2.0,
  'Scale must be between 0.1 and 2.0');

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  double _currentScale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _currentScale = widget.scale;
    });
  }

  void _onTapUp(TapUpDetails details) => _resetScale();
  void _onTapCancel() => _resetScale();
  void _resetScale() => setState(() => _currentScale = 1.0);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? 'Button',
      child: SizedBox(
        width: 48.0,
        height: 48.0,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          behavior: HitTestBehavior.opaque,
          child: Focus(
            autofocus: false,
            onKey: (node, event) {
              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space) {
                widget.onTap();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: AnimatedScale(
              scale: _currentScale,
              duration: widget.duration,
              curve: Curves.easeOut,
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}