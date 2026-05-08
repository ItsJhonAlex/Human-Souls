import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../common/glass_card.dart';

class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              )),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: SoulColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
