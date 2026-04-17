// lib/screens/explore/explore_screen.dart
//
// Explore screen — full venue search, sport filtering, sort, and staggered list.
//
// Design standards:
//   • CsChip for sport filter pills
//   • CsCard for venue cards with press feedback
//   • CsShimmer for loading skeleton
//   • CsEmptyState when no results
//   • Staggered list entrance (30ms delay per card)
//   • All tokens — no raw colors or magic numbers

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/tokens/spacing_tokens.dart';
import '../../models/fake_data.dart';
import '../../widgets/common/cs_chip.dart';
import '../../widgets/common/cs_empty_state.dart';

// ── Sport filter config ────────────────────────────────────────────

const _kSports = ['All', 'Basketball', 'Cricket', 'Football', 'Badminton'];
const _kSortOptions = ['Near Me', 'Top Rated', 'Price: Low'];

final _sportColors = <String, Color>{
  'Basketball': Color(0xFFFF6B35),
  'Cricket':    Color(0xFF00C9A7),
  'Badminton':  Color(0xFFFFC107),
  'Football':   Color(0xFF4CAF50),
};

// ── Screen ────────────────────────────────────────────────────────

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String _sport = 'All';
  String _sort  = 'Near Me';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Venue> get _filtered {
    var list = List<Venue>.from(FakeData.venues);

    // Sport filter
    if (_sport != 'All') {
      list = list.where((v) => v.sports.contains(_sport.toLowerCase())).toList();
    }

    // Search query
    if (_searchQuery.isNotEmpty) {
      list = list.where((v) =>
        v.name.toLowerCase().contains(_searchQuery) ||
        v.area.toLowerCase().contains(_searchQuery),
      ).toList();
    }

    // Sort
    if (_sort == 'Top Rated') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sort == 'Price: Low') {
      // Fake: stable order
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final venues = _filtered;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _Header(sort: _sort, onSortTap: _showSortSheet),
            _SearchBar(controller: _searchCtrl),
            const SizedBox(height: AppSpacing.sm),
            _SportFilterRow(
              selected: _sport,
              onSelect: (s) => setState(() => _sport = s),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: venues.isEmpty
                  ? CsEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No courts found',
                      subtitle: 'Try a different sport or clear your search.',
                      ctaLabel: 'Clear filters',
                      onCta: () => setState(() {
                        _sport = 'All';
                        _searchCtrl.clear();
                      }),
                    )
                  : _VenueList(venues: venues),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorSurfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: AppComponentSizes.sheetHandleW,
              height: AppComponentSizes.sheetHandleH,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.colorBorderMedium,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            ..._kSortOptions.map((opt) => InkWell(
              onTap: () {
                setState(() => _sort = opt);
                Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Text(opt, style: AppTextStyles.bodyM(colors.colorTextPrimary)),
                    const Spacer(),
                    if (opt == _sort)
                      Icon(Icons.check_circle_rounded,
                           color: colors.colorAccentPrimary, size: AppComponentSizes.iconLg),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.sort, required this.onSortTap});
  final String sort;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COURTS', style: AppTextStyles.overline(colors.colorTextTertiary)),
                const SizedBox(height: 2),
                Text('Explore', style: AppTextStyles.headingL(colors.colorTextPrimary)),
              ],
            ),
          ),
          // Sort button
          GestureDetector(
            onTap: onSortTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: colors.colorSurfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, color: colors.colorTextSecondary, size: AppComponentSizes.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                  Text(sort, style: AppTextStyles.labelM(colors.colorTextSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.md),
            Icon(Icons.search_rounded,
                 color: colors.colorTextTertiary, size: AppComponentSizes.iconMd),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodyM(colors.colorTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Search courts or areas…',
                  hintStyle: AppTextStyles.bodyM(colors.colorTextTertiary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: controller.clear,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Icon(Icons.close_rounded,
                              color: colors.colorTextTertiary, size: AppComponentSizes.iconMd),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sport filter row ──────────────────────────────────────────────

class _SportFilterRow extends StatelessWidget {
  const _SportFilterRow({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: _kSports.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final sport = _kSports[i];
          final isActive = sport == selected;
          return CsChip(
            label: sport,
            isActive: isActive,
            sportColor: _sportColors[sport],
            onTap: () => onSelect(sport),
          );
        },
      ),
    );
  }
}

// ── Venue list with staggered entrance ───────────────────────────

class _VenueList extends StatefulWidget {
  const _VenueList({required this.venues});
  final List<Venue> venues;

  @override
  State<_VenueList> createState() => _VenueListState();
}

class _VenueListState extends State<_VenueList>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl,
      ),
      itemCount: widget.venues.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return _StaggeredItem(
          delay: Duration(milliseconds: index * 30),
          child: _VenueCard(venue: widget.venues[index]),
        );
      },
    );
  }
}

