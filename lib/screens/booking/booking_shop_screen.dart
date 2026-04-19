// lib/screens/booking/booking_shop_screen.dart
//
// Step 3 — mini-shop.
// Performance: cartProvider is watched ONCE at the root; a Map<id,qty>
// is passed to all child widgets so individual product cards are
// plain StatelessWidgets with no Riverpod subscriptions of their own.
// Product lists are cached in initState — no repeated FakeData calls.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../models/cart_item.dart';
import '../../providers/booking_flow_provider.dart' hide CartItem;
import '../../providers/cart_provider.dart';
import 'booking_step_widgets.dart';

// ─────────────────────────────────────────────────────────────────

class _CatMeta {
  final String   label;
  final IconData icon;
  final Color    color;
  const _CatMeta(this.label, this.icon, this.color);
}

const _kCategories = <_CatMeta>[
  _CatMeta('Hydration',  Icons.water_drop_rounded,        Color(0xFF0EA5E9)),
  _CatMeta('Nutrition',  Icons.fitness_center_rounded,    Color(0xFF22C55E)),
  _CatMeta('Equipment',  Icons.sports_basketball_rounded, Color(0xFFFF6B35)),
  _CatMeta('Footwear',   Icons.directions_run_rounded,    Color(0xFF8B5CF6)),
  _CatMeta('Apparel',    Icons.checkroom_rounded,         Color(0xFFF59E0B)),
  _CatMeta('Protection', Icons.shield_rounded,            Color(0xFFEC4899)),
];

// IDs for the "Order Again" simulated row
const _kRepeatIds = ['p1', 'p10', 'p13'];

// ─────────────────────────────────────────────────────────────────
//  ROOT SCREEN
// ─────────────────────────────────────────────────────────────────

class BookingShopScreen extends ConsumerStatefulWidget {
  const BookingShopScreen({super.key});

  @override
  ConsumerState<BookingShopScreen> createState() => _BookingShopScreenState();
}

class _BookingShopScreenState extends ConsumerState<BookingShopScreen> {
  String? _activeCategory;

  // Cached product lists — built once, never recomputed in build()
  late final Map<String, List<Product>> _byCategory;
  late final List<Product>              _deals;
  late final List<Product>              _repeatBuys;

