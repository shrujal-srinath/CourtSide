// courtside/lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // ── Back ──────────────────────────────────────
              GestureDetector(
                onTap: () => context.go(AppRoutes.landing),
                child: Icon(Icons.arrow_back_rounded,
                    color: colors.colorTextPrimary, size: 24),
              ),

              const SizedBox(height: AppSpacing.section),

              Text(
                'COURTSIDE',
                style: AppTextStyles.displayS(colors.colorAccentPrimary),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              Text(
                'Welcome back.',
                style: AppTextStyles.displayM(colors.colorTextPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in to your player account.',
                style: AppTextStyles.bodyL(colors.colorTextSecondary),
              ),

              const Spacer(),

              // ── Google ─────────────────────────────────────
              _buildSocialButton(
                label: 'Continue with Google',
                icon: _GoogleIcon(),
                loading: _googleLoading,
                bgColor: colors.colorSurfaceElevated,
                borderColor: colors.colorBorderSubtle,
                textColor: colors.colorTextPrimary,
                onTap: _signInWithGoogle,
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Phone ──────────────────────────────────────
              _buildSocialButton(
                label: 'Continue with Phone',
                icon: Icon(Icons.phone_rounded,
                    color: colors.colorTextOnAccent, size: 20),
                loading: false,
                bgColor: colors.colorAccentPrimary,
                borderColor: colors.colorAccentPrimary,
                textColor: colors.colorTextOnAccent,
                onTap: () => context.go(AppRoutes.phoneAuth),
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md + 2,
                      vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.colorError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: colors.colorError.withValues(alpha: 0.3),
                        width: 0.5),
                  ),
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodyS(colors.colorError),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xxxl),

              // ── New user link ──────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.landing),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyM(colors.colorTextSecondary),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Create one',
                          style: AppTextStyles.bodyM(
                                  colors.colorAccentPrimary)
                              .copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: colors.colorAccentPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.section),
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
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: loading
                ? [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: textColor),
                    )
                  ]
                : [
                    icon,
                    const SizedBox(width: AppSpacing.md),
                    Text(label,
                        style: AppTextStyles.headingS(textColor)),
                  ],
          ),
        ),
      );
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(painter: _GooglePainter()));
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
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
