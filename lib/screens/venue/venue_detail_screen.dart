// lib/screens/venue/venue_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../widgets/common/cs_button.dart';

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
              // Hero Image
              Container(
                height: 280 + topPad,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: _venue.photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_venue.photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: _venue.photoUrl.isEmpty
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.colorSurfaceOverlay,
                            colors.colorSurfacePrimary,
                          ],
                        )
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.colorBackgroundPrimary.withValues(alpha: 0.3),
                        Colors.transparent,
                        colors.colorBackgroundPrimary.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),

              // Back button
              Positioned(
                top: topPad + 12,
                left: 16,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.colorSurfaceOverlay.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: colors.colorBorderSubtle, width: 0.5),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: colors.colorTextPrimary, size: 18),
                  ),
                ),
              ),

              // Bottom details in Hero
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_venue.hasTheBox)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.colorAccentPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'THE BOX',
                          style: AppTextStyles.labelS(colors.colorTextOnAccent)
                              .copyWith(letterSpacing: 1),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      _venue.name,
                      style: AppTextStyles.displayM(colors.colorTextPrimary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: colors.colorAccentPrimary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _venue.area,
                          style: AppTextStyles.bodyM(colors.colorTextSecondary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.colorSurfaceOverlay
                                .withValues(alpha: 0.6),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                                color: colors.colorBorderSubtle, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: colors.colorWarning, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${_venue.rating}',
                                style: AppTextStyles.labelS(
                                    colors.colorTextPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Scrollable content ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Container(height: 0.5, color: colors.colorBorderSubtle),

                  // ── Sport grid ─────────────────────────────
                  const _SectionHeader(title: 'PICK A SPORT'),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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

                  if (court != null) ...[
                    const _SectionHeader(title: 'FACILITY INFO'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        children: [
                          _InfoRow(
                              label: 'Surface',
                              value: '${court.surface} · ${court.isIndoor ? 'Indoor' : 'Outdoor'}',
                              colors: colors),
                          _InfoRow(
                            label: 'THE BOX',
                            value: court.hasTheBox ? 'Equipped ✓' : 'Not equipped',
                            valueColor: court.hasTheBox
                                ? colors.colorAccentPrimary
                                : colors.colorTextSecondary,
                            colors: colors,
                          ),
                          _InfoRow(
                            label: 'Available Today',
                            value: court.slotsAvailableToday == 0
                                ? 'Fully Booked'
                                : '${court.slotsAvailableToday} Slots',
                            valueColor: court.slotsAvailableToday == 0
                                ? colors.colorError
                                : colors.colorSuccess,
                            colors: colors,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const _SectionHeader(title: 'AMENITIES'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Parking',
                        'Restrooms',
                        'Changing Rooms',
                        'Drinking Water',
                        'First Aid',
                      ].map((a) => _AmenityTag(label: a, colors: colors)).toList(),
                    ),
                  ),

                  const _SectionHeader(title: 'LOCATION'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: colors.colorSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border:
                            Border.all(color: colors.colorBorderSubtle, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          'MAP PLACEHOLDER\n${_venue.lat}, ${_venue.lng}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyS(colors.colorTextTertiary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Fixed CTA Button ────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + botPad),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          border: Border(
              top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: colors.colorBackgroundPrimary.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: CsButton.primary(
          label: bookLabel,
          onTap: bookEnabled ? _handleBookTap : null,
        ),
      ),
    );
  }
}

// ── Shared Subview Components ──────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 24, AppSpacing.lg, 12),
      child: Text(
        title,
        style: AppTextStyles.overline(context.colors.colorTextTertiary),
      ),
    );
  }
}

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
  final Function(String) onSelect;
  final Color Function(String, AppColorScheme) sportColor;
  final IconData Function(String) sportIcon;
  final String Function(String) sportLabel;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: sports.length,
      itemBuilder: (context, i) {
        final sport = sports[i];
        final selected = activeSport == sport;
        final color = sportColor(sport, colors);

        return GestureDetector(
          onTap: () => onSelect(sport),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.08)
                  : colors.colorSurfacePrimary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? color : colors.colorBorderSubtle,
                width: selected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(sportIcon(sport),
                    color: selected ? color : colors.colorTextSecondary,
                    size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sportLabel(sport),
                    style: AppTextStyles.headingS(selected
                        ? colors.colorTextPrimary
                        : colors.colorTextSecondary),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: color, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.label,
      required this.value,
      this.valueColor,
      required this.colors});
  final String label;
  final String value;
  final Color? valueColor;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyM(colors.colorTextSecondary)),
          Text(value,
              style: AppTextStyles.headingS(
                  valueColor ?? colors.colorTextPrimary)),
        ],
      ),
    );
  }
}

class _AmenityTag extends StatelessWidget {
  const _AmenityTag({required this.label, required this.colors});
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.colorBackgroundPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelS(colors.colorTextSecondary),
      ),
    );
  }
}
