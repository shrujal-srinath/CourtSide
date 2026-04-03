import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

// ═══════════════════════════════════════════════════════════════
//  APP SHELL — Bottom nav + top bar
// ═══════════════════════════════════════════════════════════════

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded,         label: 'Feed',     path: AppRoutes.home),
    _TabItem(icon: Icons.explore_rounded,       label: 'Explore',  path: AppRoutes.explore),
    _TabItem(icon: Icons.bar_chart_rounded,     label: 'Stats',    path: AppRoutes.stats),
    _TabItem(icon: Icons.calendar_today_rounded,label: 'Bookings', path: AppRoutes.bookings),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIdx = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomBar(
        tabs: _tabs,
        currentIndex: currentIdx,
        isDark: isDark,
        onTap: (i) => context.go(_tabs[i].path),
      ),
    );
  }
}

// ── Bottom Bar ─────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.tabs,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  final List<_TabItem> tabs;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? AppColors.surface : AppColors.white;
    final border = isDark ? AppColors.border  : AppColors.borderLight;
    final accent = isDark ? AppColors.red     : AppColors.redDark;
    final inactive= isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = i == currentIndex;
              final tab = tabs[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected ? accent.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          tab.icon,
                          size: 22,
                          color: selected ? accent : inactive,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? accent : inactive,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
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