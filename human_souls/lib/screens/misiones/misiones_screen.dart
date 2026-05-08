import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/theme.dart';
import '../../models/mision.dart';
import '../../providers/misiones_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/misiones/mision_card.dart';
import 'mision_detail_sheet.dart';
import 'validation_queue_screen.dart';

class MisionesScreen extends ConsumerStatefulWidget {
  const MisionesScreen({super.key});

  @override
  ConsumerState<MisionesScreen> createState() => _MisionesScreenState();
}

class _MisionesScreenState extends ConsumerState<MisionesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final misionesAsync = ref.watch(misionesPorTipoProvider);
    final completadasAsync = ref.watch(misCompletadasDelPeriodoProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final isBuddy = profileAsync.asData?.value.isBuddy ?? false;

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              isBuddy: isBuddy,
              onOpenQueue: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ValidationQueueScreen(),
                  ),
                );
              },
            ),
            _Tabs(controller: _tabCtrl),
            Expanded(
              child: misionesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (porTipo) {
                  final completadas = completadasAsync.asData?.value ?? {};
                  return TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _MisionesList(
                        misiones: porTipo[MisionTipo.daily] ?? [],
                        completadas: completadas,
                        emptyCta: 'No hay misiones diarias hoy',
                      ),
                      _MisionesList(
                        misiones: porTipo[MisionTipo.weekly] ?? [],
                        completadas: completadas,
                        emptyCta: 'No hay misiones semanales activas',
                      ),
                      _MisionesList(
                        misiones: porTipo[MisionTipo.monthly] ?? [],
                        completadas: completadas,
                        emptyCta: 'No hay misiones mensuales activas',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// HEADER
// =====================================================================
class _Header extends StatelessWidget {
  final bool isBuddy;
  final VoidCallback onOpenQueue;
  const _Header({required this.isBuddy, required this.onOpenQueue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Misiones',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Pequeños actos que transforman',
                  style: TextStyle(
                    color: SoulColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isBuddy)
            Container(
              decoration: BoxDecoration(
                gradient: SoulColors.ctaGradient,
                borderRadius: BorderRadius.circular(100),
              ),
              child: IconButton(
                icon: const Icon(Icons.verified_rounded, color: Colors.white),
                onPressed: onOpenQueue,
                tooltip: 'Validar misiones',
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
// TABS
// =====================================================================
class _Tabs extends StatelessWidget {
  final TabController controller;
  const _Tabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: SoulColors.glass,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: SoulColors.glassBorder),
        ),
        child: TabBar(
          controller: controller,
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
            Tab(text: 'Diarias'),
            Tab(text: 'Semanales'),
            Tab(text: 'Mensuales'),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// LIST
// =====================================================================
class _MisionesList extends ConsumerWidget {
  final List<Mision> misiones;
  final Map<String, MisionCompletada> completadas;
  final String emptyCta;

  const _MisionesList({
    required this.misiones,
    required this.completadas,
    required this.emptyCta,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (misiones.isEmpty) return _EmptyState(message: emptyCta);

    return RefreshIndicator(
      color: SoulColors.turquoise,
      backgroundColor: SoulColors.midnight,
      onRefresh: () async {
        ref.invalidate(misionesPorTipoProvider);
        ref.invalidate(misCompletadasDelPeriodoProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: misiones.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final m = misiones[i];
          final c = completadas[m.id];
          return MisionCard(
            mision: m,
            completion: c,
            onTap: () => showMisionDetailSheet(context, ref, m, c),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

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
                Icons.spa_outlined,
                size: 48,
                color: SoulColors.turquoise,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'Volvé a pasar pronto por acá ✨',
                style: TextStyle(color: SoulColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
