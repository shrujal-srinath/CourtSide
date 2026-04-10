// courtside/lib/screens/auth/phone_auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

// ── State ──────────────────────────────────────────────────────
enum _PhoneStep { enterPhone, enterOtp }

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});
  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();

  _PhoneStep _step     = _PhoneStep.enterPhone;
  bool       _loading  = false;
  String?    _error;
  String     _phone    = '';

  // Country code — default India
  final String _countryCode = '+91';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final number = _phoneCtrl.text.trim();
    if (number.length < 10) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      _phone = '$_countryCode$number';
      await Supabase.instance.client.auth.signInWithOtp(phone: _phone);
      if (mounted) {
        setState(() { _step = _PhoneStep.enterOtp; _loading = false; });
      }
    } catch (e) {
      setState(() {
        _error   = 'Could not send OTP. Check your number and try again.';
        _loading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        phone: _phone,
        token: otp,
        type: OtpType.sms,
      );
      if (res.user != null && mounted) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('username')
            .eq('id', res.user!.id)
            .maybeSingle();
        if (!mounted) return;
        final hasUsername = profile != null &&
            profile['username'] != null &&
            (profile['username'] as String).isNotEmpty;
        if (hasUsername) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.onboarding);
        }
      }
    } catch (e) {
      setState(() {
        _error   = 'Invalid code. Please try again.';
        _loading = false;
      });
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
                onTap: () {
                  if (_step == _PhoneStep.enterOtp) {
                    setState(() {
                      _step = _PhoneStep.enterPhone;
                      _error = null;
                    });
                  } else {
                    context.go(AppRoutes.landing);
                  }
                },
                child: Icon(Icons.arrow_back_rounded,
                    color: colors.colorTextPrimary, size: 24),
              ),

              const SizedBox(height: AppSpacing.section),

              // ── Logo ──────────────────────────────────────
              Text(
                'COURTSIDE',
                style: AppTextStyles.displayS(colors.colorAccentPrimary),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              if (_step == _PhoneStep.enterPhone)
                _buildPhoneStep(colors)
              else
                _buildOtpStep(colors),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Enter phone ────────────────────────────────────
  Widget _buildPhoneStep(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's your\nphone number?",
          style: AppTextStyles.displayM(colors.colorTextPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "We'll send you a one-time code to verify.",
          style: AppTextStyles.bodyM(colors.colorTextSecondary),
        ),

        const SizedBox(height: AppSpacing.section),

        // Phone input row
        Row(
          children: [
            // Country code pill
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.colorSurfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: colors.colorBorderSubtle, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇮🇳',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _countryCode,
                    style: AppTextStyles.headingS(
                        colors.colorTextPrimary),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm + 2),

            // Number field
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                maxLength: 10,
                style: AppTextStyles.headingL(colors.colorTextPrimary),
                decoration: InputDecoration(
                  hintText: '98765 43210',
                  hintStyle:
                      AppTextStyles.headingL(colors.colorTextTertiary),
                  filled: true,
                  fillColor: colors.colorSurfaceElevated,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                        color: colors.colorBorderSubtle, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                        color: colors.colorBorderSubtle, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                        color: colors.colorAccentPrimary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg),
                ),
                onSubmitted: (_) => _sendOtp(),
              ),
            ),
          ],
        ),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildError(_error!, colors),
        ],

        const SizedBox(height: AppSpacing.xxl + 4),

        _buildPrimaryButton(
          label: 'Send Code',
          loading: _loading,
          colors: colors,
          onTap: _sendOtp,
        ),
      ],
    );
  }

  // ── Step 2: Enter OTP ──────────────────────────────────────
  Widget _buildOtpStep(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the code.',
          style: AppTextStyles.displayM(colors.colorTextPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodyM(colors.colorTextSecondary),
            children: [
              const TextSpan(text: 'Sent to '),
              TextSpan(
                text: _phone,
                style: AppTextStyles.bodyM(colors.colorTextPrimary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.section),

        // OTP field — large centered digits
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          textAlign: TextAlign.center,
          style: AppTextStyles.statL(colors.colorTextPrimary)
              .copyWith(letterSpacing: 12),
          decoration: InputDecoration(
            hintText: '------',
            hintStyle: AppTextStyles.statL(colors.colorTextTertiary)
                .copyWith(letterSpacing: 12),
            filled: true,
            fillColor: colors.colorSurfaceElevated,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                  color: colors.colorBorderSubtle, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                  color: colors.colorBorderSubtle, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                  color: colors.colorAccentPrimary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          ),
          onChanged: (v) { if (v.length == 6) _verifyOtp(); },
        ),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildError(_error!, colors),
        ],

        const SizedBox(height: AppSpacing.xxl + 4),

        _buildPrimaryButton(
          label: 'Verify',
          loading: _loading,
          colors: colors,
          onTap: _verifyOtp,
        ),

        const SizedBox(height: AppSpacing.xl),

        // Resend
        Center(
          child: GestureDetector(
            onTap: _loading ? null : _sendOtp,
            child: Text(
              'Resend code',
              style: AppTextStyles.labelM(colors.colorAccentPrimary)
                  .copyWith(
                decoration: TextDecoration.underline,
                decorationColor: colors.colorAccentPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool loading,
    required AppColorScheme colors,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: loading ? null : onTap,
        child: AnimatedOpacity(
          opacity: loading ? 0.6 : 1.0,
          duration: AppDuration.fast,
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: colors.colorAccentPrimary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: AppShadow.fab,
            ),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.colorTextOnAccent,
                    ),
                  )
                : Text(
                    label,
                    style:
                        AppTextStyles.headingM(colors.colorTextOnAccent),
                  ),
          ),
        ),
      );

  Widget _buildError(String message, AppColorScheme colors) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.colorError.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: colors.colorError.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Text(
          message,
          style: AppTextStyles.bodyS(colors.colorError),
        ),
      );
}
