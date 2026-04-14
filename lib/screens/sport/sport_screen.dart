import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart' as fd;

// ═══════════════════════════════════════════════════════════════
//  MODELS — temporary until Supabase is wired
// ═══════════════════════════════════════════════════════════════

class VenueItem {
  const VenueItem({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.pricePerSlot,
    required this.sport,
    required this.surface,
    required this.isIndoor,
    required this.hasTheBox,
    required this.slotsAvailable,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final double rating;
  final int pricePerSlot;
  final String sport;
  final String surface;
  final bool isIndoor;
  final bool hasTheBox;
  final int slotsAvailable;
  final String? photoUrl;
}


// ── Sport config ────────────────────────────────────────────────

class SportConfig {
  const SportConfig({
    required this.id,
    required this.label,
    required this.emoji,
  });

  final String id;
  final String label;
  final String emoji;
}

const _sportConfigs = {
  'basketball':
      SportConfig(id: 'basketball', label: 'Basketball', emoji: '🏀'),
  'cricket':
      SportConfig(id: 'cricket', label: 'Box Cricket', emoji: '🏏'),
  'badminton':
      SportConfig(id: 'badminton', label: 'Badminton', emoji: '🏸'),
  'football':
      SportConfig(id: 'football', label: 'Football', emoji: '⚽'),
};


// ── Date option ─────────────────────────────────────────────────

enum DateOption { today, tomorrow, weekend, custom }

extension DateOptionLabel on DateOption {
  String get label {
    switch (this) {
      case DateOption.today:    return 'Today';
      case DateOption.tomorrow: return 'Tomorrow';
      case DateOption.weekend:  return 'This Weekend';
      case DateOption.custom:   return 'Pick date';
    }
  }
}

// ── Filter chip type ────────────────────────────────────────────

enum SportFilter { all, venues, groups, games }

extension SportFilterLabel on SportFilter {
  String get label {
    switch (this) {
      case SportFilter.all:    return 'All';
      case SportFilter.venues: return 'Venues';
      case SportFilter.groups: return 'Groups';
      case SportFilter.games:  return 'Games';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  SPORT SCREEN
// ═══════════════════════════════════════════════════════════════

class SportScreen extends ConsumerStatefulWidget {
  const SportScreen({super.key, required this.sportId});
  final String sportId;

  @override
  ConsumerState<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends ConsumerState<SportScreen> {
  DateOption _date = DateOption.today;
  SportFilter _filter = SportFilter.all;
  final _searchCtrl = TextEditingController();

  SportConfig get _sport =>
      _sportConfigs[widget.sportId] ??
      const SportConfig(
          id: 'basketball', label: 'Basketball', emoji: '🏀');

  List<VenueItem> get _filteredVenues {
    final fdVenues = fd.FakeData.venuesBySport(widget.sportId);
    var venues = fdVenues.map((v) {
      final court = fd.FakeData.courtByVenueAndSport(v.id, widget.sportId);
      return VenueItem(
        id: v.id,
        name: v.name,
        address: v.address,
        distanceKm: v.distanceFromKm(12.9716, 77.5946),
        rating: v.rating,
        pricePerSlot: court?.pricePerSlot ?? 0,
        sport: widget.sportId,
        surface: court?.surface ?? 'Hardwood',
        isIndoor: court?.isIndoor ?? v.isIndoor,
        hasTheBox: v.hasTheBox,
        slotsAvailable: court?.slotsAvailableToday ?? 0,
        photoUrl: v.photoUrl.isNotEmpty ? v.photoUrl : null,
      );
    }).toList();
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      venues = venues
          .where((v) =>
              v.name.toLowerCase().contains(q) ||
              v.address.toLowerCase().contains(q))
          .toList();
    }
    return venues;
  }

  List<fd.PickupGame> get _pickupGames =>
      fd.FakeData.pickupGamesBySport(widget.sportId);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.colorSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) => _DateSheet(
        selected: _date,
        onSelected: (d) {
          setState(() => _date = d);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.colorSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      isScrollControlled: true,
      builder: (_) => _FilterSheet(sportId: widget.sportId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors    = context.colors;
    final topPad    = MediaQuery.of(context).padding.top;
    final venues    = _filteredVenues;
    final pickups   = _pickupGames;
    final showPickups =
        pickups.isNotEmpty && _filter == SportFilter.all ||
        _filter == SportFilter.games;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          SizedBox(height: topPad),
          _Header(
            sport: _sport,
            date: _date,
            filter: _filter,
            searchCtrl: _searchCtrl,
            onBack: () => Navigator.of(context).pop(),
            onDateTap: _showDateSheet,
            onFilterTap: _showFilterSheet,
            onFilterChanged: (f) => setState(() => _filter = f),
            onSearchChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: _filter == SportFilter.groups
                ? _EmptyState(
                    emoji: '👥',
                    title: 'No groups yet',
                    subtitle:
                        'Be the first to start a ${_sport.label} group',
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (showPickups && pickups.isNotEmpty)
                        _PickupSection(games: pickups),

                      if (_filter == SportFilter.all ||
                          _filter == SportFilter.venues) ...[
                        _SectionHeader(
                          title: 'Courts available',
                          trailing: 'Map view →',
                          onTrailingTap: () {},
                        ),
                        if (venues.isEmpty)
                          _EmptyState(
                            emoji: '🏟️',
                            title: 'No courts found',
                            subtitle:
                                'Try adjusting your search or filters',
                          )
                        else
                          ...venues.map((v) => _VenueCard(venue: v)),
                      ],

                      if (_filter == SportFilter.games &&
                          pickups.isEmpty)
                        _EmptyState(
                          emoji: '🎮',
                          title: 'No pickup games today',
                          subtitle:
                              'Host one and get players to join',
                        ),

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.sport,
    required this.date,
    required this.filter,
    required this.searchCtrl,
    required this.onBack,
    required this.onDateTap,
    required this.onFilterTap,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final SportConfig sport;
  final DateOption date;
  final SportFilter filter;
  final TextEditingController searchCtrl;
  final VoidCallback onBack;
  final VoidCallback onDateTap;
  final VoidCallback onFilterTap;
  final ValueChanged<SportFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.colorBackgroundPrimary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: back · sport · date pill · filter icon ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm,
                AppSpacing.md, AppSpacing.sm + 2),
            child: Row(
              children: [
                // Back
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.colorSurfacePrimary,
                      border: Border.all(
                          color: colors.colorBorderSubtle, width: 0.5),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colors.colorTextPrimary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),

                // Sport emoji + name
                Text(sport.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    sport.label,
                    style: AppTextStyles.headingL(
                        colors.colorTextPrimary),
                  ),
                ),

                // Date pill
                GestureDetector(
                  onTap: onDateTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs + 3),
                    decoration: BoxDecoration(
                      color: colors.colorSurfacePrimary,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                          color: colors.colorBorderSubtle,
                          width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date.label,
                          style: AppTextStyles.labelM(
                              colors.colorTextPrimary),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colors.colorTextSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Filter icon
                GestureDetector(
                  onTap: onFilterTap,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.colorSurfacePrimary,
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: colors.colorBorderSubtle, width: 0.5),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: colors.colorTextPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Row 2: Search bar ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm + 2),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colors.colorSurfacePrimary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: colors.colorBorderSubtle, width: 0.5),
              ),
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearchChanged,
                style: AppTextStyles.bodyM(colors.colorTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Search ${sport.label} courts...',
                  hintStyle:
                      AppTextStyles.bodyM(colors.colorTextSecondary),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colors.colorTextSecondary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Row 3: Filter chips ───────────────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, 0),
              itemCount: SportFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f      = SportFilter.values[i];
                final active = f == filter;
                return GestureDetector(
                  onTap: () => onFilterChanged(f),
                  child: AnimatedContainer(
                    duration: AppDuration.fast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs + 3),
                    decoration: BoxDecoration(
                      color: active
                          ? colors.colorAccentSubtle
                          : colors.colorSurfacePrimary,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: active
                            ? colors.colorAccentPrimary
                            : colors.colorBorderSubtle,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      f.label,
                      style: AppTextStyles.labelM(
                        active
                            ? colors.colorAccentPrimary
                            : colors.colorTextSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm + 2),
          Container(height: 0.5, color: colors.colorBorderSubtle),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PICKUP GAMES SECTION
// ═══════════════════════════════════════════════════════════════

class _PickupSection extends StatelessWidget {
  const _PickupSection({required this.games});
  final List<fd.PickupGame> games;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.colorAccentSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.colorAccentPrimary.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm + 2,
                AppSpacing.md, AppSpacing.sm),
            child: Text(
              '🔥  Pickup games today',
              style: AppTextStyles.labelM(colors.colorAccentPrimary),
            ),
          ),
          ...games.map((g) => _PickupGameRow(game: g)),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _PickupGameRow extends StatelessWidget {
  const _PickupGameRow({required this.game});
  final fd.PickupGame game;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${game.title} · ${game.time}',
                  style: AppTextStyles.bodyS(colors.colorTextPrimary)
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  game.venueName,
                  style: AppTextStyles.overline(
                      colors.colorTextTertiary),
                ),
              ],
            ),
          ),
          // Spots left
          Text(
            '${game.spotsLeft} spot${game.spotsLeft == 1 ? '' : 's'}',
            style: AppTextStyles.labelS(colors.colorWarning),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          // Join button
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: colors.colorAccentPrimary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'Join',
              style: AppTextStyles.labelM(colors.colorTextOnAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SECTION HEADER
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md,
          AppSpacing.md, AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.overline(colors.colorTextTertiary),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailing!,
                style: AppTextStyles.labelS(
                    colors.colorAccentPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  VENUE CARD
// ═══════════════════════════════════════════════════════════════

class _VenueCard extends StatelessWidget {
  const _VenueCard({required this.venue});
  final VenueItem venue;

  @override
  Widget build(BuildContext context) {
    final colors    = context.colors;
    final available = venue.slotsAvailable > 0;
    final scarce    = const [1, 2, 3].contains(venue.slotsAvailable);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.venueById(venue.id)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
              color: colors.colorBorderSubtle, width: 0.5),
          boxShadow: AppShadow.card,
        ),
        child: Row(
          children: [
            // ── Photo ─────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.card - 1),
                bottomLeft: Radius.circular(AppRadius.card - 1),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    color: colors.colorSurfaceElevated,
                    child: venue.photoUrl != null
                        ? Image.network(
                            venue.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _PlaceholderImage(venue: venue),
                          )
                        : _PlaceholderImage(venue: venue),
                  ),
                  if (venue.hasTheBox)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs + 1,
                            vertical: AppSpacing.xs - 2),
                        decoration: BoxDecoration(
                          color: colors.colorAccentPrimary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm - 4),
                        ),
                        child: Text(
                          'THE BOX',
                          style: AppTextStyles.overline(
                              colors.colorTextOnAccent),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: AppTextStyles.headingS(
                          colors.colorTextPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    Text(
                      '${venue.distanceKm.toStringAsFixed(1)} km  ·  ${venue.rating} ★  ·  ${venue.surface} ${venue.isIndoor ? 'indoor' : 'outdoor'}',
                      style: AppTextStyles.bodyS(
                          colors.colorTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppSpacing.sm + 2),

                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${venue.pricePerSlot}/slot',
                              style: AppTextStyles.headingS(
                                  colors.colorTextPrimary),
                            ),
                            Text(
                              available
                                  ? scarce
                                      ? '${venue.slotsAvailable} slots left'
                                      : 'Available now'
                                  : 'Fully booked',
                              style: AppTextStyles.labelS(
                                available
                                    ? scarce
                                        ? colors.colorWarning
                                        : colors.colorSuccess
                                    : colors.colorTextTertiary,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        AnimatedContainer(
                          duration: AppDuration.fast,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: available
                                ? colors.colorAccentPrimary
                                : colors.colorSurfaceElevated,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            available ? 'Book' : 'Full',
                            style: AppTextStyles.labelM(
                              available
                                  ? colors.colorTextOnAccent
                                  : colors.colorTextTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.venue});
  final VenueItem venue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.colorSurfaceElevated,
      child: Center(
        child: Text(
          venue.name[0],
          style: AppTextStyles.displayM(colors.colorBorderMedium),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.section + AppSpacing.sm,
          horizontal: AppSpacing.xxxl),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTextStyles.headingM(colors.colorTextPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.bodyS(colors.colorTextSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DATE SHEET
// ═══════════════════════════════════════════════════════════════

class _DateSheet extends StatelessWidget {
  const _DateSheet({required this.selected, required this.onSelected});
  final DateOption selected;
  final ValueChanged<DateOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.sm + 2),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: colors.colorBorderMedium,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg,
              AppSpacing.lg, AppSpacing.sm),
          child: Text(
            'SELECT DATE',
            style: AppTextStyles.overline(colors.colorTextTertiary),
          ),
        ),
        ...DateOption.values.map((d) {
          final active = d == selected;
          return GestureDetector(
            onTap: () => onSelected(d),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: colors.colorBorderSubtle, width: 0.5),
                ),
                color: active ? colors.colorAccentSubtle : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d.label,
                      style: AppTextStyles.bodyM(
                        active
                            ? colors.colorAccentPrimary
                            : colors.colorTextSecondary,
                      ).copyWith(
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (active)
                    Icon(Icons.check_rounded,
                        color: colors.colorAccentPrimary, size: 18),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FILTER SHEET
// ═══════════════════════════════════════════════════════════════

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.sportId});
  final String sportId;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  bool _theBoxOnly   = false;
  bool _indoorOnly   = false;
  bool _outdoorOnly  = false;
  double _maxDistance = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle
        Center(
          child: Container(
            margin:
                const EdgeInsets.only(top: AppSpacing.sm + 2),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.colorBorderMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg,
              AppSpacing.lg, 0),
          child: Text(
            'FILTERS',
            style: AppTextStyles.overline(colors.colorTextTertiary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        _FilterToggle(
          label: 'THE BOX equipped only',
          subtitle: 'Courts with live stat tracking',
          value: _theBoxOnly,
          onChanged: (v) => setState(() => _theBoxOnly = v),
        ),

        _FilterToggle(
          label: 'Indoor courts only',
          subtitle: 'Covered, climate-controlled',
          value: _indoorOnly,
          onChanged: (v) => setState(() {
            _indoorOnly = v;
            if (v) _outdoorOnly = false;
          }),
        ),

        _FilterToggle(
          label: 'Outdoor courts only',
          subtitle: 'Open air venues',
          value: _outdoorOnly,
          onChanged: (v) => setState(() {
            _outdoorOnly = v;
            if (v) _indoorOnly = false;
          }),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md,
              AppSpacing.lg, AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Max distance',
                style: AppTextStyles.bodyM(colors.colorTextPrimary),
              ),
              Text(
                '${_maxDistance.toInt()} km',
                style: AppTextStyles.headingS(
                    colors.colorAccentPrimary),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.colorAccentPrimary,
              inactiveTrackColor: colors.colorBorderSubtle,
              thumbColor: colors.colorAccentPrimary,
              overlayColor:
                  colors.colorAccentPrimary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _maxDistance,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + AppSpacing.lg),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: colors.colorAccentPrimary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: AppShadow.fab,
              ),
              alignment: Alignment.center,
              child: Text(
                'Apply filters',
                style: AppTextStyles.headingS(colors.colorTextOnAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: colors.colorBorderSubtle, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyM(colors.colorTextPrimary),
                  ),
                  Text(
                    subtitle,
                    style:
                        AppTextStyles.bodyS(colors.colorTextSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: colors.colorAccentPrimary,
              activeTrackColor: colors.colorAccentPrimary.withValues(alpha: 0.5),
              inactiveThumbColor: colors.colorTextTertiary,
              inactiveTrackColor: colors.colorBorderSubtle,
            ),
          ],
        ),
      ),
    );
  }
}
