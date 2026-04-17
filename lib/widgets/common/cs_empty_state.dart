// lib/widgets/common/cs_empty_state.dart
//
// CsEmptyState  — shown when a screen has no data (no bookings, no results, etc.)
// CsErrorState  — shown when a fetch fails, with a retry action.
//
// Both components:
//   • Use semantic tokens only (no raw colors)
//   • Animate in: fade + slide from y+16px, 300ms easeOutCubic
//   • Pair with CsButton for the action
//
// Usage:
//   CsEmptyState(
//     icon: Icons.calendar_today_outlined,
//     title: 'No upcoming bookings',
//     subtitle: 'Book a court and start playing.',
//     ctaLabel: 'Explore courts',
//     onCta: () => context.push('/explore'),
//   )
//
//   CsErrorState(
//     message: 'Could not load venues',
//     onRetry: () => ref.refresh(venuesProvider),
//   )

import 'package:flutter/material.dart';
import '../../core/tokens/color_tokens.dart';
import '../../core/tokens/spacing_tokens.dart';
import '../../core/tokens/typography_tokens.dart';
import 'cs_button.dart';

// ── CsEmptyState ───────────────────────────────────────────────────

class CsEmptyState extends StatefulWidget {
  const CsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  State<CsEmptyState> createState() => _CsEmptyStateState();
}

class _CsEmptyStateState extends State<CsEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxxl,
              vertical: AppSpacing.section,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.colorSurfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: colors.colorBorderSubtle,
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: AppComponentSizes.iconXl,
                    color: colors.colorTextTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  widget.title,
                  style: AppTextStyles.headingM(colors.colorTextPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                Text(
                  widget.subtitle,
                  style: AppTextStyles.bodyS(colors.colorTextSecondary),
                  textAlign: TextAlign.center,
                ),

                // CTA
                if (widget.ctaLabel != null && widget.onCta != null) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  CsButton.primary(
                    label: widget.ctaLabel!,
                    onTap: widget.onCta!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── CsErrorState ───────────────────────────────────────────────────

class CsErrorState extends StatefulWidget {
  const CsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  State<CsErrorState> createState() => _CsErrorStateState();
}

class _CsErrorStateState extends State<CsErrorState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxxl,
              vertical: AppSpacing.section,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon container — uses colorError tint
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.colorError.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: colors.colorError.withValues(alpha: 0.20),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: AppComponentSizes.iconXl,
                    color: colors.colorError,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Something went wrong',
                  style: AppTextStyles.headingM(colors.colorTextPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                Text(
                  widget.message,
                  style: AppTextStyles.bodyS(colors.colorTextSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                CsButton.secondary(
                  label: 'Try again',
                  onTap: widget.onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