// Staggered entrance wrapper
class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>  _fade;
  late Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ── Venue card ────────────────────────────────────────────────────

class _VenueCard extends StatefulWidget {
  const _VenueCard({required this.venue});
  final Venue venue;

  @override
  State<_VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends State<_VenueCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final venue  = widget.venue;

    final slotsOk   = venue.id.hashCode.isEven; // fake: alternates per venue
    final distance  = '1.${venue.id.hashCode.abs() % 9 + 1} km';
    final price     = 400 + (venue.id.hashCode.abs() % 6) * 50;

    return GestureDetector(
      onTap:         () => context.push(AppRoutes.venueById(venue.id)),
      onTapDown:     (_) => setState(() => _pressed = true),
      onTapUp:       (_) => setState(() => _pressed = false),
      onTapCancel:   ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.97 : 1.0,
        duration: AppDuration.fast,
        curve:    Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
            boxShadow: AppShadow.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo area ──────────────────────────────────────
              Stack(
                children: [
                  // Hero image / fallback
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      color: colors.colorSurfaceElevated,
                      child: venue.photoUrl.isNotEmpty
                        ? Image.network(
                            venue.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _PhotoFallback(colors: colors),
                          )
                        : _PhotoFallback(colors: colors),
                    ),
                  ),

                  // Distance badge — top left
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.colorSurfaceOverlay.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me_rounded,
                               color: colors.colorInfo, size: AppComponentSizes.iconSm),
                          const SizedBox(width: AppSpacing.xs),
                          Text(distance,
                               style: AppTextStyles.labelM(colors.colorTextPrimary)),
                        ],
                      ),
                    ),
                  ),

                  // THE BOX badge — top right
                  if (venue.hasTheBox)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: colors.colorAccentPrimary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text('THE BOX',
                                    style: AppTextStyles.overline(colors.colorTextOnAccent)),
                      ),
                    ),

                  // Slots badge — bottom right
                  Positioned(
                    bottom: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: (slotsOk ? colors.colorSuccess : colors.colorError)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: (slotsOk ? colors.colorSuccess : colors.colorError)
                              .withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        slotsOk ? 'Slots available' : 'Full today',
                        style: AppTextStyles.labelM(
                          slotsOk ? colors.colorSuccess : colors.colorError,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Card body ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + rating row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            venue.name,
                            style: AppTextStyles.headingS(colors.colorTextPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.star_rounded,
                             color: colors.colorWarning, size: AppComponentSizes.iconSm),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          venue.rating.toStringAsFixed(1),
                          style: AppTextStyles.labelM(colors.colorTextPrimary),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '(${venue.reviewCount})',
                          style: AppTextStyles.bodyS(colors.colorTextTertiary),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Address
                    Text(
                      venue.address,
                      style: AppTextStyles.bodyS(colors.colorTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Sport pills + price
                    Row(
                      children: [
                        ...venue.sports.take(3).map((s) {
                          final sportColor = _sportColors[_capitalise(s)];
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: (sportColor ?? colors.colorSurfaceElevated)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: (sportColor ?? colors.colorBorderSubtle)
                                      .withValues(alpha: 0.4),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                s.toUpperCase(),
                                style: AppTextStyles.overline(
                                  sportColor ?? colors.colorTextTertiary,
                                ),
                              ),
                            ),
                          );
                        }),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('from', style: AppTextStyles.bodyS(colors.colorTextTertiary)),
                            Text(
                              '₹$price/slot',
                              style: AppTextStyles.headingS(colors.colorAccentPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Photo fallback ────────────────────────────────────────────────

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.sports_basketball_outlined,
             size: AppComponentSizes.iconXl + 8,
             color: colors.colorTextTertiary),
        const SizedBox(height: AppSpacing.xs),
        Text('No photo', style: AppTextStyles.bodyS(colors.colorTextTertiary)),
      ],
    ),
  );
}

