// lib/screens/booking/booking_step_widgets.dart
//
// Shared widgets used across all 4 booking wizard steps.

import 'package:flutter/material.dart';
import '../../core/theme.dart';

// ═══════════════════════════════════════════════════════════════
//  STEP HEADER
// ═══════════════════════════════════════════════════════════════

class BookingStepHeader extends StatelessWidget {
  const BookingStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.colors,
  });

  final int step;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: colors.colorBackgroundPrimary,
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, topPad + AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.colorSurfacePrimary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: colors.colorTextPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP $step OF 4',
                    style: AppTextStyles.overline(colors.colorTextTertiary)),
                const SizedBox(height: 2),
                Text(title,
                    style: AppTextStyles.headingL(colors.colorTextPrimary)),
                Text(subtitle,
                    style: AppTextStyles.bodyS(colors.colorTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STEP PROGRESS BAR
// ═══════════════════════════════════════════════════════════════

class BookingStepProgressBar extends StatelessWidget {
  const BookingStepProgressBar({
    super.key,
    required this.currentStep,
    required this.colors,
  });

  final int currentStep;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: List.generate(4, (i) {
          final active = i < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: active
                    ? colors.colorAccentPrimary
                    : colors.colorBorderSubtle,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STEP FOOTER CTA
// ═══════════════════════════════════════════════════════════════

class BookingStepFooter extends StatelessWidget {
  const BookingStepFooter({
    super.key,
    required this.label,
    required this.colors,
    required this.botPad,
    required this.onTap,
    this.isSkip = false,
    this.isLoading = false,
  });

  final String label;
  final AppColorScheme colors;
  final double botPad;
  final VoidCallback onTap;
  final bool isSkip;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, botPad + AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        border: Border(
            top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navBar,
      ),
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          height: 54,
          decoration: BoxDecoration(
            color: isSkip
                ? colors.colorSurfaceElevated
                : colors.colorAccentPrimary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: isSkip
                ? Border.all(color: colors.colorBorderSubtle, width: 0.5)
                : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: isSkip
                          ? colors.colorTextSecondary
                          : colors.colorTextOnAccent,
                    ),
                  )
                : Text(
                    label,
                    style: AppTextStyles.headingS(
                      isSkip
                          ? colors.colorTextSecondary
                          : colors.colorTextOnAccent,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
