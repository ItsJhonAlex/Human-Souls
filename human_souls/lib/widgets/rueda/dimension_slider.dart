import 'package:flutter/material.dart';

import '../../models/rueda_vida.dart';

class DimensionSlider extends StatelessWidget {
  final RuedaArea area;
  final int value;
  final ValueChanged<int> onChanged;

  const DimensionSlider({
    super.key,
    required this.area,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: area.color.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: area.color.withValues(alpha: .35)),
            ),
            child: Icon(area.icon, size: 20, color: area.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(area.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: area.color.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('$value / 10',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: area.color,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: area.color,
                    inactiveTrackColor: Colors.white.withValues(alpha: .12),
                    thumbColor: Colors.white,
                    overlayColor: area.color.withValues(alpha: .2),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 9),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 18),
                  ),
                  child: Slider(
                    min: 0,
                    max: 10,
                    divisions: 10,
                    value: value.toDouble(),
                    onChanged: (v) => onChanged(v.round()),
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
