// lib/screens/venue/venue_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String _activeSport = '';
  late ScrollController _scrollController;
  bool _isCollapsed = false;

  static const _sportLabels = {
    'basketball': 'Basketball',
    'cricket': 'Box Cricket',
    'badminton': 'Badminton',
    'football': 'Football',
  };

  static const Map<String, List<String>> _sportRules = {
    'basketball': [
      'Non-marking shoes are compulsory on court',
      'Max 5 players per team (full court)',
      'Ball available on rent at reception',
      'Sleeveless jerseys must have an inner T-shirt',
    ],
    'cricket': [
      'Synthetic / tennis balls only — no leather',
      'Batting pads and helmets are provided',
      'Max 6 players per side (box cricket format)',
      'Metal spike footwear is not permitted indoors',
    ],
    'badminton': [
      'Non-marking shoes are compulsory on court',
      'Shuttlecocks available on rent at reception',
      'Max 2 players per court for singles play',
      'Rackets available for rent at reception',
    ],
    'football': [
      'Rubber-stud boots only — no metal studs',
      'Max 5 players per side (futsal format)',
      'Match ball provided by the venue',
      'Sliding tackles are prohibited on turf courts',
    ],
  };

  static const Map<String, IconData> _amenityIcons = {
    'Parking': Icons.local_parking_rounded,
    'Restrooms': Icons.wc_rounded,
    'Changing Rooms': Icons.door_back_door_rounded,
    'Drinking Water': Icons.water_drop_rounded,
    'First Aid': Icons.medical_services_rounded,
    'Floodlights': Icons.light_mode_rounded,
    'AC': Icons.ac_unit_rounded,
    'Water': Icons.water_drop_rounded,
    'Cafe': Icons.local_cafe_rounded,
    'Locker': Icons.lock_rounded,
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
    _scrollController = ScrollController()
      ..addListener(() {
        final collapsed = _scrollController.offset > 220;
        if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Court? get _activeCourt => _activeSport.isEmpty
      ? null
      : FakeData.courtByVenueAndSport(_venue.id, _activeSport);

  Future<void> _openInMaps() async {
    final uri = Uri.parse(
      'https://maps.google.com/maps?q=${_venue.lat},${_venue.lng}(${Uri.encodeComponent(_venue.name)})',
    );
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: colors.colorBorderMedium, borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('PICK A SPORT', style: AppTextStyles.overline(colors.colorTextTertiary)),
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
                    context.push(AppRoutes.bookVenue(_venue.id), extra: {'sport': sport, 'venue': _venue});
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Icon(_sportIcon(sport), color: sc, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_sportLabels[sport] ?? sport, style: AppTextStyles.headingS(colors.colorTextPrimary)),
                            Text(priceLabel, style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 4),
                        decoration: BoxDecoration(
                          color: court != null && court.slotsAvailableToday > 0
                              ? colors.colorSuccess.withValues(alpha: 0.12)
                              : colors.colorSurfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: court != null && court.slotsAvailableToday > 0
                                ? colors.colorSuccess.withValues(alpha: 0.3)
                                : colors.colorBorderSubtle,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          court != null && court.slotsAvailableToday > 0 ? '${court.slotsAvailableToday} slots' : 'Full',
                          style: AppTextStyles.labelS(
                            court != null && court.slotsAvailableToday > 0 ? colors.colorSuccess : colors.colorTextTertiary,
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
    final botPad = MediaQuery.of(context).padding.bottom;
    final court = _activeCourt;

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
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Collapsing hero ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: colors.colorBackgroundPrimary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isCollapsed
                        ? Colors.transparent
                        : colors.colorSurfaceOverlay.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                    border: _isCollapsed
                        ? null
                        : Border.all(color: colors.colorBorderSubtle, width: 0.5),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.colorTextPrimary, size: 18),
                ),
              ),
            ),
            title: AnimatedOpacity(
              opacity: _isCollapsed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Text(_venue.name, style: AppTextStyles.headingS(colors.colorTextPrimary)),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _isCollapsed
                          ? Colors.transparent
                          : colors.colorSurfaceOverlay.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.share_outlined, color: colors.colorTextPrimary, size: 18),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHeroBackground(colors),
            ),
          ),

          // ── Scrollable content ────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card: hours + address + Show in Maps
                _buildInfoCard(colors),

                // Stats strip
                _buildStatsStrip(colors),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(height: 0.5, color: colors.colorBorderSubtle),
                ),

                // Sport picker
                const _SectionHeader(title: 'PICK A SPORT'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _SportGrid(
                    sports: _venue.sports,
                    venueId: _venue.id,
                    activeSport: _activeSport,
                    onSelect: (sport) => setState(() => _activeSport = sport),
                    sportColor: _sportColor,
                    sportIcon: _sportIcon,
                    sportLabel: (s) => _sportLabels[s] ?? s,
                    colors: colors,
                  ),
                ),

                // Facility info — only shown when sport selected
                if (court != null) ...[
                  const _SectionHeader(title: 'FACILITY INFO'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildFacilityInfo(colors, court),
                  ),
                ],

                // Amenities
                const _SectionHeader(title: 'AMENITIES'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _buildAmenities(colors),
                ),

                // About this sport (rules) — shown when sport selected
                if (_activeSport.isNotEmpty && _sportRules.containsKey(_activeSport)) ...[
                  _SectionHeader(
                    title: 'ABOUT ${(_sportLabels[_activeSport] ?? _activeSport).toUpperCase()} HERE',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildSportRules(colors),
                  ),
                ],

                // Location
                const _SectionHeader(title: 'LOCATION'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _buildLocationCard(colors),
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),

      // ── Fixed CTA ──────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          border: Border(top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: colors.colorBackgroundPrimary.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CsButton.primary(label: bookLabel, onTap: bookEnabled ? _handleBookTap : null),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Want to organise a game here?  ', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.hostGame, extra: {'venueId': _venue.id, 'venueName': _venue.name}),
                  child: Text('Create game →',
                      style: AppTextStyles.bodyS(colors.colorAccentPrimary).copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero background ─────────────────────────────────────────

  Widget _buildHeroBackground(AppColorScheme colors) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo or gradient fallback
        Container(
          decoration: BoxDecoration(
            image: _venue.photoUrl.isNotEmpty
                ? DecorationImage(image: NetworkImage(_venue.photoUrl), fit: BoxFit.cover)
                : null,
            gradient: _venue.photoUrl.isEmpty
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.colorSurfaceOverlay, colors.colorSurfaceElevated],
                  )
                : null,
          ),
        ),
        // Faint sport icon watermark when no photo
        if (_venue.photoUrl.isEmpty)
          Positioned(
            right: -30, top: -20,
            child: Icon(
              _venue.sports.isNotEmpty ? _sportIcon(_venue.sports.first) : Icons.sports,
              size: 220,
              color: colors.colorBorderSubtle.withValues(alpha: 0.25),
            ),
          ),
        // Bottom gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                colors.colorBackgroundPrimary.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        // Bottom info overlay
        Positioned(
          bottom: 20, left: 20, right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_venue.hasTheBox)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.colorAccentPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('THE BOX',
                      style: AppTextStyles.labelS(colors.colorTextOnAccent).copyWith(letterSpacing: 1)),
                ),
              Text(_venue.name, style: AppTextStyles.displayM(colors.colorTextPrimary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, color: colors.colorAccentPrimary, size: 14),
                  const SizedBox(width: 4),
                  Text(_venue.area, style: AppTextStyles.bodyM(colors.colorTextSecondary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.colorSurfaceOverlay.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: colors.colorWarning, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_venue.rating}  (${_venue.reviewCount})',
                          style: AppTextStyles.labelS(colors.colorTextPrimary),
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
    );
  }

  // ── Info card: hours + address + Show in Maps ───────────────

  Widget _buildInfoCard(AppColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operating hours row
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: colors.colorTextTertiary, size: 16),
              const SizedBox(width: 10),
              Text(
                '${_venue.openingTime} – ${_venue.closingTime}',
                style: AppTextStyles.headingS(colors.colorTextPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_venue.isIndoor ? colors.colorInfo : colors.colorSuccess).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: (_venue.isIndoor ? colors.colorInfo : colors.colorSuccess).withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _venue.isIndoor ? 'INDOOR' : 'OUTDOOR',
                  style: AppTextStyles.labelS(
                    _venue.isIndoor ? colors.colorInfo : colors.colorSuccess,
                  ).copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: colors.colorBorderSubtle),
          const SizedBox(height: 12),
          // Full address row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded, color: colors.colorTextTertiary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _venue.address,
                  style: AppTextStyles.bodyM(colors.colorTextSecondary).copyWith(height: 1.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Show in Maps button
          GestureDetector(
            onTap: _openInMaps,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: colors.colorSurfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: colors.colorBorderMedium, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4285F4),
                    ),
                    child: const Icon(Icons.map_rounded, color: Colors.white, size: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Show in Maps',
                    style: AppTextStyles.bodyM(colors.colorTextPrimary)
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.open_in_new_rounded, color: colors.colorTextTertiary, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats strip ─────────────────────────────────────────────

  Widget _buildStatsStrip(AppColorScheme colors) {
    final totalGames = (_venue.reviewCount * 1.8).round();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                value: '${_venue.rating}',
                label: '${_venue.reviewCount} ratings',
                icon: Icons.star_rounded,
                iconColor: colors.colorWarning,
                colors: colors,
              ),
            ),
            VerticalDivider(color: colors.colorBorderSubtle, width: 1, indent: 6, endIndent: 6),
            Expanded(
              child: _StatCell(
                value: _formatCount(totalGames),
                label: 'Games Played',
                icon: Icons.sports_rounded,
                iconColor: colors.colorAccentPrimary,
                colors: colors,
              ),
            ),
            VerticalDivider(color: colors.colorBorderSubtle, width: 1, indent: 6, endIndent: 6),
            Expanded(
              child: _StatCell(
                value: '${_venue.sports.length}',
                label: _venue.sports.length == 1 ? 'Sport' : 'Sports',
                icon: Icons.category_rounded,
                iconColor: colors.colorInfo,
                colors: colors,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Facility info ───────────────────────────────────────────

  Widget _buildFacilityInfo(AppColorScheme colors, Court court) {
    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'Surface',
            value: '${court.surface} · ${court.isIndoor ? 'Indoor' : 'Outdoor'}',
            colors: colors,
          ),
          Container(height: 0.5, color: colors.colorBorderSubtle, margin: const EdgeInsets.symmetric(horizontal: 16)),
          _InfoRow(
            label: 'THE BOX Hardware',
            value: court.hasTheBox ? 'Equipped ✓' : 'Not equipped',
            valueColor: court.hasTheBox ? colors.colorAccentPrimary : colors.colorTextSecondary,
            colors: colors,
          ),
          Container(height: 0.5, color: colors.colorBorderSubtle, margin: const EdgeInsets.symmetric(horizontal: 16)),
          _InfoRow(
            label: 'Available Today',
            value: court.slotsAvailableToday == 0 ? 'Fully Booked' : '${court.slotsAvailableToday} Slots',
            valueColor: court.slotsAvailableToday == 0 ? colors.colorError : colors.colorSuccess,
            colors: colors,
          ),
        ],
      ),
    );
  }

  // ── Amenities ───────────────────────────────────────────────

  Widget _buildAmenities(AppColorScheme colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _venue.amenities.map((a) {
        final icon = _amenityIcons[a] ?? Icons.check_circle_outline_rounded;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.colorAccentPrimary, size: 14),
              const SizedBox(width: 6),
              Text(a, style: AppTextStyles.bodyM(colors.colorTextSecondary).copyWith(fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Sport rules ─────────────────────────────────────────────

  Widget _buildSportRules(AppColorScheme colors) {
    final rules = _sportRules[_activeSport] ?? [];
    final sc = _sportColor(_activeSport, colors);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(rules.length, (i) => Padding(
          padding: EdgeInsets.only(bottom: i < rules.length - 1 ? 12 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6, height: 6,
                decoration: BoxDecoration(color: sc, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rules[i],
                  style: AppTextStyles.bodyM(colors.colorTextSecondary).copyWith(height: 1.45),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  // ── Location card with Show in Maps ─────────────────────────

  Widget _buildLocationCard(AppColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map preview placeholder
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: colors.colorSurfaceElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Grid lines for map feel
                CustomPaint(
                  size: const Size(double.infinity, 160),
                  painter: _MapGridPainter(color: colors.colorBorderSubtle),
                ),
                // Location pin
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_rounded, color: colors.colorAccentPrimary, size: 40),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.colorSurfaceOverlay,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
                      ),
                      child: Text(
                        _venue.area,
                        style: AppTextStyles.labelS(colors.colorTextSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Address + MAPS button row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_venue.name, style: AppTextStyles.headingS(colors.colorTextPrimary)),
                      const SizedBox(height: 3),
                      Text(
                        _venue.address,
                        style: AppTextStyles.bodyS(colors.colorTextSecondary).copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _openInMaps,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation_rounded, color: Color(0xFF4285F4), size: 14),
                        const SizedBox(width: 5),
                        Text('MAPS', style: AppTextStyles.labelS(const Color(0xFF4285F4))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ── Map grid painter ──────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  final Color color;
  const _MapGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => old.color != color;
}

// ── Stat cell ─────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.colors,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.headingM(colors.colorTextPrimary)),
        Text(label, style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 10)),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 24, AppSpacing.lg, 12),
      child: Text(title, style: AppTextStyles.overline(context.colors.colorTextTertiary)),
    );
  }
}

// ── Sport grid ────────────────────────────────────────────────

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
        final court = FakeData.courtByVenueAndSport(venueId, sport);
        return GestureDetector(
          onTap: () => onSelect(sport),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.08) : colors.colorSurfacePrimary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? color : colors.colorBorderSubtle,
                width: selected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(sportIcon(sport), color: selected ? color : colors.colorTextSecondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(sportLabel(sport),
                          style: AppTextStyles.headingS(selected ? colors.colorTextPrimary : colors.colorTextSecondary)),
                      if (court != null)
                        Text(
                          '₹${court.pricePerSlot}/${court.slotDurationMin}min',
                          style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 10),
                        ),
                    ],
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

// ── Info row ──────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor, required this.colors});
  final String label;
  final String value;
  final Color? valueColor;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyM(colors.colorTextSecondary)),
          Text(value, style: AppTextStyles.headingS(valueColor ?? colors.colorTextPrimary)),
        ],
      ),
    );
  }
}
