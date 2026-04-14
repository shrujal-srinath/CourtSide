// lib/screens/booking/booking_invite_screen.dart
//
// Step 1 of the booking wizard — Invite friends + game settings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../providers/booking_flow_provider.dart';
import 'booking_step_widgets.dart';

class BookingInviteScreen extends ConsumerStatefulWidget {
  const BookingInviteScreen({super.key});

  @override
  ConsumerState<BookingInviteScreen> createState() => _BookingInviteScreenState();
}

class _BookingInviteScreenState extends ConsumerState<BookingInviteScreen> {
  final _searchCtrl = TextEditingController();
  List<FriendProfile> _searchResults = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _queryIsPhone {
    final q = _searchCtrl.text.trim().replaceAll(RegExp(r'[\s\-+]'), '');
    return RegExp(r'^\d{7,13}$').hasMatch(q);
  }

  void _onSearch() {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }
    setState(() {
      _hasSearched = true;
      _searchResults = fakeFriends.where((f) {
        return f.name.toLowerCase().contains(query) ||
            f.username.toLowerCase().contains(query) ||
            f.id.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(bookingFlowProvider);
    final notifier = ref.read(bookingFlowProvider.notifier);
    final colors = context.colors;
    final botPad = MediaQuery.of(context).padding.bottom;

    final displayList = _hasSearched ? _searchResults : fakeFriends;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          BookingStepHeader(
            step: 1,
            title: 'Game Setup',
            subtitle: 'Invite friends & set visibility',
            onBack: () => context.pop(),
            colors: colors,
          ),

          // ── Progress bar ─────────────────────────────────────────
          BookingStepProgressBar(currentStep: 1, colors: colors),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
                  botPad + AppSpacing.xxl + 70),
              children: [
                // ── Public / Private toggle ──────────────────────────
                _SectionHeader('GAME VISIBILITY', colors),
                const SizedBox(height: AppSpacing.sm),
                _VisibilityToggle(
                  isPublic: flow.isPublicGame,
                  colors: colors,
                  onChanged: notifier.setPublicGame,
                ),

                // ── Public game settings ─────────────────────────────
                if (flow.isPublicGame) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader('PLAYER LIMIT', colors),
                  const SizedBox(height: AppSpacing.sm),
                  _PlayerLimitRow(
                    limit: flow.playerLimit,
                    colors: colors,
                    onChanged: notifier.setPlayerLimit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader('SKILL LEVEL', colors),
                  const SizedBox(height: AppSpacing.sm),
                  _SkillLevelPicker(
                    selected: flow.skillLevel,
                    colors: colors,
                    onChanged: notifier.setSkillLevel,
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // ── Friend search ──────────────────────────────────────
                _SectionHeader('INVITE FRIENDS', colors),
                const SizedBox(height: AppSpacing.sm),
                _SearchField(controller: _searchCtrl, colors: colors),
                const SizedBox(height: AppSpacing.sm),

                if (_hasSearched && _searchResults.isEmpty)
                  _queryIsPhone
                      ? _PhoneInvite(phone: _searchCtrl.text.trim(), colors: colors)
                      : _EmptySearch(colors: colors)
                else
                  ...displayList.map((friend) {
                    final invited = flow.invitedFriendIds.contains(friend.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _FriendTile(
                        friend: friend,
                        invited: invited,
                        colors: colors,
                        onTap: () => notifier.toggleFriend(friend.id),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),

      // ── Sticky footer ────────────────────────────────────────────
      bottomNavigationBar: BookingStepFooter(
        label: flow.invitedFriendIds.isEmpty
            ? 'Skip — play solo'
            : 'Next — Shop (${flow.invitedFriendIds.length} invited)',
        isSkip: flow.invitedFriendIds.isEmpty,
        colors: colors,
        botPad: botPad,
        onTap: () => context.push(AppRoutes.bookShop(flow.venueId)),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, this.colors);
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.overline(colors.colorTextTertiary));
  }
}

// ── Visibility toggle ─────────────────────────────────────────────

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.isPublic,
    required this.colors,
    required this.onChanged,
  });

  final bool isPublic;
  final AppColorScheme colors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToggleOption(
          icon: Icons.lock_rounded,
          label: 'Private',
          subtitle: 'Only invited players',
          isSelected: !isPublic,
          colors: colors,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: AppSpacing.sm),
        _ToggleOption(
          icon: Icons.public_rounded,
          label: 'Public',
          subtitle: 'Anyone can request to join',
          isSelected: isPublic,
          colors: colors,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.colorAccentPrimary.withValues(alpha: 0.08)
                : colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isSelected ? colors.colorAccentPrimary : colors.colorBorderSubtle,
              width: isSelected ? 1.0 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected ? colors.colorAccentPrimary : colors.colorTextTertiary),
              const SizedBox(height: AppSpacing.sm),
              Text(label,
                  style: AppTextStyles.headingS(
                      isSelected ? colors.colorAccentPrimary : colors.colorTextPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTextStyles.bodyS(colors.colorTextSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Player limit row ──────────────────────────────────────────────

class _PlayerLimitRow extends StatelessWidget {
  const _PlayerLimitRow({
    required this.limit,
    required this.colors,
    required this.onChanged,
  });

  final int limit;
  final AppColorScheme colors;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.group_rounded, size: 18, color: colors.colorTextSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('Max players', style: AppTextStyles.labelM(colors.colorTextPrimary)),
          ),
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: limit > 2 ? () => onChanged(limit - 1) : null,
            colors: colors,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '$limit',
              style: AppTextStyles.headingM(colors.colorTextPrimary),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: limit < 20 ? () => onChanged(limit + 1) : null,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final AppColorScheme colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? colors.colorSurfaceElevated : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled ? colors.colorTextPrimary : colors.colorTextTertiary),
      ),
    );
  }
}

// ── Skill level picker ────────────────────────────────────────────

class _SkillLevelPicker extends StatelessWidget {
  const _SkillLevelPicker({
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  final SkillLevel selected;
  final AppColorScheme colors;
  final ValueChanged<SkillLevel> onChanged;

  static const _levels = [
    (SkillLevel.all,           'All Levels',    Icons.groups_rounded),
    (SkillLevel.beginner,      'Beginner',      Icons.emoji_people_rounded),
    (SkillLevel.intermediate,  'Intermediate',  Icons.trending_up_rounded),
    (SkillLevel.competitive,   'Competitive',   Icons.military_tech_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _levels.map((entry) {
        final (level, label, icon) = entry;
        final isSelected = selected == level;
        return GestureDetector(
          onTap: () => onChanged(level),
          child: AnimatedContainer(
            duration: AppDuration.fast,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.colorAccentPrimary.withValues(alpha: 0.1)
                  : colors.colorSurfacePrimary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isSelected ? colors.colorAccentPrimary : colors.colorBorderSubtle,
                width: isSelected ? 1.0 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 14,
                    color: isSelected ? colors.colorAccentPrimary : colors.colorTextTertiary),
                const SizedBox(width: 5),
                Text(label,
                    style: AppTextStyles.labelM(
                        isSelected ? colors.colorAccentPrimary : colors.colorTextSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Search field ──────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.colors});

  final TextEditingController controller;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.bodyM(colors.colorTextPrimary),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by name, @username, or phone',
          hintStyle: AppTextStyles.bodyM(colors.colorTextTertiary),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: colors.colorTextTertiary),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: controller.clear,
                  child: Icon(Icons.close_rounded, size: 16, color: colors.colorTextTertiary),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ── Empty search state ────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.person_search_rounded, size: 36, color: colors.colorTextTertiary),
          const SizedBox(height: AppSpacing.sm),
          Text('No players found', style: AppTextStyles.headingS(colors.colorTextSecondary)),
          const SizedBox(height: 4),
          Text(
            'Try a different name or username',
            style: AppTextStyles.bodyS(colors.colorTextTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Phone invite (number not in DB) ──────────────────────────────

class _PhoneInvite extends StatelessWidget {
  const _PhoneInvite({required this.phone, required this.colors});
  final String phone;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.colorAccentPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add_rounded,
                      size: 20, color: colors.colorAccentPrimary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Not on Courtside yet',
                          style: AppTextStyles.headingS(colors.colorTextPrimary)),
                      const SizedBox(height: 2),
                      Text(phone,
                          style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(height: 0.5, color: colors.colorBorderSubtle),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Send them an invite to download Courtside. Once they join, they\'ll appear in your friends list.',
              style: AppTextStyles.bodyS(colors.colorTextSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invite sent to $phone',
                          style: AppTextStyles.bodyM(colors.colorTextPrimary)),
                      backgroundColor: colors.colorSurfaceOverlay,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text('Send App Invite',
                    style: AppTextStyles.labelM(colors.colorTextOnAccent)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.colorAccentPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Friend tile ───────────────────────────────────────────────────

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.invited,
    required this.colors,
    required this.onTap,
  });

  final FriendProfile friend;
  final bool invited;
  final AppColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: invited
              ? colors.colorAccentSubtle
              : colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: invited
                ? colors.colorAccentPrimary.withValues(alpha: 0.4)
                : colors.colorBorderSubtle,
            width: invited ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: invited
                    ? colors.colorAccentPrimary
                    : colors.colorSurfaceElevated,
                border: invited
                    ? null
                    : Border.all(color: colors.colorBorderSubtle, width: 0.5),
              ),
              child: Center(
                child: Text(
                  friend.avatarInitials,
                  style: AppTextStyles.labelM(
                    invited ? colors.colorTextOnAccent : colors.colorTextPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.name,
                      style: AppTextStyles.headingS(colors.colorTextPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    '${friend.username} · ${friend.gamesPlayed} games',
                    style: AppTextStyles.bodyS(colors.colorTextTertiary),
                  ),
                ],
              ),
            ),
            // Check
            AnimatedSwitcher(
              duration: AppDuration.fast,
              child: invited
                  ? Icon(Icons.check_circle_rounded,
                      key: const ValueKey('on'),
                      color: colors.colorAccentPrimary, size: 22)
                  : Icon(Icons.add_circle_outline_rounded,
                      key: const ValueKey('off'),
                      color: colors.colorTextTertiary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
