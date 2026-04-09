// courtside/lib/screens/auth/landing_screen.dart

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
  bool _googleLoading = false;
  String? _error;

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

  Future<void> _signInWithGoogle() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // GoRouter redirect handles navigation after OAuth callback
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c       = context.col;
    final bg      = c.bg;
    final accent  = AppColors.red;
    final primary = c.text;
    final muted   = c.textSec;
    final surf    = c.surface;
    final border  = c.border;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),

                  // ── Logo block ─────────────────────────────
                  _buildLogo(accent, muted),

                  const Spacer(),

                  // ── Hero text ──────────────────────────────
                  _buildHero(primary, muted),

                  const SizedBox(height: 52),

                  // ── Buttons ────────────────────────────────
                  _buildGoogleButton(surf, border, primary),
                  const SizedBox(height: 12),
                  _buildPhoneButton(accent),

                  // ── Error ──────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _buildError(_error!),
                  ],

                  const SizedBox(height: 32),

                  // ── Sign in link ───────────────────────────
                  _buildSignInLink(muted, accent),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ───────────────────────────────────────────────────
  Widget _buildLogo(Color accent, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COURTSIDE',
          style: GoogleFonts.syne(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: accent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'BY THE BOX',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.22 * 10,
            color: muted,
          ),
        ),
      ],
    );
  }

  // ── Hero ───────────────────────────────────────────────────
  Widget _buildHero(Color primary, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book the Court.\nOwn the Stats.',
          style: GoogleFonts.syne(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: primary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your verified game stats, court bookings\nand player rank — all in one place.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: muted,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // ── Google button ──────────────────────────────────────────
  Widget _buildGoogleButton(Color surf, Color border, Color primary) {
    return GestureDetector(
      onTap: _googleLoading ? null : _signInWithGoogle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_googleLoading)
              SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primary,
                ),
              )
            else ...[
              _GoogleIcon(),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Phone button ───────────────────────────────────────────
  Widget _buildPhoneButton(Color accent) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.phoneAuth),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Continue with Phone',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────
  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
      ),
    );
  }

  // ── Sign in link ───────────────────────────────────────────
  Widget _buildSignInLink(Color muted, Color accent) {
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: muted),
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Sign in',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  decoration: TextDecoration.underline,
                  decorationColor: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Google Icon ────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22, height: 22,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final p = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap  = StrokeCap.round;

    p.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -0.3, 1.9, false, p);
    p.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 1.6, 1.6, false, p);
    p.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 3.2, 1.0, false, p);
    p.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 4.2, 1.2, false, p);
    p
      ..color      = const Color(0xFF4285F4)
      ..strokeWidth = 2.5;
    canvas.drawLine(c, Offset(c.dx + r * 0.9, c.dy), p);
  }

  @override
  bool shouldRepaint(_) => false;
}