  @override
  void initState() {
    super.initState();
    _byCategory = {
      for (final c in _kCategories)
        c.label: FakeData.productsByCategory(c.label),
    };
    _deals = FakeData.products
        .where((p) => p.discountPercent >= 20)
        .toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    _repeatBuys = _kRepeatIds
        .map((id) => FakeData.productById(id))
        .whereType<Product>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // ── SINGLE cart watch ─────────────────────────────────────────
    final cart      = ref.watch(cartProvider);
    final flow      = ref.watch(bookingFlowProvider);
    final colors    = context.colors;
    final botPad    = MediaQuery.of(context).padding.bottom;

    // Build a flat id→qty map once; pass it down to every card.
    final quantities = <String, int>{
      for (final item in cart.products) item.id: item.quantity,
    };

    void addToCart(Product p) {
      ref.read(cartProvider.notifier).addItem(CartItem(
        id:       p.id,
        name:     p.name,
        price:    p.price,
        imageUrl: p.image,
        type:     CartItemType.product,
      ));
    }

    void updateQty(String id, int qty) =>
        ref.read(cartProvider.notifier).updateQuantity(id, qty);

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          BookingWizardNav(
            currentStep: 3,
            venueId:     flow.venueId,
            onBack:      () => context.pop(),
          ),

          _CategoryStrip(
            activeCategory: _activeCategory,
            colors:         colors,
            onSelect: (cat) => setState(() => _activeCategory = cat),
          ),

          Expanded(
            child: _activeCategory == null
                ? _AllView(
                    byCategory: _byCategory,
                    deals:      _deals,
                    repeatBuys: _repeatBuys,
                    colors:     colors,
                    venueId:    flow.venueId,
                    venueName:  flow.venue?.name ?? 'your venue',
                    quantities: quantities,
                    addToCart:  addToCart,
                    updateQty:  updateQty,
                    onShowAll:  (cat) => setState(() => _activeCategory = cat),
                  )
                : _CategoryView(
                    products:   _byCategory[_activeCategory] ?? [],
                    category:   _activeCategory!,
                    colors:     colors,
                    venueId:    flow.venueId,
                    quantities: quantities,
                    addToCart:  addToCart,
                    updateQty:  updateQty,
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _ShopFooter(
        cartCount: cart.productCount,
        cartTotal: cart.products.fold(0, (s, i) => s + i.total),
        venueId:   flow.venueId,
        colors:    colors,
        botPad:    botPad,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  CATEGORY STRIP
// ─────────────────────────────────────────────────────────────────

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.activeCategory,
    required this.colors,
    required this.onSelect,
  });

  final String?              activeCategory;
  final AppColorScheme       colors;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.colorBackgroundPrimary,
        border: Border(bottom: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 7),
        children: [
          _CatChip(
            label:    'All',
            icon:     Icons.grid_view_rounded,
            color:    colors.colorAccentPrimary,
            isActive: activeCategory == null,
            colors:   colors,
            onTap:    () => onSelect(null),
          ),
          ...List.generate(_kCategories.length, (i) {
            final c = _kCategories[i];
            return Padding(
              padding: const EdgeInsets.only(left: 7),
              child: _CatChip(
                label:    c.label,
                icon:     c.icon,
                color:    c.color,
                isActive: activeCategory == c.label,
                colors:   colors,
                onTap:    () => onSelect(activeCategory == c.label ? null : c.label),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });

  final String         label;
  final IconData       icon;
  final Color          color;
  final bool           isActive;
  final AppColorScheme colors;
  final VoidCallback   onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color:        isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isActive ? color : colors.colorBorderSubtle,
            width: isActive ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: isActive ? color : colors.colorTextTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize:   10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color:      isActive ? color : colors.colorTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  ALL VIEW
// ─────────────────────────────────────────────────────────────────

class _AllView extends StatelessWidget {
  const _AllView({
    required this.byCategory,
    required this.deals,
    required this.repeatBuys,
    required this.colors,
    required this.venueId,
    required this.venueName,
    required this.quantities,
    required this.addToCart,
    required this.updateQty,
    required this.onShowAll,
  });

  final Map<String, List<Product>> byCategory;
  final List<Product>              deals;
  final List<Product>              repeatBuys;
  final AppColorScheme             colors;
  final String                     venueId;
  final String                     venueName;
  final Map<String, int>           quantities;
  final void Function(Product)     addToCart;
  final void Function(String, int) updateQty;
  final ValueChanged<String>       onShowAll;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ── Hero header ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
          child: _ShopHero(colors: colors, venueName: venueName),
        ),

        // ── Flash Deals ─────────────────────────────────────────
        if (deals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _SectionHeader(
              label: '⚡  FLASH DEALS',
              sub:   'Best prices right now',
              colors: colors,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProductRow(
            products:   deals.take(8).toList(),
            catColor:   const Color(0xFFE8112D),
            colors:     colors,
            venueId:    venueId,
            quantities: quantities,
            addToCart:  addToCart,
            updateQty:  updateQty,
            showDeal:   true,
          ),
        ],

        // ── Order Again ─────────────────────────────────────────
        if (repeatBuys.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _SectionHeader(
              label: '🔁  ORDER AGAIN',
              sub:   'Your usual picks',
              colors: colors,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _RepeatBuyRow(
            products:   repeatBuys,
            colors:     colors,
            venueId:    venueId,
            quantities: quantities,
            addToCart:  addToCart,
            updateQty:  updateQty,
          ),
        ],

        // ── Category sections ────────────────────────────────────
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _SectionHeader(
            label:  'BROWSE CATEGORIES',
            colors: colors,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _CategoryGrid(colors: colors, onTap: onShowAll),
        ),

        ...List.generate(_kCategories.length, (ci) {
          final cat   = _kCategories[ci];
          final items = byCategory[cat.label] ?? [];
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color:        cat.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(cat.icon, size: 11, color: cat.color),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        cat.label.toUpperCase(),
                        style: AppTextStyles.overline(colors.colorTextTertiary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onShowAll(cat.label),
                      child: Text(
                        'All ${items.length} →',
                        style: AppTextStyles.bodyS(colors.colorAccentPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProductRow(
                products:   items.take(8).toList(),
                catColor:   cat.color,
                colors:     colors,
                venueId:    venueId,
                quantities: quantities,
                addToCart:  addToCart,
                updateQty:  updateQty,
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  CATEGORY VIEW — 2-col grid
// ─────────────────────────────────────────────────────────────────

class _CategoryView extends StatelessWidget {
  const _CategoryView({
    required this.products,
    required this.category,
    required this.colors,
    required this.venueId,
    required this.quantities,
    required this.addToCart,
    required this.updateQty,
  });

  final List<Product>              products;
  final String                     category;
  final AppColorScheme             colors;
  final String                     venueId;
  final Map<String, int>           quantities;
  final void Function(Product)     addToCart;
  final void Function(String, int) updateQty;

  static const _catColors = {
    'Hydration':  Color(0xFF0EA5E9),
    'Nutrition':  Color(0xFF22C55E),
    'Equipment':  Color(0xFFFF6B35),
    'Footwear':   Color(0xFF8B5CF6),
    'Apparel':    Color(0xFFF59E0B),
    'Protection': Color(0xFFEC4899),
  };

  @override
  Widget build(BuildContext context) {
    final catColor = _catColors[category] ?? colors.colorAccentPrimary;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing:  AppSpacing.sm,
        childAspectRatio: 0.74,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(
        product:   products[i],
        catColor:  catColor,
        colors:    colors,
        venueId:   venueId,
        quantity:  quantities[products[i].id] ?? 0,
        onAdd:     () => addToCart(products[i]),
        onMinus:   () => updateQty(products[i].id, (quantities[products[i].id] ?? 1) - 1),
        onPlus:    () => updateQty(products[i].id, (quantities[products[i].id] ?? 0) + 1),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SHOP HERO HEADER
// ─────────────────────────────────────────────────────────────────

class _ShopHero extends StatelessWidget {
  const _ShopHero({required this.colors, required this.venueName});
  final AppColorScheme colors;
  final String         venueName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            colors.colorSurfaceElevated,
            colors.colorSurfacePrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GEAR UP',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: colors.colorTextPrimary, letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Delivered to $venueName\nbefore your slot.',
                  style: AppTextStyles.bodyS(colors.colorTextSecondary)
                      .copyWith(height: 1.45),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.local_shipping_rounded,
                      label: '25–35 min',
                      color: colors.colorSuccess,
                      colors: colors,
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      icon: Icons.bolt_rounded,
                      label: 'FREE delivery',
                      color: colors.colorAccentPrimary,
                      colors: colors,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('🏀', style: const TextStyle(fontSize: 52)),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.colors,
  });
  final IconData       icon;
  final String         label;
  final Color          color;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border:       Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.colors,
    this.sub,
  });
  final String         label;
  final String?        sub;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.headingS(colors.colorTextPrimary)),
        if (sub != null) ...[
          const SizedBox(height: 1),
          Text(sub!, style: AppTextStyles.bodyS(colors.colorTextTertiary)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  CATEGORY GRID (2×3 browse tiles)
// ─────────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.colors, required this.onTap});
  final AppColorScheme       colors;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount:   3,
      shrinkWrap:       true,
      physics:          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing:  AppSpacing.sm,
      childAspectRatio: 2.4,
      children: _kCategories.map((c) => GestureDetector(
        onTap: () => onTap(c.label),
        child: Container(
          decoration: BoxDecoration(
            color:        c.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border:       Border.all(color: c.color.withValues(alpha: 0.18), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(c.icon, size: 12, color: c.color),
              const SizedBox(width: 5),
              Text(
                c.label,
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600, color: c.color,
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PRODUCT ROW — horizontal scroll of small cards
// ─────────────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.products,
    required this.catColor,
    required this.colors,
    required this.venueId,
    required this.quantities,
    required this.addToCart,
    required this.updateQty,
    this.showDeal = false,
  });

  final List<Product>              products;
  final Color                      catColor;
  final AppColorScheme             colors;
  final String                     venueId;
  final Map<String, int>           quantities;
  final void Function(Product)     addToCart;
  final void Function(String, int) updateQty;
  final bool                       showDeal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 158,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics:         const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: products.length,
        itemBuilder: (_, i) {
          final p   = products[i];
          final qty = quantities[p.id] ?? 0;
          return Padding(
            padding: EdgeInsets.only(right: i < products.length - 1 ? 10 : 0),
            child: _ProductCard(
              product:  p,
              catColor: catColor,
              colors:   colors,
              venueId:  venueId,
              quantity: qty,
              showDeal: showDeal,
              onAdd:    () => addToCart(p),
              onMinus:  () => updateQty(p.id, qty - 1),
              onPlus:   () => updateQty(p.id, qty + 1),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  REPEAT BUY ROW — compact horizontal list tiles
// ─────────────────────────────────────────────────────────────────

class _RepeatBuyRow extends StatelessWidget {
  const _RepeatBuyRow({
    required this.products,
    required this.colors,
    required this.venueId,
    required this.quantities,
    required this.addToCart,
    required this.updateQty,
  });

  final List<Product>              products;
  final AppColorScheme             colors;
  final String                     venueId;
  final Map<String, int>           quantities;
  final void Function(Product)     addToCart;
  final void Function(String, int) updateQty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color:        colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border:       Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        children: List.generate(products.length, (i) {
          final p      = products[i];
          final qty    = quantities[p.id] ?? 0;
          final isLast = i == products.length - 1;
          return Column(
            children: [
              GestureDetector(
                onTap: () => context.push(
                  AppRoutes.productDetail(p.id),
                  extra: <String, String>{'fromBooking': venueId},
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color:        _catColor(p.category).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(
                          child: Text(_catEmoji(p.category),
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: AppTextStyles.headingS(colors.colorTextPrimary)
                                    .copyWith(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('₹${p.price}',
                                style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SmallQtyControl(
                        qty:     qty,
                        color:   colors.colorAccentPrimary,
                        onAdd:   () => addToCart(p),
                        onMinus: () => updateQty(p.id, qty - 1),
                        onPlus:  () => updateQty(p.id, qty + 1),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Container(height: 0.5, color: colors.colorBorderSubtle,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md)),
            ],
          );
        }),
      ),
    );
  }

  Color  _catColor(String c) => _kCategories
      .firstWhere((m) => m.label == c,
          orElse: () => _kCategories.first)
      .color;

  String _catEmoji(String c) {
    switch (c.toLowerCase()) {
      case 'hydration':  return '💧';
      case 'nutrition':  return '💪';
      case 'equipment':  return '🏀';
      case 'footwear':   return '👟';
      case 'apparel':    return '👕';
      case 'protection': return '🛡️';
      default:           return '📦';
    }
  }
}

// ─────────────────────────────────────────────────────────────────
//  PRODUCT CARD — plain StatelessWidget (no Riverpod)
// ─────────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.catColor,
    required this.colors,
    required this.venueId,
    required this.quantity,
    required this.onAdd,
    required this.onMinus,
    required this.onPlus,
    this.showDeal = false,
  });

  final Product        product;
  final Color          catColor;
  final AppColorScheme colors;
  final String         venueId;
  final int            quantity;
  final VoidCallback   onAdd;
  final VoidCallback   onMinus;
  final VoidCallback   onPlus;
  final bool           showDeal;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final p      = widget.product;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) {
        setState(() => _pressed = false);
        context.push(
          AppRoutes.productDetail(p.id),
          extra: <String, String>{'fromBooking': widget.venueId},
        );
      },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.96 : 1.0,
        duration: Duration(milliseconds: _pressed ? 70 : 140),
        curve:    _pressed ? Curves.easeIn : Curves.elasticOut,
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color:        colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border:       Border.all(color: colors.colorBorderSubtle, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area ──────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft:  Radius.circular(AppRadius.card),
                  topRight: Radius.circular(AppRadius.card),
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 76, width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                          colors: [
                            widget.catColor.withValues(alpha: 0.14),
                            widget.catColor.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _catEmoji(p.category),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    // Deal badge
                    if (widget.showDeal && p.discountPercent > 0)
                      Positioned(
                        top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color:        colors.colorAccentPrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${p.discountPercent}% OFF',
                            style: GoogleFonts.inter(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Info area ───────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: AppTextStyles.headingS(colors.colorTextPrimary)
                            .copyWith(fontSize: 11, height: 1.25),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '₹${p.price}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: colors.colorTextPrimary,
                              ),
                            ),
                          ),
                          _SmallQtyControl(
                            qty:     widget.quantity,
                            color:   widget.catColor,
                            onAdd:   widget.onAdd,
                            onMinus: widget.onMinus,
                            onPlus:  widget.onPlus,
                          ),
                        ],
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
  }

  String _catEmoji(String c) {
    switch (c.toLowerCase()) {
      case 'hydration':  return '💧';
      case 'nutrition':  return '💪';
      case 'equipment':  return '🏀';
      case 'footwear':   return '👟';
      case 'apparel':    return '👕';
      case 'protection': return '🛡️';
      default:           return '📦';
    }
  }
}

// ─────────────────────────────────────────────────────────────────
//  SMALL QUANTITY CONTROL
// ─────────────────────────────────────────────────────────────────

class _SmallQtyControl extends StatelessWidget {
  const _SmallQtyControl({
    required this.qty,
    required this.color,
    required this.onAdd,
    required this.onMinus,
    required this.onPlus,
  });

  final int          qty;
  final Color        color;
  final VoidCallback onAdd;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return GestureDetector(
        onTap: onAdd,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color:        color,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
        ),
      );
    }

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border:       Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap:    onMinus,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 22, height: 24,
              child: Icon(Icons.remove_rounded, size: 11, color: color),
            ),
          ),
          SizedBox(
            width: 16,
            child: Text(
              '$qty',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11, fontWeight: FontWeight.w700, color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap:    onPlus,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 22, height: 24,
              child: Icon(Icons.add_rounded, size: 11, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SHOP FOOTER
// ─────────────────────────────────────────────────────────────────

class _ShopFooter extends StatelessWidget {
  const _ShopFooter({
    required this.cartCount,
    required this.cartTotal,
    required this.venueId,
    required this.colors,
    required this.botPad,
  });

  final int          cartCount;
  final int          cartTotal;
  final String       venueId;
  final AppColorScheme colors;
  final double       botPad;

  @override
  Widget build(BuildContext context) {
    final isEmpty = cartCount == 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md,
          AppSpacing.lg, AppSpacing.md + botPad),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        border: Border(top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navBar,
      ),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.bookCart(venueId)),
        child: AnimatedContainer(
          duration: AppDuration.fast,
          height: 52,
          decoration: BoxDecoration(
            color: isEmpty
                ? colors.colorSurfaceElevated
                : colors.colorAccentPrimary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: isEmpty
                ? Border.all(color: colors.colorBorderMedium, width: 0.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color:        Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$cartCount item${cartCount == 1 ? '' : 's'}',
                    style: AppTextStyles.labelS(Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                isEmpty ? 'Skip — no items' : 'Review Cart  ·  ₹$cartTotal',
                style: isEmpty
                    ? AppTextStyles.headingS(colors.colorTextTertiary)
                    : AppTextStyles.headingS(Colors.white),
              ),
              if (!isEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
