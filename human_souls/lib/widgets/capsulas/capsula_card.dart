import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/theme.dart';
import '../../models/capsula.dart';
import '../common/glass_card.dart';

class CapsulaCard extends StatelessWidget {
  final Capsula capsula;
  final bool isInscripto;
  final VoidCallback onTap;

  const CapsulaCard({
    super.key,
    required this.capsula,
    required this.isInscripto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat("EEE d MMM", 'es');
    final timeFmt = DateFormat.Hm('es');

    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          SoulColors.turquoise.withValues(alpha: .22),
          SoulColors.violet.withValues(alpha: .22),
        ],
      ),
      child: Stack(
        children: [
          if (capsula.coverUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.35,
                child: Image.network(
                  capsula.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (capsula.isLive) _LiveBadge(),
                    if (capsula.isLive) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${dateFmt.format(capsula.startsAt)} · ${timeFmt.format(capsula.startsAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isInscripto) _InscriptoPill(),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  capsula.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (capsula.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    capsula.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SoulColors.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (capsula.hostName != null) ...[
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: SoulColors.violet,
                        backgroundImage: capsula.hostAvatar != null
                            ? NetworkImage(capsula.hostAvatar!)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        capsula.hostName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: SoulColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: SoulColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${capsula.duration.inMinutes} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: SoulColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (capsula.includedInMembership && capsula.priceUsd == 0)
                      _MemberOnlyTag()
                    else
                      _PriceTag(price: capsula.priceUsd),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'EN VIVO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InscriptoPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SoulColors.turquoise.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: SoulColors.turquoise),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 12, color: SoulColors.turquoise),
          SizedBox(width: 3),
          Text(
            'Inscripto',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SoulColors.turquoise,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberOnlyTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: SoulColors.ctaGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'MEMBRESÍA',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final double price;
  const _PriceTag({required this.price});
  @override
  Widget build(BuildContext context) {
    return Text(
      'USD ${price.toStringAsFixed(0)}',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: SoulColors.gold,
      ),
    );
  }
}
