import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: gradient,
                color: gradient == null ? SoulColors.glass : null,
                border: Border.all(color: SoulColors.glassBorder, width: 1),
                borderRadius: borderRadius,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
