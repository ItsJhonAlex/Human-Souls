import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/theme.dart';
import '../../providers/community_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/community/post_card.dart';

class ComunidadScreen extends ConsumerWidget {
  const ComunidadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    final likes = ref.watch(myReactionsProvider);
    // Activa la suscripción realtime mientras esta pantalla esté montada.
    ref.watch(feedRealtimeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(),
              Expanded(
                child: feed.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (posts) {
                    if (posts.isEmpty) return _EmptyFeed();
                    final likedSet = likes.asData?.value ?? <String>{};
                    return RefreshIndicator(
                      color: SoulColors.turquoise,
                      backgroundColor: SoulColors.midnight,
                      onRefresh: () async {
                        ref.invalidate(feedProvider);
                        ref.invalidate(myReactionsProvider);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                        itemCount: posts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final p = posts[i];
                          return PostCard(
                            post: p,
                            isLiked: likedSet.contains(p.id),
                            onTap: () => context.push('/comunidad/${p.id}'),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: Container(
          decoration: BoxDecoration(
            gradient: SoulColors.ctaGradient,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: SoulColors.violet.withValues(alpha: .45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => context.push('/comunidad/crear'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Compartir',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comunidad', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 2),
          const Text(
            'Lo que los Souls están compartiendo',
            style: TextStyle(color: SoulColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
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
                Icons.auto_awesome,
                size: 44,
                color: SoulColors.turquoise,
              ),
              const SizedBox(height: 12),
              Text(
                'El feed está esperando tu voz',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Compartí algo que te esté pasando, una pregunta o una intención. '
                'Lo que necesitás encontrar empieza cuando te animás a decirlo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SoulColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
