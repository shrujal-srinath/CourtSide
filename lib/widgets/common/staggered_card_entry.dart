// lib/widgets/common/staggered_card_entry.dart
//
// Reusable staggered card entrance animation.
// Fades and slides cards in sequence with customizable delay and duration.
//
// Usage:
//   StaggeredCardEntry(
//     cards: [playCard, exploreCard],
//     staggerDelay: Duration(milliseconds: 120),
//     totalDuration: AppDuration.page,
//   )

import 'package:flutter/material.dart';

class StaggeredCardEntry extends StatefulWidget {
  const StaggeredCardEntry({
    super.key,
    required this.cards,
    this.staggerDelay = const Duration(milliseconds: 120),
    this.totalDuration = const Duration(milliseconds: 320),
    this.screenFadeInterval = const Interval(0.0, 0.65),
  });

  final List<Widget> cards;
  final Duration staggerDelay;
  final Duration totalDuration;
  final Interval screenFadeInterval;

  @override
  State<StaggeredCardEntry> createState() => _StaggeredCardEntryState();
}

class _StaggeredCardEntryState extends State<StaggeredCardEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _screenFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.totalDuration,
    );

    _screenFade = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        widget.screenFadeInterval.begin,
        widget.screenFadeInterval.end,
        curve: Curves.easeOut,
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _screenFade,
      child: Column(
        children: List.generate(
          widget.cards.length,
          (index) => _StaggeredCard(
            delay: widget.staggerDelay * (index + 1),
            duration: widget.totalDuration,
            child: widget.cards[index],
          ),
        ),
      ),
    );
  }
}

class _StaggeredCard extends StatefulWidget {
  const _StaggeredCard({
    required this.delay,
    required this.duration,
    required this.child,
  });

  final Duration delay;
  final Duration duration;
  final Widget child;

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
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
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
