import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signUpWithEmail(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
        fullName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim().toLowerCase(),
      );
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('already registered')) return 'This email is already in use.';
    if (raw.contains('Password should')) return 'Password must be at least 6 characters.';
    if (raw.contains('network')) return 'No internet connection.';
    return 'Something went wrong. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.black : AppColors.white;
    final surf   = isDark ? AppColors.surface : AppColors.lightCard;
    final accent = isDark ? AppColors.red : AppColors.redDark;
    final primary= isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted  = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.border : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Back ──────────────────────────────────────
                GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: Icon(Icons.arrow_back_rounded, color: primary, size: 24),
                ),

                const SizedBox(height: 32),

                Text(
                  'THE BOX',
                  style: GoogleFonts.barlow(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    letterSpacing: 3, color: accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your\nplayer profile.',
                  style: GoogleFonts.barlow(
                    fontSize: 30, fontWeight: FontWeight.w700,
                    letterSpacing: -0.5, color: primary, height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your stats live here forever.',
                  style: GoogleFonts.dmSans(fontSize: 15, color: muted),
                ),

                const SizedBox(height: 40),

                // ── Full name ─────────────────────────────────
                _label('Full name', muted),
                const SizedBox(height: 6),
                _field(
                  ctrl: _nameCtrl, hint: 'Shrujal Srinath',
                  action: TextInputAction.next,
                  surf: surf, border: border, accent: accent,
                  muted: muted, primary: primary,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),

                const SizedBox(height: 16),

                // ── Username ──────────────────────────────────
                _label('Username', muted),
                const SizedBox(height: 6),
                _field(
                  ctrl: _usernameCtrl, hint: '@shrujal',
                  action: TextInputAction.next,
                  surf: surf, border: border, accent: accent,
                  muted: muted, primary: primary,
                  prefix: Text('@', style: GoogleFonts.dmSans(fontSize: 15, color: muted)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Choose a username';
                    if (v.length < 3) return 'Minimum 3 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) return 'Letters, numbers and _ only';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Email ─────────────────────────────────────
                _label('Email', muted),
                const SizedBox(height: 6),
                _field(
                  ctrl: _emailCtrl, hint: 'you@example.com',
                  type: TextInputType.emailAddress,
                  action: TextInputAction.next,
                  surf: surf, border: border, accent: accent,
                  muted: muted, primary: primary,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Password ──────────────────────────────────
                _label('Password', muted),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  style: GoogleFonts.dmSans(fontSize: 15, color: primary),
                  decoration: _deco(
                    hint: 'Min. 6 characters',
                    surf: surf, border: border, accent: accent, muted: muted,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20, color: muted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),

                // ── Error ─────────────────────────────────────
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
                    child: Text(_error!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.error)),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Create account button ─────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: accent.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Create Account',
                            style: GoogleFonts.barlow(
                              fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Terms note ────────────────────────────────
                Text(
                  'By creating an account you agree to our Terms of Service and Privacy Policy.',
                  style: GoogleFonts.dmSans(fontSize: 11, color: muted, height: 1.5),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // ── Login link ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: GoogleFonts.dmSans(fontSize: 14, color: muted)),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text('Sign in',
                          style: GoogleFonts.dmSans(
                              fontSize: 14, fontWeight: FontWeight.w600, color: accent)),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) => Text(
    text,
    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: color),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    required Color surf, required Color border,
    required Color accent, required Color muted, required Color primary,
    Widget? prefix,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: type,
    textInputAction: action,
    style: GoogleFonts.dmSans(fontSize: 15, color: primary),
    decoration: _deco(
      hint: hint, surf: surf, border: border, accent: accent, muted: muted,
    ).copyWith(prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 14, right: 4), child: prefix) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    ),
    validator: validator,
  );

  InputDecoration _deco({
    required String hint,
    required Color surf, required Color border,
    required Color accent, required Color muted,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.dmSans(fontSize: 15, color: muted),
    filled: true,
    fillColor: surf,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border, width: 0.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border, width: 0.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 0.5)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  );
}