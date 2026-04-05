// lib/screens/home/home_screen.dart

import 'dart:math' as math;
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
  GoogleMapController? _expandedMapController;
  LatLng? _userLocation;
  String? _activeSport;
  Set<Marker> _markers = {};
  bool _locationLoading = true;
  bool _mapExpanded = false;
  String _mapFilter = 'all';
  double _radiusKm = 2.0;
  String? _mapStyle;
  Venue? _selectedVenue;
  Venue? _displayedVenue; // cached for slide-out animation
  late AnimationController _pulseController;

  static const _bengaluru = LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _loadMapStyle();
    _initLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _expandedMapController?.dispose();
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
      final rawPos = LatLng(pos.latitude, pos.longitude);
      final cameraTarget = _isInIndia(rawPos) ? rawPos : _bengaluru;
      setState(() {
        _userLocation = cameraTarget;
        _locationLoading = false;
      });
      _buildMarkersFiltered(_mapFilter);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(cameraTarget, 13),
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
    _buildMarkersFiltered(_mapFilter);
  }

  // ── Helpers ───────────────────────────────────────────────────

  bool _isInIndia(LatLng pos) {
    return pos.latitude >= 8.0 &&
        pos.latitude <= 37.0 &&
        pos.longitude >= 68.0 &&
        pos.longitude <= 97.0;
  }

  double _toRad(double deg) => deg * math.pi / 180.0;

  double _haversineKm(LatLng a, LatLng b) {
    const earthR = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(a.latitude)) *
            math.cos(_toRad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthR * 2 * math.asin(math.sqrt(h));
  }

  // ── Markers ──────────────────────────────────────────────────

  void _buildMarkersFiltered(String filter) {
    final markers = <Marker>[];
    final loc = _userLocation;
    final hasRadius = loc != null && _radiusKm != double.infinity;

    // ── Candidate venues ─────────────────────────────────────
    List<Venue> candidates;
    if (filter == 'pickup' || filter == 'community') {
      candidates = FakeData.pickupGames
          .map((g) => FakeData.venues.firstWhere((v) => v.id == g.venueId))
          .toSet()
          .toList();
    } else {
      candidates = filter == 'all'
          ? FakeData.venues
          : FakeData.venuesBySport(filter);
    }

    // ── Apply radius filter ───────────────────────────────────
    final inRadius = hasRadius
        ? candidates
            .where((v) =>
                _haversineKm(loc, LatLng(v.lat, v.lng)) <= _radiusKm)
            .toSet()
        : candidates.toSet();

    // ── Build markers ─────────────────────────────────────────
    if (filter == 'pickup' || filter == 'community') {
      for (final g in FakeData.pickupGames) {
        final venue =
            inRadius.where((v) => v.id == g.venueId).firstOrNull;
        if (venue == null) continue;
        markers.add(Marker(
          markerId: MarkerId('pickup_${g.id}'),
          position: LatLng(venue.lat, venue.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              filter == 'pickup'
                  ? BitmapDescriptor.hueAzure
                  : BitmapDescriptor.hueCyan),
          onTap: () {
            if (_displayedVenue != venue) _displayedVenue = venue;
            setState(() => _selectedVenue = venue);
          },
        ));
      }
    } else {
      for (final v in inRadius) {
        // Use sport-specific hue: primary sport when filter is 'all'
        final hue = filter == 'all'
            ? _markerHue(v.sports.isNotEmpty ? v.sports.first : 'all')
            : _markerHue(filter);
        markers.add(Marker(
          markerId: MarkerId(v.id),
          position: LatLng(v.lat, v.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () {
            if (_displayedVenue != v) _displayedVenue = v;
            setState(() => _selectedVenue = v);
          },
        ));
      }
    }

    setState(() => _markers = markers.toSet());
  }

  double _markerHue(String sport) {
    switch (sport) {
      case 'basketball': return BitmapDescriptor.hueOrange;
      case 'cricket':    return 180.0;
      case 'badminton':  return BitmapDescriptor.hueYellow;
      case 'football':   return BitmapDescriptor.hueGreen;
      default:           return BitmapDescriptor.hueRed;
    }
  }

  // ── Map style ────────────────────────────────────────────────

  Future<void> _loadMapStyle() async {
    try {
      final style = await rootBundle.loadString('assets/map_style_dark.json');
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {}
  }

  void _onMapCreated(GoogleMapController c) {
    _mapController = c;
    if (_userLocation != null) {
      c.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 13));
    }
  }

  void _onExpandedMapCreated(GoogleMapController c) {
    _expandedMapController = c;
    if (_userLocation != null) {
      c.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 14));
    }
  }

  // ── Sport selection ──────────────────────────────────────────

  void _selectSport(String sport) {
    context.push(AppRoutes.sportById(sport));
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
      body: Stack(
        children: [
          // ── Normal scrollable home ───────────────────────────
          Column(
            children: [
              _Header(
                firstName: firstName,
                topPad: topPad,
                greeting: _greeting(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // ── Live Now Strip ───────────────────────
                      _LiveNowStrip(pulseController: _pulseController),

                      const SizedBox(height: 16),

                      // ── Collapsed map preview ────────────────
                      _CollapsedMapPreview(
                        userLocation: _userLocation,
                        markers: _markers,
                        loading: _locationLoading,
                        mapStyle: _mapStyle,
                        onMapCreated: _onMapCreated,
                        onTap: () {
                          setState(() {
                            _mapExpanded = true;
                            _selectedVenue = null;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // ── Sport chips ──────────────────────────
                      _SportChipRow(
                        activeSport: _activeSport,
                        onSelect: _selectSport,
                      ),

                      const SizedBox(height: 4),

                      // ── Courts near you ──────────────────────
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

                      // ── Community Feed ───────────────────────
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

                      // ── Promo tiles ──────────────────────────
                      _PromoTiles(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Expanded map overlay ────────────────────────────
          if (_mapExpanded)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (ctx, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - v)),
                  child: child,
                ),
              ),
              child: _ExpandedMapOverlay(
                userLocation: _userLocation,
                markers: _markers,
                loading: _locationLoading,
                mapStyle: _mapStyle,
                onMapCreated: _onExpandedMapCreated,
                activeFilter: _mapFilter,
                radiusKm: _radiusKm,
                selectedVenue: _selectedVenue,
                displayedVenue: _displayedVenue,
                onFilterChange: (f) {
                  setState(() {
                    _mapFilter = f;
                    _selectedVenue = null;
                  });
                  _buildMarkersFiltered(f);
                },
                onRadiusChange: (r) {
                  setState(() => _radiusKm = r);
                  _buildMarkersFiltered(_mapFilter);
                },
                onVenueDismissed: () =>
                    setState(() => _selectedVenue = null),
                onClose: () => setState(() {
                  _mapExpanded = false;
                  _selectedVenue = null;
                }),
                onRecenter: () {
                  if (_userLocation != null) {
                    _expandedMapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_userLocation!, 14),
                    );
                  }
                },
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
//  COLLAPSED MAP PREVIEW
// ═══════════════════════════════════════════════════════════════

class _CollapsedMapPreview extends StatelessWidget {
  const _CollapsedMapPreview({
    required this.userLocation,
    required this.markers,
    required this.loading,
    required this.mapStyle,
    required this.onMapCreated,
    required this.onTap,
  });

  final LatLng? userLocation;
  final Set<Marker> markers;
  final bool loading;
  final String? mapStyle;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onTap;

  static const _bengaluru = LatLng(12.9716, 77.5946);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: SizedBox(
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Static non-interactive map
                AbsorbPointer(
                  absorbing: true,
                  child: GoogleMap(
                    onMapCreated: onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: userLocation ?? _bengaluru,
                      zoom: 13,
                    ),
                    markers: markers,
                    style: mapStyle,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ),
                ),

                // Loading overlay
                if (loading)
                  Container(
                    color: AppColors.black.withValues(alpha: 0.55),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.red, strokeWidth: 2),
                    ),
                  ),

                // Bottom gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.black.withValues(alpha: 0.0),
                          AppColors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom-left label
                Positioned(
                  bottom: 12,
                  left: 14,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🗺', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        'Courts Near You',
                        style: AppTextStyles.labelM(AppColors.white),
                      ),
                    ],
                  ),
                ),

                // Bottom-right pill
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.45),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.15),
                              width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_full_rounded,
                                color: AppColors.white, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to explore',
                              style: AppTextStyles.labelS(AppColors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
//  EXPANDED MAP OVERLAY
// ═══════════════════════════════════════════════════════════════

class _ExpandedMapOverlay extends StatelessWidget {
  const _ExpandedMapOverlay({
    required this.userLocation,
    required this.markers,
    required this.loading,
    required this.mapStyle,
    required this.onMapCreated,
    required this.activeFilter,
    required this.radiusKm,
    required this.selectedVenue,
    required this.displayedVenue,
    required this.onFilterChange,
    required this.onRadiusChange,
    required this.onVenueDismissed,
    required this.onClose,
    required this.onRecenter,
  });

  final LatLng? userLocation;
  final Set<Marker> markers;
  final bool loading;
  final String? mapStyle;
  final Function(GoogleMapController) onMapCreated;
  final String activeFilter;
  final double radiusKm;
  final Venue? selectedVenue;
  final Venue? displayedVenue;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<double> onRadiusChange;
  final VoidCallback onVenueDismissed;
  final VoidCallback onClose;
  final VoidCallback onRecenter;

  static const _bengaluru = LatLng(12.9716, 77.5946);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final venueVisible = selectedVenue != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Interactive full-screen map
        GoogleMap(
          onMapCreated: onMapCreated,
          initialCameraPosition: CameraPosition(
            target: userLocation ?? _bengaluru,
            zoom: 14,
          ),
          markers: markers,
          style: mapStyle,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          onTap: (_) => onVenueDismissed(),
        ),

        // Loading overlay
        if (loading)
          Container(
            color: AppColors.black.withValues(alpha: 0.5),
            child: const Center(
              child: CircularProgressIndicator(
                  color: AppColors.red, strokeWidth: 2),
            ),
          ),

        // Top filter bar (safe area)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(top: topPad + 10, bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.black.withValues(alpha: 0.88),
                  AppColors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MapFilterBar(
                  activeFilter: activeFilter,
                  onSelect: onFilterChange,
                ),
                const SizedBox(height: AppSpacing.sm),
                _RadiusSelectorRow(
                  radiusKm: radiusKm,
                  onSelect: onRadiusChange,
                ),
              ],
            ),
          ),
        ),

        // Close + recenter buttons (top right)
        Positioned(
          top: topPad + 10,
          right: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlassButton(
                onTap: onClose,
                child: const Icon(Icons.close_rounded,
                    color: AppColors.white, size: 18),
              ),
              const SizedBox(height: 8),
              _GlassButton(
                onTap: onRecenter,
                child: const Icon(Icons.my_location_rounded,
                    color: AppColors.white, size: 16),
              ),
            ],
          ),
        ),

        // Court count badge (top left) — animates on change
        if (!loading)
          Positioned(
            top: topPad + 88,
            left: 14,
            child: AnimatedSwitcher(
              duration: AppDuration.fast,
              child: markers.isEmpty
                  ? const _NoCourtsChip(key: ValueKey('none'))
                  : _CourtCountChip(
                      count: markers.length,
                      key: ValueKey(markers.length),
                    ),
            ),
          ),

        // Empty state — when no courts match filter
        if (!loading && markers.isEmpty)
          Positioned.fill(
            top: topPad + 130,
            bottom: 120,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.overlay,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No courts here',
                        style: AppTextStyles.headingS(
                            AppColors.textPrimaryDark)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Try a wider radius or All sports',
                      style: AppTextStyles.bodyS(
                          AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Venue quick card — slides up from bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !venueVisible,
            child: AnimatedSlide(
              offset: venueVisible ? Offset.zero : const Offset(0, 1),
              duration: AppDuration.normal,
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: venueVisible ? 1.0 : 0.0,
                duration: AppDuration.normal,
                child: displayedVenue == null
                    ? const SizedBox.shrink()
                    : _VenueQuickCard(
                        venue: displayedVenue!,
                        bottomPad: bottomPad,
                        userLocation: userLocation,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Glassmorphic icon button ──────────────────────────────────

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.1), width: 0.5),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAP FILTER BAR
// ═══════════════════════════════════════════════════════════════

class _MapFilterBar extends StatelessWidget {
  const _MapFilterBar({
    required this.activeFilter,
    required this.onSelect,
  });

  final String activeFilter;
  final ValueChanged<String> onSelect;

  static const _filters = [
    ('all',        'All',        ''),
    ('basketball', 'Basketball', '🏀'),
    ('cricket',    'Cricket',    '🏏'),
    ('badminton',  'Badminton',  '🏸'),
    ('football',   'Football',   '⚽'),
    ('pickup',     'Pickup',     '🤝'),
    ('community',  'Community',  '👥'),
  ];

  Color _chipColor(String id) {
    switch (id) {
      case 'basketball': return AppColors.basketball;
      case 'cricket':    return AppColors.cricket;
      case 'badminton':  return AppColors.badminton;
      case 'football':   return AppColors.football;
      default:           return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _filters.length,
        separatorBuilder: (c, i) => const SizedBox(width: AppSpacing.xs + 2),
        itemBuilder: (context, i) {
          final (id, label, emoji) = _filters[i];
          final active = activeFilter == id;
          final chipColor = _chipColor(id);
          return GestureDetector(
            onTap: () => onSelect(id),
            child: AnimatedContainer(
              duration: AppDuration.fast,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: active
                    ? chipColor.withValues(alpha: 0.14)
                    : AppColors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: active
                      ? chipColor.withValues(alpha: 0.75)
                      : AppColors.white.withValues(alpha: 0.18),
                  width: active ? 1.0 : 0.5,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: chipColor.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (emoji.isNotEmpty) ...[
                          Text(emoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          label,
                          style: AppTextStyles.labelM(
                            active
                                ? chipColor
                                : AppColors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RADIUS SELECTOR ROW
// ═══════════════════════════════════════════════════════════════

class _RadiusSelectorRow extends StatelessWidget {
  const _RadiusSelectorRow({
    required this.radiusKm,
    required this.onSelect,
  });

  final double radiusKm;
  final ValueChanged<double> onSelect;

  static const _options = [
    (1.0,            '1 km'),
    (2.0,            '2 km'),
    (5.0,            '5 km'),
    (double.infinity, 'All'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14, right: AppSpacing.sm),
          child: Text(
            'RADIUS',
            style: AppTextStyles.overline(AppColors.textTertiaryDark),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _options.length,
              separatorBuilder: (c, i) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) {
                final (value, label) = _options[i];
                final active = radiusKm == value;
                return GestureDetector(
                  onTap: () => onSelect(value),
                  child: AnimatedContainer(
                    duration: AppDuration.fast,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.red.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: active
                            ? AppColors.red.withValues(alpha: 0.7)
                            : AppColors.white.withValues(alpha: 0.12),
                        width: active ? 1.0 : 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: AppTextStyles.labelS(
                          active
                              ? AppColors.white
                              : AppColors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  COURT COUNT CHIPS
// ═══════════════════════════════════════════════════════════════

class _CourtCountChip extends StatelessWidget {
  const _CourtCountChip({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count ${count == 1 ? 'court' : 'courts'}',
                style: AppTextStyles.labelS(AppColors.textPrimaryDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoCourtsChip extends StatelessWidget {
  const _NoCourtsChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: AppColors.red.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Text(
            'No courts — try wider radius',
            style: AppTextStyles.labelS(AppColors.textSecondaryDark),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  VENUE QUICK CARD
// ═══════════════════════════════════════════════════════════════

class _VenueQuickCard extends StatelessWidget {
  const _VenueQuickCard({
    required this.venue,
    required this.bottomPad,
    this.userLocation,
  });

  final Venue venue;
  final double bottomPad;
  final LatLng? userLocation;

  static const _sportEmoji = {
    'basketball': '🏀',
    'cricket': '🏏',
    'badminton': '🏸',
    'football': '⚽',
  };

  static double _km(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLng = (b.longitude - a.longitude) * math.pi / 180.0;
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180.0) *
            math.cos(b.latitude * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.asin(math.sqrt(x));
  }

  String _distanceLabel(LatLng from, Venue v) {
    final d = _km(from, LatLng(v.lat, v.lng));
    return d < 1.0
        ? '${(d * 1000).round()} m away'
        : '${d.toStringAsFixed(1)} km away';
  }

  Color _sportColor(String sport) {
    switch (sport) {
      case 'basketball': return AppColors.basketball;
      case 'cricket':    return AppColors.cricket;
      case 'badminton':  return AppColors.badminton;
      default:           return AppColors.football;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courts = FakeData.courtsByVenue(venue.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
        border: const Border(
            top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.6),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo placeholder
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: AppColors.border, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          venue.name[0],
                          style: AppTextStyles.displayL(AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  venue.name,
                                  style: AppTextStyles.headingM(
                                      AppColors.textPrimaryDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (venue.hasTheBox)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.red.withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(
                                        color: AppColors.red
                                            .withValues(alpha: 0.3),
                                        width: 0.5),
                                  ),
                                  child: Text('THE BOX',
                                      style: AppTextStyles.overline(
                                          AppColors.red)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.warning, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                '${venue.rating}',
                                style: AppTextStyles.labelM(
                                    AppColors.textPrimaryDark),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.textTertiaryDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                venue.area,
                                style: AppTextStyles.bodyS(
                                    AppColors.textSecondaryDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  color: AppColors.textTertiaryDark,
                                  size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'Open till ${venue.closingTime}',
                                style: AppTextStyles.bodyS(
                                    AppColors.textSecondaryDark),
                              ),
                              if (userLocation != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.textTertiaryDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _distanceLabel(userLocation!, venue),
                                  style: AppTextStyles.bodyS(
                                      AppColors.textSecondaryDark),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Court pricing chips
                if (courts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: courts.length,
                      separatorBuilder: (c, i) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final c = courts[i];
                        final color = _sportColor(c.sport);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 0.5),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _sportEmoji[c.sport] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${c.slotDurationMin}min  ·  ₹${c.pricePerSlot}',
                                  style: AppTextStyles.labelM(color),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            context.push(AppRoutes.venueById(venue.id)),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.red.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Book a Slot',
                              style: AppTextStyles.headingS(AppColors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () =>
                          context.push(AppRoutes.venueById(venue.id)),
                      child: Container(
                        height: 48,
                        width: 48,
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
          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }
}
