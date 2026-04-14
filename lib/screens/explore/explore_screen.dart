// lib/screens/explore/explore_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String _selectedSport = 'All';
  String _selectedSort = 'Near Me';

  final List<String> _sports = ['All', 'Basketball', 'Cricket', 'Football', 'Badminton'];
  final List<String> _sortOptions = ['Near Me', 'Top Rated', 'Price: Low to High'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final venues = _filterVenues();

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            _buildFilters(colors),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: venues.length,
                itemBuilder: (context, index) {
                  final venue = venues[index];
                  return _VenueListItem(venue: venue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Venue> _filterVenues() {
    var list = FakeData.venues;
    if (_selectedSport != 'All') {
      list = list.where((v) => v.sports.contains(_selectedSport.toLowerCase())).toList();
    }
    
    if (_selectedSort == 'Top Rated') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedSort == 'Near Me') {
      // For fake data, we just keep current order or random
    }
    
    return list;
  }

  Widget _buildHeader(AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EXPLORE', style: AppTextStyles.overline(colors.colorTextTertiary)),
              Text('Nearby Courts', style: AppTextStyles.headingM(colors.colorTextPrimary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.colorSurfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: colors.colorBorderSubtle),
            ),
            child: Icon(Icons.map_outlined, color: colors.colorAccentPrimary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppColorScheme colors) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _sports.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final sport = _sports[index];
              final isSelected = sport == _selectedSport;
              return GestureDetector(
                onTap: () => setState(() => _selectedSport = sport),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.colorAccentPrimary : colors.colorSurfaceElevated,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : colors.colorBorderSubtle,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      sport,
                      style: AppTextStyles.labelM(isSelected ? Colors.white : colors.colorTextSecondary),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, color: colors.colorTextTertiary, size: 16),
              const SizedBox(width: 8),
              Text('Sorted by: ', style: AppTextStyles.bodyS(colors.colorTextTertiary)),
              GestureDetector(
                onTap: _showSortPicker,
                child: Row(
                  children: [
                    Text(_selectedSort, style: AppTextStyles.labelM(colors.colorAccentPrimary)),
                    Icon(Icons.keyboard_arrow_down_rounded, color: colors.colorAccentPrimary, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: colors.colorBorderSubtle, height: 1),
      ],
    );
  }

  void _showSortPicker() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorSurfacePrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sortOptions.map((opt) => ListTile(
            title: Text(opt, style: AppTextStyles.bodyM(colors.colorTextPrimary)),
            onTap: () {
              setState(() => _selectedSort = opt);
              Navigator.pop(context);
            },
            trailing: opt == _selectedSort ? Icon(Icons.check_circle_rounded, color: colors.colorAccentPrimary) : null,
          )).toList(),
        ),
      ),
    );
  }
}

class _VenueListItem extends StatelessWidget {
  final Venue venue;
  const _VenueListItem({required this.venue});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.venueById(venue.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: colors.colorSurfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(child: Icon(Icons.image_outlined, size: 48, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(venue.name, style: AppTextStyles.headingS(colors.colorTextPrimary)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${venue.rating}', style: AppTextStyles.labelM(colors.colorTextPrimary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(venue.address, style: AppTextStyles.bodyS(colors.colorTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...venue.sports.take(3).map((s) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.colorBackgroundPrimary,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.colorBorderSubtle),
                        ),
                        child: Text(s.toUpperCase(), style: AppTextStyles.overline(colors.colorTextTertiary).copyWith(fontSize: 8)),
                      )),
                      const Spacer(),
                      Text('Starting ₹400', style: AppTextStyles.headingS(colors.colorAccentPrimary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}