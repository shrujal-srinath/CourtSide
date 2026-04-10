// lib/onboarding/onboarding_screen.dart
// Shown to NEW users only — collect username + primary sport

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/constants.dart';

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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl + 4),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.section + AppSpacing.lg),

                // Brand wordmark
                Text(
                  'COURTSIDE',
                  style: AppTextStyles.labelM(colors.colorAccentPrimary),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Headline
                Text(
                  'One last thing.',
                  style: AppTextStyles.displayM(colors.colorTextPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Set your player handle and primary sport.\nThis appears on all your stats and recap cards.',
                  style: AppTextStyles.bodyM(colors.colorTextSecondary),
                ),

                const SizedBox(height: AppSpacing.section + AppSpacing.md),

                // ── Username ───────────────────────────────
                Text(
                  'USERNAME',
                  style: AppTextStyles.overline(colors.colorTextTertiary),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _usernameCtrl,
                  textInputAction: TextInputAction.done,
                  style: AppTextStyles.bodyL(colors.colorTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'shrujal',
                    hintStyle: AppTextStyles.bodyL(colors.colorTextTertiary),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(
                          left: AppSpacing.lg, right: AppSpacing.sm),
                      child: Text(
                        '@',
                        style: AppTextStyles.headingM(
                            colors.colorTextSecondary),
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    filled: true,
                    fillColor: colors.colorSurfaceElevated,
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                          color: colors.colorError, width: 0.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                          color: colors.colorError, width: 1.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.lg),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Choose a username';
                    if (v.length < 3) return 'Minimum 3 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                      return 'Letters, numbers and _ only';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // ── Sport picker ───────────────────────────
                Text(
                  'PRIMARY SPORT',
                  style: AppTextStyles.overline(colors.colorTextTertiary),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _SportTile(
                      emoji: '🏀',
                      label: 'Basketball',
                      value: AppConstants.sportBasketball,
                      selected: _sport == AppConstants.sportBasketball,
                      sportColor: colors.colorSportBasketball,
                      onTap: () =>
                          setState(() => _sport = AppConstants.sportBasketball),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _SportTile(
                      emoji: '🏏',
                      label: 'Cricket',
                      value: AppConstants.sportCricket,
                      selected: _sport == AppConstants.sportCricket,
                      sportColor: colors.colorSportCricket,
                      onTap: () =>
                          setState(() => _sport = AppConstants.sportCricket),
                    ),
                  ],
                ),

                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.xl),
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

                const SizedBox(height: AppSpacing.section),

                // ── CTA ────────────────────────────────────
                _LetsGoButton(loading: _loading, onTap: _save),

                const SizedBox(height: AppSpacing.section),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sport Tile ────────────────────────────────────────────────

class _SportTile extends StatelessWidget {
  const _SportTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.selected,
    required this.sportColor,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String value;
  final bool selected;
  final Color sportColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          decoration: BoxDecoration(
            color: selected
                ? sportColor.withValues(alpha: 0.1)
                : colors.colorSurfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? sportColor : colors.colorBorderSubtle,
              width: selected ? 1.0 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.labelM(
                  selected ? sportColor : colors.colorTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Let's Go Button ───────────────────────────────────────────

class _LetsGoButton extends StatefulWidget {
  const _LetsGoButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  State<_LetsGoButton> createState() => _LetsGoButtonState();
}

class _LetsGoButtonState extends State<_LetsGoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedOpacity(
          opacity: widget.loading ? 0.7 : 1.0,
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
            child: widget.loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.colorTextOnAccent,
                    ),
                  )
                : Text(
                    "Let's go",
                    style:
                        AppTextStyles.headingM(colors.colorTextOnAccent),
                  ),
          ),
        ),
      ),
    );
  }
}
