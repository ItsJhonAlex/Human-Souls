import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../../models/mision.dart';
import '../common/glass_card.dart';

class MisionCard extends StatelessWidget {
  final Mision mision;
  final MisionCompletada? completion;
  final VoidCallback onTap;

  const MisionCard({
    super.key,
    required this.mision,
    required this.completion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusOf(completion);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: status.gradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(status.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(mision.title,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 16),
                    ),
                  ),
                  _RewardChip(
                    xp: mision.xpReward, sp: mision.soulPointsReward,
                  ),
                ]),
                const SizedBox(height: 4),
                Text(mision.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SoulColors.textSecondary, fontSize: 13, height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  _StatusPill(status: status),
                  const SizedBox(width: 8),
                  _EvidencePill(evidence: mision.evidenceType),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _MisionStatus _statusOf(MisionCompletada? c) {
    if (c == null) return _MisionStatus.pending;
    if (c.validated) return _MisionStatus.done;
    return _MisionStatus.inReview;
  }
}

class _RewardChip extends StatelessWidget {
  final int xp, sp;
  const _RewardChip({required this.xp, required this.sp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SoulColors.gold.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.bolt_rounded, size: 12, color: SoulColors.gold),
        const SizedBox(width: 3),
        Text('$xp',
          style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: SoulColors.gold,
          )),
        const SizedBox(width: 6),
        const Icon(Icons.favorite_rounded, size: 10, color: SoulColors.pink),
        const SizedBox(width: 3),
        Text('$sp',
          style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: SoulColors.pink,
          )),
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _MisionStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: status.fg.withValues(alpha: .4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(status.dotIcon, size: 10, color: status.fg),
        const SizedBox(width: 4),
        Text(status.label,
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: status.fg, letterSpacing: 0.4,
          )),
      ]),
    );
  }
}

class _EvidencePill extends StatelessWidget {
  final EvidenceType evidence;
  const _EvidencePill({required this.evidence});

  @override
  Widget build(BuildContext context) {
    if (evidence == EvidenceType.none) return const SizedBox.shrink();

    final icon = switch (evidence) {
      EvidenceType.photo => Icons.photo_camera_outlined,
      EvidenceType.audio => Icons.mic_none_rounded,
      EvidenceType.post => Icons.forum_outlined,
      _ => Icons.edit_note_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: SoulColors.textMuted),
        const SizedBox(width: 4),
        Text(evidence.label,
          style: const TextStyle(fontSize: 11, color: SoulColors.textMuted)),
      ]),
    );
  }
}

enum _MisionStatus {
  pending(
    label: 'Pendiente', bg: Color(0x1AFFFFFF), fg: Colors.white70,
    icon: Icons.bolt_rounded, dotIcon: Icons.fiber_manual_record,
    gradient: SoulColors.ctaGradient,
  ),
  inReview(
    label: 'En revisión', bg: Color(0x33FFD166), fg: SoulColors.gold,
    icon: Icons.hourglass_top_rounded, dotIcon: Icons.fiber_manual_record,
    gradient: LinearGradient(colors: [SoulColors.gold, SoulColors.pink]),
  ),
  done(
    label: 'Completada', bg: Color(0x3300D4C8), fg: SoulColors.turquoise,
    icon: Icons.check_rounded, dotIcon: Icons.check_circle_rounded,
    gradient: LinearGradient(colors: [SoulColors.turquoise, SoulColors.cyan]),
  );

  final String label;
  final Color bg, fg;
  final IconData icon, dotIcon;
  final Gradient gradient;
  const _MisionStatus({
    required this.label, required this.bg, required this.fg,
    required this.icon, required this.dotIcon, required this.gradient,
  });
}
