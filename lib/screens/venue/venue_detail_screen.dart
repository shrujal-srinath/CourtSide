// lib/screens/venue/venue_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../widgets/common/cs_button.dart';
import '../../widgets/common/cs_shimmer.dart';

class VenueDetailScreen extends StatefulWidget {
  const VenueDetailScreen({super.key, required this.venueId});
  final String venueId;

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  late Venue _venue;
  String _activeSport = ''; // no pre-selection

  static const _sportLabels = {
    'basketball': 'Basketball',
    'cricket':    'Box Cricket',
    'badminton':  'Badminton',
    'football':   'Football',
  };

  Color _sportColor(String sport, AppColorScheme colors) {
    switch (sport) {
      case 'basketball': return colors.colorSportBasketball;
      case 'cricket':    return colors.colorSportCricket;
      case 'badminton':  return colors.colorSportBadminton;
      default:           return colors.colorSportFootball;
    }
  }

  IconData _sportIcon(String sport) {
    switch (sport) {
      case 'basketball': return Icons.sports_basketball_rounded;
      case 'cricket':    return Icons.sports_cricket_rounded;
      case 'badminton':  return Icons.sports_tennis_rounded;
      default:           return Icons.sports_soccer_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _venue = FakeData.venues.firstWhere(
      (v) => v.id == widget.venueId,
      orElse: () => FakeData.venues.first,
    );
  }

  Court? get _activeCourt => _activeSport.isEmpty
      ? null
      : FakeData.courtByVenueAndSport(_venue.id, _activeSport);

  Future<void> _launchMaps() async {
    final uri = Uri.parse(
        'https://maps.google.com/maps?daddr=${_venue.lat},${_venue.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleBookTap() {
    if (_activeSport.isEmpty) {
      _showSportPicker();
      return;
    }
    final court = _activeCourt;
    if (court == null || court.slotsAvailableToday == 0) return;
    context.push(
      AppRoutes.bookVenue(_venue.id),
      extra: {'sport': _activeSport, 'venue': _venue},
    );
  }

  void _showSportPicker() {
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.colorBorderMedium,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'PICK A SPORT',
              style: AppTextStyles.overline(colors.colorTextTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._venue.sports.map((sport) {
              final court = FakeData.courtByVenueAndSport(_venue.id, sport);
              final sc = _sportColor(sport, colors);
              final priceLabel = court != null
                  ? '₹${court.pricePerSlot} / ${court.slotDurationMin} min'
                  : 'Not available';
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _activeSport = sport);
                  if (court != null && court.slotsAvailableToday > 0) {
                    context.push(
                      AppRoutes.bookVenue(_venue.id),
                      extra: {'sport': sport, 'venue': _venue},
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(_sportIcon(sport), color: sc, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _sportLabels[sport] ?? sport,
                              style: AppTextStyles.headingS(
                                  colors.colorTextPrimary),
                            ),
                            Text(
                              priceLabel,
                              style: AppTextStyles.bodyS(
                                  colors.colorTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2, vertical: 4),
                        decoration: BoxDecoration(
                          color: court != null && court.slotsAvailableToday > 0
                              ? colors.colorSuccess.withValues(alpha: 0.12)
                              : colors.colorSurfaceElevated,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: court != null &&
                                    court.slotsAvailableToday > 0
                                ? colors.colorSuccess.withValues(alpha: 0.3)
                                : colors.colorBorderSubtle,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          court != null && court.slotsAvailableToday > 0
                              ? '${court.slotsAvailableToday} slots'
                              : 'Full',
                          style: AppTextStyles.labelS(
                            court != null && court.slotsAvailableToday > 0
                                ? colors.colorSuccess
                                : colors.colorTextTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final court = _activeCourt;

    // Book button state
    final String bookLabel;
    final bool bookEnabled;
    if (_activeSport.isEmpty) {
      bookLabel = 'Select a Sport to Book';
      bookEnabled = true;
    } else if (court == null) {
      bookLabel = 'Not Available';
      bookEnabled = false;
    } else if (court.slotsAvailableToday == 0) {
      bookLabel = 'No Slots Today';
      bookEnabled = false;
    } else {
      bookLabel = 'Book · ₹${court.pricePerSlot}/slot';
      bookEnabled = true;
    }

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          // ── Hero image area ────────────────────────────────────
          Stack(
            children: [
              CsShimmer(
                child: Container(
                  height: 220 + topPad,
                  width: double.infinity,
                  color: colors.colorSurfaceOverlay,
                ),
              ),
              Container(
                height: 220 + topPad,
                width: double.infinity,
                color: colors.colorSurfaceOverlay.withValues(alpha: 0.85),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: topPad),
                    Text(
                      _venue.name[0],
                      style: AppTextStyles.displayXL(colors.colorBorderMedium),
                    ),
                  ],
                ),
              ),
              // Back button
              Positioned(
                top: topPad + AppSpacing.sm,
                left: AppSpacing.md,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.colorSurfaceOverlay.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: colors.colorBorderSubtle, width: 0.5),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: colors.colorTextPrimary, size: 16),
                  ),
                ),
              ),
              // THE BOX badge
              if (_venue.hasTheBox)
                Positioned(
                  top: topPad + AppSpacing.sm,
                  right: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.colorAccentPrimary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'THE BOX',
                      style: AppTextStyles.overline(colors.colorTextOnAccent),
                    ),
                  ),
                ),
            ],
          ),

          // ── Scrollable content ───────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Venue info ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.lg,
                        AppSpacing.lg, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _venue.name,
                          style: AppTextStyles.displayS(colors.colorTextPrimary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: colors.colorTextSecondary, size: 13),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${_venue.address}  ·  Open till ${_venue.closingTime}',
                                style:
                                    AppTextStyles.bodyS(colors.colorTextSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Directions row
                        GestureDetector(
                          onTap: _launchMaps,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs),
                            child: Row(
                              children: [
                                Icon(Icons.directions_rounded,
                                    size: 14,
                                    color: colors.colorInfo),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Get directions',
                                  style: AppTextStyles.labelS(colors.colorInfo),
                                ),
                                const Spacer(),
                                Icon(Icons.open_in_new_rounded,
                                    size: 12,
                                    color: colors.colorTextTertiary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            _StatPill(
                                value: _venue.rating.toString(),
                                label: 'Rating',
                                colors: colors),
                            const SizedBox(width: AppSpacing.sm),
                            _StatPill(
                                value: _venue.reviewCount.toString(),
                                label: 'Reviews',
                                colors: colors),
                            const SizedBox(width: AppSpacing.sm),
                            _StatPill(
                                value: _venue.sports.length.toString(),
                                label: 'Sports',
                                colors: colors),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  Container(height: 0.5, color: colors.colorBorderSubtle),

                  // ── Sport grid ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: Text(
                      'PICK A SPORT',
                      style: AppTextStyles.overline(colors.colorTextTertiary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: _SportGrid(
                      sports: _venue.sports,
                      venueId: _venue.id,
                      activeSport: _activeSport,
                      onSelect: (sport) =>
                          setState(() => _activeSport = sport),
                      sportColor: _sportColor,
                      sportIcon: _sportIcon,
                      sportLabel: (s) => _sportLabels[s] ?? s,
                      colors: colors,
                    ),
                  ),

                  // ── Court info (when sport selected) ────────
                  if (court != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(height: 0.5, color: colors.colorBorderSubtle),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md,
                          AppSpacing.lg, AppSpacing.md),
                      child: Column(
                        children: [
                          _InfoRow(
                              label: 'Surface',
                              value:
                                  '${court.surface} · ${court.isIndoor ? 'Indoor' : 'Outdoor'}',
                              colors: colors),
                          _InfoRow(
                            label: 'THE BOX',
                            value: court.hasTheBox
                                ? 'Equipped ✓'
                                : 'Not equipped',
                            valueColor: court.hasTheBox
                                ? colors.colorAccentPrimary
                                : colors.colorTextSecondary,
                            colors: colors,
                          ),
                          _InfoRow(
                            label: 'Available today',
                            value: court.slotsAvailableToday == 0
                                ? 'Fully booked'
                                : '${court.slotsAvailableToday} slots',
                            valueColor: court.slotsAvailableToday == 0
                                ? colors.colorError
                                : colors.colorSuccess,
                            colors: colors,
                          ),
                        ],
                      ),
                    ),
                  ],

                  Container(height: 0.5, color: colors.colorBorderSubtle),

                  // ── Amenities ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md,
                        AppSpacing.lg, AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMENITIES',
                          style:
                              AppTextStyles.overline(colors.colorTextTertiary),
                        ),
                        const SizedBox(height: AppSpacing.sm + 2),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _venue.amenities
                              .map((a) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm + 2,
                                        vertical: AppSpacing.xs + 1),
                                    decoration: BoxDecoration(
                                      color: colors.colorSurfaceElevated,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.pill),
                                      border: Border.all(
                                          color: colors.colorBorderSubtle,
                                          width: 0.5),
                                    ),
                                    child: Text(a,
                                        style: AppTextStyles.labelS(
                                            colors.colorTextSecondary)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: botPad + 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Persistent bottom bar ─────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.colorBackgroundPrimary,
          border: Border(
              top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        ),
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md,
            AppSpacing.lg, botPad + AppSpacing.md),
        child: _activeSport.isEmpty
            ? CsButton.secondary(
                label: bookLabel,
                onTap: _handleBookTap,
              )
            : CsButton.primary(
                label: bookLabel,
                onTap: bookEnabled ? _handleBookTap : null,
                isDisabled: !bookEnabled,
              ),
      ),
    );
  }
}

