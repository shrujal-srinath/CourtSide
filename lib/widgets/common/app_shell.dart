// lib/widgets/common/app_shell.dart
//
// AppShell — persistent scaffold with floating pill nav + center FAB.
//
// Nav active indicator: accentPrimary dot BELOW icon (not filled pill bg).
// Tab label: overline style, appears ONLY on active tab.
// FAB: 52px circle, accentPrimary, AppShadow.fab glow.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import 'cs_bottom_sheet.dart';


// ═══════════════════════════════════════════════════════════════
//  APP SHELL — Floating nav + center FAB (Light UI)
// ═══════════════════════════════════════════════════════════════

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded,          label: 'Feed',     path: AppRoutes.home),
    _TabItem(icon: Icons.stadium_outlined,         label: 'Explore',  path: AppRoutes.explore),
    _TabItem(icon: Icons.bar_chart_rounded,      label: 'Stats',    path: AppRoutes.stats),
    _TabItem(icon: Icons.calendar_today_rounded, label: 'Book',     path: AppRoutes.bookings),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = _currentIndex(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      extendBody: true,
      body: child,
      bottomNavigationBar: _FloatingNavBar(
        tabs: _tabs,
        currentIndex: currentIdx,
        onTap: (i) => context.go(_tabs[i].path),
        onFabTap: () => _showQuickActions(context),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showCsBottomSheet(
      context: context,
      showHandle: true,
      child: _QuickActionSheet(
        onBookCourt: () {
          Navigator.pop(context);
          context.go(AppRoutes.explore);
        },
        onStartScoring: () {
          Navigator.pop(context);
          _showSportPicker(context);
        },
        onJoinGame: () {
          Navigator.pop(context);
          context.push(AppRoutes.explore);
        },
      ),
    );
  }

  void _showSportPicker(BuildContext context) {
    showCsBottomSheet(
      context: context,
      title: 'SELECT SPORT',
      child: _SportPickerSheet(
        onSelectSport: (sport) {
          Navigator.pop(context);
          if (sport == 'basketball') {
            context.push(AppRoutes.bballMode);
          } else if (sport == 'cricket') {
            context.push(AppRoutes.scoreCricket);
          }
          // badminton / football scorer not yet built — no-op
        },
      ),
    );
  }
}

// ── Floating Nav Bar ───────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  final List<_TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Frosted blur backing
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: colors.colorBackgroundPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),

            // Pill nav
            Positioned(
              bottom: 12,
              left: 18,
              right: 18,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: colors.colorSurfacePrimary.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.colorBorderSubtle,
                    width: 1,
                  ),
                  boxShadow: AppShadow.navFor(context),
                ),
                child: Row(
                  children: [
                    _buildTab(context, 0),
                    _buildTab(context, 1),
                    const SizedBox(width: 56), // FAB gap
                    _buildTab(context, 2),
                    _buildTab(context, 3),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 19,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onFabTap,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.colorAccentPrimary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadow.fab,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    final colors = context.colors;
    final selected = index == currentIndex;
    final tab = tabs[index];
    final accent = colors.colorAccentPrimary;
    final inactive = colors.colorTextTertiary;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.icon,
              size: 20,
              color: selected ? accent : inactive,
            ),
            const SizedBox(height: 3),
            Text(
              tab.label.toUpperCase(),
              style: AppTextStyles.overline(selected ? accent : inactive).copyWith(fontSize: 8, letterSpacing: 0.5),
            ),

            const SizedBox(height: 3),

            // Dot indicator
            AnimatedContainer(
              duration: AppDuration.fast,
              width: selected ? 4 : 0,
              height: selected ? 4 : 0,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Sheet ─────────────────────────────────────────

class _QuickActionSheet extends StatelessWidget {
  const _QuickActionSheet({
    required this.onBookCourt,
    required this.onStartScoring,
    required this.onJoinGame,
  });

  final VoidCallback onBookCourt;
  final VoidCallback onStartScoring;
  final VoidCallback onJoinGame;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.colorBorderMedium,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 24),
          _ActionTile(
            icon: Icons.sports_basketball_rounded,
            label: 'Book a Court',
            subtitle: 'Find and reserve a court near you',
            color: colors.colorSportBasketball,
            onTap: onBookCourt,
          ),
          _ActionTile(
            icon: Icons.scoreboard_rounded,
            label: 'Start Scoring',
            subtitle: 'Track live game stats',
            color: colors.colorAccentPrimary,
            onTap: onStartScoring,
          ),
          _ActionTile(
            icon: Icons.group_rounded,
            label: 'Join a Game',
            subtitle: 'Find pickup games near you',
            color: colors.colorSportCricket,
            onTap: onJoinGame,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,    style: AppTextStyles.headingS(colors.colorTextPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colors.colorTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sport Picker Sheet ─────────────────────────────────────────

class _SportPickerSheet extends StatelessWidget {
  const _SportPickerSheet({required this.onSelectSport});
  final ValueChanged<String> onSelectSport;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.colorBorderSubtle, width: 1),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.colorBorderMedium,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'SELECT SPORT',
              style: AppTextStyles.overline(colors.colorTextTertiary),
            ),
          ),
          const SizedBox(height: 16),
          _SportTile(emoji: '🏀', label: 'Basketball', onTap: () => onSelectSport('basketball')),
          _SportTile(emoji: '🏏', label: 'Cricket',    onTap: () => onSelectSport('cricket')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SportTile extends StatelessWidget {
  const _SportTile({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.headingM(colors.colorTextPrimary),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colors.colorTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.path,
  });
  final IconData icon;
  final String label;
  final String path;
}
