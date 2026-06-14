// lib/widgets/common/cs_pressable.dart
//
// CsPressable — one shared press feel for every tappable surface.
// Promoted from mode_gate's private _PressScaleWrapper so cards, tiles, list
// rows and bespoke buttons all scale + give haptic feedback identically.
//
// Use it to wrap anything that isn't already a CsButton/CsCard with onTap.

import 'package:flutter/material.dart';
import '../../core/tokens/spacing_tokens.dart';
import '../../core/haptics.dart';

class CsPressable extends StatefulWidget {
  const CsPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.curve = Curves.easeOut,
    this.duration,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Pressed-state scale. 0.97 reads as a button; 0.99 as a large card.
  final double scale;
  final Curve curve;
  final Duration? duration;
  final bool haptic;
  final HitTestBehavior behavior;
  final bool enabled;

  @override
  State<CsPressable> createState() => _CsPressableState();
}

class _CsPressableState extends State<CsPressable> {
  bool _pressed = false;

  bool get _active =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: active ? (_) => _set(true) : null,
      onTapUp: active && widget.onTap != null
          ? (_) {
              _set(false);
              if (widget.haptic) AppHaptics.tap();
              widget.onTap!.call();
            }
          : null,
      onTapCancel: active ? () => _set(false) : null,
      onLongPress: active && widget.onLongPress != null
          ? () {
              if (widget.haptic) AppHaptics.impact();
              widget.onLongPress!.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: widget.duration ?? AppDuration.fast,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
