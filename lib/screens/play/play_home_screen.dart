// lib/screens/play/play_home_screen.dart
//
// Play shell home — focused court list, dark background.
// No map, no sport chips, no feed. Courts only.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';
import 'play_action_sheet.dart';

// ── Palette ───────────────────────────────────────────────────────
const _kBg         = Color(0xFF0D0D0D);
const _kSurface    = Color(0xFF161B24);
const _kBorder     = Color(0xFF1A2030);
const _kWhite      = Color(0xFFF8F9FA);
const _kGrey       = Color(0xFF6B7280);
const _kRed        = Color(0xFFE8112D);

class PlayHomeScreen extends StatelessWidget {
  const PlayHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final venues = FakeData.venues;

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, topPad + AppSpacing.xxl,
                  AppSpacing.lg, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Near you',
                    style: AppTextStyles.displayXL(_kWhite).copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: _kRed),
                      const SizedBox(width: 4),
                      Text(
                        'Koramangala, Bengaluru',
                        style: AppTextStyles.bodyS(_kGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Venue list ─────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                if (i == venues.length) {
                  return _HostGameCard(
                    onTap: () => showPlayActionSheet(context),
                  );
                }
                return _PlayVenueCard(
                  venue: venues[i],
                  onTap: () => context.push(AppRoutes.venueById(venues[i].id)),
                );
              },
              childCount: venues.length + 1, // +1 for host card
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// ── Venue card ────────────────────────────────────────────────────

class _PlayVenueCard extends StatelessWidget {
  const _PlayVenueCard({required this.venue, required this.onTap});
  final Venue venue;
  final VoidCallback onTap;

  Color _sportColor(String sport) {
    switch (sport) {
      case 'basketball': return const Color(0xFFFF6B35);
      case 'cricket':    return const Color(0xFF00C9A7);
      case 'badminton':  return const Color(0xFFFFC107);
      default:           return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final court = FakeData.courts.where((c) => c.venueId == venue.id).firstOrNull;
    final slots = court?.slotsAvailableToday ?? 0;
    final price = court?.pricePerSlot ?? 0;
    final primarySport = venue.sports.isNotEmpty ? venue.sports.first : 'basketball';
    final sportColor = _sportColor(primarySport);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        child: Row(
          children: [
            // Sport colour bar
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: sportColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: AppTextStyles.headingS(_kWhite),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    venue.area,
                    style: AppTextStyles.bodyS(_kGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Right: slots + price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: slots > 0
                        ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    slots > 0 ? '$slots slots' : 'Full',
                    style: AppTextStyles.labelS(
                      slots > 0
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price > 0 ? '₹$price' : '—',
                  style: AppTextStyles.headingS(_kWhite),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Host game card ────────────────────────────────────────────────

class _HostGameCard extends StatelessWidget {
  const _HostGameCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: _kRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
              color: _kRed.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.add_rounded, color: _kRed, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Host your own game',
                      style: AppTextStyles.headingS(_kWhite)),
                  const SizedBox(height: 3),
                  Text('Book any court and invite players',
                      style: AppTextStyles.bodyS(_kGrey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: _kGrey),
          ],
        ),
      ),
    );
  }
}

extension _ListX<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
