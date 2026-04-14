// lib/providers/booking_flow_provider.dart
//
// Shared state for the 4-step booking wizard.
// Slot + Court are set by BookingScreen before pushing to step 1.
// Each step screen reads and writes its slice via the notifier.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fake_data.dart';

// ═══════════════════════════════════════════════════════════════
//  CART ITEM — wraps a ShopItem with a quantity
// ═══════════════════════════════════════════════════════════════

class CartItem {
  const CartItem({required this.item, this.quantity = 1});
  final ShopItem item;
  final int quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(item: item, quantity: quantity ?? this.quantity);

  int get subtotal => item.price * quantity;
}

// ═══════════════════════════════════════════════════════════════
//  BOOKING FLOW STATE
// ═══════════════════════════════════════════════════════════════

enum SkillLevel { all, beginner, intermediate, competitive }

class BookingFlowState {
  const BookingFlowState({
    this.venueId = '',
    this.sport = '',
    this.venue,
    this.court,
    this.slot,
    this.date,
    this.invitedFriendIds = const [],
    this.cartItems = const [],
    this.hardware,
    this.isPublicGame = false,
    this.playerLimit = 10,
    this.skillLevel = SkillLevel.all,
  });

  final String venueId;
  final String sport;
  final Venue? venue;
  final Court? court;
  final Slot? slot;
  final DateTime? date;
  final List<String> invitedFriendIds;
  final List<CartItem> cartItems;
  final HardwareOption? hardware;
  final bool isPublicGame;
  final int playerLimit;
  final SkillLevel skillLevel;

  int get courtTotal => court?.pricePerSlot ?? 0;
  int get shopTotal  => cartItems.fold(0, (s, i) => s + i.subtotal);
  int get hwTotal    => hardware?.pricePerGame ?? 0;
  int get grandTotal => courtTotal + shopTotal + hwTotal;

  BookingFlowState copyWith({
    String? venueId,
    String? sport,
    Venue? venue,
    Court? court,
    Slot? slot,
    DateTime? date,
    List<String>? invitedFriendIds,
    List<CartItem>? cartItems,
    HardwareOption? hardware,
    bool clearHardware = false,
    bool? isPublicGame,
    int? playerLimit,
    SkillLevel? skillLevel,
  }) {
    return BookingFlowState(
      venueId:          venueId          ?? this.venueId,
      sport:            sport            ?? this.sport,
      venue:            venue            ?? this.venue,
      court:            court            ?? this.court,
      slot:             slot             ?? this.slot,
      date:             date             ?? this.date,
      invitedFriendIds: invitedFriendIds ?? this.invitedFriendIds,
      cartItems:        cartItems        ?? this.cartItems,
      hardware:         clearHardware ? null : (hardware ?? this.hardware),
      isPublicGame:     isPublicGame     ?? this.isPublicGame,
      playerLimit:      playerLimit      ?? this.playerLimit,
      skillLevel:       skillLevel       ?? this.skillLevel,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════════

class BookingFlowNotifier extends Notifier<BookingFlowState> {
  @override
  BookingFlowState build() => const BookingFlowState();

  // Called by BookingScreen before navigating to step 1
  void init({
    required String venueId,
    required String sport,
    required Venue venue,
    required Court court,
    required Slot slot,
    required DateTime date,
  }) {
    state = BookingFlowState(
      venueId: venueId,
      sport: sport,
      venue: venue,
      court: court,
      slot: slot,
      date: date,
    );
  }

  // ── Step 1: Friends + Game settings ─────────────────────────

  void toggleFriend(String friendId) {
    final ids = [...state.invitedFriendIds];
    if (ids.contains(friendId)) {
      ids.remove(friendId);
    } else {
      ids.add(friendId);
    }
    state = state.copyWith(invitedFriendIds: ids);
  }

  void setPublicGame(bool isPublic) =>
      state = state.copyWith(isPublicGame: isPublic);

  void setPlayerLimit(int limit) =>
      state = state.copyWith(playerLimit: limit);

  void setSkillLevel(SkillLevel level) =>
      state = state.copyWith(skillLevel: level);

  // ── Step 2: Shop ─────────────────────────────────────────────

  void addItem(ShopItem item) {
    final items = [...state.cartItems];
    final idx = items.indexWhere((c) => c.item.id == item.id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
    } else {
      items.add(CartItem(item: item));
    }
    state = state.copyWith(cartItems: items);
  }

  void removeItem(ShopItem item) {
    final items = [...state.cartItems];
    final idx = items.indexWhere((c) => c.item.id == item.id);
    if (idx < 0) return;
    if (items[idx].quantity > 1) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity - 1);
    } else {
      items.removeAt(idx);
    }
    state = state.copyWith(cartItems: items);
  }

  int quantityOf(String itemId) {
    for (final c in state.cartItems) {
      if (c.item.id == itemId) return c.quantity;
    }
    return 0;
  }

  // ── Step 3: Hardware ─────────────────────────────────────────

  void selectHardware(HardwareOption? option) {
    state = state.copyWith(
      hardware: option,
      clearHardware: option == null,
    );
  }

  // ── Reset ────────────────────────────────────────────────────

  void reset() => state = const BookingFlowState();
}

final bookingFlowProvider =
    NotifierProvider<BookingFlowNotifier, BookingFlowState>(
        BookingFlowNotifier.new);
