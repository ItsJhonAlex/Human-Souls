import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

/// Fondo oficial Human Souls: gradiente + blobs aurora con blur.
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradiente base
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: SoulColors.gradient),
          ),
        ),
        // Blob violeta arriba-izquierda
        Positioned(
          top: -120,
          left: -80,
          child:
              _Blob(color: SoulColors.violet.withValues(alpha: .55), size: 340),
        ),
        // Blob turquesa abajo-derecha
        Positioned(
          bottom: -140,
          right: -100,
          child: _Blob(
              color: SoulColors.turquoise.withValues(alpha: .45), size: 380),
        ),
        // Blob rosa sutil
        Positioned(
          top: 220,
          right: -60,
          child:
              _Blob(color: SoulColors.pink.withValues(alpha: .25), size: 220),
        ),
        // Oscurecedor inferior para legibilidad
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  SoulColors.deepBlue.withValues(alpha: .35),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
