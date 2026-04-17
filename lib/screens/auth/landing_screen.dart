import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});
  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Zone 1 — Top block ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 56),
                      Text(
                        'COURTSIDE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize:      30,
                          fontWeight:    FontWeight.w800,
                          letterSpacing: -0.8,
                          color:         colors.colorTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Playo books a court.\nCourtside makes you a player.',
                        style: GoogleFonts.inter(
                          fontSize:   14,
                          fontWeight: FontWeight.w400,
                          height:     1.5,
                          color:      colors.colorTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Zone 2 — Spacer ────────────────────────────
                const Spacer(),

                // ── Zone 3 — Mode cards ────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _ModeCard(
                        label:    'PLAY',
                        subtitle: 'Book courts · Track stats',
                        filled:   true,
                        onTap:    () => context.go(AppRoutes.home),
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        label:    'EXPLORE',
                        subtitle: 'Find courts · Discover players',
                        filled:   false,
                        onTap:    () => context.go(AppRoutes.explore),
                      ),
                    ],
                  ),
                ),

                // ── Zone 4 — Dev button (debug only) ──────────
                if (kDebugMode) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(devAccessProvider.notifier).state = true;
                        context.go(AppRoutes.home);
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color:        colors.colorSurfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border:       Border.all(
                            color: colors.colorBorderSubtle,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.developer_mode_rounded,
                              color: colors.colorTextSecondary,
                              size:  18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dev Access',
                              style: GoogleFonts.inter(
                                fontSize:   13,
                                fontWeight: FontWeight.w600,
                                color:      colors.colorTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Zone 5 — Attribution ───────────────────────
                const SizedBox(height: 36),
                Center(
                  child: Text(
                    'A product of THE BOX by BMSCE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize:      11,
                      fontWeight:    FontWeight.w500,
                      letterSpacing: 0.4,
                      color:         colors.colorTextTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.label,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final String   label;
  final String   subtitle;
  final bool     filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 172,
        width:  double.infinity,
        decoration: BoxDecoration(
          color:        filled
              ? colors.colorAccentPrimary
              : colors.colorSurfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border:       filled
              ? null
              : Border.all(color: colors.colorAccentPrimary, width: 1.0),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize:   28,
                fontWeight: FontWeight.w800,
                color:      filled
                    ? colors.colorTextOnAccent
                    : colors.colorTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize:   13,
                fontWeight: FontWeight.w400,
                color:      filled
                    ? colors.colorTextOnAccent.withValues(alpha: 0.7)
                    : colors.colorTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
