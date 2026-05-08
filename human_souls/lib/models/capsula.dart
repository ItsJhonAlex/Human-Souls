class Capsula {
  final String id;
  final String title;
  final String? description;
  final String? hostId;
  final String? hostName;
  final String? hostAvatar;
  final String? coverUrl;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? meetingLink;
  final int capacity;
  final double priceUsd;
  final bool includedInMembership;
  final int xpReward;
  final int soulPointsReward;
  final String status; // scheduled, live, ended, cancelled
  final int inscripcionesCount;

  const Capsula({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.priceUsd,
    required this.includedInMembership,
    required this.xpReward,
    required this.soulPointsReward,
    required this.status,
    this.description,
    this.hostId,
    this.hostName,
    this.hostAvatar,
    this.coverUrl,
    this.meetingLink,
    this.inscripcionesCount = 0,
  });

  factory Capsula.fromMap(Map<String, dynamic> m) {
    final host = m['host'] is Map ? m['host'] as Map : null;
    return Capsula(
      id: m['id'] as String,
      title: m['title'] as String,
      description: m['description'] as String?,
      hostId: m['host_id'] as String?,
      hostName: host?['full_name'] as String?,
      hostAvatar: host?['avatar_url'] as String?,
      coverUrl: m['cover_url'] as String?,
      startsAt: DateTime.parse(m['starts_at'] as String),
      endsAt: DateTime.parse(m['ends_at'] as String),
      meetingLink: m['meeting_link'] as String?,
      capacity: (m['capacity'] ?? 50) as int,
      priceUsd: double.parse((m['price_usd'] ?? 0).toString()),
      includedInMembership: (m['included_in_membership'] ?? true) as bool,
      xpReward: (m['xp_reward'] ?? 30) as int,
      soulPointsReward: (m['soul_points_reward'] ?? 15) as int,
      status: (m['status'] ?? 'scheduled') as String,
      inscripcionesCount: (m['inscripciones_count'] ?? 0) as int,
    );
  }

  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  bool get isPast => DateTime.now().isAfter(endsAt);

  /// Minutos hasta que empieza (negativo si ya pasó).
  int minutesUntilStart() => startsAt.difference(DateTime.now()).inMinutes;

  Duration get duration => endsAt.difference(startsAt);
}

class CapsulaInscripcion {
  final String id;
  final String userId;
  final String capsulaId;
  final bool paid;
  final String? paymentId;
  final bool attended;
  final bool xpAwarded;
  final DateTime createdAt;

  const CapsulaInscripcion({
    required this.id,
    required this.userId,
    required this.capsulaId,
    required this.paid,
    required this.attended,
    required this.xpAwarded,
    required this.createdAt,
    this.paymentId,
  });

  factory CapsulaInscripcion.fromMap(Map<String, dynamic> m) => CapsulaInscripcion(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        capsulaId: m['capsula_id'] as String,
        paid: (m['paid'] ?? false) as bool,
        paymentId: m['payment_id'] as String?,
        attended: (m['attended'] ?? false) as bool,
        xpAwarded: (m['xp_awarded'] ?? false) as bool,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
