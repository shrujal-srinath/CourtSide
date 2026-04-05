// lib/screens/home/home_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import '../../core/app_spacing.dart';
import '../../core/app_gradients.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../providers/auth_provider.dart';

// ── Sport config ────────────────────────────────────────────────

class _Sport {
  const _Sport(this.id, this.label, this.emoji);
  final String id;
  final String label;
  final String emoji;
}

const _sports = [
  _Sport('basketball', 'Basketball', '🏀'),
  _Sport('cricket',    'Box Cricket', '🏏'),
  _Sport('badminton',  'Badminton',   '🏸'),
  _Sport('football',   'Football',    '⚽'),
];

// ═══════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  String? _activeSport;
  Set<Marker> _markers = {};
  bool _locationLoading = true;
  late AnimationController _pulseController;

  static const _bengaluru = LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Location ─────────────────────────────────────────────────

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _useFallback();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _locationLoading = false;
      });
      _buildMarkers();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 13),
      );
    } catch (e) {
      _useFallback();
    }
  }

  void _useFallback() {
    if (!mounted) return;
    setState(() {
      _userLocation = _bengaluru;
      _locationLoading = false;
    });
    _buildMarkers();
  }

  // ── Markers ──────────────────────────────────────────────────

  void _buildMarkers() {
    final venues = _activeSport == null
        ? FakeData.venues
        : FakeData.venuesBySport(_activeSport!);

    setState(() {
      _markers = venues.map((v) => Marker(
        markerId: MarkerId(v.id),
        position: LatLng(v.lat, v.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: v.name, snippet: v.area),
        onTap: () => _showVenueSheet(v),
      )).toSet();
    });
  }

  // ── Map style ────────────────────────────────────────────────

  Future<void> _onMapCreated(GoogleMapController c) async {
    _mapController = c;
    try {
      final style = await rootBundle.loadString('assets/map_style_dark.json');
      c.setMapStyle(style);
    } catch (e) {
      // fallback to default style
    }
    if (_userLocation != null) {
      c.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 13));
    }
  }

  // ── Sport selection ──────────────────────────────────────────

  void _selectSport(String sport) {
    context.push(AppRoutes.sportById(sport));
  }

  // ── Venue bottom sheet ────────────────────────────────────────

  void _showVenueSheet(Venue venue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => _MapVenueSheet(venue: venue),
    );
  }

  // ── Greeting ─────────────────────────────────────────────────

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final user = ref.watch(currentUserProvider);
    final name = user?.userMetadata?['full_name'] as String? ?? 'Player';
    final firstName = name.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          _Header(
            firstName: firstName,
            topPad: topPad,
            greeting: _greeting(),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Live Now Strip ───────────────────────────
                  _LiveNowStrip(pulseController: _pulseController),

                  const SizedBox(height: 16),

                  // ── Map ──────────────────────────────────────
                  _MapSection(
                    userLocation: _userLocation,
                    markers: _markers,
                    loading: _locationLoading,
                    onMapCreated: _onMapCreated,
                    onExpand: () {},
                    onRecenter: () {
                      if (_userLocation != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(_userLocation!, 14),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── Sport chips ──────────────────────────────
                  _SportChipRow(
                    activeSport: _activeSport,
                    onSelect: _selectSport,
                  ),

                  const SizedBox(height: 4),

                  // ── Courts near you ──────────────────────────
                  _SectionHeader(
                    title: 'Courts Near You',
                    onSeeAll: () => context.push('/explore'),
                  ),
                  _CourtsNearYou(
                    venues: FakeData.venues,
                    onVenueTap: (v) =>
                        context.push(AppRoutes.venueById(v.id)),
                  ),

                  const SizedBox(height: 20),

                  // ── Community Feed ───────────────────────────
                  _SectionHeader(
                    title: 'Activity',
                    onSeeAll: () {},
                  ),
                  _CommunityFeed(
                    bookings: FakeData.bookingHistory
                        .where((b) => b.hasStats)
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  // ── Promo tiles ──────────────────────────────
                  _PromoTiles(),

                  const SizedBox(height: 100),
                ],
              ),
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
    required this.firstName,
    required this.topPad,
    required this.greeting,
  });

  final String firstName;
  final double topPad;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(18, topPad + 8, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
                    style: AppTextStyles.headingM(AppColors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTextStyles.bodyS(AppColors.textSecondaryDark),
                    ),
                    Text(
                      firstName,
                      style: AppTextStyles.headingL(AppColors.textPrimaryDark),
                    ),
                  ],
                ),
              ),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('7', style: AppTextStyles.labelM(AppColors.warning)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Notification bell
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search bar
          GestureDetector(
            onTap: () => context.push('/explore'),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.textSecondaryDark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search venues, courts, areas...',
                      style: AppTextStyles.bodyM(AppColors.textSecondaryDark),
                    ),
                  ),
                  const Icon(Icons.mic_none_rounded,
                      color: AppColors.textTertiaryDark, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LIVE NOW STRIP
// ═══════════════════════════════════════════════════════════════

class _LiveNowStrip extends StatelessWidget {
  const _LiveNowStrip({required this.pulseController});
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    final games = FakeData.pickupGames;
    if (games.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: pulseController,
                builder: (c, ch) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.red.withValues(
                        alpha: 0.4 + pulseController.value * 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text('LIVE NOW', style: AppTextStyles.overline(AppColors.red)),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: games.length,
            separatorBuilder: (c, i) => const SizedBox(width: 10),
            itemBuilder: (c, i) {
              final g = games[i];
              final sportEmoji = g.sport == 'basketball'
                  ? '🏀'
                  : g.sport == 'cricket'
                      ? '🏏'
                      : '🏸';
              final gradient = AppGradients.forSport(g.sport);
              return Container(
                width: 200,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(sportEmoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            g.venueName,
                            style: AppTextStyles.headingS(AppColors.textPrimaryDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${g.spotsTotal - g.spotsFilled} spots left',
                            style: AppTextStyles.overline(AppColors.success),
                          ),
                        ),
                        const Spacer(),
                        Text(g.time,
                            style: AppTextStyles.bodyS(AppColors.textSecondaryDark)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAP SECTION
// ═══════════════════════════════════════════════════════════════

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.userLocation,
    required this.markers,
    required this.loading,
    required this.onMapCreated,
    required this.onExpand,
    required this.onRecenter,
  });

  final LatLng? userLocation;
  final Set<Marker> markers;
  final bool loading;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onExpand;
  final VoidCallback onRecenter;

  static const _bengaluru = LatLng(12.9716, 77.5946);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: SizedBox(
          height: 200,
          child: Stack(
            children: [
              // Map
              AbsorbPointer(
                absorbing: true,
                child: GoogleMap(
                  onMapCreated: onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: userLocation ?? _bengaluru,
                    zoom: 13,
                  ),
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                ),
              ),

              // Loading overlay
              if (loading)
                Container(
                  color: AppColors.black.withValues(alpha: 0.6),
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.red, strokeWidth: 2),
                  ),
                ),

              // Expand button — glassmorphic
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onExpand,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        color: AppColors.black.withValues(alpha: 0.5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_full_rounded,
                                color: AppColors.white, size: 12),
                            const SizedBox(width: 5),
                            Text('Expand',
                                style: AppTextStyles.labelS(AppColors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Recenter button — glassmorphic
              Positioned(
                bottom: 12,
                left: 12,
                child: GestureDetector(
                  onTap: onRecenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 34,
                        height: 34,
                        color: AppColors.black.withValues(alpha: 0.5),
                        child: const Icon(Icons.my_location_rounded,
                            color: AppColors.white, size: 16),
                      ),
                    ),
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

// ═══════════════════════════════════════════════════════════════
//  SPORT CHIP ROW
// ═══════════════════════════════════════════════════════════════

class _SportChipRow extends StatelessWidget {
  const _SportChipRow({
    required this.activeSport,
    required this.onSelect,
  });

  final String? activeSport;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Text(
            'PICK A SPORT',
            style: AppTextStyles.overline(AppColors.textSecondaryDark),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _sports.length,
            separatorBuilder: (c, i) => const SizedBox(width: 8),
            itemBuilder: (c, i) {
              final sport = _sports[i];
              final active = sport.id == activeSport;
              return GestureDetector(
                onTap: () => onSelect(sport.id),
                child: AnimatedContainer(
                  duration: AppDuration.fast,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.red : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: active ? AppColors.red : AppColors.border,
                      width: 0.5,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.red.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sport.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        sport.label,
                        style: AppTextStyles.labelM(
                          active
                              ? AppColors.white
                              : AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  COURTS NEAR YOU
// ═══════════════════════════════════════════════════════════════

class _CourtsNearYou extends StatelessWidget {
  const _CourtsNearYou({
    required this.venues,
    required this.onVenueTap,
  });

  final List<Venue> venues;
  final ValueChanged<Venue> onVenueTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: venues.length,
        separatorBuilder: (c, i) => const SizedBox(width: 12),
        itemBuilder: (c, i) {
          final v = venues[i];
          return _CourtCard(venue: v, onTap: () => onVenueTap(v));
        },
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({required this.venue, required this.onTap});
  final Venue venue;
  final VoidCallback onTap;

  Color _sportColor(String sport) {
    switch (sport) {
      case 'basketball': return AppColors.basketball;
      case 'cricket': return AppColors.cricket;
      case 'badminton': return AppColors.badminton;
      default: return AppColors.football;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            const BoxShadow(
              color: Color(0xFF000000),
              blurRadius: 20,
              offset: Offset(0, 8),
              spreadRadius: -4,
            ),
            const BoxShadow(
              color: Color(0x1AE8112D),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo placeholder with shimmer
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card)),
              child: Stack(
                children: [
                  Shimmer.fromColors(
                    baseColor: AppColors.surfaceHigh,
                    highlightColor: AppColors.overlay,
                    child: Container(
                      height: 96,
                      width: double.infinity,
                      color: AppColors.surfaceHigh,
                    ),
                  ),
                  // Letter placeholder over shimmer
                  Container(
                    height: 96,
                    width: double.infinity,
                    color: AppColors.surfaceHigh.withValues(alpha: 0.8),
                    child: Center(
                      child: Text(
                        venue.name[0],
                        style: AppTextStyles.displayL(
                            AppColors.border),
                      ),
                    ),
                  ),
                  // THE BOX badge
                  if (venue.hasTheBox)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'THE BOX',
                          style: AppTextStyles.overline(AppColors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: AppTextStyles.headingS(AppColors.textPrimaryDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${venue.area}  ·  ${venue.rating} ★',
                    style: AppTextStyles.bodyS(AppColors.textSecondaryDark),
                  ),
                  const SizedBox(height: 8),
                  // Sport colored dots
                  Row(
                    children: [
                      ...venue.sports.take(3).map((s) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _sportColor(s),
                            ),
                          )),
                      const Spacer(),
                      Text(
                        'Tap to book',
                        style: AppTextStyles.overline(AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  COMMUNITY FEED
// ═══════════════════════════════════════════════════════════════

class _CommunityFeed extends StatelessWidget {
  const _CommunityFeed({required this.bookings});
  final List<BookingRecord> bookings;

  String _sportEmoji(String sport) {
    switch (sport) {
      case 'basketball': return '🏀';
      case 'cricket': return '🏏';
      default: return '🏸';
    }
  }

  String _timeAgo(String date) => '2h ago'; // fake for now

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: bookings.take(3).map((b) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.red.withValues(alpha: 0.15),
                    border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      'S',
                      style: AppTextStyles.headingS(AppColors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'You',
                            style: AppTextStyles.headingS(AppColors.textPrimaryDark),
                          ),
                          Text(
                            ' played ${b.sport} at',
                            style: AppTextStyles.bodyS(AppColors.textSecondaryDark),
                          ),
                        ],
                      ),
                      Text(
                        b.venueName,
                        style: AppTextStyles.bodyS(AppColors.textPrimaryDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Mini stat row
                      if (b.sport == 'basketball')
                        Row(
                          children: [
                            _MiniStat(label: 'PTS', value: '18'),
                            const SizedBox(width: 12),
                            _MiniStat(label: 'REB', value: '7'),
                            const SizedBox(width: 12),
                            _MiniStat(label: 'AST', value: '4'),
                          ],
                        )
                      else
                        Row(
                          children: [
                            _MiniStat(label: 'RUNS', value: '42'),
                            const SizedBox(width: 12),
                            _MiniStat(label: 'SR', value: '138'),
                            const SizedBox(width: 12),
                            _MiniStat(label: 'WKT', value: '2'),
                          ],
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _timeAgo(b.date),
                      style: AppTextStyles.bodyS(AppColors.textTertiaryDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sportEmoji(b.sport),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.headingS(AppColors.textPrimaryDark)),
        Text(label, style: AppTextStyles.overline(AppColors.textTertiaryDark)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PROMO TILES
// ═══════════════════════════════════════════════════════════════

class _PromoTiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: _PromoTile(
              emoji: '🏟️',
              sport: 'football',
              title: 'List your venue',
              subtitle: 'Register your turf on Courtside',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PromoTile(
              emoji: '📊',
              sport: 'basketball',
              title: 'THE BOX',
              subtitle: 'Live stats for your games',
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({
    required this.emoji,
    required this.sport,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String sport;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppGradients.forSport(sport),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.textTertiaryDark, size: 12),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTextStyles.headingS(AppColors.textPrimaryDark),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: AppTextStyles.bodyS(AppColors.textSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.headingM(AppColors.textPrimaryDark)),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: AppTextStyles.bodyS(AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAP VENUE SHEET
// ═══════════════════════════════════════════════════════════════

class _MapVenueSheet extends StatelessWidget {
  const _MapVenueSheet({required this.venue});
  final Venue venue;

  static const _sportLabels = {
    'basketball': '🏀',
    'cricket': '🏏',
    'badminton': '🏸',
    'football': '⚽',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
        border: const Border(
            top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name,
                            style: AppTextStyles.displayS(AppColors.textPrimaryDark),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${venue.area}  ·  Open till ${venue.closingTime}  ·  ${venue.rating} ★',
                            style: AppTextStyles.bodyS(AppColors.textSecondaryDark),
                          ),
                        ],
                      ),
                    ),
                    if (venue.hasTheBox)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.3),
                              width: 0.5),
                        ),
                        child: Text('THE BOX',
                            style: AppTextStyles.overline(AppColors.red)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: venue.sports.map((s) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.sportById(s));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: AppColors.border, width: 0.5),
                        ),
                        child: Text(
                          '${_sportLabels[s] ?? ''} $s',
                          style: AppTextStyles.labelM(AppColors.textPrimaryDark),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.venueById(venue.id));
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Center(
                            child: Text(
                              'Book a slot',
                              style: AppTextStyles.headingS(AppColors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.venueById(venue.id));
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: AppColors.border, width: 0.5),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