// ── Sport Grid ──────────────────────────────────────────────────

class _SportGrid extends StatelessWidget {
  const _SportGrid({
    required this.sports,
    required this.venueId,
    required this.activeSport,
    required this.onSelect,
    required this.sportColor,
    required this.sportIcon,
    required this.sportLabel,
    required this.colors,
  });

  final List<String> sports;
  final String venueId;
  final String activeSport;
  final ValueChanged<String> onSelect;
  final Color Function(String, AppColorScheme) sportColor;
  final IconData Function(String) sportIcon;
  final String Function(String) sportLabel;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    // Build rows of 2 sport cards each
    final cards = sports.map((sport) {
      final court = FakeData.courtByVenueAndSport(venueId, sport);
      final sc = sportColor(sport, colors);
      final isActive = sport == activeSport;
      final priceLabel = court != null
          ? '₹${court.pricePerSlot} / ${court.slotDurationMin} min'
          : '—';

      return GestureDetector(
        onTap: () => onSelect(sport),
        child: AnimatedContainer(
          duration: AppDuration.fast,
          height: 80,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isActive
                ? sc.withValues(alpha: 0.12)
                : colors.colorSurfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isActive ? sc : colors.colorBorderSubtle,
              width: isActive ? 1.0 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                sportIcon(sport),
                size: 28,
                color: isActive ? sc : colors.colorTextSecondary,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sportLabel(sport),
                      style: AppTextStyles.headingS(
                        isActive ? sc : colors.colorTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priceLabel,
                      style: AppTextStyles.bodyS(colors.colorTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    // Lay out in rows of 2
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      final rowCards = cards.sublist(i, (i + 2).clamp(0, cards.length));
      rows.add(Row(
        children: [
          Expanded(child: rowCards[0]),
          if (rowCards.length > 1) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: rowCards[1]),
          ] else
            const Expanded(child: SizedBox()),
        ],
      ));
      if (i + 2 < cards.length) rows.add(const SizedBox(height: AppSpacing.sm));
    }

    return Column(children: rows);
  }
}

// ── Stat Pill ──────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    required this.colors,
  });
  final String value;
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.headingM(colors.colorTextPrimary)),
          Text(label,
              style: AppTextStyles.labelS(colors.colorTextSecondary)),
        ],
      ),
    );
  }
}

// ── Info Row ────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });
  final String label;
  final String value;
  final AppColorScheme colors;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyM(colors.colorTextSecondary)),
          Text(value,
              style: AppTextStyles.headingS(
                  valueColor ?? colors.colorTextPrimary)),
        ],
      ),
    );
  }
}
