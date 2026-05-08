import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/theme.dart';
import '../../providers/capsulas_provider.dart';
import '../../widgets/capsulas/capsula_card.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';

class CapsulasScreen extends ConsumerStatefulWidget {
  const CapsulasScreen({super.key});

  @override
  ConsumerState<CapsulasScreen> createState() => _CapsulasScreenState();
}

class _CapsulasScreenState extends ConsumerState<CapsulasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = ref.watch(upcomingCapsulasProvider);
    final past = ref.watch(pastCapsulasProvider);
    final mine = ref.watch(myInscripcionesProvider);

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: SoulColors.glass,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: SoulColors.glassBorder),
                ),
                child: TabBar(
                  controller: _tab,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    gradient: SoulColors.ctaGradient,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: SoulColors.textMuted,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Próximas'),
                    Tab(text: 'Mi historial'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _UpcomingTab(upcoming: upcoming, inscripciones: mine),
                  _PastTab(past: past),
                ],
              ),
            ),
          ],
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
          Text('Cápsulas', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 2),
          const Text(
            'Experiencias en vivo para transformar',
            style: TextStyle(color: SoulColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTab extends ConsumerWidget {
  final AsyncValue upcoming;
  final AsyncValue inscripciones;
  const _UpcomingTab({required this.upcoming, required this.inscripciones});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return upcoming.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if ((list as List).isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      size: 44,
                      color: SoulColors.turquoise,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Muy pronto',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'No hay cápsulas agendadas todavía. Estamos preparando las próximas ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SoulColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final mine = inscripciones.asData?.value as Map? ?? {};
        return RefreshIndicator(
          color: SoulColors.turquoise,
          backgroundColor: SoulColors.midnight,
          onRefresh: () async {
            ref.invalidate(upcomingCapsulasProvider);
            ref.invalidate(myInscripcionesProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = list[i];
              return CapsulaCard(
                capsula: c,
                isInscripto: mine.containsKey(c.id),
                onTap: () => context.push('/experiencias/${c.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _PastTab extends ConsumerWidget {
  final AsyncValue past;
  const _PastTab({required this.past});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return past.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if ((list as List).isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 44,
                      color: SoulColors.violet,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tu historial está vacío',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Apenas vayas a tu primera cápsula, va a aparecer acá.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SoulColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, i) => CapsulaCard(
            capsula: list[i],
            isInscripto: true,
            onTap: () => context.push('/experiencias/${list[i].id}'),
          ),
        );
      },
    );
  }
}
