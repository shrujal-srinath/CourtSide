// lib/widgets/common/cs_shimmer.dart
//
// CsShimmer — skeleton loading effect.
// shimmerBaseColor    = colorSurfacePrimary
// shimmerHighlightColor = colorSurfaceElevated
//
// Usage:
//   CsShimmer(child: MySkeletonWidget())
//
//   Or use the static .box() and .line() helpers for quick layout placeholders.

import 'package:flutter/material.dart';
import '../../core/tokens/color_tokens.dart';
import '../../core/tokens/spacing_tokens.dart';

class CsShimmer extends StatefulWidget {
  const CsShimmer({
    super.key,
    required this.child,
  });

  /// Convenience: rectangular shimmer placeholder.
  static Widget box({
    required double width,
    required double height,
    double radius = AppRadius.md,
  }) {
    return CsShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  /// Convenience: text line shimmer placeholder.
  static Widget line({
    double widthFactor = 1.0,
    double height = 14,
  }) {
    return CsShimmer(
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }

  final Widget child;

  @override
  State<CsShimmer> createState() => _CsShimmerState();
}

class _CsShimmerState extends State<CsShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colors.colorSurfacePrimary,
                colors.colorSurfaceElevated,
                colors.colorSurfacePrimary,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlideTransform(_animation.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.offset);
  final double offset;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * offset, 0, 0);
  }
}
