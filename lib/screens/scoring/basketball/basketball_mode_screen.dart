// lib/screens/scoring/basketball/basketball_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import 'models/basketball_models.dart';

class BasketballModeScreen extends StatelessWidget {
  const BasketballModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          SizedBox(height: topPad),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border:
                          Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏀  BASKETBALL',
                        style:
                            AppTextStyles.overline(AppColors.basketball),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'HOW DO YOU WANT TO PLAY?',
                        style: AppTextStyles.headingL(
                            AppColors.textPrimaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Mode cards
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Expanded(
                    child: _ModeCard(
                      badge: 'QUICK GAME',
                      badgeColor: AppColors.basketball,
                      title: 'Quick Game',
                      subtitle:
                          'Jump straight in. Track team scores, fouls and a live event log.',
                      infoRows: const [
                        _InfoRow('🏀', 'Live team score — +2, +3, FT'),
                        _InfoRow('🚨', 'Team fouls with bonus tracking'),
                        _InfoRow('⏱', 'Game clock + shot clock'),
                        _InfoRow('📋', 'Timestamped event log'),
                      ],
                      accentColor: AppColors.basketball,
                      onTap: () => context.push(
                        AppRoutes.bballSetup,
                        extra: BballMode.quick,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: _ModeCard(
                      badge: 'DETAILED STATS',
                      badgeColor: AppColors.info,
                      title: 'Detailed Stats',
                      subtitle:
                          'Add your full roster and track every player\'s points, rebounds, assists and more.',
                      infoRows: const [
                        _InfoRow('👤', 'Per-player PTS / REB / AST / STL'),
                        _InfoRow('🔄', 'In-game substitutions'),
                        _InfoRow('📊', 'Full roster with jersey numbers'),
                        _InfoRow('🎯', 'Stat attributions per event'),
                      ],
                      accentColor: AppColors.info,
                      onTap: () => context.push(
                        AppRoutes.bballSetup,
                        extra: BballMode.detailed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: bottomPad + AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.infoRows,
    required this.accentColor,
    required this.onTap,
  });

  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final List<_InfoRow> infoRows;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge + arrow
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3),
                        width: 0.5),
                  ),
                  child: Text(
                    badge,
                    style: AppTextStyles.overline(badgeColor),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondaryDark,
                  size: 14,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              title,
              style: AppTextStyles.displayS(AppColors.textPrimaryDark),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              subtitle,
              style: AppTextStyles.bodyM(AppColors.textSecondaryDark),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Divider
            Container(height: 0.5, color: AppColors.border),

            const SizedBox(height: AppSpacing.md),

            // Info rows — fills the empty middle area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: infoRows.map((row) {
                  return Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(
                          child: Text(
                            row.icon,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          row.label,
                          style: AppTextStyles.bodyS(
                              AppColors.textSecondaryDark),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.icon, this.label);
  final String icon;
  final String label;
}
