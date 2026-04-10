import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

// ═══════════════════════════════════════════════════════════════
//  PROFILE SCREEN
// ═══════════════════════════════════════════════════════════════

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final themeMode = ref.watch(themeModeProvider);

    // Derive display name — metadata → phone fallback
    final meta = user?.userMetadata;
    final name = (meta?['full_name'] as String? ??
            meta?['name'] as String? ??
            user?.phone ??
            'Athlete')
        .trim();
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final phone = user?.phone ?? '';
    final joinDate = user?.createdAt != null
        ? _formatDate(DateTime.parse(user!.createdAt))
        : '';

    return Scaffold(
      backgroundColor: context.col.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header banner ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileBanner(
              name: name,
              initials: initials,
              subtitle: phone.isNotEmpty ? phone : 'Member since $joinDate',
              joinDate: joinDate,
            ),
          ),

          // ── Stats strip ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: _StatsStrip(),
            ),
          ),

          // ── Sport badges ────────────────────────────────────────
          const SliverToBoxAdapter(child: _SportBadges()),

          // ── Settings ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0),
              child: _SettingsSection(currentThemeMode: themeMode),
            ),
          ),

          // ── Sign out ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _SignOutButton(),
            ),
          ),

          // ── Bottom padding ──────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  MediaQuery.of(context).padding.bottom + AppSpacing.xl + 80,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Profile Banner ─────────────────────────────────────────────

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({
    required this.name,
    required this.initials,
    required this.subtitle,
    required this.joinDate,
  });

  final String name;
  final String initials;
  final String subtitle;
  final String joinDate;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: context.col.gradBrand,
        border: Border(
          bottom: BorderSide(color: context.col.border, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, top + AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.col.surface.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: context.col.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: context.col.text, size: 16),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Avatar circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.red.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.red, width: 1.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.displayXL(AppColors.red),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Name
          Text(name, style: AppTextStyles.headingL(context.col.text)),
          if (joinDate.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Member since $joinDate',
              style: AppTextStyles.bodyS(context.col.textSec),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stats Strip ────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  // These are placeholder zeros until Supabase data is wired
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatPill(label: 'Bookings', value: '0'),
        const SizedBox(width: AppSpacing.sm),
        _StatPill(label: 'Games Won', value: '0'),
        const SizedBox(width: AppSpacing.sm),
        _StatPill(label: 'Sports', value: '0'),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.col.border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.statL(
                    context.col.isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.labelS(context.col.textSec),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Sport Badges ───────────────────────────────────────────────

class _SportBadges extends StatelessWidget {
  const _SportBadges();

  @override
  Widget build(BuildContext context) {
    // Placeholder until real data — show empty state prompt
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR SPORTS',
            style: AppTextStyles.overline(context.col.textSec),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.col.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.col.border, width: 0.5),
            ),
            child: Text(
              'Sports you play will appear here after your first booking.',
              style: AppTextStyles.bodyS(context.col.textSec),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Section ───────────────────────────────────────────

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection({required this.currentThemeMode});
  final ThemeMode currentThemeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SETTINGS', style: AppTextStyles.overline(context.col.textSec)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: context.col.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.col.border, width: 0.5),
          ),
          child: Column(
            children: [
              // Theme row
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.wb_sunny_rounded,
                          color: AppColors.warning, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Appearance',
                        style: AppTextStyles.bodyM(context.col.text)),
                    const Spacer(),
                    _ThemeSegment(currentMode: currentThemeMode),
                  ],
                ),
              ),

              Divider(height: 0.5, color: context.col.border),

              // Notifications row (placeholder)
              _SettingsRow(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.info,
                label: 'Notifications',
                onTap: () {},
              ),

              Divider(height: 0.5, color: context.col.border),

              // Edit profile row (placeholder)
              _SettingsRow(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.cricket,
                label: 'Edit Profile',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTextStyles.bodyM(context.col.text)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: context.col.textTer),
          ],
        ),
      ),
    );
  }
}

// ── 3-way Theme Segment Control ────────────────────────────────

class _ThemeSegment extends ConsumerWidget {
  const _ThemeSegment({required this.currentMode});
  final ThemeMode currentMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.col.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.col.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            icon: Icons.wb_sunny_rounded,
            selected: currentMode == ThemeMode.light,
            onTap: () =>
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
          ),
          _Segment(
            icon: Icons.brightness_auto_rounded,
            selected: currentMode == ThemeMode.system,
            onTap: () =>
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
          ),
          _Segment(
            icon: Icons.nightlight_round,
            selected: currentMode == ThemeMode.dark,
            onTap: () =>
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        width: 34,
        height: 26,
        decoration: BoxDecoration(
          color: selected ? AppColors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Icon(
          icon,
          size: 14,
          color: selected ? AppColors.white : context.col.textTer,
        ),
      ),
    );
  }
}

// ── Sign Out ───────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) context.go(AppRoutes.landing);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: AppColors.red.withValues(alpha: 0.35), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.red, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text('Sign Out', style: AppTextStyles.bodyM(AppColors.red)),
          ],
        ),
      ),
    );
  }
}
