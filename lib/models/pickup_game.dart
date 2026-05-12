class PickupGame {
  const PickupGame({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.sport,
    required this.title,
    required this.time,
    required this.spotsTotal,
    required this.spotsFilled,
  });

  final String id;
  final String venueId;
  final String venueName;
  final String sport;
  final String title;
  final String time;
  final int spotsTotal;
  final int spotsFilled;

  int get spotsLeft => spotsTotal - spotsFilled;
}
