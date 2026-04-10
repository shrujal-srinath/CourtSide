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
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.section + AppSpacing.lg),

                  // ── Logo block ─────────────────────────────────
                  _buildLogo(),

                  const Spacer(),

                  // ── Hero text ──────────────────────────────────
                  _buildHero(c),

                  const SizedBox(height: AppSpacing.section + AppSpacing.md),

                  // ── Buttons ────────────────────────────────────
                  _buildGoogleButton(c),
                  const SizedBox(height: 12),
                  _buildPhoneButton(),
                  const SizedBox(height: 12),
                  _buildDevButton(c),

                  // ── Error ──────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildError(_error!, colors),
                  ],

                  const SizedBox(height: AppSpacing.xxxl),

                  // ── Sign in link ───────────────────────────────
                  _buildSignInLink(c),

                  const SizedBox(height: AppSpacing.section),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ───────────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COURTSIDE',
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.red,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'BY THE BOX',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.2,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  // ── Hero ───────────────────────────────────────────────────
  Widget _buildHero(ThemeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book the Court.\nOwn the Stats.',
          style: GoogleFonts.inter(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: c.text,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.md + 2),
        Text(
          'Your verified game stats, court bookings\nand player rank — all in one place.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: c.textSec,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // ── Google button ──────────────────────────────────────────
  Widget _buildGoogleButton(ThemeColors c) {
    return GestureDetector(
      onTap: _googleLoading ? null : _signInWithGoogle,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        height: 54,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border, width: 0.5),
          boxShadow: AppShadow.searchLight,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_googleLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.text,
                ),
              )
            else ...[
              _GoogleIcon(),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Continue with Google',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Phone button ───────────────────────────────────────────
  Widget _buildPhoneButton() {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.phoneAuth),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.red,
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

  // ── Dev Access button ───────────────────────────────────────────
  Widget _buildDevButton(ThemeColors c) {
    return GestureDetector(
      onTap: () {
        ref.read(devAccessProvider.notifier).state = true;
        context.go(AppRoutes.home);
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.developer_mode_rounded, color: c.text, size: 20),
            const SizedBox(width: 10),
            Text(
              'Dev Access',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message, AppColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(message, style: AppTextStyles.bodyS(colors.colorError)),
    );
  }

  // ── Sign in link ───────────────────────────────────────────
  Widget _buildSignInLink(ThemeColors c) {
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: c.textSec),
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Sign in',
                style: AppTextStyles.bodyM(context.colors.colorAccentPrimary).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.red,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.red,
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
      width: 22,
      height: 22,
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
    p.color = const Color(0xFF4285F4);
    canvas.drawLine(c, Offset(c.dx + r * 0.9, c.dy), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
