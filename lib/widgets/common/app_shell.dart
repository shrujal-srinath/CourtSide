import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/app_spacing.dart';

// ═══════════════════════════════════════════════════════════════
//  APP SHELL — Floating nav + center FAB
// ═══════════════════════════════════════════════════════════════

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded,          label: 'Feed',     path: AppRoutes.home),
    _TabItem(icon: Icons.explore_rounded,        label: 'Explore',  path: AppRoutes.explore),
    _TabItem(icon: Icons.bar_chart_rounded,      label: 'Stats',    path: AppRoutes.stats),
    _TabItem(icon: Icons.calendar_today_rounded, label: 'Bookings', path: AppRoutes.bookings),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = _currentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.black,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickActionSheet(
        onBookCourt: () {
          Navigator.pop(context);
          context.push(AppRoutes.explore);
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SportPickerSheet(
        onSelectSport: (sport) {
          Navigator.pop(context);
          if (sport == 'basketball') {
            context.push(AppRoutes.bballMode);
          } else {
            context.push('/score/$sport');
          }
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
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Frosted glass background strip
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: AppColors.black.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),

            // Pill nav bar
            Positioned(
              bottom: 12,
              left: 20,
              right: 20,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.overlay.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border, width: 0.5),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xCC000000),
                      blurRadius: 32,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left 2 tabs
                    _buildTab(context, 0),
                    _buildTab(context, 1),
                    // Center gap for FAB
                    const SizedBox(width: 56),
                    // Right 2 tabs
                    _buildTab(context, 2),
                    _buildTab(context, 3),
                  ],
                ),
              ),
            ),

            // Center FAB — elevated above pill
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onFabTap,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0x99E8112D),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 26,
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
    final selected = index == currentIndex;
    final tab = tabs[index];
    const accent = AppColors.red;
    const inactive = AppColors.textTertiaryDark;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppDuration.fast,
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(
                tab.icon,
                size: 22,
                color: selected ? accent : inactive,
              ),
            ),
            AnimatedSize(
              duration: AppDuration.fast,
              curve: Curves.easeInOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tab.label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: accent,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Bottom Sheet ───────────────────────────────────

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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: 24),
          _ActionTile(
            icon: Icons.sports_basketball_rounded,
            label: 'Book a Court',
            subtitle: 'Find and reserve a court near you',
            color: AppColors.basketball,
            onTap: onBookCourt,
          ),
          _ActionTile(
            icon: Icons.scoreboard_rounded,
            label: 'Start Scoring',
            subtitle: 'Track live game stats',
            color: AppColors.red,
            onTap: onStartScoring,
          ),
          _ActionTile(
            icon: Icons.group_rounded,
            label: 'Join a Game',
            subtitle: 'Find pickup games near you',
            color: AppColors.cricket,
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
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textTertiaryDark,
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'SELECT SPORT',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.textSecondaryDark,
              ),
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
  const _SportTile({required this.emoji, required this.label, required this.onTap});
  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textTertiaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String label;
  final String path;
}
