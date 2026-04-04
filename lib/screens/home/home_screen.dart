import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'widgets/home_header.dart';
import 'widgets/sport_selector_panel.dart';

// ── Venue model (temporary until Supabase is wired) ────────────

class _Venue {
  const _Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.sports,
    required this.rating,
    required this.closingTime,
    this.hasTheBox = false,
  });
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final List<String> sports;
  final double rating;
  final String closingTime;
  final bool hasTheBox;
}

// Seeded Bengaluru venues — replace with Supabase query later
const _seedVenues = [
  _Venue(
    id: '1',
    name: 'Koramangala Sports Hub',
    address: '5th Block, Koramangala',
    lat: 12.9352,
    lng: 77.6245,
    sports: ['basketball', 'cricket'],
    rating: 4.7,
    closingTime: '10 PM',
    hasTheBox: true,
  ),
  _Venue(
    id: '2',
    name: 'Indiranagar Court',
    address: '12th Main, Indiranagar',
    lat: 12.9784,
    lng: 77.6408,
    sports: ['basketball', 'badminton'],
    rating: 4.5,
    closingTime: '9 PM',
    hasTheBox: false,
  ),
  _Venue(
    id: '3',
    name: 'HSR Sports Arena',
    address: 'Sector 6, HSR Layout',
    lat: 12.9116,
    lng: 77.6473,
    sports: ['cricket', 'football'],
    rating: 4.8,
    closingTime: '11 PM',
    hasTheBox: true,
  ),
  _Venue(
    id: '4',
    name: 'Whitefield Box Arena',
    address: 'ITPL Main Rd, Whitefield',
    lat: 12.9698,
    lng: 77.7499,
    sports: ['cricket', 'basketball'],
    rating: 4.3,
    closingTime: '10 PM',
    hasTheBox: true,
  ),
  _Venue(
    id: '5',
    name: 'BTM Sports Complex',
    address: 'BTM 2nd Stage',
    lat: 12.9166,
    lng: 77.6101,
    sports: ['football', 'badminton'],
    rating: 4.2,
    closingTime: '9 PM',
    hasTheBox: false,
  ),
];

// ── Home screen ────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  String? _selectedSport;
  Set<Marker> _markers = {};
  bool _locationLoading = true;

  // Bengaluru centre fallback
  static const _bengaluruCentre = LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────────

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallback();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallback();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setFallback();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _locationLoading = false;
        });
        _buildMarkers();
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_userLocation!, 14),
        );
      }
    } catch (_) {
      _setFallback();
    }
  }

  void _setFallback() {
    if (mounted) {
      setState(() {
        _userLocation = _bengaluruCentre;
        _locationLoading = false;
      });
      _buildMarkers();
    }
  }

  // ── Markers ─────────────────────────────────────────────────

  void _buildMarkers() {
    final venues = _selectedSport == null
        ? _seedVenues
        : _seedVenues
            .where((v) => v.sports.contains(_selectedSport))
            .toList();

    setState(() {
      _markers = venues.map((venue) {
        return Marker(
          markerId: MarkerId(venue.id),
          position: LatLng(venue.lat, venue.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          onTap: () => _showVenueSheet(venue),
        );
      }).toSet();
    });
  }

  void _onSportSelected(String? sport) {
    if (sport != null) {
      // Navigate to dedicated sport screen
      context.push('/sport/$sport');
    } else {
      // "View all" — clear filter, show all pins
      setState(() => _selectedSport = null);
      _buildMarkers();
    }
  }

  // ── Map style (dark) ─────────────────────────────────────────

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    final style = await rootBundle.loadString('assets/map_style_dark.json');
    controller.setMapStyle(style);
    if (_userLocation != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 14),
      );
    }
  }

  // ── Venue bottom sheet ───────────────────────────────────────

  void _showVenueSheet(_Venue venue) {
    // Default to selected sport if available and venue supports it
    String activeTab = _selectedSport != null &&
            venue.sports.contains(_selectedSport)
        ? _selectedSport!
        : venue.sports.first;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _VenueBottomSheet(
        venue: venue,
        initialSport: activeTab,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          // ── Status bar space + Header ──────────────────────
          SizedBox(height: topPadding),
          const HomeHeader(),

          // ── Map ───────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _userLocation ?? _bengaluruCentre,
                    zoom: 13,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                ),

                // Loading overlay
                if (_locationLoading)
                  Container(
                    color: AppColors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.red,
                        strokeWidth: 2,
                      ),
                    ),
                  ),

                // Recenter button
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _RecenterBtn(
                    onTap: () {
                      if (_userLocation != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(_userLocation!, 14),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Sport selector panel ──────────────────────────
          SportSelectorPanel(
            onSportSelected: _onSportSelected,
            onViewAll: () => _onSportSelected(null),
          ),
        ],
      ),
    );
  }
}

