// lib/widgets/common/cs_bottom_sheet.dart
//
// CsBottomSheet — standard bottom sheet wrapper.
// Handle bar: 36×4px, colorBorderMedium.
// Background: colorSurfaceOverlay, AppRadius.xxl top corners.
// showCsBottomSheet() is the standard way to present it.

import 'package:flutter/material.dart';
import '../../core/tokens/color_tokens.dart';
import '../../core/tokens/spacing_tokens.dart';

class CsBottomSheet extends StatelessWidget {
  const CsBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.padding,
  });

  final Widget child;
  final String? title;
  final bool showHandle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfaceOverlay,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        border: Border(
          top: BorderSide(color: colors.colorBorderSubtle, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ────────────────────────────────────────────
          if (showHandle)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.colorBorderMedium,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),

          // ── Optional title ────────────────────────────────────
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),

          // ── Content ───────────────────────────────────────────
          Padding(
            padding: padding ??
                EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  bottom + AppSpacing.lg,
                ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Standard presenter — use instead of showModalBottomSheet directly.
Future<T?> showCsBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool showHandle = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: true,
    builder: (_) => CsBottomSheet(
      title: title,
      showHandle: showHandle,
      child: child,
    ),
  );
}
