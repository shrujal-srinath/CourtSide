// lib/screens/venue/venue_screen.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';

import '../../models/fake_data.dart';

class VenueScreen extends ConsumerStatefulWidget {
  const VenueScreen({super.key});

  @override
  ConsumerState<VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends ConsumerState<VenueScreen> {
  bool _isMapMode = false;
  String _search = '';
  String _activeSport = 'all';
  String _activeTab = 'venues';

  LatLng? _userLocation;
  String? _mapStyle;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  final Map<String, BitmapDescriptor> _normalMarkers = {};
  final Map<String, BitmapDescriptor> _selectedMarkers = {};

  late PageController _pageController;
  int _focusedIndex = 0;

  static const _bengaluru = LatLng(12.9716, 77.5946);

  static const _sports = [
    ('all', 'All'),
    ('football', 'Football'),
    ('cricket', 'Cricket'),
    ('basketball', 'Basketball'),
    ('nearby', 'Nearby'),
  ];

  static const _tabs = [
    ('venues', 'Venues'),
    ('coaching', 'Coaching'),
    ('events', 'Events'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _initLocation();
    _prepareMarkers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapStyle();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String title, bool isSelected) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Fixed width label, handle overflow by textPainter ellipsis
    const double width = 140.0;
    const double height = 50.0;
    
    // Shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
    // Body RRect
    final RRect rrect = RRect.fromLTRBR(0, 0, width, 24, const Radius.circular(12));
    canvas.drawRRect(rrect.shift(const Offset(0, 4)), shadowPaint);
    
    // Background
    final Paint bgPaint = Paint()..color = isSelected ? AppColors.red : Colors.white;
    canvas.drawRRect(rrect, bgPaint);
    
    // Triangle Pin Bottom Center
    final Paint pinPaint = Paint()..color = isSelected ? AppColors.red : Colors.white;
    final Path pinPath = Path()
      ..moveTo(width / 2 - 5, 23)
      ..lineTo(width / 2 + 5, 23)
      ..lineTo(width / 2, 32)
      ..close();
    canvas.drawPath(pinPath, pinPaint);
    
    // Text Label
    final TextSpan textSpan = TextSpan(
      text: title,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
    
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
      textAlign: TextAlign.center,
    );
    textPainter.layout(minWidth: 0, maxWidth: width - 12);
    
    final xCenter = (width - textPainter.width) / 2;
    final yCenter = (24 - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(xCenter, yCenter));
    
    final img = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final data = await img.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<void> _prepareMarkers() async {
    for (var v in FakeData.venues) {
      _normalMarkers[v.id] = await _createCustomMarkerBitmap(v.name, false);
      _selectedMarkers[v.id] = await _createCustomMarkerBitmap(v.name, true);
    }
    if (mounted) _buildMarkers();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _userLocation = _bengaluru);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
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

  bool _isInIndia(LatLng p) => p.latitude >= 8 && p.latitude <= 37 && p.longitude >= 68 && p.longitude <= 97;

  Future<void> _loadMapStyle() async {
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final file = isDark ? 'assets/map_style_dark.json' : 'assets/map_style_light.json';
      final style = await DefaultAssetBundle.of(context).loadString(file);
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {}
  }

  double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180) * math.cos(b.latitude * math.pi / 180) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.asin(math.sqrt(h));
  }

  String _distanceLabel(Venue v) {
    final loc = _userLocation ?? _bengaluru;
    final km = _haversineKm(loc, LatLng(v.lat, v.lng));
    return km < 1.0 ? '${(km * 1000).round()} m' : '~${km.toStringAsFixed(1)} km';
  }

