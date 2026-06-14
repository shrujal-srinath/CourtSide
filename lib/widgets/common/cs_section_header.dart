// lib/widgets/common/cs_section_header.dart
//
// CsSectionHeader — the one section-header pattern for the whole app.
// Accent bar + headingM title, with an optional "See all" action or a custom
// trailing widget. Promoted from home_screen's _SectionHeader so every screen
// titles its sections identically (CLAUDE.md §11: never use grey overline
// labels for section headers).

import 'package:flutter/material.dart';
import '../../core/tokens/color_tokens.dart';
import '../../core/tokens/spacing_tokens.dart';
import '../../core/tokens/typography_tokens.dart';

class CsSectionHeader extends StatelessWidget {
  const CsSectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.actionLabel = 'See all',
    this.trailing,
  });

  final String title;

  /// When non-null (and [trailing] is null), shows a tappable [actionLabel].
  final VoidCallback? onSeeAll;
  final String actionLabel;

  /// Overrides the default see-all action with a custom trailing widget.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors.colorAccentPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingM(colors.colorTextPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  actionLabel,
                  style: AppTextStyles.labelM(colors.colorTextSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
