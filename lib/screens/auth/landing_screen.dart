// courtside/lib/screens/auth/landing_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
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

                  // ── Logo block ─────────────────────────────
                  _buildLogo(colors),

                  const Spacer(),

                  // ── Hero text ──────────────────────────────
                  _buildHero(colors),

                  const SizedBox(height: AppSpacing.section + AppSpacing.md),

                  // ── Buttons ────────────────────────────────
                  _buildGoogleButton(colors),
                  const SizedBox(height: AppSpacing.md),
                  _buildPhoneButton(colors),

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildError(_error!, colors),
                  ],

                  const SizedBox(height: AppSpacing.xxxl),

                  // ── Sign in link ───────────────────────────
                  _buildSignInLink(colors),

                  const SizedBox(height: AppSpacing.section),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COURTSIDE',
          style: AppTextStyles.displayS(colors.colorAccentPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'BY THE BOX',
          style: AppTextStyles.overline(colors.colorTextTertiary),
        ),
      ],
    );
  }

  Widget _buildHero(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book the Court.\nOwn the Stats.',
          style: AppTextStyles.displayL(colors.colorTextPrimary),
        ),
        const SizedBox(height: AppSpacing.md + 2),
        Text(
          'Your verified game stats, court bookings\nand player rank — all in one place.',
          style: AppTextStyles.bodyL(colors.colorTextSecondary),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(AppColorScheme colors) {
    return GestureDetector(
      onTap: _googleLoading ? null : _signInWithGoogle,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        height: 54,
        decoration: BoxDecoration(
          color: colors.colorSurfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: colors.colorBorderSubtle, width: 0.5),
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
                  color: colors.colorTextPrimary,
                ),
              )
            else ...[
              _GoogleIcon(),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Continue with Google',
                style: AppTextStyles.headingS(colors.colorTextPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneButton(AppColorScheme colors) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.phoneAuth),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: colors.colorAccentPrimary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_rounded,
                color: colors.colorTextOnAccent, size: 20),
            const SizedBox(width: AppSpacing.sm + 2),
            Text(
              'Continue with Phone',
              style: AppTextStyles.headingS(colors.colorTextOnAccent),
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
        color: colors.colorError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: colors.colorError.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(message, style: AppTextStyles.bodyS(colors.colorError)),
    );
  }

  Widget _buildSignInLink(AppColorScheme colors) {
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.bodyM(colors.colorTextSecondary),
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Sign in',
                style: AppTextStyles.bodyM(colors.colorAccentPrimary).copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: colors.colorAccentPrimary,
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
