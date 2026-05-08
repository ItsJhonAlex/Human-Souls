import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/theme.dart';
import '../../models/buddy_dashboard.dart';
import '../../providers/buddy_dashboard_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/soul_button.dart';

class BuddyDashboardScreen extends ConsumerWidget {
  const BuddyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(buddyDashboardProvider);

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _NotBuddyError(onBack: () => context.pop()),
          data: (dash) => _Body(dashboard: dash),
        ),
      ),
    );
  }
}

// =====================================================================
// BODY
// =====================================================================
class _Body extends ConsumerWidget {
  final BuddyDashboard dashboard;
  const _Body({required this.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(buddyMonthlyIncomeProvider);
    final upcomingAsync = ref.watch(buddyUpcomingCapsulasProvider);

    return Column(
      children: [
        _Header(dashboard: dashboard),
        Expanded(
          child: RefreshIndicator(
            color: SoulColors.turquoise,
            backgroundColor: SoulColors.midnight,
            onRefresh: () async {
              ref.invalidate(buddyDashboardProvider);
              ref.invalidate(buddyMonthlyIncomeProvider);
              ref.invalidate(buddyUpcomingCapsulasProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _IncomeHero(dashboard: dashboard),
                const SizedBox(height: 14),
                _SplitBreakdown(dashboard: dashboard),
                const SizedBox(height: 18),
                _StatsGrid(dashboard: dashboard),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'Evolución mensual',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    const _PeriodChip(label: 'Últimos 12m'),
                  ],
                ),
                const SizedBox(height: 10),
                _IncomeChart(incomeAsync: incomeAsync),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'Próximas sesiones',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context.push('/buddy/nueva-capsula'),
                      icon: const Icon(
                        Icons.add_rounded,
                        color: SoulColors.turquoise,
                        size: 16,
                      ),
                      label: const Text(
                        'Crear',
                        style: TextStyle(
                          color: SoulColors.turquoise,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _UpcomingList(upcomingAsync: upcomingAsync),
                const SizedBox(height: 18),
                if (dashboard.pendientesValidacion > 0)
                  _PendingValidationCard(
                    count: dashboard.pendientesValidacion,
                    onTap: () => context.push('/misiones'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// HEADER
// =====================================================================
class _Header extends StatelessWidget {
  final BuddyDashboard dashboard;
  const _Header({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Soul Buddy',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 22),
                    ),
                    if (dashboard.isFounderBuddy) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [SoulColors.gold, SoulColors.pink],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'FUNDADOR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Text(
                  'Tu trabajo facilitando transformaciones',
                  style: TextStyle(
                    color: SoulColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// INCOME HERO
// =====================================================================
class _IncomeHero extends StatelessWidget {
  final BuddyDashboard dashboard;
  const _IncomeHero({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'USD ',
      decimalDigits: 0,
    );
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          SoulColors.gold.withValues(alpha: .35),
          SoulColors.pink.withValues(alpha: .25),
          SoulColors.violet.withValues(alpha: .3),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 16,
                color: SoulColors.gold,
              ),
              SizedBox(width: 6),
              Text(
                'INGRESOS TOTALES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fmt.format(dashboard.ingresosBuddyUsd),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 14,
                color: SoulColors.turquoise,
              ),
              const SizedBox(width: 4),
              Text(
                'Tu 70% de ${fmt.format(dashboard.ingresosBrutosUsd)} facturados',
                style: const TextStyle(
                  fontSize: 13,
                  color: SoulColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitBreakdown extends StatelessWidget {
  final BuddyDashboard dashboard;
  const _SplitBreakdown({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final gross = dashboard.ingresosBrutosUsd;
    final buddyRatio = gross > 0 ? dashboard.ingresosBuddyUsd / gross : 0.7;
    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'USD ',
      decimalDigits: 0,
    );

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Split 70/30',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: SoulColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                fmt.format(gross),
                style: const TextStyle(
                  fontSize: 12,
                  color: SoulColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (buddyRatio * 100).round(),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: SoulColors.ctaGradient,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (100 - (buddyRatio * 100)).round(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LegendItem(
                  color: SoulColors.turquoise,
                  label: 'Vos',
                  value: fmt.format(dashboard.ingresosBuddyUsd),
                ),
              ),
              Expanded(
                child: _LegendItem(
                  color: Colors.white.withValues(alpha: .3),
                  label: 'Plataforma',
                  value: fmt.format(dashboard.feePlataformaUsd),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label, value;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: SoulColors.textMuted),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

// =====================================================================
// STATS GRID
// =====================================================================
class _StatsGrid extends StatelessWidget {
  final BuddyDashboard dashboard;
  const _StatsGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatMini(
            icon: Icons.auto_awesome_rounded,
            color: SoulColors.turquoise,
            value: '${dashboard.capsulasRealizadas}',
            label: 'CÁPSULAS',
            sub: '${dashboard.capsulasProximas} próximas',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatMini(
            icon: Icons.diversity_3_rounded,
            color: SoulColors.violet,
            value: '${dashboard.soulsAlcanzadas}',
            label: 'SOULS',
            sub: '${dashboard.inscripcionesPagas} inscripciones',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatMini(
            icon: Icons.verified_rounded,
            color: SoulColors.gold,
            value: '${dashboard.misionesValidadas}',
            label: 'VALIDADAS',
            sub: dashboard.pendientesValidacion > 0
                ? '${dashboard.pendientesValidacion} pendientes'
                : 'Todo al día',
          ),
        ),
      ],
    );
  }
}

class _StatMini extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label, sub;
  const _StatMini({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: SoulColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: .85)),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  const _PeriodChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SoulColors.glass,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: SoulColors.glassBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: SoulColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =====================================================================
// INCOME CHART (bar chart simple con fl_chart)
// =====================================================================
class _IncomeChart extends StatelessWidget {
  final AsyncValue<List<BuddyMonthlyIncome>> incomeAsync;
  const _IncomeChart({required this.incomeAsync});

  @override
  Widget build(BuildContext context) {
    return incomeAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) {
          return const GlassCard(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 32,
                    color: SoulColors.textMuted,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Todavía no hay ingresos que graficar',
                    style: TextStyle(color: SoulColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }
        // Invertimos: queremos oldest → newest
        final data = list.reversed.toList();
        final maxY = data
            .map((e) => e.ingresosBuddyUsd)
            .fold<double>(0, (m, v) => v > m ? v : m);
        final niceMax = maxY < 10 ? 10.0 : (maxY * 1.15);

        return GlassCard(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: niceMax,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, _) {
                      final item = data[group.x.toInt()];
                      return BarTooltipItem(
                        'USD ${rod.toY.toStringAsFixed(0)}\n'
                        '${DateFormat.yMMM('es').format(item.month)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: .1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        '\$${v.toInt()}',
                        style: const TextStyle(
                          color: SoulColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat.MMM('es').format(data[i].month),
                            style: const TextStyle(
                              color: SoulColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  data.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i].ingresosBuddyUsd,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        gradient: SoulColors.ctaGradient,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =====================================================================
// UPCOMING CAPSULAS
// =====================================================================
class _UpcomingList extends StatelessWidget {
  final AsyncValue<List<BuddyUpcomingCapsula>> upcomingAsync;
  const _UpcomingList({required this.upcomingAsync});

  @override
  Widget build(BuildContext context) {
    return upcomingAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) {
          return GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.event_note_rounded,
                  size: 32,
                  color: SoulColors.textMuted,
                ),
                const SizedBox(height: 6),
                const Text(
                  'No tenés cápsulas programadas',
                  style: TextStyle(color: SoulColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SoulButton(
                  label: 'Crear primera cápsula',
                  icon: Icons.add_rounded,
                  variant: SoulButtonVariant.ghost,
                  onPressed: () => context.push('/buddy/nueva-capsula'),
                ),
              ],
            ),
          );
        }
        return Column(
          children: list
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _UpcomingTile(item: c),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final BuddyUpcomingCapsula item;
  const _UpcomingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat("EEE d MMM · HH:mm", 'es');
    final occupancy = item.capacity > 0
        ? (item.inscritosTotal / item.capacity).clamp(0.0, 1.0)
        : 0.0;
    final isFree = item.priceUsd == 0;

    return GlassCard(
      onTap: () => context.push('/experiencias/${item.capsulaId}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isFree ? 'Free' : 'USD ${item.priceUsd.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isFree ? SoulColors.turquoise : SoulColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateFmt.format(item.startsAt),
            style: const TextStyle(
              color: SoulColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: occupancy,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: .08),
                    valueColor: const AlwaysStoppedAnimation(
                      SoulColors.turquoise,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${item.inscritosTotal}/${item.capacity}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SoulColors.textPrimary,
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
// PENDING VALIDATION
// =====================================================================
class _PendingValidationCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _PendingValidationCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      gradient: LinearGradient(
        colors: [
          SoulColors.gold.withValues(alpha: .3),
          SoulColors.pink.withValues(alpha: .2),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [SoulColors.gold, SoulColors.pink],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hay $count misiones esperando',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tu validación las completa y acredita XP.',
                  style: TextStyle(
                    color: SoulColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

// =====================================================================
// NOT BUDDY (acceso denegado)
// =====================================================================
class _NotBuddyError extends StatelessWidget {
  final VoidCallback onBack;
  const _NotBuddyError({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: SoulColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'Esta pantalla es para Soul Buddies',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Si querés sumarte como facilitador, escribinos desde la comunidad.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SoulColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              SoulButton(label: 'Volver', onPressed: onBack),
            ],
          ),
        ),
      ),
    );
  }
}
