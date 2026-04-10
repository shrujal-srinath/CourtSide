// lib/widgets/common/cs_button.dart
//
// CsButton — Courtside primary interaction primitive.
// Named constructors: primary, secondary, ghost, destructive.
// All variants share press-scale feedback (0.96, 80ms).
// Loading state replaces label with CupertinoActivityIndicator.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/tokens/color_tokens.dart';
import '../../core/tokens/spacing_tokens.dart';
import '../../core/tokens/typography_tokens.dart';

enum _CsButtonVariant { primary, secondary, ghost, destructive }

class CsButton extends StatefulWidget {
  const CsButton._({
    super.key,
    required this.label,
    required this.onTap,
    required this.variant,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.fullWidth = true,
  });

  /// High-emphasis: accentPrimary fill, white text. 54px height.
  const CsButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    bool fullWidth = true,
  }) : this._(
          key: key,
          label: label,
          onTap: onTap,
          variant: _CsButtonVariant.primary,
          isLoading: isLoading,
          isDisabled: isDisabled,
          icon: icon,
          fullWidth: fullWidth,
        );

  /// Medium-emphasis: surfaceElevated fill, primary text. 48px height.
  const CsButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    bool fullWidth = true,
  }) : this._(
          key: key,
          label: label,
          onTap: onTap,
          variant: _CsButtonVariant.secondary,
          isLoading: isLoading,
          isDisabled: isDisabled,
          icon: icon,
          fullWidth: fullWidth,
        );

  /// Low-emphasis: transparent fill, borderSubtle border. 48px height.
  const CsButton.ghost({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    bool fullWidth = true,
  }) : this._(
          key: key,
          label: label,
          onTap: onTap,
          variant: _CsButtonVariant.ghost,
          isLoading: isLoading,
          isDisabled: isDisabled,
          icon: icon,
          fullWidth: fullWidth,
        );

  /// Destructive: colorError fill, white text. 48px height.
  const CsButton.destructive({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    bool fullWidth = true,
  }) : this._(
          key: key,
          label: label,
          onTap: onTap,
          variant: _CsButtonVariant.destructive,
          isLoading: isLoading,
          isDisabled: isDisabled,
          icon: icon,
          fullWidth: fullWidth,
        );

  final String label;
  final VoidCallback? onTap;
  // ignore: library_private_types_in_public_api
  final _CsButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final bool fullWidth;

  @override
  State<CsButton> createState() => _CsButtonState();
}

class _CsButtonState extends State<CsButton> {
  bool _pressed = false;

  bool get _isInactive => widget.isDisabled || widget.isLoading;

  void _onTapDown(_) {
    if (_isInactive) return;
    setState(() => _pressed = true);
  }

  void _onTapUp(_) {
    if (_isInactive) return;
    setState(() => _pressed = false);
    widget.onTap?.call();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // ── Variant-specific tokens ───────────────────────────────────
    final bool isPrimary = widget.variant == _CsButtonVariant.primary;
    final bool isGhost   = widget.variant == _CsButtonVariant.ghost;

    final double height = isPrimary ? 54.0 : 48.0;

    final Color bgColor = switch (widget.variant) {
      _CsButtonVariant.primary     => colors.colorAccentPrimary,
      _CsButtonVariant.secondary   => colors.colorSurfaceElevated,
      _CsButtonVariant.ghost       => Colors.transparent,
      _CsButtonVariant.destructive => colors.colorError,
    };

    final Color textColor = switch (widget.variant) {
      _CsButtonVariant.primary     => colors.colorTextOnAccent,
      _CsButtonVariant.secondary   => colors.colorTextPrimary,
      _CsButtonVariant.ghost       => colors.colorTextPrimary,
      _CsButtonVariant.destructive => colors.colorTextOnAccent,
    };

    final Border? border = isGhost
        ? Border.all(color: colors.colorBorderSubtle, width: 0.5)
        : null;

    // ── Layout ────────────────────────────────────────────────────
    Widget content = widget.isLoading
        ? CupertinoActivityIndicator(color: textColor, radius: 9)
        : Row(
            mainAxisSize:
                widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: AppTextStyles.headingS(textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

    Widget button = AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: _isInactive ? 0.5 : 1.0,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppDuration.fast,
            height: height,
            width: widget.fullWidth ? double.infinity : null,
            padding: widget.fullWidth
                ? null
                : const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: border,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );

    return button;
  }
}
