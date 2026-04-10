import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = user?.userMetadata?['full_name'] as String? ?? 'Player';
    final firstName = name.split(' ').first;

    return Container(
      color: context.col.bg,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Avatar ──────────────────────────────────────
              _Avatar(name: name),
              const SizedBox(width: 12),

              // ── Greeting ────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey $firstName 👋',
                      style: GoogleFonts.barlow(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.col.text,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Find your next game',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: context.col.textSec,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Hamburger menu ──────────────────────────────
              _IconBtn(
                icon: Icons.menu_rounded,
                onTap: () {
                  // TODO: open drawer
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Search bar ────────────────────────────────────
          _SearchBar(),
        ],
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.red.withValues(alpha: 0.15),
        border: Border.all(
          color: AppColors.red.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: GoogleFonts.barlow(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.red,
          ),
        ),
      ),
    );
  }
}

// ── Icon button ────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.col.surface,
          border: Border.all(color: context.col.border, width: 1),
        ),
        child: Icon(icon, color: context.col.text, size: 20),
      ),
    );
  }
}

// ── Search bar ─────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: navigate to explore/search screen
      },
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.col.border, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: context.col.textSec,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Search venues, courts...',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: context.col.textSec,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}