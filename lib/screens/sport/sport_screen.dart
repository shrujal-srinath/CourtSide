import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/app_spacing.dart';

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

class PickupGame {
  const PickupGame({
    required this.id,
    required this.title,
    required this.venue,
    required this.time,
    required this.spotsLeft,
    required this.sport,
  });

  final String id;
  final String title;
  final String venue;
  final String time;
  final int spotsLeft;
  final String sport;
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
  'basketball': SportConfig(id: 'basketball', label: 'Basketball', emoji: '🏀'),
  'cricket':    SportConfig(id: 'cricket',    label: 'Box Cricket', emoji: '🏏'),
  'badminton':  SportConfig(id: 'badminton',  label: 'Badminton',  emoji: '🏸'),
  'football':   SportConfig(id: 'football',   label: 'Football',   emoji: '⚽'),
};

// ── Seed data — replace with Supabase later ─────────────────────

const _seedVenues = [
  VenueItem(
    id: '1', name: 'Koramangala Sports Hub',
    address: '5th Block, Koramangala',
    distanceKm: 1.2, rating: 4.7, pricePerSlot: 400,
    sport: 'basketball', surface: 'Hardwood', isIndoor: true,
    hasTheBox: true, slotsAvailable: 5,
  ),
  VenueItem(
    id: '2', name: 'Indiranagar Court',
    address: '12th Main, Indiranagar',
    distanceKm: 2.1, rating: 4.5, pricePerSlot: 350,
    sport: 'basketball', surface: 'Concrete', isIndoor: false,
    hasTheBox: false, slotsAvailable: 3,
  ),
  VenueItem(
    id: '3', name: 'HSR Sports Arena',
    address: 'Sector 6, HSR Layout',
    distanceKm: 3.4, rating: 4.8, pricePerSlot: 500,
    sport: 'basketball', surface: 'Hardwood', isIndoor: true,
    hasTheBox: true, slotsAvailable: 8,
  ),
  VenueItem(
    id: '4', name: 'Whitefield Box Arena',
    address: 'ITPL Main Rd, Whitefield',
    distanceKm: 6.1, rating: 4.3, pricePerSlot: 450,
    sport: 'basketball', surface: 'Rubber', isIndoor: true,
    hasTheBox: true, slotsAvailable: 2,
  ),
  VenueItem(
    id: '5', name: 'BTM Sports Complex',
    address: 'BTM 2nd Stage',
    distanceKm: 4.2, rating: 4.1, pricePerSlot: 300,
    sport: 'basketball', surface: 'Concrete', isIndoor: false,
    hasTheBox: false, slotsAvailable: 0,
  ),
];

