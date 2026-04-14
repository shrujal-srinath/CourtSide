import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/fake_data.dart';

class BookingDraft {
  final Venue? venue;
  final Court? court;
  final Slot? slot;
  final List<CartAddon> addons;

  BookingDraft({
    this.venue,
    this.court,
    this.slot,
    this.addons = const [],
  });

  BookingDraft copyWith({
    Venue? venue,
    Court? court,
    Slot? slot,
    List<CartAddon>? addons,
  }) {
    return BookingDraft(
      venue: venue ?? this.venue,
      court: court ?? this.court,
      slot: slot ?? this.slot,
      addons: addons ?? this.addons,
    );
  }

  int get basePrice => court?.pricePerSlot ?? 0;
  int get addonsTotal => addons.fold(0, (sum, a) => sum + a.price);
  int get totalAmount => basePrice + addonsTotal;

  bool get isValid => venue != null && court != null && slot != null;
}

class BookingDraftNotifier extends StateNotifier<BookingDraft> {
  BookingDraftNotifier() : super(BookingDraft());

  void setBooking(Venue venue, Court court, Slot slot) {
    state = state.copyWith(
      venue: venue,
      court: court,
      slot: slot,
      addons: [], // Reset addons for new booking draft
    );
  }

  void toggleAddon(CartAddon addon) {
    final addons = [...state.addons];
    if (addons.any((a) => a.id == addon.id)) {
      addons.removeWhere((a) => a.id == addon.id);
    } else {
      addons.add(addon);
    }
    state = state.copyWith(addons: addons);
  }

  void clear() {
    state = BookingDraft();
  }
}

final bookingDraftProvider = StateNotifierProvider<BookingDraftNotifier, BookingDraft>((ref) {
  return BookingDraftNotifier();
});
