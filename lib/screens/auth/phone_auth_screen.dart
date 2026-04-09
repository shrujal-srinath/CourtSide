// courtside/lib/screens/auth/phone_auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _countryCode = '+91';

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
      if (mounted) setState(() { _step = _PhoneStep.enterOtp; _loading = false; });
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
        // Check if new user — no username yet
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
                onTap: () {
                  if (_step == _PhoneStep.enterOtp) {
                    setState(() { _step = _PhoneStep.enterPhone; _error = null; });
                  } else {
                    context.go(AppRoutes.landing);
                  }
                },
                child: Icon(Icons.arrow_back_rounded, color: primary, size: 24),
              ),

              const SizedBox(height: 40),

              // ── Logo ──────────────────────────────────────
              Text(
                'COURTSIDE',
                style: GoogleFonts.syne(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5, color: accent,
                ),
              ),

              const SizedBox(height: 32),

              if (_step == _PhoneStep.enterPhone) ...[
                _buildPhoneStep(primary, muted, surf, border, accent),
              ] else ...[
                _buildOtpStep(primary, muted, surf, border, accent),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Enter phone ────────────────────────────────────
  Widget _buildPhoneStep(
    Color primary, Color muted, Color surf, Color border, Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your\nphone number?',
          style: GoogleFonts.syne(
            fontSize: 32, fontWeight: FontWeight.w800,
            letterSpacing: -0.8, color: primary, height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll send you a one-time code to verify.',
          style: GoogleFonts.inter(fontSize: 14, color: muted),
        ),

        const SizedBox(height: 40),

        // Phone input row
        Row(
          children: [
            // Country code pill
            GestureDetector(
              onTap: () {}, // expand country picker later
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: surf,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Text(
                      '🇮🇳',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _countryCode,
                      style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Number field
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                style: GoogleFonts.inter(fontSize: 20, color: primary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '98765 43210',
                  hintStyle: GoogleFonts.inter(fontSize: 20, color: muted, fontWeight: FontWeight.w400),
                  filled: true,
                  fillColor: surf,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                onSubmitted: (_) => _sendOtp(),
              ),
            ),
          ],
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _buildError(_error!),
        ],

        const SizedBox(height: 28),

        _buildPrimaryButton(
          label: 'Send Code',
          loading: _loading,
          accent: accent,
          onTap: _sendOtp,
        ),
      ],
    );
  }

  // ── Step 2: Enter OTP ──────────────────────────────────────
  Widget _buildOtpStep(
    Color primary, Color muted, Color surf, Color border, Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the code.',
          style: GoogleFonts.syne(
            fontSize: 32, fontWeight: FontWeight.w800,
            letterSpacing: -0.8, color: primary, height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: muted),
            children: [
              const TextSpan(text: 'Sent to '),
              TextSpan(
                text: _phone,
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // OTP field — large centered digits
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.syne(
            fontSize: 32, fontWeight: FontWeight.w700,
            letterSpacing: 12, color: primary,
          ),
          decoration: InputDecoration(
            hintText: '------',
            hintStyle: GoogleFonts.syne(
              fontSize: 32, fontWeight: FontWeight.w400,
              letterSpacing: 12, color: muted,
            ),
            filled: true,
            fillColor: surf,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          ),
          onChanged: (v) { if (v.length == 6) _verifyOtp(); },
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _buildError(_error!),
        ],

        const SizedBox(height: 28),

        _buildPrimaryButton(
          label: 'Verify',
          loading: _loading,
          accent: accent,
          onTap: _verifyOtp,
        ),

        const SizedBox(height: 20),

        // Resend
        Center(
          child: GestureDetector(
            onTap: _loading ? null : _sendOtp,
            child: Text(
              'Resend code',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: accent, decoration: TextDecoration.underline,
                decorationColor: accent,
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
    required Color accent,
    required VoidCallback onTap,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: accent.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.syne(
                    fontSize: 16, fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );

  Widget _buildError(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3), width: 0.5,
          ),
        ),
        child: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
        ),
      );
}