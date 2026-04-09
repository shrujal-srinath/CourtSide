// courtside/lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _googleLoading = false;
  String? _error;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Back ──────────────────────────────────────
              GestureDetector(
                onTap: () => context.go(AppRoutes.landing),
                child: Icon(Icons.arrow_back_rounded, color: primary, size: 24),
              ),

              const SizedBox(height: 40),

              Text(
                'COURTSIDE',
                style: GoogleFonts.syne(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5, color: accent,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Welcome back.',
                style: GoogleFonts.syne(
                  fontSize: 34, fontWeight: FontWeight.w800,
                  letterSpacing: -0.8, color: primary, height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your player account.',
                style: GoogleFonts.inter(fontSize: 15, color: muted),
              ),

              const Spacer(),

              // ── Google ─────────────────────────────────────
              _buildSocialButton(
                label: 'Continue with Google',
                icon: _GoogleIcon(),
                loading: _googleLoading,
                color: surf,
                border: border,
                textColor: primary,
                onTap: _signInWithGoogle,
              ),

              const SizedBox(height: 12),

              // ── Phone ──────────────────────────────────────
              _buildSocialButton(
                label: 'Continue with Phone',
                icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                loading: false,
                color: accent,
                border: accent,
                textColor: Colors.white,
                onTap: () => context.go(AppRoutes.phoneAuth),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.error)),
                ),
              ],

              const SizedBox(height: 32),

              // ── New user link ──────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.landing),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 14, color: muted),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Create one',
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
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required bool loading,
    required Color color,
    required Color border,
    required Color textColor,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: loading
                ? [SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))]
                : [
                    icon,
                    const SizedBox(width: 12),
                    Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                  ],
          ),
        ),
      );
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GooglePainter()));
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
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