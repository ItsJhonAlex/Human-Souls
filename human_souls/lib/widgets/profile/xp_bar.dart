import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class XpBar extends StatelessWidget {
  final double progress; // 0..1
  final int xp;
  final int nextXp;

  const XpBar({
    super.key,
    required this.progress,
    required this.xp,
    required this.nextXp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('XP', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: SoulColors.textSecondary, letterSpacing: 2,
            )),
            Text('$xp / $nextXp', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: SoulColors.textPrimary,
            )),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Stack(children: [
            Container(height: 10, color: Colors.white.withValues(alpha: .12)),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: progress),
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  height: 10,
                  decoration: const BoxDecoration(gradient: SoulColors.ctaGradient),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
