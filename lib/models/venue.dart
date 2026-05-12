class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.lat,
    required this.lng,
    required this.sports,
    required this.rating,
    required this.reviewCount,
    this.openingTime = '6 AM',
    required this.closingTime,
    required this.photoUrl,
    required this.amenities,
    required this.isIndoor,
    this.hasTheBox = false,
  });

  final String id;
  final String name;
  final String address;
  final String area;
  final double lat;
  final double lng;
  final List<String> sports;
  final double rating;
  final int reviewCount;
  final String openingTime;
  final String closingTime;
  final String photoUrl;
  final List<String> amenities;
  final bool isIndoor;
  final bool hasTheBox;

  double distanceFromKm(double userLat, double userLng) {
    final dlat = (lat - userLat).abs();
    final dlng = (lng - userLng).abs();
    return ((dlat + dlng) * 111).clamp(0.3, 20.0);
  }
}
