enum BookingStatus { upcoming, completed, cancelled }

class BookingRecord {
  const BookingRecord({
    required this.id,
    required this.venueName,
    this.courtName,
    required this.sport,
    required this.date,
    required this.timeSlot,
    required this.amount,
    required this.status,
    this.hasStats = false,
    this.addons = const [],
  });

  final String id;
  final String venueName;
  final String? courtName;
  final String sport;
  final String date;
  final String timeSlot;
  final int amount;
  final BookingStatus status;
  final bool hasStats;
  final List<String> addons;
}
