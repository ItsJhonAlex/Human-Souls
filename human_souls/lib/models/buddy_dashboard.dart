class BuddyDashboard {
  final String buddyId;
  final String? fullName;
  final bool isFounderBuddy;
  final int capsulasTotal;
  final int capsulasRealizadas;
  final int capsulasProximas;
  final int inscripcionesPagas;
  final int soulsAlcanzadas;
  final double ingresosBrutosUsd;
  final double ingresosBuddyUsd;
  final double feePlataformaUsd;
  final int misionesValidadas;
  final int pendientesValidacion;

  const BuddyDashboard({
    required this.buddyId,
    required this.fullName,
    required this.isFounderBuddy,
    required this.capsulasTotal,
    required this.capsulasRealizadas,
    required this.capsulasProximas,
    required this.inscripcionesPagas,
    required this.soulsAlcanzadas,
    required this.ingresosBrutosUsd,
    required this.ingresosBuddyUsd,
    required this.feePlataformaUsd,
    required this.misionesValidadas,
    required this.pendientesValidacion,
  });

  factory BuddyDashboard.fromMap(Map<String, dynamic> m) => BuddyDashboard(
        buddyId: m['buddy_id'] as String,
        fullName: m['full_name'] as String?,
        isFounderBuddy: (m['is_founder_buddy'] ?? false) as bool,
        capsulasTotal: (m['capsulas_total'] ?? 0) as int,
        capsulasRealizadas: (m['capsulas_realizadas'] ?? 0) as int,
        capsulasProximas: (m['capsulas_proximas'] ?? 0) as int,
        inscripcionesPagas: (m['inscripciones_pagas'] ?? 0) as int,
        soulsAlcanzadas: (m['souls_alcanzadas'] ?? 0) as int,
        ingresosBrutosUsd: double.parse((m['ingresos_brutos_usd'] ?? 0).toString()),
        ingresosBuddyUsd: double.parse((m['ingresos_buddy_usd'] ?? 0).toString()),
        feePlataformaUsd: double.parse((m['fee_plataforma_usd'] ?? 0).toString()),
        misionesValidadas: (m['misiones_validadas'] ?? 0) as int,
        pendientesValidacion: (m['pendientes_validacion'] ?? 0) as int,
      );
}

class BuddyMonthlyIncome {
  final DateTime month;
  final double ingresosBrutosUsd;
  final double ingresosBuddyUsd;
  final int soulsPagas;
  final int capsulasConIngreso;

  const BuddyMonthlyIncome({
    required this.month,
    required this.ingresosBrutosUsd,
    required this.ingresosBuddyUsd,
    required this.soulsPagas,
    required this.capsulasConIngreso,
  });

  factory BuddyMonthlyIncome.fromMap(Map<String, dynamic> m) => BuddyMonthlyIncome(
        month: DateTime.parse(m['month'] as String),
        ingresosBrutosUsd: double.parse((m['ingresos_brutos_usd'] ?? 0).toString()),
        ingresosBuddyUsd: double.parse((m['ingresos_buddy_usd'] ?? 0).toString()),
        soulsPagas: (m['souls_pagas'] ?? 0) as int,
        capsulasConIngreso: (m['capsulas_con_ingreso'] ?? 0) as int,
      );
}

class BuddyUpcomingCapsula {
  final String capsulaId;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final double priceUsd;
  final String status;
  final int inscritosTotal;
  final int inscritosPagos;

  const BuddyUpcomingCapsula({
    required this.capsulaId,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.priceUsd,
    required this.status,
    required this.inscritosTotal,
    required this.inscritosPagos,
  });

  factory BuddyUpcomingCapsula.fromMap(Map<String, dynamic> m) => BuddyUpcomingCapsula(
        capsulaId: m['capsula_id'] as String,
        title: m['title'] as String,
        startsAt: DateTime.parse(m['starts_at'] as String),
        endsAt: DateTime.parse(m['ends_at'] as String),
        capacity: (m['capacity'] ?? 0) as int,
        priceUsd: double.parse((m['price_usd'] ?? 0).toString()),
        status: m['status'] as String? ?? 'scheduled',
        inscritosTotal: (m['inscritos_total'] ?? 0) as int,
        inscritosPagos: (m['inscritos_pagos'] ?? 0) as int,
      );
}
