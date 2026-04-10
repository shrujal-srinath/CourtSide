// lib/widgets/common/cs_chip.dart
//
// CsChip — sport / filter tag chip.
// Active (no sport): accentSubtle bg + accentPrimary border + accentPrimary text.
// Active (sport):    sportColor.withValues(alpha:0.14) bg + sportColor border.
// Inactive:          surfaceElevated bg + borderSubtle border + textSecondary text.
// AnimatedContainer 150ms for all state transitions.

import 'package:flutter/material.dart';
import '../../core/tokens/color_tokens.dart';
import '../../core/tokens/spacing_tokens.dart';
import '../../core/tokens/typography_tokens.dart';

class CsChip extends StatelessWidget {
  const CsChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.sportColor,
    this.icon,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  /// When provided, active state uses sport-specific color instead of accent.
  final Color? sportColor;

  /// Optional leading icon (16px recommended).
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final Color bg;
    final Color border;
    final Color text;

    if (isActive) {
      if (sportColor != null) {
        bg     = sportColor!.withValues(alpha: 0.14);
        border = sportColor!;
        text   = sportColor!;
      } else {
        bg     = colors.colorAccentSubtle;
        border = colors.colorAccentPrimary;
        text   = colors.colorAccentPrimary;
      }
    } else {
      bg     = colors.colorSurfaceElevated;
      border = colors.colorBorderSubtle;
      text   = colors.colorTextSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: border, width: isActive ? 1.0 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(label, style: AppTextStyles.labelM(text)),
          ],
        ),
      ),
    );
  }
}
