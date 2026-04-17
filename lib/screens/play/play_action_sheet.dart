// lib/screens/play/play_action_sheet.dart
//
// + button action sheet for the Play shell.
// Dark modal with 4 primary actions + a secondary "Switch" row.
// Uses semantic tokens — adapts to both dark and light themes.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

void showPlayActionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => _PlayActionSheet(parentContext: context),
  );
}

class _PlayActionSheet extends StatelessWidget {
  const _PlayActionSheet({required this.parentContext});
  final BuildContext parentContext;

  void _close() => Navigator.of(parentContext).pop();

  @override
  Widget build(BuildContext context) {
    final colors  = context.colors;
    final botPad  = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfaceOverlay,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
            top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, botPad + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.colorBorderMedium,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'WHAT DO YOU WANT TO DO?',
              style: AppTextStyles.overline(colors.colorTextTertiary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── 4 primary options ─────────────────────────────────
          _ActionRow(
            icon: Icons.location_on_rounded,
            iconColor: colors.colorAccentPrimary,
            title: 'Book a court',
            subtitle: 'Find and reserve a nearby court',
            onTap: () {
              _close();
              parentContext.go(AppRoutes.explore);
            },
          ),
          _ActionRow(
            icon: Icons.flag_rounded,
            iconColor: colors.colorInfo,
            title: 'Host a game',
            subtitle: 'Create a public or private game',
            onTap: () {
              _close();
              parentContext.push(AppRoutes.hostGame);
            },
          ),
          _ActionRow(
            icon: Icons.scoreboard_rounded,
            iconColor: colors.colorSuccess,
            title: 'Live scoring',
            subtitle: 'Open the scorer for your game',
            onTap: () {
              _close();
              _showSportPicker(parentContext);
            },
          ),
          _ActionRow(
            icon: Icons.bar_chart_rounded,
            iconColor: colors.colorWarning,
            title: 'Add stats',
            subtitle: 'Log stats from a completed game',
            onTap: () {
              _close();
              parentContext.push(AppRoutes.hostGame);
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Divider
          Container(height: 0.5, color: colors.colorBorderSubtle),
          const SizedBox(height: AppSpacing.md),

          // Switch to Explore
          GestureDetector(
            onTap: () {
              _close();
              parentContext.go(AppRoutes.home);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width:  36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.colorSurfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.grid_view_rounded,
                        size: 16, color: colors.colorTextSecondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Switch to Explore',
                      style: AppTextStyles.bodyM(colors.colorTextSecondary),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: colors.colorTextTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSportPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SportPickerSheet(parentContext: context),
    );
  }
}

// ── Sport picker ──────────────────────────────────────────────────

class _SportPickerSheet extends StatelessWidget {
  const _SportPickerSheet({required this.parentContext});
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final colors  = context.colors;
    final botPad  = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfaceOverlay,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
            top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, botPad + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.colorBorderMedium,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('SELECT SPORT',
                style: AppTextStyles.overline(colors.colorTextTertiary)),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SportRow(
            emoji: '🏀',
            label: 'Basketball',
            onTap: () {
              Navigator.pop(context);
              parentContext.push(AppRoutes.bballMode);
            },
          ),
          _SportRow(
            emoji: '🏏',
            label: 'Cricket',
            onTap: () {
              Navigator.pop(context);
              parentContext.push(AppRoutes.scoreCricket);
            },
          ),
        ],
      ),
    );
  }
}

class _SportRow extends StatelessWidget {
  const _SportRow(
      {required this.emoji, required this.label, required this.onTap});
  final String       emoji;
  final String       label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTextStyles.headingM(colors.colorTextPrimary)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: colors.colorTextTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData     icon;
  final Color        iconColor;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.colorSurfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.headingS(colors.colorTextPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: colors.colorTextTertiary),
          ],
        ),
      ),
    );
  }
}
