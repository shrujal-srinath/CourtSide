import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  String? _activeCategory;
  bool _isSearchActive = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _bannerController = PageController();
  int _currentBanner = 0;
  Timer? _bannerTimer;

  static const _categoryMeta = [
    _CatMeta('Hydration', Icons.water_drop_rounded, Color(0xFF0EA5E9)),
    _CatMeta('Nutrition', Icons.fitness_center_rounded, Color(0xFF22C55E)),
    _CatMeta('Equipment', Icons.sports_basketball_rounded, Color(0xFFFF6B35)),
    _CatMeta('Footwear', Icons.directions_run_rounded, Color(0xFF8B5CF6)),
    _CatMeta('Apparel', Icons.checkroom_rounded, Color(0xFFF59E0B)),
    _CatMeta('Protection', Icons.shield_rounded, Color(0xFFEC4899)),
  ];

  static const _banners = [
    _BannerData('⚡ QUICK DELIVERY', 'Gear before\nyour game', 'Delivered in 30 mins', Icons.bolt_rounded, Color(0xFF0F0A1A), Color(0xFF8B5CF6)),
    _BannerData('🏀 NEW ARRIVALS', 'Basketball\nseason is here', 'Shop latest equipment', Icons.sports_basketball_rounded, Color(0xFF1A0A08), Color(0xFFFF6B35)),
    _BannerData('💪 NUTRITION DEALS', 'Up to 40% off\non protein', 'MuscleBlaze, ON & more', Icons.fitness_center_rounded, Color(0xFF081A0A), Color(0xFF22C55E)),
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_currentBanner + 1) % _banners.length;
      _bannerController.animateToPage(next,
          duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cart = ref.watch(cartProvider);

    return PopScope(
      canPop: _activeCategory == null && !_isSearchActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            if (_isSearchActive) {
              _isSearchActive = false;
              _searchQuery = '';
              _searchController.clear();
            } else {
              _activeCategory = null;
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: colors.colorBackgroundPrimary,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, colors, cart),
              Expanded(
                child: _activeCategory != null
                    ? _buildCategoryView(context, colors)
                    : _isSearchActive
                        ? _buildSearchView(context, colors)
                        : _buildHomeView(context, colors),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: cart.isEmpty ? null : _buildCartBadge(context, cart, colors),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, dynamic colors, CartState cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (!_isSearchActive) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: colors.colorAccentPrimary, size: 20),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Delivering to', style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 10)),
                        Row(
                          children: [
                            Text('Koramangala', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                            const SizedBox(width: 3),
                            Icon(Icons.keyboard_arrow_down_rounded, color: colors.colorTextSecondary, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push(AppRoutes.orderHistory),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.colorSurfacePrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: colors.colorTextSecondary, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.cart),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.colorSurfacePrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
                        ),
                        child: Icon(Icons.shopping_bag_outlined, color: colors.colorTextPrimary, size: 20),
                      ),
                      if (cart.items.isNotEmpty)
                        Positioned(
                          top: 4, right: 4,
                          child: Container(
                            width: 15, height: 15,
                            decoration: BoxDecoration(color: colors.colorAccentPrimary, shape: BoxShape.circle),
                            child: Center(child: Text('${cart.items.length}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: () => setState(() { _isSearchActive = false; _searchQuery = ''; _searchController.clear(); }),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.colorTextPrimary, size: 18),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.colorSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: colors.colorTextTertiary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: AppTextStyles.bodyM(colors.colorTextPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search socks, balls, protein...',
                          hintStyle: AppTextStyles.bodyM(colors.colorTextTertiary),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() { _searchQuery = ''; _searchController.clear(); }),
                        child: Icon(Icons.close_rounded, color: colors.colorTextTertiary, size: 18),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Home view ─────────────────────────────────────────────────

  Widget _buildHomeView(BuildContext context, dynamic colors) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildSearchBar(context, colors),
        _buildPromoStrip(context, colors),
        _buildHeroBanners(context, colors),
        _buildCategoryChips(context, colors),
        _buildDealsSection(context, colors),
        _buildBrandsRow(context, colors),
        for (final cat in _categoryMeta)
          _buildCategorySection(context, colors, cat),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, dynamic colors) {
    return GestureDetector(
      onTap: () => setState(() => _isSearchActive = true),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: colors.colorSurfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colors.colorTextTertiary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Search socks, balls, protein...', style: AppTextStyles.bodyM(colors.colorTextTertiary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.colorAccentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('SEARCH', style: AppTextStyles.overline(colors.colorAccentPrimary).copyWith(fontSize: 9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoStrip(BuildContext context, dynamic colors) {
    final promises = [
      (Icons.bolt_rounded, '30 min', 'Delivery'),
      (Icons.replay_rounded, '7-day', 'Returns'),
      (Icons.verified_rounded, '100%', 'Genuine'),
      (Icons.local_offer_rounded, 'Best', 'Prices'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: List.generate(promises.length * 2 - 1, (idx) {
            if (idx.isOdd) {
              return VerticalDivider(width: 1, color: colors.colorBorderSubtle, indent: 10, endIndent: 10);
            }
            final p = promises[idx ~/ 2];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p.$1, color: colors.colorAccentPrimary, size: 16),
                    const SizedBox(height: 4),
                    Text(p.$2, style: AppTextStyles.headingS(colors.colorTextPrimary).copyWith(fontSize: 11)),
                    Text(p.$3, style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 9)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeroBanners(BuildContext context, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          SizedBox(
            height: 144,
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (i) => setState(() => _currentBanner = i),
              itemCount: _banners.length,
              itemBuilder: (_, i) => _buildBannerCard(_banners[i]),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBanner == i ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: _currentBanner == i ? colors.colorAccentPrimary : colors.colorBorderMedium,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(_BannerData b) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [b.bgColor, Color.lerp(b.bgColor, b.accentColor, 0.08)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: b.accentColor.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Large faded background circle
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: b.accentColor.withValues(alpha: 0.07)),
            ),
          ),
          // Small accent circle
          Positioned(
            right: 80, bottom: -20,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, color: b.accentColor.withValues(alpha: 0.05)),
            ),
          ),
          // Big icon
          Positioned(
            right: 10, bottom: -8,
            child: Icon(b.icon, size: 100, color: b.accentColor.withValues(alpha: 0.18)),
          ),
          // Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 110, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: b.accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(b.label, style: AppTextStyles.overline(b.accentColor).copyWith(fontSize: 8)),
                  ),
                  const SizedBox(height: 6),
                  Text(b.title, style: AppTextStyles.headingM(Colors.white), maxLines: 2),
                  const SizedBox(height: 3),
                  Text(b.subtitle, style: AppTextStyles.bodyS(Colors.white.withValues(alpha: 0.5)).copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: b.accentColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: b.accentColor.withValues(alpha: 0.35), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('SHOP NOW', style: AppTextStyles.overline(b.accentColor).copyWith(fontSize: 9)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: b.accentColor, size: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SHOP BY CATEGORY', style: AppTextStyles.overline(colors.colorTextTertiary)),
                Text('${FakeData.products.length} products', style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 10)),
              ],
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categoryMeta.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categoryMeta[i];
                return GestureDetector(
                  onTap: () => setState(() => _activeCategory = cat.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.colorSurfacePrimary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: cat.color.withValues(alpha: 0.25), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 15),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.name, style: AppTextStyles.headingS(colors.colorTextPrimary).copyWith(fontSize: 12)),
                            Text('${FakeData.productsByCategory(cat.name).length} items', style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsSection(BuildContext context, dynamic colors) {
    final deals = FakeData.products.where((p) => p.discountPercent >= 28).toList();
    if (deals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Red accent header bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.colorAccentPrimary, const Color(0xFFB50022)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text("TODAY'S DEALS", style: AppTextStyles.headingS(Colors.white)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text('UP TO ${deals.map((p) => p.discountPercent).reduce((a, b) => a > b ? a : b)}% OFF',
                        style: AppTextStyles.overline(Colors.white).copyWith(fontSize: 9)),
                  ),
                ],
              ),
              Text('${deals.length} deals', style: AppTextStyles.bodyS(Colors.white.withValues(alpha: 0.8)).copyWith(fontSize: 11)),
            ],
          ),
        ),
        SizedBox(
          height: 252,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: deals.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _ProductCard(product: deals[i]),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildBrandsRow(BuildContext context, dynamic colors) {
    const brands = ['Nike', 'Adidas', 'Yonex', 'NIVIA', 'Decathlon', 'SG', 'Tynor', 'Fast&Up'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text('BRANDS WE CARRY', style: AppTextStyles.overline(colors.colorTextTertiary)),
        ),
        SizedBox(
          height: 34,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: brands.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: colors.colorSurfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(brands[i], style: AppTextStyles.labelM(colors.colorTextSecondary).copyWith(fontSize: 11, letterSpacing: 0.3)),
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, dynamic colors, _CatMeta cat) {
    final products = FakeData.productsByCategory(cat.name);
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(cat.name, style: AppTextStyles.headingS(colors.colorTextPrimary)),
                  const SizedBox(width: 6),
                  Text('(${products.length})', style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 11)),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _activeCategory = cat.name),
                child: Row(
                  children: [
                    Text('See all', style: AppTextStyles.bodyM(colors.colorAccentPrimary).copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, color: colors.colorAccentPrimary, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 252,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _ProductCard(product: products[i]),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Category view ─────────────────────────────────────────────

  Widget _buildCategoryView(BuildContext context, dynamic colors) {
    final meta = _categoryMeta.firstWhere((c) => c.name == _activeCategory, orElse: () => _categoryMeta.first);
    List<Product> products = FakeData.productsByCategory(_activeCategory!);
    if (_searchQuery.isNotEmpty) {
      products = products.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.colorTextPrimary, size: 18),
                onPressed: () => setState(() { _activeCategory = null; _searchQuery = ''; _searchController.clear(); }),
              ),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(meta.icon, color: meta.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(_activeCategory!, style: AppTextStyles.headingM(colors.colorTextPrimary))),
              Text('${products.length} items', style: AppTextStyles.bodyM(colors.colorTextTertiary)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GestureDetector(
            onTap: () => setState(() => _isSearchActive = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: colors.colorSurfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: colors.colorTextTertiary, size: 18),
                  const SizedBox(width: 10),
                  Text('Search in ${_activeCategory!.toLowerCase()}...', style: AppTextStyles.bodyM(colors.colorTextTertiary)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.60,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) => _ProductCardGrid(product: products[i]),
          ),
        ),
      ],
    );
  }

  // ── Search view ───────────────────────────────────────────────

  Widget _buildSearchView(BuildContext context, dynamic colors) {
    if (_searchQuery.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('POPULAR SEARCHES', style: AppTextStyles.overline(colors.colorTextTertiary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Basketball', 'Protein', 'Socks', 'Gatorade', 'Cricket bat', 'Knee sleeve', 'Yonex']
                  .map((tag) => GestureDetector(
                        onTap: () => setState(() { _searchQuery = tag; _searchController.text = tag; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.colorSurfacePrimary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
                          ),
                          child: Text(tag, style: AppTextStyles.bodyM(colors.colorTextSecondary)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }

    final results = FakeData.products.where((p) =>
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: colors.colorBorderMedium),
            const SizedBox(height: 16),
            Text('No results for "$_searchQuery"', style: AppTextStyles.headingS(colors.colorTextTertiary)),
            const SizedBox(height: 8),
            Text('Try a different search term', style: AppTextStyles.bodyM(colors.colorTextTertiary)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) => _ProductCardGrid(product: results[i]),
    );
  }

  // ── Cart badge ────────────────────────────────────────────────

  Widget _buildCartBadge(BuildContext context, CartState cart, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.cart),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: colors.colorAccentPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadow.fab,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${cart.items.length} ITEM${cart.items.length == 1 ? '' : 'S'}', style: AppTextStyles.overline(Colors.white.withValues(alpha: 0.75))),
                  Text('₹${cart.totalAmount}', style: AppTextStyles.headingS(Colors.white)),
                ],
              ),
              Row(
                children: [
                  Text('VIEW CART', style: AppTextStyles.headingS(Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 13),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product card (horizontal scroll) ─────────────────────────

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.productDetail(product.id)),
      child: Container(
        width: 152,
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _catColor(product.category).withValues(alpha: 0.12),
                          _catColor(product.category).withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                    child: Center(child: Icon(_catIcon(product.category), size: 52, color: _catColor(product.category).withValues(alpha: 0.6))),
                  ),
                  if (!product.inStock)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                      ),
                      child: Center(child: Text('OUT OF\nSTOCK', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, height: 1.3))),
                    ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: colors.colorAccentPrimary, borderRadius: BorderRadius.circular(4)),
                      child: Text('${product.discountPercent}% OFF', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 10),
                          const SizedBox(width: 2),
                          Text('${product.rating}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.brand, style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 9)),
                    const SizedBox(height: 2),
                    Text(product.name, style: AppTextStyles.bodyM(colors.colorTextPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('₹${product.price}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                        const SizedBox(width: 4),
                        Text('₹${product.originalPrice}', style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(decoration: TextDecoration.lineThrough, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _AddButton(product: product),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product card (2-col grid) ─────────────────────────────────

class _ProductCardGrid extends ConsumerWidget {
  final Product product;
  const _ProductCardGrid({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.productDetail(product.id)),
      child: Container(
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _catColor(product.category).withValues(alpha: 0.13),
                          _catColor(product.category).withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                    child: Center(child: Icon(_catIcon(product.category), size: 58, color: _catColor(product.category).withValues(alpha: 0.65))),
                  ),
                  if (!product.inStock)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                      ),
                      child: Center(child: Text('OUT OF STOCK', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                    ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: colors.colorAccentPrimary, borderRadius: BorderRadius.circular(4)),
                      child: Text('${product.discountPercent}% OFF', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 11),
                          const SizedBox(width: 2),
                          Text('${product.rating}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(product.brand, style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(product.name, style: AppTextStyles.bodyM(colors.colorTextPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹${product.price}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                      const SizedBox(width: 4),
                      Text('₹${product.originalPrice}', style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(decoration: TextDecoration.lineThrough, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AddButton(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ADD / Qty button ──────────────────────────────────────────

class _AddButton extends ConsumerWidget {
  final Product product;
  const _AddButton({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final cartItems = ref.watch(cartProvider.select((s) => s.products));
    final item = cartItems.where((i) => i.id == product.id).firstOrNull;
    final qty = item?.quantity ?? 0;

    if (qty == 0) {
      return GestureDetector(
        onTap: () => ref.read(cartProvider.notifier).addItem(CartItem(
          id: product.id, name: product.name, price: product.price,
          imageUrl: product.image, type: CartItemType.product,
        )),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: colors.colorAccentPrimary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text('ADD', style: AppTextStyles.headingS(colors.colorAccentPrimary).copyWith(fontSize: 13))),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: colors.colorAccentPrimary, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(cartProvider.notifier).updateQuantity(product.id, qty - 1),
            child: const Padding(padding: EdgeInsets.all(7), child: Icon(Icons.remove, color: Colors.white, size: 14)),
          ),
          Expanded(child: Center(child: Text('$qty', style: AppTextStyles.headingS(Colors.white)))),
          GestureDetector(
            onTap: () => ref.read(cartProvider.notifier).updateQuantity(product.id, qty + 1),
            child: const Padding(padding: EdgeInsets.all(7), child: Icon(Icons.add, color: Colors.white, size: 14)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

Color _catColor(String cat) {
  switch (cat) {
    case 'Hydration': return const Color(0xFF0EA5E9);
    case 'Nutrition': return const Color(0xFF22C55E);
    case 'Equipment': return const Color(0xFFFF6B35);
    case 'Footwear': return const Color(0xFF8B5CF6);
    case 'Apparel': return const Color(0xFFF59E0B);
    case 'Protection': return const Color(0xFFEC4899);
    default: return const Color(0xFF6B7280);
  }
}

IconData _catIcon(String cat) {
  switch (cat) {
    case 'Hydration': return Icons.water_drop_rounded;
    case 'Nutrition': return Icons.fitness_center_rounded;
    case 'Equipment': return Icons.sports_basketball_rounded;
    case 'Footwear': return Icons.directions_run_rounded;
    case 'Apparel': return Icons.checkroom_rounded;
    case 'Protection': return Icons.shield_rounded;
    default: return Icons.shopping_bag_rounded;
  }
}

// ── Data classes ──────────────────────────────────────────────

class _CatMeta {
  final String name;
  final IconData icon;
  final Color color;
  const _CatMeta(this.name, this.icon, this.color);
}

class _BannerData {
  final String label;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color accentColor;
  const _BannerData(this.label, this.title, this.subtitle, this.icon, this.bgColor, this.accentColor);
}
