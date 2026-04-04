// courtside/lib/screens/onboarding/onboarding_screen.dart
// Shown to NEW users only — collect username + primary sport

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  String _sport       = AppConstants.sportBasketball;
  bool   _loading     = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('profiles').upsert({
        'id':            uid,
        'username':      _usernameCtrl.text.trim().toLowerCase(),
        'primary_sport': _sport,
      });
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      final msg = e.toString();
      setState(() {
        _error = msg.contains('unique')
            ? 'That username is taken. Try another.'
            : 'Something went wrong. Try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppColors.black : AppColors.white;
    final accent  = isDark ? AppColors.red   : AppColors.redDark;
    final primary = isDark ? AppColors.textPrimaryDark  : AppColors.textPrimaryLight;
    final muted   = isDark ? AppColors.textSecondaryDark: AppColors.textSecondaryLight;
    final surf    = isDark ? AppColors.surface : AppColors.surfaceLight;
    final border  = isDark ? AppColors.border  : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),

                Text('COURTSIDE', style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: accent)),
                const SizedBox(height: 32),

                Text('One last thing.', style: GoogleFonts.syne(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: primary, height: 1.1)),
                const SizedBox(height: 8),
                Text('Set your player handle and primary sport.\nThis appears on all your stats and recap cards.', style: GoogleFonts.inter(fontSize: 14, color: muted, height: 1.55)),

                const SizedBox(height: 44),

                // ── Username ───────────────────────────────
                Text('Username', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: muted)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameCtrl,
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.inter(fontSize: 16, color: primary, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'shrujal',
                    hintStyle: GoogleFonts.inter(fontSize: 16, color: muted),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text('@', style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w600, color: muted)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    filled: true, fillColor: surf,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border, width: 0.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border, width: 0.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accent, width: 1.5)),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.error, width: 0.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Choose a username';
                    if (v.length < 3) return 'Minimum 3 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) return 'Letters, numbers and _ only';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // ── Sport picker ───────────────────────────
                Text('Primary sport', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: muted)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _sportTile(
                      emoji: '🏀',
                      label: 'Basketball',
                      value: AppConstants.sportBasketball,
                      accent: accent, surf: surf, border: border,
                      primary: primary, muted: muted,
                    ),
                    const SizedBox(width: 12),
                    _sportTile(
                      emoji: '🏏',
                      label: 'Cricket',
                      value: AppConstants.sportCricket,
                      accent: accent, surf: surf, border: border,
                      primary: primary, muted: muted,
                    ),
                  ],
                ),

                if (_error != null) ...[
                  const SizedBox(height: 20),
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

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: accent.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text("Let's go", style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sportTile({
    required String emoji, required String label, required String value,
    required Color accent, required Color surf, required Color border,
    required Color primary, required Color muted,
  }) {
    final selected = _sport == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sport = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.08) : surf,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: selected ? accent : muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}