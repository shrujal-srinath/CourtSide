// lib/screens/home/home_screen.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/cs_shimmer.dart';

// ── Sport config ────────────────────────────────────────────────

class _Sport {
  const _Sport(this.id, this.label, this.emoji, this.color);
  final String id;
  final String label;
  final String emoji;
  final Color color;
}

// ignore: unused_element
const _sports = [
  _Sport('basketball', 'Basketball', '🏀', AppColors.basketball),
  _Sport('cricket',    'Box Cricket', '🏏', AppColors.cricket),
  _Sport('badminton',  'Badminton',   '🏸', AppColors.badminton),
  _Sport('football',   'Football',    '⚽', AppColors.football),
];

Color _sportColor(String sport) {
  switch (sport) {
    case 'basketball': return AppColors.basketball;
    case 'cricket':    return AppColors.cricket;
    case 'badminton':  return AppColors.badminton;
    default:           return AppColors.football;
  }
}

String _sportEmoji(String sport) {
  switch (sport) {
    case 'basketball': return '🏀';
    case 'cricket':    return '🏏';
    default:           return '🏸';
  }
}

// ═══════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
  Venue? _displayedVenue;

  static const _bengaluru = LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapStyle();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _expandedMapController?.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final colors = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Using Bengaluru as default — enable GPS for your actual location',
          ),
          backgroundColor: colors.colorSurfaceOverlay,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    });
  }

  bool _isInIndia(LatLng pos) =>
      pos.latitude >= 8.0 && pos.latitude <= 37.0 &&
      pos.longitude >= 68.0 && pos.longitude <= 97.0;

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

    final inRadius = hasRadius
        ? candidates.where((v) =>
            _haversineKm(loc, LatLng(v.lat, v.lng)) <= _radiusKm).toSet()
        : candidates.toSet();

    if (filter == 'pickup' || filter == 'community') {
      for (final g in FakeData.pickupGames) {
        final venue = inRadius.where((v) => v.id == g.venueId).firstOrNull;
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

  Future<void> _loadMapStyle() async {
    try {
      const path = 'assets/map_style_dark.json';
      final style = await rootBundle.loadString(path);
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {}
  }

  void _onExpandedMapCreated(GoogleMapController c) {
    _expandedMapController = c;
    if (_userLocation != null) {
      c.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 14));
    }
  }

  void _selectSport(String sport) => context.push(AppRoutes.sportById(sport));

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final user = ref.watch(currentUserProvider);
    final name = user?.userMetadata?['full_name'] as String? ?? 'Player';
    final firstName = name.split(' ').first;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Stack(
        children: [
          Column(
            children: [
              _HomeHeader(
                firstName: firstName,
                topPad: topPad,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      const _HomeCarousel(),

                      const SizedBox(height: AppSpacing.md),

                      _SportChipRow(
                        activeSport: _activeSport,
                        onSelect: _selectSport,
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      _SectionHeader(
                        title: 'COURTS NEAR YOU',
                        onSeeAll: () => context.go(AppRoutes.explore),
                      ),
                      _CourtsNearYou(
                        venues: FakeData.venues,
                        onVenueTap: (v) =>
                            context.push(AppRoutes.venueById(v.id)),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      _SectionHeader(
                        title: 'ACTIVITY',
                        onSeeAll: () {},
                      ),
                      _CommunityFeed(
                        bookings: FakeData.bookingHistory
                            .where((b) => b.hasStats)
                            .toList(),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      _PromoTiles(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

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
                onVenueDismissed: () => setState(() => _selectedVenue = null),
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
//  HOME HEADER
// ═══════════════════════════════════════════════════════════════

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.firstName,
    required this.topPad,
  });

  final String firstName;
  final double topPad;

  void _showNotificationsSheet(BuildContext context) {
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
          children: [
            // Handle
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
            Icon(Icons.notifications_none_rounded,
                size: 36, color: colors.colorTextTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('No new notifications',
                style: AppTextStyles.headingS(colors.colorTextPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You\'re all caught up. Booking confirmations\nand game alerts will appear here.',
              style: AppTextStyles.bodyM(colors.colorTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P';

    return Container(
      color: colors.colorBackgroundPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ROW 1: name + location | bell + avatar ────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, topPad + AppSpacing.sm,
                AppSpacing.lg, AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: name + tappable location row
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        firstName,
                        style: AppTextStyles.headingL(colors.colorTextPrimary)
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.colorAccentPrimary,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Koramangala, Bengaluru',
                              style: AppTextStyles.labelS(
                                  colors.colorTextSecondary),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 12,
                              color: colors.colorTextTertiary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Notification bell — taps open notifications sheet
                GestureDetector(
                  onTap: () => _showNotificationsSheet(context),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.colorSurfacePrimary,
                          border: Border.all(
                              color: colors.colorBorderSubtle, width: 0.5),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: colors.colorTextPrimary,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.colorAccentPrimary,
                            border: Border.all(
                              color: colors.colorBackgroundPrimary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Avatar — taps navigate to profile
                GestureDetector(
                  onTap: () => context.push(AppRoutes.profile),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.colorAccentSubtle,
                      border: Border.all(
                          color: colors.colorAccentPrimary, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style:
                            AppTextStyles.labelS(colors.colorAccentPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── ROW 2: search bar with animated hint ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.explore),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.colorSurfacePrimary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border:
                      Border.all(color: colors.colorBorderSubtle, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        size: 18, color: colors.colorTextTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Search for ',
                            style: AppTextStyles.bodyS(
                                colors.colorTextTertiary),
                          ),
                          const _AnimatedSearchHint(),
                        ],
                      ),
                    ),
                  ],
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
//  ANIMATED SEARCH HINT
//  Cycles through search term suggestions with a vertical slide
// ═══════════════════════════════════════════════════════════════

class _AnimatedSearchHint extends StatefulWidget {
  const _AnimatedSearchHint();

  @override
  State<_AnimatedSearchHint> createState() => _AnimatedSearchHintState();
}

class _AnimatedSearchHintState extends State<_AnimatedSearchHint>
    with SingleTickerProviderStateMixin {
  static const _terms = ['courts', 'players', 'venues', 'games'];

  int _index = 0;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
    _scheduleCycle();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _scheduleCycle() {
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _ctrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % _terms.length);
        _ctrl.forward();
        _scheduleCycle();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Text(
          _terms[_index],
          style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CONTEXT-DRIVEN CAROUSEL
// ═══════════════════════════════════════════════════════════════

enum _CarouselPanel { map, ongoingGame, friendGame, lastGame }

class _HomeCarousel extends StatefulWidget {
  const _HomeCarousel();

  @override
  State<_HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<_HomeCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  late final List<_CarouselPanel> _panels;

  static const _swipeLabels = {
    _CarouselPanel.ongoingGame: '⚡ game',
    _CarouselPanel.friendGame: '👥 friends',
    _CarouselPanel.lastGame: '📊 last game',
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _panels = _buildPanels();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_CarouselPanel> _buildPanels() {
    final panels = <_CarouselPanel>[_CarouselPanel.map];

    // Upcoming basketball booking → treat as "your game is happening"
    final hasOngoingGame = FakeData.bookingHistory.any(
      (b) => b.status == BookingStatus.upcoming && b.sport == 'basketball',
    );
    if (hasOngoingGame) panels.add(_CarouselPanel.ongoingGame);

    // Hardcoded friend playing flag for now
    const hasFriendPlaying = true;
    if (hasFriendPlaying) panels.add(_CarouselPanel.friendGame);

    // Any completed booking → last game panel
    final hasLastGame = FakeData.bookingHistory.any(
      (b) => b.status == BookingStatus.completed,
    );
    if (hasLastGame) panels.add(_CarouselPanel.lastGame);

    return panels;
  }

  Widget _buildPanel(_CarouselPanel panel) {
    switch (panel) {
      case _CarouselPanel.map:
        return const _MapPanel();
      case _CarouselPanel.ongoingGame:
        return const _OngoingGamePanel();
      case _CarouselPanel.friendGame:
        return const _FriendGamePanel();
      case _CarouselPanel.lastGame:
        return const _LastGamePanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showIndicators = _panels.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 96px carousel container ──────────────────────────────
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border:
                    Border.all(color: colors.colorBorderSubtle, width: 1),
              ),
              child: Stack(
                children: [
                  // PageView sits below the 3px indicator strip
                  Positioned(
                    top: showIndicators ? 3 : 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) =>
                          setState(() => _currentPage = i),
                      children: _panels
                          .map(_buildPanel)
                          .toList(),
                    ),
                  ),
                  // Top-edge line indicators
                  if (showIndicators)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: List.generate(_panels.length, (i) {
                          final active = i == _currentPage;
                          return Expanded(
                            flex: active ? 2 : 1,
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 250),
                              height: 3,
                              decoration: BoxDecoration(
                                color: active
                                    ? colors.colorAccentPrimary
                                    : colors.colorBorderSubtle,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(2),
                                  bottomRight: Radius.circular(2),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ── Swipe hint row (centered, only when multiple panels) ─
        if (showIndicators)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 4, AppSpacing.lg, 4),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'swipe for  ',
                    style:
                        AppTextStyles.labelS(colors.colorTextTertiary),
                  ),
                  ..._panels.skip(1).map((p) {
                    final label = _swipeLabels[p] ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.colorSurfacePrimary,
                          border: Border.all(
                              color: colors.colorBorderSubtle, width: 1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          label,
                          style: AppTextStyles.labelS(
                              colors.colorTextTertiary),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PULSING PIN (map venue dot with animated outer ring)
// ═══════════════════════════════════════════════════════════════

class _PulsingPin extends StatefulWidget {
  const _PulsingPin({
    required this.color,
    required this.size,
    required this.borderColor,
    this.pulse = true,
  });

  final Color color;
  final double size;
  final Color borderColor;
  final bool pulse;

  @override
  State<_PulsingPin> createState() => _PulsingPinState();
}

class _PulsingPinState extends State<_PulsingPin>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outerSize = widget.size + 8.0;
    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_ctrl != null)
            AnimatedBuilder(
              animation: _ctrl!,
              builder: (_, _) => Container(
                width: outerSize,
                height: outerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(
                      alpha: _ctrl!.value * 0.35),
                ),
              ),
            ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              border: Border.all(color: widget.borderColor, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PULSING DOT (live indicator in _OngoingGamePanel)
// ═══════════════════════════════════════════════════════════════

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + _ctrl.value * 0.5),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAP PANEL  (pure Flutter — no google_maps_flutter)
// ═══════════════════════════════════════════════════════════════

class _MapPanel extends StatelessWidget {
  const _MapPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Container(
          color: colors.colorSurfacePrimary,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Faint horizontal grid lines at 25%, 50%, 75%
              ...[0.25, 0.5, 0.75].map(
                (f) => Positioned(
                  top: h * f,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.4,
                    child: Container(
                        height: 1, color: colors.colorBorderSubtle),
                  ),
                ),
              ),
              // Faint vertical grid lines at 40%, 70%
              ...[0.4, 0.7].map(
                (f) => Positioned(
                  left: w * f,
                  top: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: 0.4,
                    child: Container(
                        width: 1, color: colors.colorBorderSubtle),
                  ),
                ),
              ),

              // Nearest venue pin — pulsing accent
              Positioned(
                left: w * 0.35 - 8.5,
                top: h * 0.28 - 8.5,
                child: _PulsingPin(
                  color: colors.colorAccentPrimary,
                  size: 9,
                  borderColor: colors.colorTextOnAccent,
                ),
              ),
              // Secondary pins — no pulse
              Positioned(
                left: w * 0.62 - 7.5,
                top: h * 0.45 - 7.5,
                child: _PulsingPin(
                  color: colors.colorSuccess,
                  size: 7,
                  borderColor: colors.colorTextOnAccent,
                  pulse: false,
                ),
              ),
              Positioned(
                left: w * 0.18 - 7.5,
                top: h * 0.55 - 7.5,
                child: _PulsingPin(
                  color: colors.colorInfo,
                  size: 7,
                  borderColor: colors.colorTextOnAccent,
                  pulse: false,
                ),
              ),

              // Bottom gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: h * 0.6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.colorBackgroundPrimary
                            .withValues(alpha: 0.0),
                        colors.colorBackgroundPrimary
                            .withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),

              // Top-left map label chip
              Positioned(
                top: 8,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.colorSurfaceOverlay,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                        color: colors.colorBorderSubtle, width: 0.5),
                  ),
                  child: Text(
                    '🗺 Courts near you',
                    style:
                        AppTextStyles.labelS(colors.colorTextTertiary),
                  ),
                ),
              ),

              // Bottom info row: venue name + slots + Book button
              Positioned(
                bottom: 8,
                left: 10,
                right: 10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Game Theory Koramangala',
                            style: AppTextStyles.labelM(
                                colors.colorTextPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '0.8 km · 5 slots open',
                            style: AppTextStyles.labelS(
                                colors.colorTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.colorAccentPrimary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'Book →',
                          style: AppTextStyles.labelS(
                              colors.colorTextOnAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ONGOING GAME PANEL
// ═══════════════════════════════════════════════════════════════

class _OngoingGamePanel extends StatelessWidget {
  const _OngoingGamePanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.colorSurfacePrimary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left accent bar 3px colorAccentPrimary
          Container(width: 3, color: colors.colorAccentPrimary),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live indicator row
                  Row(
                    children: [
                      _PulsingDot(color: colors.colorAccentPrimary),
                      const SizedBox(width: 5),
                      Text(
                        'YOUR GAME · LIVE',
                        style: AppTextStyles.overline(
                            colors.colorAccentPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Score row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Warriors',
                        style: AppTextStyles.labelS(
                            colors.colorTextSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '48',
                        style: AppTextStyles.headingL(
                                colors.colorTextPrimary)
                            .copyWith(
                          letterSpacing: -1,
                          fontFeatures: [
                            const FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '–',
                        style: AppTextStyles.headingS(
                            colors.colorTextTertiary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '41',
                        style: AppTextStyles.headingL(
                                colors.colorTextPrimary)
                            .copyWith(
                          letterSpacing: -1,
                          fontFeatures: [
                            const FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rivals',
                        style: AppTextStyles.labelS(
                            colors.colorTextSecondary),
                      ),
                    ],
                  ),
                  Text(
                    'Q3 · 4:22',
                    style:
                        AppTextStyles.labelS(colors.colorTextSecondary),
                  ),
                  const Spacer(),
                  // Bottom stat + action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'You: 14pts · 5reb',
                        style: AppTextStyles.labelS(
                            colors.colorTextSecondary),
                      ),
                      Text(
                        'Open scorer →',
                        style: AppTextStyles.labelS(
                            colors.colorAccentPrimary),
                      ),
                    ],
                  ),
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
//  FRIEND GAME PANEL
// ═══════════════════════════════════════════════════════════════

class _FriendGamePanel extends StatelessWidget {
  const _FriendGamePanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.colorSurfacePrimary,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Friend header
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.colorSurfaceElevated,
                  border: Border.all(
                      color: colors.colorBorderSubtle, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    'AR',
                    style: AppTextStyles.overline(
                            colors.colorTextSecondary)
                        .copyWith(fontSize: 7),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('Arjun R',
                  style: AppTextStyles.labelM(colors.colorTextPrimary)),
              const SizedBox(width: 4),
              Text('is playing now',
                  style:
                      AppTextStyles.labelS(colors.colorTextSecondary)),
            ],
          ),
          const SizedBox(height: 3),
          // Live dot + venue
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.colorSuccess,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Live · Box Sports',
                style: AppTextStyles.labelS(colors.colorSuccess),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Score + quarter
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '34 – 28',
                style:
                    AppTextStyles.headingM(colors.colorTextPrimary)
                        .copyWith(
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Q2',
                style: AppTextStyles.labelS(colors.colorTextTertiary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Arjun: 18pts · 3ast · 71% FG',
            style: AppTextStyles.labelS(colors.colorTextSecondary),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Watch live →',
              style: AppTextStyles.labelS(colors.colorTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LAST GAME PANEL
// ═══════════════════════════════════════════════════════════════

class _LastGamePanel extends StatelessWidget {
  const _LastGamePanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Pull PTS from FakeData basketball stats if available
    final stat = FakeData.playerStats
        .where((s) => s.sport == 'basketball')
        .firstOrNull;
    final pts = stat != null
        ? '${(stat.stats['ppg'] as double).round()}'
        : '24';

    return Container(
      color: colors.colorSurfacePrimary,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: label + W badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last game · Yesterday',
                style: AppTextStyles.labelS(colors.colorTextTertiary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.colorSuccess.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'W',
                  style: AppTextStyles.labelS(colors.colorSuccess),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Warriors 72 – 58',
            style: AppTextStyles.labelM(colors.colorTextPrimary).copyWith(
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 5),
          // 4-cell stat row with dividers
          IntrinsicHeight(
            child: Row(
              children: [
                _StatCell(
                    value: pts,
                    label: 'PTS',
                    valueColor: colors.colorAccentPrimary,
                    colors: colors),
                _StatDivider(colors: colors),
                _StatCell(
                    value: '8',
                    label: 'REB',
                    valueColor: colors.colorTextPrimary,
                    colors: colors),
                _StatDivider(colors: colors),
                _StatCell(
                    value: '5',
                    label: 'AST',
                    valueColor: colors.colorTextPrimary,
                    colors: colors),
                _StatDivider(colors: colors),
                _StatCell(
                    value: '68%',
                    label: 'FG%',
                    valueColor: colors.colorTextPrimary,
                    colors: colors),
              ],
            ),
          ),
          const Spacer(),
          // Bottom: hardware verified + share button
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.colorSuccess,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Hardware verified · THE BOX',
                style: AppTextStyles.labelS(colors.colorSuccess),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/stats/share'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.colorAccentPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Share →',
                    style:
                        AppTextStyles.labelS(colors.colorTextOnAccent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.colors,
  });

  final String value;
  final String label;
  final Color valueColor;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.headingS(valueColor).copyWith(
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: AppTextStyles.overline(colors.colorTextTertiary),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: colors.colorBorderSubtle);
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

  static const _chipSports = [
    _Sport('basketball', 'Basketball', '🏀', AppColors.basketball),
    _Sport('cricket',    'Box Cricket', '🏏', AppColors.cricket),
    _Sport('badminton',  'Badminton',   '🏸', AppColors.badminton),
    _Sport('football',   'Football',    '⚽', AppColors.football),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
          child: Text(
            'PICK A SPORT',
            style: AppTextStyles.overline(colors.colorTextTertiary),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: _chipSports.length,
            separatorBuilder: (c, i) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (c, i) {
              final sport = _chipSports[i];
              final active = sport.id == activeSport;
              return GestureDetector(
                onTap: () => onSelect(sport.id),
                child: AnimatedContainer(
                  duration: AppDuration.fast,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    // Sport-colored active state — NOT solid red fill
                    color: active
                        ? sport.color.withValues(alpha: 0.14)
                        : colors.colorSurfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: active
                          ? sport.color
                          : colors.colorBorderSubtle,
                      width: active ? 1.0 : 0.5,
                    ),
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
                              ? sport.color
                              : colors.colorTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
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
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: venues.length,
        separatorBuilder: (c, i) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (c, i) {
          final v = venues[i];
          return _CourtCard(venue: v, onTap: () => onVenueTap(v));
        },
      ),
    );
  }
}

class _CourtCard extends StatefulWidget {
  const _CourtCard({required this.venue, required this.onTap});
  final Venue venue;
  final VoidCallback onTap;

  @override
  State<_CourtCard> createState() => _CourtCardState();
}

class _CourtCardState extends State<_CourtCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 175,
          decoration: BoxDecoration(
            color: colors.colorSurfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
            boxShadow: AppShadow.cardElevated,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo placeholder
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.card)),
                child: Stack(
                  children: [
                    CsShimmer(
                      child: Container(
                        height: 108,
                        width: double.infinity,
                        color: colors.colorSurfaceOverlay,
                      ),
                    ),
                    Container(
                      height: 108,
                      width: double.infinity,
                      color: colors.colorSurfaceOverlay.withValues(alpha: 0.8),
                      child: Center(
                        child: Text(
                          widget.venue.name[0],
                          style: AppTextStyles.displayL(
                              colors.colorBorderMedium),
                        ),
                      ),
                    ),
                    if (widget.venue.hasTheBox)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.colorAccentPrimary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
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

              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm + 2, AppSpacing.sm,
                    AppSpacing.sm + 2, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.venue.name,
                      style: AppTextStyles.headingS(colors.colorTextPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.venue.area}  ·  ${widget.venue.rating} ★',
                      style: AppTextStyles.bodyS(colors.colorTextSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        ...widget.venue.sports.take(3).map((s) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _sportColor(s),
                              ),
                            )),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: colors.colorTextTertiary,
                        ),
                      ],
                    ),
                  ],
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
//  COMMUNITY FEED
// ═══════════════════════════════════════════════════════════════

class _CommunityFeed extends StatelessWidget {
  const _CommunityFeed({required this.bookings});
  final List<BookingRecord> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: bookings.take(3).map((b) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.colorSurfacePrimary,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                  color: colors.colorBorderSubtle, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.colorAccentPrimary.withValues(alpha: 0.15),
                    border: Border.all(
                        color: colors.colorAccentPrimary.withValues(alpha: 0.3),
                        width: 1),
                  ),
                  child: Center(
                    child: Text(
                      'S',
                      style: AppTextStyles.headingS(colors.colorAccentPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('You',
                              style: AppTextStyles.headingS(
                                  colors.colorTextPrimary)),
                          Text(' played ${b.sport} at',
                              style: AppTextStyles.bodyS(
                                  colors.colorTextSecondary)),
                        ],
                      ),
                      Text(
                        b.venueName,
                        style: AppTextStyles.bodyS(colors.colorTextPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (b.sport == 'basketball')
                        Row(
                          children: [
                            _MiniStat(label: 'PTS', value: '18',
                                colors: colors),
                            const SizedBox(width: AppSpacing.md),
                            _MiniStat(label: 'REB', value: '7',
                                colors: colors),
                            const SizedBox(width: AppSpacing.md),
                            _MiniStat(label: 'AST', value: '4',
                                colors: colors),
                          ],
                        )
                      else
                        Row(
                          children: [
                            _MiniStat(label: 'RUNS', value: '42',
                                colors: colors),
                            const SizedBox(width: AppSpacing.md),
                            _MiniStat(label: 'SR', value: '138',
                                colors: colors),
                            const SizedBox(width: AppSpacing.md),
                            _MiniStat(label: 'WKT', value: '2',
                                colors: colors),
                          ],
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('2h ago',
                        style: AppTextStyles.bodyS(colors.colorTextTertiary)),
                    const SizedBox(height: AppSpacing.sm),
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
  const _MiniStat({
    required this.label,
    required this.value,
    required this.colors,
  });
  final String label;
  final String value;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTextStyles.headingS(colors.colorTextPrimary)),
        Text(label,
            style: AppTextStyles.overline(colors.colorTextTertiary)),
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
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, 0),
      child: Row(
        children: [
          Expanded(
            child: _PromoTile(
              emoji: '🏟️',
              title: 'List your venue',
              subtitle: 'Register your turf on Courtside',
              onTap: () {},
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _PromoTile(
              emoji: '📊',
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
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
              color: colors.colorBorderSubtle, width: 0.5),
          boxShadow: AppShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: colors.colorSurfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: colors.colorTextTertiary, size: 12),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(title,
                style: AppTextStyles.headingS(colors.colorTextPrimary)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: AppTextStyles.bodyS(colors.colorTextSecondary)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SECTION HEADER — overline style, textTertiary. NEVER red.
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: AppTextStyles.overline(colors.colorTextTertiary)),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: AppTextStyles.labelS(colors.colorTextSecondary),
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
    final topPad    = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final venueVisible = selectedVenue != null;
    final colors = context.colors;

    return Stack(
      fit: StackFit.expand,
      children: [
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

        if (loading)
          Container(
            color: colors.colorSurfaceOverlay.withValues(alpha: 0.7),
            child: Center(
              child: CircularProgressIndicator(
                  color: colors.colorAccentPrimary, strokeWidth: 2),
            ),
          ),

        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.only(top: topPad + 10, bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.colorSurfaceOverlay.withValues(alpha: 0.88),
                  colors.colorSurfaceOverlay.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MapFilterBar(
                    activeFilter: activeFilter, onSelect: onFilterChange),
                const SizedBox(height: AppSpacing.sm),
                _RadiusSelectorRow(
                    radiusKm: radiusKm, onSelect: onRadiusChange),
              ],
            ),
          ),
        ),

        Positioned(
          top: topPad + 10, right: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlassButton(
                onTap: onClose,
                child: Icon(Icons.close_rounded,
                    color: colors.colorTextPrimary, size: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              _GlassButton(
                onTap: onRecenter,
                child: Icon(Icons.my_location_rounded,
                    color: colors.colorTextPrimary, size: 16),
              ),
            ],
          ),
        ),

        if (!loading)
          Positioned(
            top: topPad + 88, left: 14,
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

        if (!loading && markers.isEmpty)
          Positioned.fill(
            top: topPad + 130, bottom: 120,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.colorSurfaceOverlay,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                      color: colors.colorBorderSubtle, width: 0.5),
                  boxShadow: AppShadow.cardElevated,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No courts here',
                        style: AppTextStyles.headingS(
                            colors.colorTextPrimary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Try a wider radius or All sports',
                      style: AppTextStyles.bodyS(colors.colorTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),

        Positioned(
          bottom: 0, left: 0, right: 0,
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
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: colors.colorSurfaceOverlay.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: colors.colorBorderSubtle.withValues(alpha: 0.5),
                  width: 0.5),
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
  const _MapFilterBar({required this.activeFilter, required this.onSelect});
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

  Color _chipColor(String id, AppColorScheme colors) {
    switch (id) {
      case 'basketball': return AppColors.basketball;
      case 'cricket':    return AppColors.cricket;
      case 'badminton':  return AppColors.badminton;
      case 'football':   return AppColors.football;
      default:           return colors.colorAccentPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _filters.length,
        separatorBuilder: (c, i) =>
            const SizedBox(width: AppSpacing.xs + 2),
        itemBuilder: (context, i) {
          final (id, label, emoji) = _filters[i];
          final active = activeFilter == id;
          final chipColor = _chipColor(id, colors);
          return GestureDetector(
            onTap: () => onSelect(id),
            child: AnimatedContainer(
              duration: AppDuration.fast,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: active
                    ? chipColor.withValues(alpha: 0.14)
                    : colors.colorSurfaceOverlay.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: active
                      ? chipColor.withValues(alpha: 0.75)
                      : colors.colorBorderSubtle.withValues(alpha: 0.6),
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
                          Text(emoji,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          label,
                          style: AppTextStyles.labelM(
                            active ? chipColor : colors.colorTextSecondary,
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
//  RADIUS SELECTOR
// ═══════════════════════════════════════════════════════════════

class _RadiusSelectorRow extends StatelessWidget {
  const _RadiusSelectorRow({required this.radiusKm, required this.onSelect});
  final double radiusKm;
  final ValueChanged<double> onSelect;

  static const _options = [
    (1.0,             '1 km'),
    (2.0,             '2 km'),
    (5.0,             '5 km'),
    (double.infinity, 'All'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 14, right: AppSpacing.sm),
          child: Text(
            'RADIUS',
            style: AppTextStyles.overline(colors.colorTextTertiary),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _options.length,
              separatorBuilder: (c, i) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) {
                final (value, label) = _options[i];
                final active = radiusKm == value;
                return GestureDetector(
                  onTap: () => onSelect(value),
                  child: AnimatedContainer(
                    duration: AppDuration.fast,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: active
                          ? colors.colorAccentPrimary
                              .withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: active
                            ? colors.colorAccentPrimary
                                .withValues(alpha: 0.7)
                            : colors.colorBorderSubtle
                                .withValues(alpha: 0.5),
                        width: active ? 1.0 : 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: AppTextStyles.labelS(
                          active
                              ? colors.colorTextPrimary
                              : colors.colorTextTertiary,
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
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.colorSurfaceOverlay.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: colors.colorBorderSubtle, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.colorSuccess,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count ${count == 1 ? 'court' : 'courts'}',
                style: AppTextStyles.labelS(colors.colorTextPrimary),
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
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.colorAccentPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: colors.colorAccentPrimary.withValues(alpha: 0.3),
                width: 0.5),
          ),
          child: Text(
            'No courts — try wider radius',
            style: AppTextStyles.labelS(colors.colorTextSecondary),
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

  static const _sportEmojiMap = {
    'basketball': '🏀',
    'cricket':    '🏏',
    'badminton':  '🏸',
    'football':   '⚽',
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

  @override
  Widget build(BuildContext context) {
    final courts = FakeData.courtsByVenue(venue.id);
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfaceOverlay,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
        border: Border(
            top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navBar,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.md, bottom: AppSpacing.xs + 2),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: colors.colorBorderMedium,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                AppSpacing.sm, AppSpacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: colors.colorSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: colors.colorBorderSubtle, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          venue.name[0],
                          style: AppTextStyles.displayL(
                              colors.colorBorderMedium),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
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
                                      colors.colorTextPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (venue.hasTheBox)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colors.colorAccentPrimary
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(
                                        color: colors.colorAccentPrimary
                                            .withValues(alpha: 0.3),
                                        width: 0.5),
                                  ),
                                  child: Text(
                                    'THE BOX',
                                    style: AppTextStyles.overline(
                                        colors.colorAccentPrimary),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: colors.colorWarning, size: 13),
                              const SizedBox(width: 3),
                              Text('${venue.rating}',
                                  style: AppTextStyles.labelM(
                                      colors.colorTextPrimary)),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                width: 3, height: 3,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.colorTextTertiary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(venue.area,
                                  style: AppTextStyles.bodyS(
                                      colors.colorTextSecondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  color: colors.colorTextTertiary, size: 12),
                              const SizedBox(width: 4),
                              Text('Open till ${venue.closingTime}',
                                  style: AppTextStyles.bodyS(
                                      colors.colorTextSecondary)),
                              if (userLocation != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  width: 3, height: 3,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.colorTextTertiary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  _distanceLabel(userLocation!, venue),
                                  style: AppTextStyles.bodyS(
                                      colors.colorTextSecondary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (courts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
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
                              horizontal: AppSpacing.md),
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
                                  _sportEmojiMap[c.sport] ?? '',
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

                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            context.push(AppRoutes.venueById(venue.id)),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.colorAccentPrimary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            boxShadow: AppShadow.fab,
                          ),
                          child: Center(
                            child: Text(
                              'Book a Slot',
                              style: AppTextStyles.headingS(
                                  colors.colorTextOnAccent),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    GestureDetector(
                      onTap: () =>
                          context.push(AppRoutes.venueById(venue.id)),
                      child: Container(
                        height: 48, width: 48,
                        decoration: BoxDecoration(
                          color: colors.colorSurfacePrimary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: colors.colorBorderSubtle, width: 0.5),
                        ),
                        child: Icon(Icons.arrow_forward_rounded,
                            color: colors.colorTextPrimary, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: bottomPad + AppSpacing.lg),
        ],
      ),
    );
  }
}
