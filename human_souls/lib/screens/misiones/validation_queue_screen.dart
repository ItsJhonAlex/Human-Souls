import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/config/theme.dart';
import '../../models/mision.dart';
import '../../providers/misiones_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/soul_button.dart';

class ValidationQueueScreen extends ConsumerWidget {
  const ValidationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(validationQueueProvider);

    return Scaffold(
      backgroundColor: SoulColors.deepBlue,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(),
              Expanded(
                child: queueAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Center(child: Text('Error: $error')),
                  data: (items) {
                    if (items.isEmpty) return _EmptyState();
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _ValidationCard(item: items[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cola de validación',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 20),
              ),
              const Text(
                'Soul Buddy · misiones pendientes',
                style: TextStyle(color: SoulColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: SoulColors.turquoise,
              ),
              const SizedBox(height: 12),
              Text(
                'Todo al día',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'No hay misiones esperando validación 🌿',
                style: TextStyle(color: SoulColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValidationCard extends ConsumerStatefulWidget {
  final MisionCompletada item;
  const _ValidationCard({required this.item});

  @override
  ConsumerState<_ValidationCard> createState() => _ValidationCardState();
}

class _ValidationCardState extends ConsumerState<_ValidationCard> {
  bool _working = false;

  Future<void> _act(bool approve) async {
    setState(() => _working = true);
    try {
      await validateMision(
        ref: ref,
        completionId: widget.item.id,
        approve: approve,
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.item;
    final mision = i.mision;
    final avatarInitial = (i.userName ?? 'S').substring(0, 1).toUpperCase();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con user
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: SoulColors.violet,
                backgroundImage: i.userAvatar != null
                    ? NetworkImage(i.userAvatar!)
                    : null,
                child: i.userAvatar == null
                    ? Text(
                        avatarInitial,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.userName ?? 'Soul',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      timeago.format(i.createdAt, locale: 'es'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: SoulColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (mision != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SoulColors.gold.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 12,
                        color: SoulColors.gold,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '+${mision.xpReward}',
                        style: const TextStyle(
                          color: SoulColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (mision != null) ...[
            const SizedBox(height: 14),
            Text(
              mision.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 15),
            ),
          ],

          // Evidencia
          if (i.evidenceText != null && i.evidenceText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                i.evidenceText!,
                style: const TextStyle(
                  color: SoulColors.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (i.evidenceUrl != null && i.evidenceUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                i.evidenceUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: const Text(
                    'No se pudo cargar la imagen',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SoulButton(
                  label: 'Rechazar',
                  icon: Icons.close_rounded,
                  variant: SoulButtonVariant.ghost,
                  loading: _working,
                  onPressed: () => _act(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SoulButton(
                  label: 'Aprobar',
                  icon: Icons.check_rounded,
                  loading: _working,
                  onPressed: () => _act(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