// ── Recenter button ────────────────────────────────────────────

class _RecenterBtn extends StatelessWidget {
  const _RecenterBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: const Icon(
          Icons.my_location_rounded,
          color: AppColors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ── Venue bottom sheet ─────────────────────────────────────────

class _VenueBottomSheet extends StatefulWidget {
  const _VenueBottomSheet({
    required this.venue,
    required this.initialSport,
  });
  final _Venue venue;
  final String initialSport;

  @override
  State<_VenueBottomSheet> createState() => _VenueBottomSheetState();
}

class _VenueBottomSheetState extends State<_VenueBottomSheet> {
  late String _activeSport;

  // Dummy slot data — replace with Supabase later
  final _slots = ['6 AM', '8 AM', '10 AM', '5 PM', '7 PM', '9 PM'];
  final _bookedSlots = {'8 AM', '10 AM'};

  static const _sportLabels = {
    'basketball': '🏀 Basketball',
    'cricket': '🏏 Box Cricket',
    'badminton': '🏸 Badminton',
    'football': '⚽ Football',
  };

  static const _prices = {
    'basketball': '₹400 / 45 min',
    'cricket': '₹600 / 60 min',
    'badminton': '₹300 / 45 min',
    'football': '₹500 / 60 min',
  };

  @override
  void initState() {
    super.initState();
    _activeSport = widget.initialSport;
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
    final showTabs = venue.sports.length > 1;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Venue name + meta ────────────────────────
                Text(
                  venue.name,
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 12, color: AppColors.textSecondaryDark),
                    const SizedBox(width: 3),
                    Text(
                      '${venue.address}  ·  Open till ${venue.closingTime}  ·  ${venue.rating} ★',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),

                // ── Sport tabs (only if multi-sport + view all) ──
                if (showTabs) ...[
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: venue.sports.map((sport) {
                        final active = sport == _activeSport;
                        return GestureDetector(
                          onTap: () => setState(() => _activeSport = sport),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.red
                                  : AppColors.black,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? AppColors.red
                                    : AppColors.border,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _sportLabels[sport] ?? sport,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? AppColors.white
                                    : AppColors.textSecondaryDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Court info rows ──────────────────────────
                _InfoRow(
                  label: 'Court',
                  value: _activeSport == 'cricket'
                      ? 'Turf A · Outdoor'
                      : 'Court 1 · Indoor',
                ),
                _InfoRow(
                  label: 'Price',
                  value: _prices[_activeSport] ?? '₹400 / slot',
                ),
                _InfoRow(
                  label: 'THE BOX',
                  value: venue.hasTheBox ? 'Equipped ✓' : 'Not equipped',
                  valueColor:
                      venue.hasTheBox ? AppColors.red : AppColors.textSecondaryDark,
                ),

                const SizedBox(height: 14),

                // ── Slot chips ───────────────────────────────
                Text(
                  'Available today',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slots.map((slot) {
                    final taken = _bookedSlots.contains(slot);
                    return _SlotChip(slot: slot, taken: taken);
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // ── CTAs ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: navigate to booking screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Book ${_sportLabels[_activeSport] ?? _activeSport}  ·  ${_prices[_activeSport]?.split(' / ').first ?? ''}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: navigate to full venue detail screen
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryDark,
                      side: BorderSide(color: AppColors.border, width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View full venue →',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ── Info row ───────────────────────────────────────────────────

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
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slot chip ──────────────────────────────────────────────────

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.slot, required this.taken});
  final String slot;
  final bool taken;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: taken
            ? AppColors.black.withValues(alpha: 0.5)
            : const Color(0xFF0F6E56).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: taken
              ? AppColors.border
              : const Color(0xFF1D9E75).withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        slot,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: taken ? FontWeight.w400 : FontWeight.w600,
          color: taken
              ? AppColors.textSecondaryDark.withValues(alpha: 0.4)
              : const Color(0xFF5DCAA5),
          decoration: taken ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}