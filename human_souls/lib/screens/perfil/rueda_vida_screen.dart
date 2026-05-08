import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/theme.dart';
import '../../models/rueda_vida.dart';
import '../../providers/rueda_vida_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/soul_button.dart';
import '../../widgets/rueda/dimension_slider.dart';
import '../../widgets/rueda/rueda_vida_chart.dart';

class RuedaVidaScreen extends ConsumerStatefulWidget {
  const RuedaVidaScreen({super.key});

  @override
  ConsumerState<RuedaVidaScreen> createState() => _RuedaVidaScreenState();
}

class _RuedaVidaScreenState extends ConsumerState<RuedaVidaScreen> {
  RuedaVida? _working;
  bool _saving = false;
  bool _savedOk = false;

  @override
  Widget build(BuildContext context) {
    final actualAsync = ref.watch(ruedaActualProvider);
    final historyAsync = ref.watch(ruedaHistoryProvider);

    return GradientBackground(
      child: SafeArea(
        child: actualAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (rueda) {
            _working ??= rueda;
            final r = _working!;

            return Column(
              children: [
                _Header(onClose: () => context.pop()),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _HeroChart(rueda: r),
                      const SizedBox(height: 20),
                      Text(
                        'Ajustá cada área del 0 al 10',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '¿Cuán satisfecho te sentís con cada dimensión hoy?',
                        style: TextStyle(
                          color: SoulColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GlassCard(
                        child: Column(
                          children: ruedaAreas.map((area) {
                            final idx = ruedaAreas.indexOf(area);
                            return DimensionSlider(
                              area: area,
                              value: r.values[idx],
                              onChanged: (v) => setState(() {
                                _working = _working!.copyWithValue(area.key, v);
                                _savedOk = false;
                              }),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _HistorySection(historyAsync: historyAsync),
                    ],
                  ),
                ),
                // Save bar fija
                _SaveBar(
                  saving: _saving,
                  savedOk: _savedOk,
                  onSave: () async {
                    setState(() {
                      _saving = true;
                      _savedOk = false;
                    });
                    try {
                      await saveRueda(ref, _working!);
                      if (mounted) setState(() => _savedOk = true);
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =====================================================================
// HEADER
// =====================================================================
class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
          const SizedBox(width: 4),
          Text(
            'Rueda de la Vida',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// HERO CHART (con promedio)
// =====================================================================
class _HeroChart extends StatelessWidget {
  final RuedaVida rueda;
  const _HeroChart({required this.rueda});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          SoulColors.violet.withValues(alpha: .3),
          SoulColors.turquoise.withValues(alpha: .2),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: Column(
        children: [
          Text(
            DateFormat.yMMMM('es').format(DateTime.now()).toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: SoulColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Center(child: RuedaVidaChart(values: rueda.values, size: 300)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: SoulColors.turquoise,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Promedio ${rueda.average.toStringAsFixed(1)} / 10',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// HISTORY
// =====================================================================
class _HistorySection extends StatelessWidget {
  final AsyncValue<List<RuedaVida>> historyAsync;
  const _HistorySection({required this.historyAsync});

  @override
  Widget build(BuildContext context) {
    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (list) {
        // Ocultar el mes actual del historial
        final now = DateTime.now();
        final history = list
            .where(
              (r) => !(r.month.year == now.year && r.month.month == now.month),
            )
            .toList();
        if (history.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Tu historial',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: history.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _HistoryTile(rueda: history[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final RuedaVida rueda;
  const _HistoryTile({required this.rueda});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              DateFormat.yMMM('es').format(rueda.month).toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: SoulColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: RuedaVidaChart(
                values: rueda.values,
                size: 110,
                showLabels: false,
                animate: false,
              ),
            ),
            Text(
              '${rueda.average.toStringAsFixed(1)} / 10',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// SAVE BAR
// =====================================================================
class _SaveBar extends StatelessWidget {
  final bool saving, savedOk;
  final VoidCallback onSave;
  const _SaveBar({
    required this.saving,
    required this.savedOk,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: SoulColors.deepBlue.withValues(alpha: .7),
        border: const Border(top: BorderSide(color: SoulColors.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (savedOk) ...[
              const Icon(
                Icons.check_circle_rounded,
                color: SoulColors.turquoise,
              ),
              const SizedBox(width: 8),
              const Text(
                'Guardado ✨',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SoulColors.turquoise,
                ),
              ),
              const Spacer(),
            ],
            Expanded(
              child: SoulButton(
                label: savedOk ? 'Guardado' : 'Guardar mes',
                icon: savedOk ? Icons.check_rounded : Icons.save_rounded,
                loading: saving,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
