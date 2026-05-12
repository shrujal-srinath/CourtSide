enum SlotStatus { available, booked, blocked }

class Court {
  const Court({
    required this.id,
    required this.venueId,
    required this.sport,
    required this.name,
    required this.surface,
    required this.isIndoor,
    required this.pricePerSlot,
    required this.slotDurationMin,
    required this.hasTheBox,
    required this.slotsAvailableToday,
  });

  final String id;
  final String venueId;
  final String sport;
  final String name;
  final String surface;
  final bool isIndoor;
  final int pricePerSlot;
  final int slotDurationMin;
  final bool hasTheBox;
  final int slotsAvailableToday;
}

class Slot {
  const Slot({
    required this.id,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  final String id;
  final String courtId;
  final String startTime;
  final String endTime;
  final SlotStatus status;
}
