import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_spacing.dart';

// Factory functions returning CustomTransitionPage instances for GoRouter

// ── Slide Up + Fade — for venue/sport push screens ─────────────
CustomTransitionPage<void> slideUpPage({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppDuration.page,
    reverseTransitionDuration: AppDuration.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      final fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
  );
}

// ── Fade + Scale — for scoring screens ─────────────────────────
CustomTransitionPage<void> fadeScalePage({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppDuration.page,
    reverseTransitionDuration: AppDuration.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));

      final scaleTween = Tween(begin: 0.97, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: ScaleTransition(
          scale: animation.drive(scaleTween),
          child: child,
        ),
      );
    },
  );
}

// ── Slide from Bottom — for booking / share preview ─────────────
CustomTransitionPage<void> bottomSheetPage({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppDuration.page,
    reverseTransitionDuration: AppDuration.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween(
        begin: const Offset(0, 1.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      final fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
  );
}
