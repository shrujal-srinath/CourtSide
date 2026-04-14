// lib/widgets/common/play_shell.dart
//
// PlayShell — dark-mode nav shell for the Play side of the app.
// 3 items: Bookings | + (FAB) | Home
// Background: #0D0D0D. Active: #E8112D. Inactive: rgba(255,255,255,0.3).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../screens/play/play_action_sheet.dart';

// ── Palette (locally scoped — dark shell) ─────────────────────────
const _kNavBg       = Color(0xFF0D0D0D);
const _kNavBorder   = Color(0xFF1F1F1F);
const _kActive      = Color(0xFFE8112D);
const _kInactive    = Color(0x4DFFFFFF); // rgba(255,255,255,0.30)
const _kFab         = Color(0xFFE8112D);

class PlayShell extends StatefulWidget {
  const PlayShell({super.key, required this.child});
  final Widget child;

  @override
  State<PlayShell> createState() => _PlayShellState();
}

class _PlayShellState extends State<PlayShell> {
  bool _fabPressed = false;

  static const _tabs = [
    _Tab(icon: Icons.calendar_today_outlined, path: AppRoutes.bookings),
    _Tab(icon: Icons.home_outlined,           path: AppRoutes.playHome),
  ];

  String _activePath(BuildContext context) {
    return GoRouterState.of(context).matchedLocation;
  }

  @override
  Widget build(BuildContext context) {
    final loc     = _activePath(context);
    final botPad  = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kNavBg,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: _buildNavBar(context, loc, botPad),
    );
  }

  Widget _buildNavBar(BuildContext context, String loc, double botPad) {
    return Container(
      decoration: const BoxDecoration(
        color: _kNavBg,
        border: Border(top: BorderSide(color: _kNavBorder, width: 0.5)),
      ),
      padding: EdgeInsets.only(bottom: botPad),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            // ── Left: Bookings ──────────────────────────────────
            Expanded(child: _NavItem(
              icon: _tabs[0].icon,
              active: loc.startsWith(_tabs[0].path),
              onTap: () => context.go(_tabs[0].path),
            )),

            // ── Center: + FAB ───────────────────────────────────
            _FabButton(
              pressed: _fabPressed,
              onTapDown: () => setState(() => _fabPressed = true),
              onTapUp: () {
                setState(() => _fabPressed = false);
                showPlayActionSheet(context);
              },
              onTapCancel: () => setState(() => _fabPressed = false),
            ),

            // ── Right: Play Home ────────────────────────────────
            Expanded(child: _NavItem(
              icon: _tabs[1].icon,
              active: loc.startsWith(_tabs[1].path),
              onTap: () => context.go(_tabs[1].path),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: AppDuration.fast,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? _kActive : _kInactive,
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: AppDuration.fast,
                width: active ? 4 : 0,
                height: active ? 4 : 0,
                decoration: const BoxDecoration(
                  color: _kActive,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
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

  final bool pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeIn,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _kFab,
            shape: BoxShape.circle,
            boxShadow: AppShadow.fab,
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ── Tab descriptor ────────────────────────────────────────────────

class _Tab {
  const _Tab({required this.icon, required this.path});
  final IconData icon;
  final String path;
}
