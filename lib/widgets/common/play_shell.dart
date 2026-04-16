// lib/widgets/common/play_shell.dart
//
// PlayShell — nav shell for the Play section.
// 3 items: Bookings | + FAB | Home
// Uses semantic tokens — adapts to both dark and light themes.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../screens/play/play_action_sheet.dart';

class PlayShell extends StatefulWidget {
  const PlayShell({super.key, required this.child});
  final Widget child;

  @override
  State<PlayShell> createState() => _PlayShellState();
}

class _PlayShellState extends State<PlayShell> {
  bool _fabPressed = false;

  static const _tabs = [
    _Tab(icon: Icons.home_outlined,           label: 'Home',     path: AppRoutes.playHome),
    _Tab(icon: Icons.calendar_today_outlined, label: 'Bookings', path: AppRoutes.playBookings),
  ];

  @override
  Widget build(BuildContext context) {
    final loc    = GoRouterState.of(context).matchedLocation;
    final botPad = MediaQuery.of(context).padding.bottom;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: _buildNavBar(context, loc, botPad, colors),
    );
  }

  Widget _buildNavBar(
      BuildContext context, String loc, double botPad, AppColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        border: Border(
            top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navFor(context),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Left: Home
              Expanded(
                child: _NavItem(
                  icon: _tabs[0].icon,
                  label: _tabs[0].label,
                  active: loc.startsWith(_tabs[0].path),
                  onTap: () => context.go(_tabs[0].path),
                ),
              ),

              // Center: + FAB
              _FabButton(
                pressed: _fabPressed,
                onTapDown: () => setState(() => _fabPressed = true),
                onTapUp: () {
                  setState(() => _fabPressed = false);
                  showPlayActionSheet(context);
                },
                onTapCancel: () => setState(() => _fabPressed = false),
              ),

              // Right: Bookings
              Expanded(
                child: _NavItem(
                  icon: _tabs[1].icon,
                  label: _tabs[1].label,
                  active: loc.startsWith(_tabs[1].path),
                  onTap: () => context.go(_tabs[1].path),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData     icon;
  final String       label;
  final bool         active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors   = context.colors;
    final accent   = colors.colorAccentPrimary;
    final inactive = colors.colorTextTertiary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? accent : inactive),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.overline(active ? accent : inactive)
                  .copyWith(fontSize: 8, letterSpacing: 0.5),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: AppDuration.fast,
              width:  active ? 4 : 0,
              height: active ? 4 : 0,
              decoration: BoxDecoration(
                  color: accent, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAB button ────────────────────────────────────────────────────

class _FabButton extends StatelessWidget {
  const _FabButton({
    required this.pressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  final bool         pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp:   (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeIn,
        child: Container(
          width:  52,
          height: 52,
          decoration: BoxDecoration(
            color:    colors.colorAccentPrimary,
            shape:    BoxShape.circle,
            boxShadow: AppShadow.fab,
          ),
          child: Icon(
            Icons.add_rounded,
            color: colors.colorTextOnAccent,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ── Tab descriptor ────────────────────────────────────────────────

class _Tab {
  const _Tab({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String   label;
  final String   path;
}
