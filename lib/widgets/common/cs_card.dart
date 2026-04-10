// lib/widgets/common/cs_card.dart
//
// CsCard — Courtside surface container.
// Three elevations map to the 4-level surface hierarchy.
// Always: 0.5px borderSubtle, AppRadius.card, optional press feedback.

import 'package:flutter/material.dart';
import '../../core/tokens/color_tokens.dart';
import '../../core/tokens/spacing_tokens.dart';

enum CardElevation {
  /// colorSurfacePrimary — default card surface.
  base,

  /// colorSurfaceElevated — lifted cards, venue/court cards.
  raised,

  /// colorSurfaceOverlay — modals, drawers, overlaid panels.
  overlay,
}

class CsCard extends StatefulWidget {
  const CsCard({
    super.key,
    required this.child,
    this.elevation = CardElevation.base,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final CardElevation elevation;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadiusGeometry? borderRadius;
  final Clip clipBehavior;

  @override
  State<CsCard> createState() => _CsCardState();
}

class _CsCardState extends State<CsCard> {
  bool _pressed = false;

  void _onTapDown(_) {
    if (widget.onTap == null) return;
    setState(() => _pressed = true);
  }

  void _onTapUp(_) {
    if (widget.onTap == null) return;
    setState(() => _pressed = false);
    widget.onTap!();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final BorderRadiusGeometry radius =
        widget.borderRadius ?? BorderRadius.circular(AppRadius.card);

    final Color bg = switch (widget.elevation) {
      CardElevation.base    => colors.colorSurfacePrimary,
      CardElevation.raised  => colors.colorSurfaceElevated,
      CardElevation.overlay => colors.colorSurfaceOverlay,
    };

    final List<BoxShadow> shadow = switch (widget.elevation) {
      CardElevation.base    => AppShadow.card,
      CardElevation.raised  => AppShadow.cardElevated,
      CardElevation.overlay => [],
    };

    Widget card = AnimatedScale(
      scale: (_pressed && widget.onTap != null) ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        clipBehavior: widget.clipBehavior,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(
            color: colors.colorBorderSubtle,
            width: 0.5,
          ),
          boxShadow: shadow,
        ),
        child: widget.padding != null
            ? Padding(padding: widget.padding!, child: widget.child)
            : widget.child,
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}
