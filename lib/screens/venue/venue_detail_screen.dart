// lib/screens/venue/venue_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';

class VenueDetailScreen extends StatefulWidget {
  const VenueDetailScreen({super.key, required this.venueId});
  final String venueId;

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  late Venue _venue;
  String _activeSport = '';

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
    final topPad = MediaQuery.of(context).padding.top;
    final court = _activeCourt;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          // ── Header image + back ──────────────────────────────
          Stack(
            children: [
              Container(
                height: 220 + topPad,
                width: double.infinity,
                color: AppColors.surfaceHigh,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: topPad),
                    Text(_venue.name[0],
                      style: GoogleFonts.syne(
                        fontSize: 80, fontWeight: FontWeight.w800,
                        color: AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: topPad + 8, left: 14,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white, size: 16),
                  ),
                ),
              ),
              if (_venue.hasTheBox)
                Positioned(
                  top: topPad + 8, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('THE BOX EQUIPPED',
                      style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: AppColors.white, letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Scrollable content ───────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_venue.name,
                          style: GoogleFonts.syne(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppColors.white, letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                              color: AppColors.textSecondaryDark, size: 13),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${_venue.address}  ·  Open till ${_venue.closingTime}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatPill(
                              value: _venue.rating.toString(),
                              label: 'Rating'),
                            const SizedBox(width: 8),
                            _StatPill(
                              value: _venue.reviewCount.toString(),
                              label: 'Reviews'),
                            const SizedBox(width: 8),
                            _StatPill(
                              value: _venue.sports.length.toString(),
                              label: 'Sports'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(height: 0.5, color: AppColors.border),

                  // Sport tabs
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: Text('Select sport',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: _venue.sports.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        const icons = {
                          'basketball': '🏀', 'cricket': '🏏',
                          'badminton': '🏸', 'football': '⚽',
                        };
                        const labels = {
                          'basketball': 'Basketball', 'cricket': 'Box Cricket',
                          'badminton': 'Badminton', 'football': 'Football',
                        };
                        final s = _venue.sports[i];
                        final active = s == _activeSport;
                        return GestureDetector(
                          onTap: () => setState(() => _activeSport = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.red.withValues(alpha: 0.15)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? AppColors.red.withValues(alpha: 0.5)
                                    : AppColors.border,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              '${icons[s] ?? ''} ${labels[s] ?? s}',
                              style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: active
                                    ? AppColors.white
                                    : AppColors.textSecondaryDark,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Court info
                  if (court != null) ...[
                    Container(height: 0.5, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      child: Column(
                        children: [
                          _InfoRow(label: 'Court', value: court.name),
                          _InfoRow(label: 'Surface',
                            value: '${court.surface} · ${court.isIndoor ? 'Indoor' : 'Outdoor'}'),
                          _InfoRow(label: 'Price',
                            value: '₹${court.pricePerSlot} / ${court.slotDurationMin} min'),
                          _InfoRow(
                            label: 'THE BOX',
                            value: court.hasTheBox
                                ? 'Equipped ✓'
                                : 'Not equipped',
                            valueColor: court.hasTheBox
                                ? AppColors.red
                                : AppColors.textSecondaryDark,
                          ),
                          _InfoRow(
                            label: 'Available today',
                            value: court.slotsAvailableToday == 0
                                ? 'Fully booked'
                                : '${court.slotsAvailableToday} slots',
                            valueColor: court.slotsAvailableToday == 0
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ],
                      ),
                    ),
                  ],

                  Container(height: 0.5, color: AppColors.border),

                  // Amenities
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amenities',
                          style: GoogleFonts.syne(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _venue.amenities.map((a) =>
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.border, width: 0.5),
                              ),
                              child: Text(a,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                            ),
                          ).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // space for FAB
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Book button ──────────────────────────────────────────
      floatingActionButton: court != null && court.slotsAvailableToday > 0
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                width: double.infinity,
                child: FloatingActionButton.extended(
                  onPressed: () => context.push(
                    '/book/${court.id}',
                    extra: {'venue': _venue, 'court': court},
                  ),
                  backgroundColor: AppColors.red,
                  label: Text(
                    'Book ${_activeSport == 'basketball' ? '🏀' : _activeSport == 'cricket' ? '🏏' : ''}  ₹${court.pricePerSlot}/slot',
                    style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(value,
            style: GoogleFonts.syne(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 10, color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondaryDark),
          ),
          Text(value,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}