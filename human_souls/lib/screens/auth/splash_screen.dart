import 'package:flutter/material.dart';
import '../../core/config/theme.dart';
import '../../widgets/common/gradient_background.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: SoulColors.ctaGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: SoulColors.turquoise.withValues(alpha: .45),
                    blurRadius: 40, spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 28),
            Text('Human Souls',
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text('Despertando el valor humano…',
              style: TextStyle(color: SoulColors.textSecondary)),
            const SizedBox(height: 40),
            const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: SoulColors.turquoise),
            ),
          ],
        ),
      ),
    );
  }
}