  List<Venue> get _filtered {
    var venues = List<Venue>.from(FakeData.venues);
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      venues = venues.where((v) => v.name.toLowerCase().contains(q) || v.area.toLowerCase().contains(q)).toList();
    }
    if (_activeSport != 'all' && _activeSport != 'nearby') {
      venues = venues.where((v) => v.sports.contains(_activeSport)).toList();
    }
    final loc = _userLocation ?? _bengaluru;
    venues.sort((a, b) => _haversineKm(loc, LatLng(a.lat, a.lng)).compareTo(_haversineKm(loc, LatLng(b.lat, b.lng))));
    return venues;
  }

  void _buildMarkers() {
    final venues = _filtered;
    setState(() {
      _markers = venues.asMap().entries.map((entry) {
        final i = entry.key;
        final v = entry.value;
        final isFocused = _focusedIndex == i;
        
        final icon = isFocused 
            ? (_selectedMarkers[v.id] ?? BitmapDescriptor.defaultMarker)
            : (_normalMarkers[v.id] ?? BitmapDescriptor.defaultMarker);
            
        return Marker(
          markerId: MarkerId(v.id),
          position: LatLng(v.lat, v.lng),
          icon: icon,
          anchor: const Offset(0.5, 0.7), // roughly anchor at bottom triangle
          zIndexInt: isFocused ? 10 : 1, // Bring to front when selected
          consumeTapEvents: true,
          onTap: () {
            if (_pageController.hasClients) {
              _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
            }
          },
        );
      }).toSet();
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _focusedIndex = index;
      _buildMarkers(); 
    });
    final venues = _filtered;
    if (venues.isNotEmpty && index < venues.length) {
      final v = venues[index];
      _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(v.lat, v.lng)));
    }
  }

  String _getVenueImage(Venue v) {
    if (v.photoUrl.isNotEmpty) return v.photoUrl;
    if (v.sports.contains('football')) return 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&q=80&w=800';
    if (v.sports.contains('cricket')) return 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&q=80&w=800';
    if (v.sports.contains('badminton')) return 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&q=80&w=800';
    return 'https://images.unsplash.com/photo-1546519638-68e109498ffc?auto=format&fit=crop&q=80&w=800';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: _isMapMode ? _buildMapMode(colors) : _buildListMode(colors),
    );
  }

  // ── LIST MODE (DEFAULT) ───────────────────────────────────────────────────
  Widget _buildListMode(AppColorScheme colors) {
    final topPad = MediaQuery.of(context).padding.top;
    final venues = _filtered;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: colors.colorSurfacePrimary,
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, topPad + AppSpacing.md, AppSpacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VENUES', style: AppTextStyles.headingM(colors.colorTextPrimary)),
                        const SizedBox(height: 2),
                        Text('Book courts near you', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isMapMode = true),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.colorSurfacePrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.colorBorderSubtle, width: 1),
                          boxShadow: AppShadow.card,
                        ),
                        child: Icon(Icons.map_outlined, color: colors.colorTextPrimary, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.colorBackgroundPrimary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.colorBorderSubtle, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: colors.colorTextTertiary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v),
                          style: AppTextStyles.bodyM(colors.colorTextPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search venues or areas...',
                            hintStyle: AppTextStyles.bodyM(colors.colorTextTertiary),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _sports.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final sp = _sports[i];
                      final active = _activeSport == sp.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _activeSport = sp.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? colors.colorAccentPrimary : colors.colorSurfaceElevated,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: active ? colors.colorAccentPrimary : colors.colorBorderSubtle, width: 1),
                          ),
                          child: Text(
                            sp.$2.toUpperCase(),
                            style: AppTextStyles.labelS(active ? Colors.white : colors.colorTextSecondary).copyWith(fontSize: 10, letterSpacing: 0.5),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Tabs
                Row(
                  children: _tabs.map((t) {
                    final active = _activeTab == t.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _activeTab = t.$1),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 8, right: 24),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: active ? colors.colorAccentPrimary : Colors.transparent, width: 2)),
                        ),
                        child: Text(
                          t.$2.toUpperCase(),
                          style: AppTextStyles.labelS(active ? colors.colorAccentPrimary : colors.colorTextSecondary).copyWith(letterSpacing: 0.5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Divider line full width
                Transform.translate(
                  offset: const Offset(0, -2),
                  child: Container(height: 1, width: double.infinity, color: colors.colorBorderSubtle),
                ),
              ],
            ),
          ),
        ),

        // List of Venues
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final v = venues[index];
                return _buildListVenueCard(v, colors);
              },
              childCount: venues.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListVenueCard(Venue v, AppColorScheme colors) {
    int slotsAvailable = FakeData.courts.where((crt) => crt.venueId == v.id).fold(0, (sum, crt) => sum + crt.slotsAvailableToday);
    bool available = slotsAvailable > 0;

    return GestureDetector(
      onTap: () => context.push('/venue/${v.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
          boxShadow: AppShadow.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (Height 160)
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(_getVenueImage(v), fit: BoxFit.cover),
                  // Overlays
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                      child: Text('AVAILABLE NOW', style: AppTextStyles.labelS(Colors.white).copyWith(fontSize: 10, letterSpacing: 0.5)),
                    ),
                  ),
                  const Positioned(
                    top: 12, right: 12,
                    child: Icon(Icons.favorite_border_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(v.name, style: AppTextStyles.headingS(colors.colorTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: colors.colorWarning, size: 16),
                          const SizedBox(width: 4),
                          Text('${v.rating}', style: AppTextStyles.labelS(colors.colorTextPrimary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  Text('${v.area} • ${_distanceLabel(v)}', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: available ? colors.colorSuccess : colors.colorError, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(available ? 'Slots Available Today' : 'Fully Booked', 
                          style: AppTextStyles.labelS(available ? colors.colorSuccess : colors.colorError).copyWith(fontSize: 11)),
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

  // ── MAP MODE ──────────────────────────────────────────────────────────────
  Widget _buildMapMode(AppColorScheme colors) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final venues = _filtered;

    return Stack(
      children: [
        // Map Background
        Positioned.fill(
          child: GoogleMap(
            onMapCreated: (mc) {
              _mapController = mc;
              if (_userLocation != null) mc.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 13));
              _buildMarkers();
            },
            initialCameraPosition: CameraPosition(target: _bengaluru, zoom: 13),
            markers: _markers,
            mapType: MapType.normal,
            style: _mapStyle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),
        ),

        // Top UI
        Positioned(
          top: 0, left: 0, right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, topPad + AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                color: colors.colorSurfacePrimary.withValues(alpha: 0.8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isMapMode = false),
                          child: Container(
                            height: 48, width: 48,
                            decoration: BoxDecoration(color: colors.colorSurfacePrimary, shape: BoxShape.circle, border: Border.all(color: colors.colorBorderSubtle, width: 0.5)),
                            child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.colorTextPrimary, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(color: colors.colorSurfacePrimary, borderRadius: BorderRadius.circular(24), border: Border.all(color: colors.colorBorderSubtle, width: 1)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(Icons.search_rounded, color: colors.colorTextTertiary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) {
                                      setState(() { _search = v; _focusedIndex = 0; });
                                      if (_pageController.hasClients) _pageController.jumpToPage(0);
                                      _buildMarkers();
                                    },
                                    style: AppTextStyles.bodyM(colors.colorTextPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'Search venues or areas...',
                                      hintStyle: AppTextStyles.bodyM(colors.colorTextTertiary),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _sports.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final sp = _sports[i];
                          final active = _activeSport == sp.$1;
                          return GestureDetector(
                            onTap: () {
                              setState(() { _activeSport = sp.$1; _focusedIndex = 0; });
                              if (_pageController.hasClients) _pageController.jumpToPage(0);
                              _buildMarkers();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active ? colors.colorAccentPrimary : colors.colorSurfacePrimary,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: active ? colors.colorAccentPrimary : colors.colorBorderSubtle, width: 1),
                              ),
                              child: Text(
                                sp.$2.toUpperCase(),
                                style: AppTextStyles.labelS(active ? Colors.white : colors.colorTextSecondary).copyWith(fontSize: 10, letterSpacing: 0.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // My Location Target Button
        Positioned(
          bottom: botPad + 184, // 160(card height) + 24(padding)
          right: 16,
          child: GestureDetector(
            onTap: () {
              if (_userLocation != null) {
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 14));
              } else {
                _initLocation();
              }
            },
            child: Container(
              height: 48, width: 48,
              decoration: BoxDecoration(
                color: colors.colorSurfacePrimary,
                shape: BoxShape.circle,
                boxShadow: AppShadow.card,
              ),
              child: Icon(Icons.my_location_rounded, color: colors.colorInfo, size: 24),
            ),
          ),
        ),

        // Bottom Map Cards (Height 160)
        if (venues.isNotEmpty)
          Positioned(
            bottom: botPad + 16,
            left: 0, right: 0,
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              itemCount: venues.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final v = venues[index];
                final isFocused = _focusedIndex == index;
                int slotsAvailable = FakeData.courts.where((crt) => crt.venueId == v.id).fold(0, (sum, crt) => sum + crt.slotsAvailableToday);
                bool available = slotsAvailable > 0;

                return AnimatedScale(
                  scale: isFocused ? 1.0 : 0.95,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: GestureDetector(
                    onTap: () => context.push('/venue/${v.id}'),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: colors.colorSurfacePrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadow.cardElevated,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          // Left Image
                          SizedBox(
                            width: 120, height: 160,
                            child: Image.network(_getVenueImage(v), fit: BoxFit.cover),
                          ),
                          // Right Content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.name, style: AppTextStyles.headingS(colors.colorTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('⭐ ${v.rating} • ${_distanceLabel(v)}', style: AppTextStyles.labelS(colors.colorTextSecondary)),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Container(width: 8, height: 8, decoration: BoxDecoration(color: available ? colors.colorSuccess : colors.colorError, shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Text(available ? 'Available Today' : 'Booked', style: AppTextStyles.labelS(available ? colors.colorSuccess : colors.colorError).copyWith(fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 36, width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => context.push('/venue/${v.id}'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.colorAccentPrimary.withValues(alpha: 0.1),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text('Check Slots →', style: AppTextStyles.labelS(colors.colorAccentPrimary)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
