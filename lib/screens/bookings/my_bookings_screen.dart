// lib/screens/bookings/my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../providers/confirmed_bookings_provider.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<BookingRecord> _upcoming(List<BookingRecord> confirmed) {
    final all = [...confirmed, ...FakeData.bookingHistory];
    return all.where((b) => b.status == BookingStatus.upcoming).toList();
  }

  List<BookingRecord> _past(List<BookingRecord> confirmed) {
    final all = [...confirmed, ...FakeData.bookingHistory];
    return all.where((b) => b.status != BookingStatus.upcoming).toList();
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = ref.watch(confirmedBookingsProvider);
    final colors = context.colors;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          SizedBox(height: topPad),

          // ── Header ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colors.colorBackgroundPrimary,
              border: Border(
                bottom: BorderSide(
                    color: colors.colorBorderSubtle, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg,
                AppSpacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bookings',
                  style: AppTextStyles.displayS(colors.colorTextPrimary),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Custom segmented control
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.colorSurfacePrimary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                        color: colors.colorBorderSubtle, width: 0.5),
                  ),
                  child: Stack(
                    children: [
                      // Sliding active pill
                      AnimatedPositioned(
                        duration: AppDuration.fast,
                        curve: Curves.easeInOutCubic,
                        left: _tab.index == 0
                            ? 4
                            : (MediaQuery.of(context).size.width - 36) /
                                    2 +
                                4,
                        top: 4,
                        bottom: 4,
                        width: (MediaQuery.of(context).size.width - 36) /
                                2 -
                            8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.colorAccentPrimary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                      ),
                      // Tab labels
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _tab.animateTo(0),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Text(
                                  'Upcoming',
                                  style: AppTextStyles.labelM(
                                    _tab.index == 0
                                        ? colors.colorTextOnAccent
                                        : colors.colorTextSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _tab.animateTo(1),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Text(
                                  'Past',
                                  style: AppTextStyles.labelM(
                                    _tab.index == 1
                                        ? colors.colorTextOnAccent
                                        : colors.colorTextSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _BookingList(
                  bookings: _upcoming(confirmed),
                  emptyTitle: 'No upcoming bookings',
                  emptySubtitle: 'Book a court to get started',
                  onBookNow: () => context.go('/home'),
                ),
                _BookingList(
                  bookings: _past(confirmed),
                  emptyTitle: 'No past bookings',
                  emptySubtitle:
                      'Your booking history will appear here',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onBookNow,
  });

  final List<BookingRecord> bookings;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onBookNow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.colorSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                      color: colors.colorBorderSubtle, width: 0.5),
                ),
                child: const Center(
                  child: Text('📋', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                emptyTitle,
                style: AppTextStyles.displayS(colors.colorTextPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                emptySubtitle,
                style: AppTextStyles.bodyM(colors.colorTextSecondary),
                textAlign: TextAlign.center,
              ),
              if (onBookNow != null) ...[
                const SizedBox(height: AppSpacing.xxl + 4),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onBookNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.colorAccentPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: Text(
                      'Book a Court',
                      style: AppTextStyles.headingS(
                          colors.colorTextOnAccent),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: bookings.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppSpacing.sm + 2),
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final BookingRecord booking;

  static const _sportIcons = {
    'basketball': '🏀',
    'cricket':    '🏏',
    'badminton':  '🏸',
    'football':   '⚽',
  };

  static const _statusLabels = {
    BookingStatus.upcoming:  'Upcoming',
    BookingStatus.completed: 'Completed',
    BookingStatus.cancelled: 'Cancelled',
  };

  Color _statusColor(BookingStatus status, AppColorScheme colors) {
    switch (status) {
      case BookingStatus.upcoming:  return colors.colorInfo;
      case BookingStatus.completed: return colors.colorSuccess;
      case BookingStatus.cancelled: return colors.colorError;
    }
  }

  Color _sportColor(String sport, AppColorScheme colors) {
    switch (sport) {
      case 'basketball': return colors.colorSportBasketball;
      case 'cricket':    return colors.colorSportCricket;
      default:           return colors.colorAccentPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = _statusColor(booking.status, colors);
    final sportColor  = _sportColor(booking.sport, colors);

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        boxShadow: AppShadow.card,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left status accent bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.card),
                  bottomLeft: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Sport icon circle
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: sportColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Center(
                            child: Text(
                              _sportIcons[booking.sport] ?? '🏅',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.venueName,
                                style: AppTextStyles.headingS(
                                    colors.colorTextPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${booking.date}  ·  ${booking.timeSlot}',
                                style: AppTextStyles.bodyS(
                                    colors.colorTextSecondary),
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            _statusLabels[booking.status]!,
                            style: AppTextStyles.overline(statusColor),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    Container(
                        height: 0.5,
                        color: colors.colorBorderMedium),
                    const SizedBox(height: AppSpacing.sm + 2),

                    Row(
                      children: [
                        Text(
                          '₹${booking.amount}',
                          style: AppTextStyles.statM(
                              colors.colorTextPrimary),
                        ),
                        const Spacer(),

                        if (booking.status ==
                            BookingStatus.upcoming) ...[
                          _ScoringButton(booking: booking),
                          const SizedBox(width: AppSpacing.sm),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.labelM(
                                  colors.colorError),
                            ),
                          ),
                        ],

                        if (booking.hasStats &&
                            booking.status ==
                                BookingStatus.completed) ...[
                          GestureDetector(
                            onTap: () => context.push('/stats'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bar_chart_rounded,
                                    color: colors.colorAccentPrimary,
                                    size: 16),
                                const SizedBox(width: 5),
                                Text('Stats',
                                    style: AppTextStyles.labelM(
                                        colors.colorAccentPrimary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            onTap: () => context.push('/stats/share'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.ios_share_rounded,
                                    color: colors.colorInfo, size: 16),
                                const SizedBox(width: 5),
                                Text('Share',
                                    style: AppTextStyles.labelM(
                                        colors.colorInfo)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
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

class _ScoringButton extends StatelessWidget {
  final BookingRecord booking;
  const _ScoringButton({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bookingTime = FakeData.parseBookingTime(booking.date, booking.timeSlot);
    final now = DateTime.now();
    
    // Default to true for demo if parsing fails
    bool canScore = true;
    if (bookingTime != null) {
      final diff = bookingTime.difference(now);
      canScore = diff.inHours <= 1 && diff.inHours >= -3; // 1h before to 3h after
    }
    
    return GestureDetector(
      onTap: () {
        if (!canScore) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Available 1 hour before your slot'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        if (booking.sport.toLowerCase().contains('basketball')) {
          context.push(AppRoutes.bballMode);
        } else {
          context.push('/score/${booking.sport}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 3),
        decoration: BoxDecoration(
          color: canScore ? colors.colorAccentPrimary : colors.colorSurfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: canScore ? colors.colorAccentPrimary : colors.colorBorderSubtle,
              width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.scoreboard_rounded,
                size: 14,
                color: canScore ? Colors.white : colors.colorTextTertiary),
            const SizedBox(width: 5),
            Text('Start Scoring',
                style: AppTextStyles.labelM(
                    canScore ? Colors.white : colors.colorTextTertiary)),
          ],
        ),
      ),
    );
  }
}
