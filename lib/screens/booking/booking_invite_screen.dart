// lib/screens/booking/booking_invite_screen.dart
//
// Step 1 of the booking wizard — Game type + squad invite.
//
// Game type: two side-by-side 112px cards. Selected state uses a presence dot
// + glow shadow + flooded tint — three simultaneous signals, no ambiguity.
//
// Squad invite: a 60px collapsed bar showing avatar cluster. Tapping expands
// inline (AnimatedSize) to reveal search + friend list. The forming squad is
// always visible in the bar — the act of building it is the interaction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../providers/booking_flow_provider.dart';
import 'booking_step_widgets.dart';

// ─────────────────────────────────────────────────────────────────
class BookingInviteScreen extends ConsumerStatefulWidget {
  const BookingInviteScreen({super.key});

  @override
  ConsumerState<BookingInviteScreen> createState() =>
      _BookingInviteScreenState();
}

class _BookingInviteScreenState extends ConsumerState<BookingInviteScreen> {
  final _scrollCtrl  = ScrollController();
  final _searchCtrl  = TextEditingController();
  final _inviteKey   = GlobalKey();

  bool                _inviteExpanded = false;
  List<FriendProfile> _searchResults  = [];
  bool                _hasSearched    = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleInvite() {
    setState(() => _inviteExpanded = !_inviteExpanded);
    if (!_inviteExpanded) return;
    // Scroll so the invite section is in view after expansion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _inviteKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(ctx,
          duration: AppDuration.slow, curve: Curves.easeOutCubic,
          alignment: 0.1);
    });
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() { _searchResults = []; _hasSearched = false; });
      return;
    }
    setState(() {
      _hasSearched    = true;
      _searchResults  = fakeFriends.where((f) =>
          f.name.toLowerCase().contains(q) ||
          f.username.toLowerCase().contains(q) ||
          f.id.contains(q)).toList();
    });
  }

  bool get _queryIsPhone {
    final q = _searchCtrl.text.trim().replaceAll(RegExp(r'[\s\-+]'), '');
    return RegExp(r'^\d{7,13}$').hasMatch(q);
  }

  @override
  Widget build(BuildContext context) {
    final flow     = ref.watch(bookingFlowProvider);
    final notifier = ref.read(bookingFlowProvider.notifier);
    final colors   = context.colors;
    final botPad   = MediaQuery.of(context).padding.bottom;

    final invitedFriends = fakeFriends
        .where((f) => flow.invitedFriendIds.contains(f.id))
        .toList();
    final displayList = _hasSearched ? _searchResults : fakeFriends;
    final n = flow.invitedFriendIds.length;

    // CTA label
    final ctaLabel = n == 0
        ? 'Continue'
        : 'Continue  ·  $n playing';

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          BookingWizardNav(
            currentStep: 1,
            venueId:     flow.venueId,
            onBack:      () => context.pop(),
          ),

          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xl,
                  AppSpacing.lg, botPad + 100),
              children: [

                // ── Booking recap ────────────────────────────────────
                if (flow.venue != null && flow.slot != null)
                  _ContextPill(flow: flow, colors: colors),

                const SizedBox(height: AppSpacing.xxl),

                // ── Game type ─────────────────────────────────────────
                _Label('GAME TYPE', colors),
                const SizedBox(height: AppSpacing.md),
                _GameTypePair(
                  isPublic:  flow.isPublicGame,
                  colors:    colors,
                  onChanged: notifier.setPublicGame,
                ),

                // ── Community options (animated in/out) ───────────────
                AnimatedSize(
                  duration: AppDuration.slow,
                  curve:    Curves.easeOutCubic,
                  child: flow.isPublicGame
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xl),
                            _Label('PLAYER LIMIT', colors),
                            const SizedBox(height: AppSpacing.sm),
                            _PlayerLimitRow(
                              limit:     flow.playerLimit,
                              colors:    colors,
                              onChanged: notifier.setPlayerLimit,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _Label('SKILL LEVEL', colors),
                            const SizedBox(height: AppSpacing.sm),
                            _SkillLevelPicker(
                              selected:  flow.skillLevel,
                              colors:    colors,
                              onChanged: notifier.setSkillLevel,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Squad invite bar ──────────────────────────────────
                _Label('SQUAD', colors),
                const SizedBox(height: AppSpacing.md),
                _InviteBar(
                  key:              _inviteKey,
                  isExpanded:       _inviteExpanded,
                  invitedFriends:   invitedFriends,
                  displayList:      displayList,
                  hasSearched:      _hasSearched,
                  queryIsPhone:     _queryIsPhone,
                  searchCtrl:       _searchCtrl,
                  colors:           colors,
                  invitedIds:       flow.invitedFriendIds,
                  onToggle:         _toggleInvite,
                  onSearch:         _onSearch,
                  onToggleFriend:   notifier.toggleFriend,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Friends get their verified stats automatically after the game.',
                  style: AppTextStyles.bodyS(colors.colorTextTertiary),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BookingStepFooter(
        label:   ctaLabel,
        isSkip:  false,
        colors:  colors,
        botPad:  botPad,
        onTap:   () => context.push(AppRoutes.bookHardware(flow.venueId)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  GAME TYPE PAIR — two side-by-side 112px cards
// ─────────────────────────────────────────────────────────────────

class _GameTypePair extends StatelessWidget {
  const _GameTypePair({
    required this.isPublic,
    required this.colors,
    required this.onChanged,
  });

  final bool               isPublic;
  final AppColorScheme     colors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _GameTypeCard(
            icon:        Icons.lock_outline_rounded,
            label:       'Private',
            tagLabel:    'INVITE-ONLY',
            description: 'Only players you invite can join',
            features:    const ['You control who plays', 'Squad gets stats automatically'],
            isSelected:  !isPublic,
            colors:      colors,
            onTap:       () => onChanged(false),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _GameTypeCard(
            icon:        Icons.groups_2_rounded,
            label:       'Community',
            tagLabel:    'OPEN GAME',
            description: 'Let nearby players find and join',
            features:    const ['Players request to join', 'Set skill level & size'],
            isSelected:  isPublic,
            colors:      colors,
            onTap:       () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _GameTypeCard extends StatefulWidget {
  const _GameTypeCard({
    required this.icon,
    required this.label,
    required this.tagLabel,
    required this.description,
    required this.features,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final IconData         icon;
  final String           label;
  final String           tagLabel;
  final String           description;
  final List<String>     features;
  final bool             isSelected;
  final AppColorScheme   colors;
  final VoidCallback     onTap;

  @override
  State<_GameTypeCard> createState() => _GameTypeCardState();
}

class _GameTypeCardState extends State<_GameTypeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;
    // Both cards use the same accent — selection is signalled by border+tint,
    // not by color differentiation between the two options.
    final col = widget.colors.colorAccentPrimary;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.97 : 1.0,
        duration: Duration(milliseconds: _pressed ? 80 : 150),
        curve:    _pressed ? Curves.easeIn : Curves.elasticOut,
        child: AnimatedContainer(
          duration: AppDuration.normal,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sel
                ? widget.colors.colorSurfaceElevated
                : widget.colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: sel ? col : widget.colors.colorBorderSubtle,
              width: sel ? 1.5 : 0.5,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color:      col.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset:     const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon row + selection indicator ──────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: AppDuration.fast,
                    width:  38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.colors.colorSurfaceOverlay,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      widget.icon,
                      size:  19,
                      color: sel ? widget.colors.colorTextPrimary : widget.colors.colorTextTertiary,
                    ),
                  ),
                  const Spacer(),
                  // Checkmark when selected, tag pill when not
                  AnimatedSwitcher(
                    duration: AppDuration.fast,
                    child: sel
                        ? Container(
                            key: const ValueKey('check'),
                            width:  20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size:  12,
                              color: widget.colors.colorTextOnAccent,
                            ),
                          )
                        : Container(
                            key: const ValueKey('tag'),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.colors.colorSurfaceElevated,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                  color: widget.colors.colorBorderSubtle, width: 0.5),
                            ),
                            child: Text(
                              widget.tagLabel,
                              style: AppTextStyles.overline(widget.colors.colorTextTertiary)
                                  .copyWith(fontSize: 8),
                            ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Title ────────────────────────────────────────────
              Text(
                widget.label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize:      15,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: -0.2,
                  color: widget.colors.colorTextPrimary,
                ),
              ),
              const SizedBox(height: 3),

              // ── One-line description ─────────────────────────────
              Text(
                widget.description,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height:   1.3,
                  color: widget.colors.colorTextSecondary,
                ),
              ),

              const SizedBox(height: 12),

              // ── Feature lines ────────────────────────────────────
              ...widget.features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width:  4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 4, right: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? col.withValues(alpha: 0.75)
                              : widget.colors.colorTextTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          f,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            height:   1.35,
                            color: sel
                                ? col.withValues(alpha: 0.80)
                                : widget.colors.colorTextTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  INVITE BAR — collapsed avatar cluster + expandable search/list
// ─────────────────────────────────────────────────────────────────

class _InviteBar extends StatelessWidget {
  const _InviteBar({
    super.key,
    required this.isExpanded,
    required this.invitedFriends,
    required this.displayList,
    required this.hasSearched,
    required this.queryIsPhone,
    required this.searchCtrl,
    required this.colors,
    required this.invitedIds,
    required this.onToggle,
    required this.onSearch,
    required this.onToggleFriend,
  });

  final bool                   isExpanded;
  final List<FriendProfile>    invitedFriends;
  final List<FriendProfile>    displayList;
  final bool                   hasSearched;
  final bool                   queryIsPhone;
  final TextEditingController  searchCtrl;
  final AppColorScheme         colors;
  final List<String>           invitedIds;
  final VoidCallback           onToggle;
  final ValueChanged<String>   onSearch;
  final ValueChanged<String>   onToggleFriend;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.normal,
      decoration: BoxDecoration(
        color:        colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isExpanded
              ? colors.colorBorderSubtle
              : colors.colorBorderSubtle,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // ── Always-visible header bar ────────────────────────────
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    // Plus circle
                    Container(
                      width:  32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:  colors.colorSurfaceOverlay,
                        shape:  BoxShape.circle,
                        border: Border.all(
                            color: colors.colorBorderSubtle, width: 0.5),
                      ),
                      child: Icon(Icons.add_rounded,
                          size: 16, color: colors.colorTextSecondary),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Avatar cluster OR placeholder text
                    Expanded(
                      child: invitedFriends.isEmpty
                          ? Text(
                              'Invite your squad',
                              style: GoogleFonts.inter(
                                fontSize:   14,
                                fontWeight: FontWeight.w400,
                                color:      colors.colorTextTertiary,
                              ),
                            )
                          : _AvatarCluster(
                              friends: invitedFriends,
                              colors:  colors,
                            ),
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    // Rotating chevron
                    AnimatedRotation(
                      turns:    isExpanded ? 0.5 : 0,
                      duration: AppDuration.normal,
                      curve:    Curves.easeInOut,
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 22, color: colors.colorTextTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Expanded content ──────────────────────────────────────
          AnimatedSize(
            duration: AppDuration.slow,
            curve:    Curves.easeOutCubic,
            child: isExpanded
                ? Column(
                    children: [
                      Container(
                          height: 0.5, color: colors.colorBorderSubtle),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            // Search field
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: colors.colorSurfacePrimary,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                    color: colors.colorBorderSubtle,
                                    width: 0.5),
                              ),
                              child: TextField(
                                controller:      searchCtrl,
                                onChanged:       onSearch,
                                style:           AppTextStyles.bodyM(
                                    colors.colorTextPrimary),
                                keyboardType:    TextInputType.text,
                                textInputAction: TextInputAction.search,
                                autofocus:       isExpanded,
                                decoration: InputDecoration(
                                  hintText: 'Search by name or @handle',
                                  hintStyle: AppTextStyles.bodyM(
                                      colors.colorTextTertiary),
                                  prefixIcon: Icon(Icons.search_rounded,
                                      size: 18,
                                      color: colors.colorTextTertiary),
                                  suffixIcon: searchCtrl.text.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            searchCtrl.clear();
                                            onSearch('');
                                          },
                                          child: Icon(Icons.close_rounded,
                                              size: 15,
                                              color: colors.colorTextTertiary),
                                        )
                                      : null,
                                  border:         InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Friend list / search results
                            if (hasSearched && _searchResults(displayList).isEmpty)
                              queryIsPhone
                                  ? _PhoneInvite(
                                      phone:  searchCtrl.text.trim(),
                                      colors: colors,
                                    )
                                  : _EmptySearch(colors: colors)
                            else
                              ...displayList.asMap().entries.map((e) {
                                final friend  = e.value;
                                final last    = e.key == displayList.length - 1;
                                final invited = invitedIds.contains(friend.id);
                                return Column(
                                  children: [
                                    _FriendRow(
                                      friend:  friend,
                                      invited: invited,
                                      colors:  colors,
                                      onTap:   () =>
                                          onToggleFriend(friend.id),
                                    ),
                                    if (!last)
                                      Container(
                                          height: 0.5,
                                          color: colors.colorBorderSubtle),
                                  ],
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Helper: when searching, displayList IS already filtered
  List<FriendProfile> _searchResults(List<FriendProfile> list) => list;
}

// ─────────────────────────────────────────────────────────────────
//  AVATAR CLUSTER — overlapping initials circles
// ─────────────────────────────────────────────────────────────────

class _AvatarCluster extends StatelessWidget {
  const _AvatarCluster({
    required this.friends,
    required this.colors,
  });

  final List<FriendProfile> friends;
  final AppColorScheme      colors;

  static const _size    = 28.0;
  static const _overlap = 10.0;
  static const _max     = 4;

  Color _avatarBg(String id) {
    final hue = (id.hashCode.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.55, 0.38).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final visible = friends.take(_max).toList();
    final extra   = friends.length - _max;
    final slots   = visible.length + (extra > 0 ? 1 : 0);
    final width   = _size + (slots - 1) * (_size - _overlap);

    return Row(
      children: [
        SizedBox(
          width:  width,
          height: _size,
          child: Stack(
            children: [
              ...visible.asMap().entries.map((e) => Positioned(
                    left: e.key * (_size - _overlap),
                    child: Container(
                      width:  _size,
                      height: _size,
                      decoration: BoxDecoration(
                        color:  _avatarBg(e.value.id),
                        shape:  BoxShape.circle,
                        border: Border.all(
                            color: colors.colorSurfaceElevated, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          e.value.avatarInitials,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize:   9,
                            fontWeight: FontWeight.w700,
                            color:      Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )),
              if (extra > 0)
                Positioned(
                  left: visible.length * (_size - _overlap),
                  child: Container(
                    width:  _size,
                    height: _size,
                    decoration: BoxDecoration(
                      color:  colors.colorSurfaceOverlay,
                      shape:  BoxShape.circle,
                      border: Border.all(
                          color: colors.colorSurfaceElevated, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '+$extra',
                        style: GoogleFonts.inter(
                          fontSize:   9,
                          fontWeight: FontWeight.w600,
                          color:      colors.colorTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${friends.length} added',
          style: GoogleFonts.inter(
            fontSize:   13,
            fontWeight: FontWeight.w500,
            color:      colors.colorAccentPrimary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  FRIEND ROW — 64px tile, no row background tint
// ─────────────────────────────────────────────────────────────────

class _FriendRow extends StatefulWidget {
  const _FriendRow({
    required this.friend,
    required this.invited,
    required this.colors,
    required this.onTap,
  });

  final FriendProfile  friend;
  final bool           invited;
  final AppColorScheme colors;
  final VoidCallback   onTap;

  @override
  State<_FriendRow> createState() => _FriendRowState();
}

class _FriendRowState extends State<_FriendRow> {
  bool _pressed = false;

  Color _avatarBg() {
    final hue = (widget.friend.id.hashCode.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.55, 0.38).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invited;
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity:  _pressed ? 0.65 : 1.0,
        duration: const Duration(milliseconds: 60),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Avatar
              AnimatedContainer(
                duration: AppDuration.fast,
                width:  40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: inv
                      ? widget.colors.colorAccentPrimary
                      : _avatarBg(),
                  border: inv
                      ? Border.all(
                          color: widget.colors.colorAccentPrimary
                              .withValues(alpha: 0.4),
                          width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    widget.friend.avatarInitials,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color:      Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Name + handle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.friend.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                        color: inv
                            ? widget.colors.colorAccentPrimary
                            : widget.colors.colorTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.friend.username} · ${widget.friend.gamesPlayed} games',
                      style: AppTextStyles.bodyS(
                          widget.colors.colorTextTertiary),
                    ),
                  ],
                ),
              ),

              // Add / check button
              AnimatedContainer(
                duration: AppDuration.fast,
                width:  32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: inv
                      ? widget.colors.colorAccentPrimary
                      : widget.colors.colorSurfaceOverlay,
                  border: inv
                      ? null
                      : Border.all(
                          color: widget.colors.colorBorderSubtle, width: 0.5),
                ),
                child: Icon(
                  inv ? Icons.check_rounded : Icons.add_rounded,
                  size:  15,
                  color: inv
                      ? widget.colors.colorTextOnAccent
                      : widget.colors.colorTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  BOOKING CONTEXT PILL
// ─────────────────────────────────────────────────────────────────

class _ContextPill extends StatelessWidget {
  const _ContextPill({required this.flow, required this.colors});
  final BookingFlowState flow;
  final AppColorScheme   colors;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final date = flow.date;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:        colors.colorAccentSubtle,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.sports_basketball_rounded,
                size: 18, color: colors.colorAccentPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(flow.venue?.name ?? '',
                    style: AppTextStyles.headingS(colors.colorTextPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${flow.court?.name ?? ''} · '
                  '${date != null ? '${date.day} ${_months[date.month - 1]}' : ''}'
                  ' · ${flow.slot?.startTime ?? ''}',
                  style: AppTextStyles.bodyS(colors.colorTextSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        colors.colorSuccess.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text('₹${flow.courtTotal}',
                style: AppTextStyles.labelM(colors.colorSuccess)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text, this.colors);
  final String         text;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.overline(colors.colorTextTertiary));
}

// ─────────────────────────────────────────────────────────────────
//  PLAYER LIMIT ROW
// ─────────────────────────────────────────────────────────────────

class _PlayerLimitRow extends StatelessWidget {
  const _PlayerLimitRow({
    required this.limit,
    required this.colors,
    required this.onChanged,
  });

  final int               limit;
  final AppColorScheme    colors;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color:        colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.group_rounded,
              size: 18, color: colors.colorTextSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('Max players',
                style: AppTextStyles.labelM(colors.colorTextPrimary)),
          ),
          _StepBtn(icon: Icons.remove_rounded,
              onTap: limit > 2 ? () => onChanged(limit - 1) : null,
              colors: colors),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('$limit',
                style: AppTextStyles.headingM(colors.colorTextPrimary)),
          ),
          _StepBtn(icon: Icons.add_rounded,
              onTap: limit < 20 ? () => onChanged(limit + 1) : null,
              colors: colors),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn(
      {required this.icon, required this.colors, required this.onTap});
  final IconData       icon;
  final AppColorScheme colors;
  final VoidCallback?  onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color:  enabled ? colors.colorSurfaceElevated : Colors.transparent,
          shape:  BoxShape.circle,
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Icon(icon, size: 16,
            color: enabled
                ? colors.colorTextPrimary
                : colors.colorTextTertiary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SKILL LEVEL PICKER
// ─────────────────────────────────────────────────────────────────

class _SkillLevelPicker extends StatelessWidget {
  const _SkillLevelPicker({
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  final SkillLevel               selected;
  final AppColorScheme           colors;
  final ValueChanged<SkillLevel> onChanged;

  static const _levels = [
    (SkillLevel.all,          'All Levels',   Icons.groups_rounded),
    (SkillLevel.beginner,     'Beginner',     Icons.emoji_people_rounded),
    (SkillLevel.intermediate, 'Intermediate', Icons.trending_up_rounded),
    (SkillLevel.competitive,  'Competitive',  Icons.military_tech_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
      children: _levels.map((entry) {
        final (level, label, icon) = entry;
        final isSel = selected == level;
        return GestureDetector(
          onTap: () => onChanged(level),
          child: AnimatedContainer(
            duration: AppDuration.fast,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSel
                  ? colors.colorAccentPrimary.withValues(alpha: 0.12)
                  : colors.colorSurfacePrimary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isSel
                    ? colors.colorAccentPrimary
                    : colors.colorBorderSubtle,
                width: isSel ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14,
                    color: isSel
                        ? colors.colorAccentPrimary
                        : colors.colorTextTertiary),
                const SizedBox(width: 5),
                Text(label,
                    style: AppTextStyles.labelM(isSel
                        ? colors.colorAccentPrimary
                        : colors.colorTextSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  EMPTY / PHONE STATES
// ─────────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.person_search_rounded,
                size: 36, color: colors.colorTextTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text('No players found',
                style: AppTextStyles.headingS(colors.colorTextSecondary)),
            const SizedBox(height: 4),
            Text('Try a different name or @handle',
                style: AppTextStyles.bodyS(colors.colorTextTertiary)),
          ],
        ),
      );
}

class _PhoneInvite extends StatelessWidget {
  const _PhoneInvite({required this.phone, required this.colors});
  final String         phone;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:        colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: colors.colorAccentPrimary.withValues(alpha: 0.10),
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
            "Send them an invite to download Courtside. Once they join, "
            "they'll appear in your friends list.",
            style: AppTextStyles.bodyS(colors.colorTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Invite sent to $phone',
                  style: AppTextStyles.bodyM(colors.colorTextPrimary)),
              backgroundColor: colors.colorSurfaceOverlay,
              behavior:        SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            )),
            child: Container(
              width: double.infinity, height: 44,
              decoration: BoxDecoration(
                color:        colors.colorAccentPrimary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 15,
                      color: colors.colorTextOnAccent),
                  const SizedBox(width: 8),
                  Text('Send App Invite',
                      style: AppTextStyles.labelM(colors.colorTextOnAccent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
