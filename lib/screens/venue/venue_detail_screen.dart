// lib/screens/venue/venue_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';
import '../../widgets/common/cs_shimmer.dart';

class VenueDetailScreen extends StatefulWidget {
  const VenueDetailScreen({super.key, required this.venueId});
  final String venueId;

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  late Venue _venue;
  String _activeSport = '';

  static const _sportIcons = {
    'basketball': '🏀', 'cricket': '🏏',
    'badminton': '🏸', 'football': '⚽',
  };
  static const _sportLabels = {
    'basketball': 'Basketball', 'cricket': 'Box Cricket',
    'badminton': 'Badminton', 'football': 'Football',
  };

  Color _sportColor(String sport) {
    switch (sport) {
      case 'basketball': return AppColors.basketball;
      case 'cricket':    return AppColors.cricket;
      case 'badminton':  return AppColors.badminton;
      default:           return AppColors.football;
    }
  }

  @override
  void initState() {
    super.initState();
    _venue = FakeData.venues.firstWhere(
      (v) => v.id == widget.venueId,
      orElse: () => FakeData.venues.first,
    );
    _activeSport = _venue.sports.first;
  }

  Court? get _activeCourt =>
      FakeData.courtByVenueAndSport(_venue.id, _activeSport);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final court  = _activeCourt;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          // ── Hero image area ──────────────────────────────────
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
                      style: AppTextStyles.displayXL(
                          colors.colorBorderMedium),
                    ),
                  ],
                ),
              ),
              // Back button
              Positioned(
                top: topPad + AppSpacing.sm, left: AppSpacing.md,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: colors.colorSurfaceOverlay
                          .withValues(alpha: 0.85),
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
                  top: topPad + AppSpacing.sm, right: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.colorAccentPrimary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
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
                          style: AppTextStyles.displayS(
                              colors.colorTextPrimary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: colors.colorTextSecondary,
                                size: 13),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${_venue.address}  ·  Open till ${_venue.closingTime}',
                                style: AppTextStyles.bodyS(
                                    colors.colorTextSecondary),
                              ),
                            ),
                          ],
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

                  // ── Sport tabs ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md,
                        AppSpacing.lg, 0),
                    child: Text(
                      'PICK A SPORT',
                      style: AppTextStyles.overline(
                          colors.colorTextTertiary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      itemCount: _venue.sports.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final s      = _venue.sports[i];
                        final active = s == _activeSport;
                        final sc     = _sportColor(s);
                        return GestureDetector(
                          onTap: () => setState(() => _activeSport = s),
                          child: AnimatedContainer(
                            duration: AppDuration.fast,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs + 3),
                            decoration: BoxDecoration(
                              color: active
                                  ? sc.withValues(alpha: 0.14)
                                  : colors.colorSurfaceElevated,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: active ? sc : colors.colorBorderSubtle,
                                width: active ? 1.0 : 0.5,
                              ),
                            ),
                            child: Text(
                              '${_sportIcons[s] ?? ''} ${_sportLabels[s] ?? s}',
                              style: AppTextStyles.labelM(
                                active ? sc : colors.colorTextSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Court info ─────────────────────────────
                  if (court != null) ...[
                    Container(
                        height: 0.5, color: colors.colorBorderSubtle),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md,
                          AppSpacing.lg, AppSpacing.md),
                      child: Column(
                        children: [
                          _InfoRow(
                              label: 'Court',
                              value: court.name,
                              colors: colors),
                          _InfoRow(
                              label: 'Surface',
                              value:
                                  '${court.surface} · ${court.isIndoor ? 'Indoor' : 'Outdoor'}',
                              colors: colors),
                          _InfoRow(
                              label: 'Price',
                              value:
                                  '₹${court.pricePerSlot} / ${court.slotDurationMin} min',
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

                  Container(
                      height: 0.5, color: colors.colorBorderSubtle),

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
                          style: AppTextStyles.overline(
                              colors.colorTextTertiary),
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

      // ── Book CTA ─────────────────────────────────────────────
      floatingActionButton: court != null &&
              court.slotsAvailableToday > 0
          ? Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: FloatingActionButton.extended(
                  onPressed: () => context.push(
                    '/book/${court.id}',
                    extra: {'venue': _venue, 'court': court},
                  ),
                  backgroundColor: colors.colorAccentPrimary,
                  elevation: 0,
                  label: Text(
                    '${_sportIcons[_activeSport] ?? ''}  Book  ·  ₹${court.pricePerSlot}/slot',
                    style: AppTextStyles.headingS(
                        colors.colorTextOnAccent),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────

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

// ── Info Row ─────────────────────────────────────────────────

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
