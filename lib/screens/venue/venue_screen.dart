// lib/screens/venue/venue_screen.dart
//
// Venues tab — Playo-style court discovery.
// List-first with map toggle. Search + sport filter. Sorted by distance.

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import '../../core/app_spacing.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';

// ═══════════════════════════════════════════════════════════════
//  VENUE SCREEN
// ═══════════════════════════════════════════════════════════════

class VenueScreen extends ConsumerStatefulWidget {
  const VenueScreen({super.key});

  @override
  ConsumerState<VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends ConsumerState<VenueScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────
  String _search = '';
  String _activeSport = 'all';
  bool _mapView = false;
  LatLng? _userLocation;
  String? _mapStyle;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  static const _bengaluru = LatLng(12.9716, 77.5946);

  static const _sports = [
    ('all',        'All',        ''),
    ('football',   'Football',   '⚽'),
    ('basketball', 'Basketball', '🏀'),
    ('cricket',    'Cricket',    '🏏'),
    ('badminton',  'Badminton',  '🏸'),
  ];

  // ── Init ──────────────────────────────────────────────────────

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
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _userLocation = _bengaluru);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final raw = LatLng(pos.latitude, pos.longitude);
      final loc = _isInIndia(raw) ? raw : _bengaluru;
      setState(() => _userLocation = loc);
      _buildMarkers();
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 13));
    } catch (_) {
      if (mounted) setState(() => _userLocation = _bengaluru);
      _buildMarkers();
    }
  }

  bool _isInIndia(LatLng p) =>
      p.latitude >= 8 && p.latitude <= 37 &&
      p.longitude >= 68 && p.longitude <= 97;

  Future<void> _loadMapStyle() async {
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final file = isDark
          ? 'assets/map_style_dark.json'
          : 'assets/map_style_light.json';
      final style = await DefaultAssetBundle.of(context).loadString(file);
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────

  double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.asin(math.sqrt(h));
  }

  String _distanceLabel(Venue v) {
    final loc = _userLocation ?? _bengaluru;
    final km = _haversineKm(loc, LatLng(v.lat, v.lng));
    return km < 1.0 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
  }

  List<Venue> get _filtered {
    var venues = List<Venue>.from(FakeData.venues);
    if (_activeSport != 'all') {
      venues = venues.where((v) => v.sports.contains(_activeSport)).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      venues = venues
          .where((v) =>
              v.name.toLowerCase().contains(q) ||
              v.area.toLowerCase().contains(q))
          .toList();
    }
    // Sort by distance
    final loc = _userLocation ?? _bengaluru;
    venues.sort((a, b) {
      final da = _haversineKm(loc, LatLng(a.lat, a.lng));
      final db = _haversineKm(loc, LatLng(b.lat, b.lng));
      return da.compareTo(db);
    });
    return venues;
  }

  int _minPrice(Venue v) {
    final courts = FakeData.courts.where((c) => c.venueId == v.id).toList();
    if (courts.isEmpty) return 400;
    return courts.map((c) => c.pricePerSlot).reduce(math.min);
  }

  Color _sportColor(String sport) {
    switch (sport) {
      case 'basketball': return AppColors.basketball;
      case 'cricket':    return AppColors.cricket;
      case 'badminton':  return AppColors.badminton;
      default:           return AppColors.football;
    }
  }

  double _markerHue(String sport) {
    switch (sport) {
      case 'basketball': return BitmapDescriptor.hueOrange;
      case 'cricket':    return 180.0;
      case 'badminton':  return BitmapDescriptor.hueYellow;
      default:           return BitmapDescriptor.hueGreen;
    }
  }

  void _buildMarkers() {
    final venues = _filtered;
    setState(() {
      _markers = venues.map((v) => Marker(
        markerId: MarkerId(v.id),
        position: LatLng(v.lat, v.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          v.sports.isNotEmpty ? _markerHue(v.sports.first) : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: v.name,
          snippet: v.area,
          onTap: () => context.push(AppRoutes.venueById(v.id)),
        ),
      )).toSet();
    });
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final venues = _filtered;

    return Scaffold(
      backgroundColor: context.col.bg,
      body: Column(
        children: [
          _VenueHeader(
            topPad: topPad,
            search: _search,
            activeSport: _activeSport,
            mapView: _mapView,
            sports: _sports,
            onSearchChanged: (v) {
              setState(() => _search = v);
              if (_mapView) _buildMarkers();
            },
            onSportChanged: (s) {
              setState(() => _activeSport = s);
              if (_mapView) _buildMarkers();
            },
            onToggleMap: () {
              setState(() => _mapView = !_mapView);
              if (_mapView) _buildMarkers();
            },
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _mapView
                  ? _MapView(
                      key: const ValueKey('map'),
                      userLocation: _userLocation ?? _bengaluru,
                      markers: _markers,
                      mapStyle: _mapStyle,
                      onMapCreated: (c) {
                        _mapController = c;
                        if (_userLocation != null) {
                          c.animateCamera(
                              CameraUpdate.newLatLngZoom(_userLocation!, 13));
                        }
                      },
                    )
                  : _ListView(
                      key: const ValueKey('list'),
                      venues: venues,
                      distanceLabel: _distanceLabel,
                      minPrice: _minPrice,
                      sportColor: _sportColor,
                      onTap: (v) => context.push(AppRoutes.venueById(v.id)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HEADER (search + sport chips + map toggle)
// ═══════════════════════════════════════════════════════════════

class _VenueHeader extends StatefulWidget {
  const _VenueHeader({
    required this.topPad,
    required this.search,
    required this.activeSport,
    required this.mapView,
    required this.sports,
    required this.onSearchChanged,
    required this.onSportChanged,
    required this.onToggleMap,
  });

  final double topPad;
  final String search;
  final String activeSport;
  final bool mapView;
  final List<(String, String, String)> sports;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSportChanged;
  final VoidCallback onToggleMap;

  @override
  State<_VenueHeader> createState() => _VenueHeaderState();
}

class _VenueHeaderState extends State<_VenueHeader> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.search);
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.col.bg,
      padding: EdgeInsets.fromLTRB(18, widget.topPad + 12, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Venues',
                      style: AppTextStyles.headingL(context.col.text)),
                  Text('Book courts near you',
                      style: AppTextStyles.bodyS(context.col.textSec)),
                ],
              ),
              const Spacer(),
              // Map / List toggle
              GestureDetector(
                onTap: widget.onToggleMap,
                child: AnimatedContainer(
                  duration: AppDuration.fast,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.mapView
                        ? AppColors.red.withValues(alpha: 0.15)
                        : context.col.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: widget.mapView
                          ? AppColors.red.withValues(alpha: 0.5)
                          : context.col.border,
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    widget.mapView
                        ? Icons.view_list_rounded
                        : Icons.map_outlined,
                    color: widget.mapView
                        ? AppColors.red
                        : context.col.textSec,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search bar
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: context.col.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.col.border, width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: context.col.textSec, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    style: AppTextStyles.bodyM(context.col.text),
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search venues or areas...',
                      hintStyle: AppTextStyles.bodyM(context.col.textSec),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_ctrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _ctrl.clear();
                      widget.onSearchChanged('');
                    },
                    child: Icon(Icons.close_rounded,
                        color: context.col.textTer, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Sport chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: widget.sports.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (id, label, emoji) = widget.sports[i];
                final active = widget.activeSport == id;
                return GestureDetector(
                  onTap: () => widget.onSportChanged(id),
                  child: AnimatedContainer(
                    duration: AppDuration.fast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.red : context.col.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: active ? AppColors.red : context.col.border,
                        width: 0.5,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.red.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
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
                          style: AppTextStyles.labelS(
                            active
                                ? AppColors.white
                                : context.col.textSec,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          // Divider
          Container(height: 0.5, color: context.col.border),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LIST VIEW
// ═══════════════════════════════════════════════════════════════

class _ListView extends StatelessWidget {
  const _ListView({
    super.key,
    required this.venues,
    required this.distanceLabel,
    required this.minPrice,
    required this.sportColor,
    required this.onTap,
  });

  final List<Venue> venues;
  final String Function(Venue) distanceLabel;
  final int Function(Venue) minPrice;
  final Color Function(String) sportColor;
  final ValueChanged<Venue> onTap;

  @override
  Widget build(BuildContext context) {
    if (venues.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏟', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No venues found',
                style: AppTextStyles.headingM(context.col.text)),
            const SizedBox(height: 6),
            Text('Try a different sport or search term',
                style: AppTextStyles.bodyM(context.col.textSec)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: venues.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _VenueCard(
        venue: venues[i],
        distanceLabel: distanceLabel(venues[i]),
        minPrice: minPrice(venues[i]),
        sportColor: sportColor,
        onTap: () => onTap(venues[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  VENUE CARD
// ═══════════════════════════════════════════════════════════════

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.distanceLabel,
    required this.minPrice,
    required this.sportColor,
    required this.onTap,
  });

  final Venue venue;
  final String distanceLabel;
  final int minPrice;
  final Color Function(String) sportColor;
  final VoidCallback onTap;

  // Deterministic accent per venue (no randomness)
  Color _accentFor(Venue v) {
    if (v.sports.contains('basketball')) return AppColors.basketball;
    if (v.sports.contains('cricket'))    return AppColors.cricket;
    if (v.sports.contains('badminton'))  return AppColors.badminton;
    return AppColors.football;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(venue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.col.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: context.col.isDark
                  ? AppColors.black.withValues(alpha: 0.4)
                  : AppColors.creamBorder.withValues(alpha: 0.9),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo area ────────────────────────────────────────
            Stack(
              children: [
                // Shimmer placeholder
                Shimmer.fromColors(
                  baseColor: context.col.surfaceHigh,
                  highlightColor: context.col.overlay,
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: context.col.surfaceHigh,
                  ),
                ),
                // Coloured gradient overlay with initial letter
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.25),
                        context.col.surfaceHigh.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      venue.name[0],
                      style: AppTextStyles.displayXL(
                          accent.withValues(alpha: 0.35)),
                    ),
                  ),
                ),
                // THE BOX badge
                if (venue.hasTheBox)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text('THE BOX',
                          style: AppTextStyles.overline(AppColors.white)),
                    ),
                  ),
                // Distance badge (top right)
                Positioned(
                  top: 10,
                  right: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.col.overlay.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: context.col.border,
                              width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me_rounded,
                                color: context.col.text, size: 10),
                            const SizedBox(width: 4),
                            Text(distanceLabel,
                                style: AppTextStyles.labelS(context.col.text)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Content ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style:
                              AppTextStyles.headingM(context.col.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.warning, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            venue.rating.toStringAsFixed(1),
                            style:
                                AppTextStyles.labelM(context.col.text),
                          ),
                          Text(
                            ' (${venue.reviewCount})',
                            style: AppTextStyles.bodyS(
                                context.col.textSec),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Area
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: context.col.textTer, size: 12),
                      const SizedBox(width: 3),
                      Text(venue.area,
                          style: AppTextStyles.bodyS(
                              context.col.textSec)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sport chips + price + book button row
                  Row(
                    children: [
                      // Sport dots
                      ...venue.sports.take(3).map((s) => Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: sportColor(s).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: sportColor(s).withValues(alpha: 0.35),
                                  width: 0.5),
                            ),
                            child: Center(
                              child: Text(
                                _sportEmoji(s),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          )),
                      const Spacer(),
                      // Price
                      Text(
                        'From ₹$minPrice',
                        style: AppTextStyles.bodyS(context.col.textSec),
                      ),
                      const SizedBox(width: 10),
                      // Book button
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.red.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text('Book',
                            style: AppTextStyles.labelM(AppColors.white)),
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

  String _sportEmoji(String sport) {
    switch (sport) {
      case 'basketball': return '🏀';
      case 'cricket':    return '🏏';
      case 'badminton':  return '🏸';
      default:           return '⚽';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAP VIEW
// ═══════════════════════════════════════════════════════════════

class _MapView extends StatelessWidget {
  const _MapView({
    super.key,
    required this.userLocation,
    required this.markers,
    required this.mapStyle,
    required this.onMapCreated,
  });

  final LatLng userLocation;
  final Set<Marker> markers;
  final String? mapStyle;
  final Function(GoogleMapController) onMapCreated;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(
        target: userLocation,
        zoom: 13,
      ),
      markers: markers,
      style: mapStyle,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }
}
