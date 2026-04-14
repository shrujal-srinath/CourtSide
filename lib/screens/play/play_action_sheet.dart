// lib/screens/play/play_action_sheet.dart
//
// + button action sheet for the Play shell.
// Dark (#111) modal with 4 primary actions + a secondary "Switch" row.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

// ── Palette (dark sheet — intentionally local) ────────────────────
const _kSheetBg   = Color(0xFF111111);
const _kRowBg     = Color(0xFF1A1A1A);
const _kBorder    = Color(0xFF2A2A2A);
const _kWhite     = Color(0xFFF8F9FA);
const _kGrey      = Color(0xFF6B7280);
const _kRed       = Color(0xFFE8112D);

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
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _kSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: _kBorder,
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
              style: AppTextStyles.overline(_kGrey),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── 4 primary options ─────────────────────────────────
          _ActionRow(
            icon: Icons.location_on_rounded,
            iconColor: _kRed,
            title: 'Book a court',
            subtitle: 'Find and reserve a nearby court',
            onTap: () {
              _close();
              context.go(AppRoutes.explore);
            },
          ),
          _ActionRow(
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Host a game',
            subtitle: 'Create a public or private game',
            onTap: () {
              _close();
              context.push(AppRoutes.hostGame);
            },
          ),
          _ActionRow(
            icon: Icons.scoreboard_rounded,
            iconColor: const Color(0xFF22C55E),
            title: 'Live scoring',
            subtitle: 'Open the scorer for your game',
            onTap: () {
              _close();
              _showSportPicker(context);
            },
          ),
          _ActionRow(
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Add stats',
            subtitle: 'Log stats from a completed game',
            onTap: () {
              _close();
              context.push(AppRoutes.hostGame); // stub — same as host for now
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Divider ───────────────────────────────────────────
          Container(height: 0.5, color: _kBorder),
          const SizedBox(height: AppSpacing.md),

          // ── Switch to Explore ─────────────────────────────────
          GestureDetector(
            onTap: () {
              _close();
              context.go(AppRoutes.home);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.grid_view_rounded,
                        size: 16, color: _kGrey),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Switch to Explore',
                      style: AppTextStyles.bodyM(_kGrey),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: _kGrey),
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
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _kSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, botPad + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('SELECT SPORT', style: AppTextStyles.overline(_kGrey)),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SportRow(
            emoji: '🏀',
            label: 'Basketball',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.bballMode);
            },
          ),
          _SportRow(
            emoji: '🏏',
            label: 'Cricket',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.scoreCricket);
            },
          ),
        ],
      ),
    );
  }
}

class _SportRow extends StatelessWidget {
  const _SportRow({required this.emoji, required this.label, required this.onTap});
  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTextStyles.headingM(_kWhite)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _kGrey),
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

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: _kRowBg,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
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
                  Text(title, style: AppTextStyles.headingS(_kWhite)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodyS(_kGrey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: _kGrey),
          ],
        ),
      ),
    );
  }
}
