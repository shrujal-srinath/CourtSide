import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';

// ── Sport model ────────────────────────────────────────────────

class SportOption {
  const SportOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.count,
  });
  final String id;
  final String label;
  final String icon;
  final int count;
}

const _sports = [
  SportOption(id: 'basketball', label: 'Basketball', icon: '🏀', count: 8),
  SportOption(id: 'cricket',    label: 'Box Cricket', icon: '🏏', count: 12),
  SportOption(id: 'badminton',  label: 'Badminton',   icon: '🏸', count: 6),
  SportOption(id: 'football',   label: 'Football',    icon: '⚽', count: 5),
];

// ── Main widget ────────────────────────────────────────────────

class SportSelectorPanel extends StatefulWidget {
  const SportSelectorPanel({
    super.key,
    required this.onSportSelected,
    required this.onViewAll,
  });

  /// Called with sport id when a sport is selected, null when cleared
  final ValueChanged<String?> onSportSelected;
  final VoidCallback onViewAll;

  @override
  State<SportSelectorPanel> createState() => _SportSelectorPanelState();
}

class _SportSelectorPanelState extends State<SportSelectorPanel>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late final AnimationController _anim;
  late final Animation<double> _collapse;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _collapse = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _select(String id) {
    setState(() => _selected = id);
    _anim.forward();
    widget.onSportSelected(id);
  }

  void _clear() {
    setState(() => _selected = null);
    _anim.reverse();
    widget.onSportSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _collapse,
      builder: (context, _) {
        // Collapsed strip when sport selected
        if (_selected != null && _collapse.value > 0.5) {
          return _CollapsedStrip(
            sport: _sports.firstWhere((s) => s.id == _selected),
            onClear: _clear,
            onViewAll: widget.onViewAll,
          );
        }
        // Full panel
        return _FullPanel(
          onSelect: _select,
          onViewAll: widget.onViewAll,
        );
      },
    );
  }
}

// ── Full panel ─────────────────────────────────────────────────

class _FullPanel extends StatelessWidget {
  const _FullPanel({required this.onSelect, required this.onViewAll});
  final ValueChanged<String> onSelect;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Question ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'What are you booking?',
                style: GoogleFonts.barlow(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  'Skip',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── 2×2 Sport grid ────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
            children: _sports
                .map((s) => _SportTile(sport: s, onTap: () => onSelect(s.id)))
                .toList(),
          ),

          const SizedBox(height: 10),

          // ── View all button ───────────────────────────────
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Show all venues',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondaryDark,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sport tile ─────────────────────────────────────────────────

class _SportTile extends StatelessWidget {
  const _SportTile({required this.sport, required this.onTap});
  final SportOption sport;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(sport.icon, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sport.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${sport.count} near you',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.textSecondaryDark,
                    ),
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

// ── Collapsed strip ────────────────────────────────────────────

class _CollapsedStrip extends StatelessWidget {
  const _CollapsedStrip({
    required this.sport,
    required this.onClear,
    required this.onViewAll,
  });
  final SportOption sport;
  final VoidCallback onClear;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Active sport pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.red.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sport.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  sport.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Change / view all
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                'View all',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}