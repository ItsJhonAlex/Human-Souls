import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../../models/rueda_vida.dart';

class RuedaVidaChart extends StatelessWidget {
  final List<int> values; // 8 valores en el orden de ruedaAreas
  final double size;
  final bool showLabels;
  final bool animate;

  const RuedaVidaChart({
    super.key,
    required this.values,
    this.size = 280,
    this.showLabels = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = values.map((v) => v.clamp(0, 10).toDouble()).toList();

    return SizedBox(
      width: size,
      height: size,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          dataSets: [
            RadarDataSet(
              fillColor: SoulColors.violet.withValues(alpha: .35),
              borderColor: SoulColors.turquoise,
              borderWidth: 2,
              entryRadius: 3.5,
              dataEntries: clamped.map((v) => RadarEntry(value: v)).toList(),
            ),
          ],
          titlePositionPercentageOffset: 0.18,
          titleTextStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: showLabels ? SoulColors.textSecondary : Colors.transparent,
          ),
          getTitle: (index, _) =>
              RadarChartTitle(text: ruedaAreas[index].label),
          tickCount: 5,
          ticksTextStyle: const TextStyle(
            color: Colors.transparent,
            fontSize: 1,
          ),
          tickBorderData: BorderSide(
            color: Colors.white.withValues(alpha: .1),
            width: 1,
          ),
          gridBorderData: BorderSide(
            color: Colors.white.withValues(alpha: .18),
            width: 1,
          ),
          radarBorderData: const BorderSide(color: Colors.transparent),
          radarBackgroundColor: Colors.transparent,
        ),
        duration: animate ? const Duration(milliseconds: 600) : Duration.zero,
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
