import 'package:flutter/material.dart';

import '../core/config/theme.dart';

/// Metadata de las 8 áreas de la Rueda de la Vida.
/// El orden es fijo y se respeta tanto en el chart como en los sliders.
class RuedaArea {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const RuedaArea({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const ruedaAreas = <RuedaArea>[
  RuedaArea(key: 'salud',         label: 'Salud',         icon: Icons.favorite_rounded,          color: Color(0xFF4ADE80)),
  RuedaArea(key: 'familia',       label: 'Familia',       icon: Icons.home_rounded,              color: Color(0xFFFF8FB0)),
  RuedaArea(key: 'amor',          label: 'Amor',          icon: Icons.auto_awesome_rounded,      color: Color(0xFFFF6B6B)),
  RuedaArea(key: 'amistad',       label: 'Amistad',       icon: Icons.diversity_3_rounded,       color: Color(0xFFFFA94D)),
  RuedaArea(key: 'trabajo',       label: 'Trabajo',       icon: Icons.work_outline_rounded,      color: SoulColors.cyan),
  RuedaArea(key: 'finanzas',      label: 'Finanzas',      icon: Icons.account_balance_wallet_rounded, color: SoulColors.gold),
  RuedaArea(key: 'crecimiento',   label: 'Crecimiento',   icon: Icons.psychology_rounded,        color: SoulColors.violet),
  RuedaArea(key: 'espiritualidad',label: 'Espiritualidad',icon: Icons.self_improvement_rounded,  color: SoulColors.turquoise),
];

class RuedaVida {
  final String? id;
  final String userId;
  final DateTime month; // primer día del mes
  final int salud, familia, amor, amistad;
  final int trabajo, finanzas, crecimiento, espiritualidad;

  const RuedaVida({
    this.id,
    required this.userId,
    required this.month,
    this.salud = 0,
    this.familia = 0,
    this.amor = 0,
    this.amistad = 0,
    this.trabajo = 0,
    this.finanzas = 0,
    this.crecimiento = 0,
    this.espiritualidad = 0,
  });

  factory RuedaVida.empty(String userId, DateTime month) =>
      RuedaVida(userId: userId, month: DateTime(month.year, month.month, 1));

  factory RuedaVida.fromMap(Map<String, dynamic> m) => RuedaVida(
        id: m['id'] as String?,
        userId: m['user_id'] as String,
        month: DateTime.parse(m['month'] as String),
        salud: (m['salud'] ?? 0) as int,
        familia: (m['familia'] ?? 0) as int,
        amor: (m['amor'] ?? 0) as int,
        amistad: (m['amistad'] ?? 0) as int,
        trabajo: (m['trabajo'] ?? 0) as int,
        finanzas: (m['finanzas'] ?? 0) as int,
        crecimiento: (m['crecimiento'] ?? 0) as int,
        espiritualidad: (m['espiritualidad'] ?? 0) as int,
      );

  Map<String, dynamic> toUpsert() => {
        'user_id': userId,
        'month': '${month.year}-${month.month.toString().padLeft(2, '0')}-01',
        'salud': salud,
        'familia': familia,
        'amor': amor,
        'amistad': amistad,
        'trabajo': trabajo,
        'finanzas': finanzas,
        'crecimiento': crecimiento,
        'espiritualidad': espiritualidad,
      };

  /// Valores en el mismo orden que [ruedaAreas].
  List<int> get values => [
        salud, familia, amor, amistad,
        trabajo, finanzas, crecimiento, espiritualidad,
      ];

  double get average => values.reduce((a, b) => a + b) / values.length;

  RuedaVida copyWithValue(String key, int value) {
    return RuedaVida(
      id: id,
      userId: userId,
      month: month,
      salud:          key == 'salud'         ? value : salud,
      familia:        key == 'familia'       ? value : familia,
      amor:           key == 'amor'          ? value : amor,
      amistad:        key == 'amistad'       ? value : amistad,
      trabajo:        key == 'trabajo'       ? value : trabajo,
      finanzas:       key == 'finanzas'      ? value : finanzas,
      crecimiento:    key == 'crecimiento'   ? value : crecimiento,
      espiritualidad: key == 'espiritualidad'? value : espiritualidad,
    );
  }
}
