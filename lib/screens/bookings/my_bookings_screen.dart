// lib/screens/bookings/my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/app_spacing.dart';
import '../../models/fake_data.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<MyBookingsScreen>
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

  List<BookingRecord> get _upcoming => FakeData.bookingHistory
      .where((b) => b.status == BookingStatus.upcoming).toList();

  List<BookingRecord> get _past => FakeData.bookingHistory
      .where((b) => b.status != BookingStatus.upcoming).toList();

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          SizedBox(height: topPad),

          // ── Header ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: c.gradBrand,
              border: Border(
                bottom: BorderSide(color: c.border, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bookings',
                  style: AppTextStyles.displayS(c.text),
                ),
                const SizedBox(height: 16),

                // Custom segmented control
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: c.border, width: 0.5),
                  ),
                  child: Stack(
                    children: [
                      // Sliding active pill
                      AnimatedPositioned(
                        duration: AppDuration.fast,
                        curve: Curves.easeInOutCubic,
                        left: _tab.index == 0
                            ? 4
                            : (MediaQuery.of(context).size.width - 36) / 2 + 4,
                        top: 4,
                        bottom: 4,
                        width:
                            (MediaQuery.of(context).size.width - 36) / 2 - 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
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
                                        ? AppColors.white
                                        : c.textSec,
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
                                        ? AppColors.white
                                        : c.textSec,
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

                const SizedBox(height: 12),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _BookingList(
                  bookings: _upcoming,
                  emptyTitle: 'No upcoming bookings',
                  emptySubtitle: 'Book a court to get started',
                  onBookNow: () => context.go('/home'),
                ),
                _BookingList(
                  bookings: _past,
                  emptyTitle: 'No past bookings',
                  emptySubtitle: 'Your booking history will appear here',
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
    final c = context.col;
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: c.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: c.border, width: 0.5),
                ),
                child: const Center(
                  child: Text('📋', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                emptyTitle,
                style: AppTextStyles.displayS(c.text),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                style: AppTextStyles.bodyM(c.textSec),
                textAlign: TextAlign.center,
              ),
              if (onBookNow != null) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onBookNow,
                    child: Text(
                      'Book a Court',
                      style: AppTextStyles.headingS(AppColors.white),
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
      padding: const EdgeInsets.all(18),
      itemCount: bookings.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (c, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final BookingRecord booking;

  static const _sportIcons = {
    'basketball': '🏀',
    'cricket': '🏏',
    'badminton': '🏸',
    'football': '⚽',
  };

  static const _statusColors = {
    BookingStatus.upcoming:  AppColors.info,
    BookingStatus.completed: AppColors.success,
    BookingStatus.cancelled: AppColors.error,
  };

  static const _statusLabels = {
    BookingStatus.upcoming:  'Upcoming',
    BookingStatus.completed: 'Completed',
    BookingStatus.cancelled: 'Cancelled',
  };

  Color _sportColor(String sport) {
    switch (sport) {
      case 'basketball': return AppColors.basketball;
      case 'cricket': return AppColors.cricket;
      default: return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final statusColor = _statusColors[booking.status]!;
    final sportColor = _sportColor(booking.sport);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.border, width: 0.5),
        boxShadow: AppShadow.cardFor(context),
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
                padding: const EdgeInsets.all(14),
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
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Center(
                            child: Text(
                              _sportIcons[booking.sport] ?? '🏅',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.venueName,
                                style: AppTextStyles.headingS(c.text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${booking.date}  ·  ${booking.timeSlot}',
                                style: AppTextStyles.bodyS(c.textSec),
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            _statusLabels[booking.status]!,
                            style: AppTextStyles.overline(statusColor),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Container(height: 0.5, color: c.borderMuted),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        // Amount
                        Text(
                          '₹${booking.amount}',
                          style: AppTextStyles.statM(c.text),
                        ),
                        const Spacer(),

                        // Actions
                        if (booking.status == BookingStatus.upcoming) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.surfaceHigh,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: c.border, width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_rounded,
                                    size: 12, color: c.textSec),
                                const SizedBox(width: 4),
                                Text('QR',
                                    style: AppTextStyles.labelS(c.textSec)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.labelM(AppColors.error),
                            ),
                          ),
                        ],

                        if (booking.hasStats && booking.status == BookingStatus.completed) ...[
                          GestureDetector(
                            onTap: () => context.push('/stats'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bar_chart_rounded,
                                    color: AppColors.red, size: 14),
                                const SizedBox(width: 4),
                                Text('View',
                                    style: AppTextStyles.labelM(AppColors.red)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => context.push('/stats/share'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.ios_share_rounded,
                                    color: AppColors.red, size: 14),
                                const SizedBox(width: 4),
                                Text('Share',
                                    style: AppTextStyles.labelM(AppColors.red)),
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