const _seedPickupGames = [
  PickupGame(
    id: 'p1', title: '3v3 Pickup',
    venue: 'Koramangala Sports Hub',
    time: '5:00 PM', spotsLeft: 2, sport: 'basketball',
  ),
  PickupGame(
    id: 'p2', title: 'Full Court Run',
    venue: 'HSR Sports Arena',
    time: '7:00 PM', spotsLeft: 1, sport: 'basketball',
  ),
];

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
      const SportConfig(id: 'basketball', label: 'Basketball', emoji: '🏀');

  List<VenueItem> get _filteredVenues {
    var venues = _seedVenues
        .where((v) => v.sport == widget.sportId)
        .toList();
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

  List<PickupGame> get _pickupGames =>
      _seedPickupGames.where((g) => g.sport == widget.sportId).toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Date sheet ───────────────────────────────────────────────

  void _showDateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DateSheet(
        selected: _date,
        onSelected: (d) {
          setState(() => _date = d);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Filter sheet (secondary filters) ───────────────────────

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(sportId: widget.sportId),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final venues = _filteredVenues;
    final pickups = _pickupGames;
    final showPickups =
        pickups.isNotEmpty && _filter == SportFilter.all ||
        _filter == SportFilter.games;

    return Scaffold(
      backgroundColor: context.col.bg,
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
                    subtitle: 'Be the first to start a ${_sport.label} group',
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Pickup games — conditional
                      if (showPickups && pickups.isNotEmpty)
                        _PickupSection(games: pickups),

                      // Venue list
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
                            subtitle: 'Try adjusting your search or filters',
                          )
                        else
                          ...venues.map((v) => _VenueCard(venue: v)),
                      ],

                      // Games only view
                      if (_filter == SportFilter.games && pickups.isEmpty)
                        _EmptyState(
                          emoji: '🎮',
                          title: 'No pickup games today',
                          subtitle: 'Host one and get players to join',
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HEADER — compact, all in 3 rows
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
    final c = context.col;
    return Container(
      color: c.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: back · sport · date pill · filter icon ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              children: [
                // Back
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.surface,
                      border: Border.all(color: c.border, width: 0.5),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: c.text,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Sport emoji + name
                Text(sport.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sport.label,
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                // Date pill
                GestureDetector(
                  onTap: onDateTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.border, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: c.textSec,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Filter icon
                GestureDetector(
                  onTap: onFilterTap,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.border, width: 0.5),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: c.text,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Row 2: Search bar ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border, width: 0.5),
              ),
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearchChanged,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: c.text,
                ),
                decoration: InputDecoration(
                  hintText: 'Search ${sport.label} courts...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: c.textSec,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: c.textSec,
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
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              itemCount: SportFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = SportFilter.values[i];
                final active = f == filter;
                return GestureDetector(
                  onTap: () => onFilterChanged(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.red.withValues(alpha: 0.15)
                          : c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? AppColors.red.withValues(alpha: 0.5)
                            : c.border,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      f.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? AppColors.red
                            : c.textSec,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Container(height: 0.5, color: c.border),
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
  final List<PickupGame> games;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.red.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              '🔥  Pickup games today',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ...games.map((g) => _PickupGameRow(game: g)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _PickupGameRow extends StatelessWidget {
  const _PickupGameRow({required this.game});
  final PickupGame game;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${game.title} · ${game.time}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.col.text,
                  ),
                ),
                Text(
                  game.venue,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.col.textSec,
                  ),
                ),
              ],
            ),
          ),
          // Spots left
          Text(
            '${game.spotsLeft} spot${game.spotsLeft == 1 ? '' : 's'}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 10),
          // Join button
          GestureDetector(
            onTap: () {
              // TODO: join game flow
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Join',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.col.text,
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailing!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.red,
                  fontWeight: FontWeight.w500,
                ),
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
    final available = venue.slotsAvailable > 0;
    final scarce = const [1, 2, 3].contains(venue.slotsAvailable);

    return GestureDetector(
      onTap: () {
        // TODO: navigate to venue detail
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.col.border, width: 0.5),
          boxShadow: AppShadow.cardFor(context),
        ),
        child: Row(
          children: [
            // ── Photo ─────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    color: context.col.surfaceHigh,
                    child: venue.photoUrl != null
                        ? Image.network(
                            venue.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _PlaceholderImage(venue: venue),
                          )
                        : _PlaceholderImage(venue: venue),
                  ),
                  // THE BOX badge
                  if (venue.hasTheBox)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'THE BOX',
                          style: GoogleFonts.inter(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      venue.name,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.col.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Meta: distance · rating · surface
                    Text(
                      '${venue.distanceKm.toStringAsFixed(1)} km  ·  ${venue.rating} ★  ·  ${venue.surface} ${venue.isIndoor ? 'indoor' : 'outdoor'}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.col.textSec,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),

                    // Bottom row: price + slots + book
                    Row(
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${venue.pricePerSlot}/slot',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.col.text,
                              ),
                            ),
                            Text(
                              available
                                  ? scarce
                                      ? '${venue.slotsAvailable} slots left'
                                      : 'Available now'
                                  : 'Fully booked',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: available
                                    ? scarce
                                        ? AppColors.warning
                                        : AppColors.success
                                    : context.col.textSec,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Book button
                        GestureDetector(
                          onTap: available
                              ? () {
                                  // TODO: navigate to booking
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: available
                                  ? AppColors.red
                                  : context.col.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              available ? 'Book' : 'Full',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: available
                                    ? AppColors.white
                                    : context.col.textSec,
                              ),
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

// ── Placeholder image ─────────────────────────────────────────

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.venue});
  final VenueItem venue;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.col.surfaceHigh,
      child: Center(
        child: Text(
          venue.name[0],
          style: GoogleFonts.syne(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: context.col.border,
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.col.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.col.textSec,
            ),
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
    final c = context.col;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Text(
              'Select date',
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
          ),
          ...DateOption.values.map((d) {
            final active = d == selected;
            return GestureDetector(
              onTap: () => onSelected(d),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: c.border, width: 0.5),
                  ),
                  color: active
                      ? AppColors.red.withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.label,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: active ? AppColors.red : c.textSec,
                        ),
                      ),
                    ),
                    if (active)
                      const Icon(Icons.check_rounded,
                          color: AppColors.red, size: 18),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FILTER SHEET — secondary filters
// ═══════════════════════════════════════════════════════════════

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.sportId});
  final String sportId;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  bool _theBoxOnly = false;
  bool _indoorOnly = false;
  bool _outdoorOnly = false;
  double _maxDistance = 10;

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Text(
              'Filters',
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // THE BOX toggle
          _FilterToggle(
            label: 'THE BOX equipped only',
            subtitle: 'Courts with live stat tracking',
            value: _theBoxOnly,
            onChanged: (v) => setState(() => _theBoxOnly = v),
          ),

          // Indoor toggle
          _FilterToggle(
            label: 'Indoor courts only',
            subtitle: 'Covered, climate-controlled',
            value: _indoorOnly,
            onChanged: (v) => setState(() {
              _indoorOnly = v;
              if (v) _outdoorOnly = false;
            }),
          ),

          // Outdoor toggle
          _FilterToggle(
            label: 'Outdoor courts only',
            subtitle: 'Open air venues',
            value: _outdoorOnly,
            onChanged: (v) => setState(() {
              _outdoorOnly = v;
              if (v) _indoorOnly = false;
            }),
          ),

          // Distance slider
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Max distance',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
                Text(
                  '${_maxDistance.toInt()} km',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.red,
                inactiveTrackColor: context.col.border,
                thumbColor: AppColors.red,
                overlayColor: AppColors.red.withValues(alpha: 0.1),
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

          // Apply button
          Padding(
            padding: EdgeInsets.fromLTRB(
                18, 12, 18, MediaQuery.of(context).padding.bottom + 18),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply filters',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.col.border, width: 0.5),
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.col.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.col.textSec,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.red,
              inactiveThumbColor: context.col.textSec,
              inactiveTrackColor: context.col.border,
            ),
          ],
        ),
      ),
    );
  }
}