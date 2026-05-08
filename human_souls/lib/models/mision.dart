enum MisionTipo { daily, weekly, monthly }

enum EvidenceType { photo, audio, text, post, none }

extension MisionTipoX on MisionTipo {
  static MisionTipo parse(String raw) => switch (raw) {
        'weekly' => MisionTipo.weekly,
        'monthly' => MisionTipo.monthly,
        _ => MisionTipo.daily,
      };

  String get label => switch (this) {
        MisionTipo.daily => 'Diaria',
        MisionTipo.weekly => 'Semanal',
        MisionTipo.monthly => 'Mensual',
      };

  String get wireValue => name;
}

extension EvidenceTypeX on EvidenceType {
  static EvidenceType parse(String raw) => switch (raw) {
        'photo' => EvidenceType.photo,
        'audio' => EvidenceType.audio,
        'text' => EvidenceType.text,
        'post' => EvidenceType.post,
        _ => EvidenceType.none,
      };

  String get label => switch (this) {
        EvidenceType.photo => 'Foto',
        EvidenceType.audio => 'Audio',
        EvidenceType.text => 'Texto',
        EvidenceType.post => 'Publicación',
        EvidenceType.none => 'Automática',
      };
}

class Mision {
  final String id;
  final String title;
  final String description;
  final MisionTipo tipo;
  final int xpReward;
  final int soulPointsReward;
  final EvidenceType evidenceType;
  final bool active;
  final DateTime startsAt;
  final DateTime? endsAt;

  const Mision({
    required this.id,
    required this.title,
    required this.description,
    required this.tipo,
    required this.xpReward,
    required this.soulPointsReward,
    required this.evidenceType,
    required this.active,
    required this.startsAt,
    this.endsAt,
  });

  factory Mision.fromMap(Map<String, dynamic> m) => Mision(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String,
        tipo: MisionTipoX.parse(m['mission_type'] as String),
        xpReward: (m['xp_reward'] ?? 10) as int,
        soulPointsReward: (m['soul_points_reward'] ?? 5) as int,
        evidenceType: EvidenceTypeX.parse(m['evidence_type'] as String),
        active: (m['active'] ?? true) as bool,
        startsAt: DateTime.parse(m['starts_at'] as String),
        endsAt: m['ends_at'] != null
            ? DateTime.parse(m['ends_at'] as String) : null,
      );
}

/// Devuelve la period_key usada en la DB según cadencia + timestamp.
String periodKeyFor(MisionTipo tipo, DateTime now) {
  final utc = now.toUtc();
  switch (tipo) {
    case MisionTipo.daily:
      return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-'
          '${utc.day.toString().padLeft(2, '0')}';
    case MisionTipo.weekly:
      final week = _isoWeekNumber(utc);
      return '${utc.year}-W${week.toString().padLeft(2, '0')}';
    case MisionTipo.monthly:
      return '${utc.year}-${utc.month.toString().padLeft(2, '0')}';
  }
}

/// Número de semana ISO 8601.
int _isoWeekNumber(DateTime d) {
  final thursday = d.add(Duration(days: 4 - (d.weekday == 0 ? 7 : d.weekday)));
  final firstThursday = DateTime.utc(thursday.year, 1, 4);
  final diff = thursday.difference(
    firstThursday.subtract(Duration(days: (firstThursday.weekday - 1))),
  );
  return (diff.inDays / 7).floor() + 1;
}

class MisionCompletada {
  final String id;
  final String userId;
  final String misionId;
  final String periodKey;
  final String? evidenceUrl;
  final String? evidenceText;
  final bool validated;
  final String? validatedBy;
  final DateTime? validatedAt;
  final DateTime createdAt;

  // Opcional: joins hidratados
  final Mision? mision;
  final String? userName;
  final String? userAvatar;

  const MisionCompletada({
    required this.id,
    required this.userId,
    required this.misionId,
    required this.periodKey,
    required this.validated,
    required this.createdAt,
    this.evidenceUrl,
    this.evidenceText,
    this.validatedBy,
    this.validatedAt,
    this.mision,
    this.userName,
    this.userAvatar,
  });

  factory MisionCompletada.fromMap(Map<String, dynamic> m) {
    final misionData = m['misiones'] ?? m['mision'];
    final profileData = m['profiles'];
    return MisionCompletada(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      misionId: m['mision_id'] as String,
      periodKey: m['period_key'] as String,
      evidenceUrl: m['evidence_url'] as String?,
      evidenceText: m['evidence_text'] as String?,
      validated: (m['validated'] ?? false) as bool,
      validatedBy: m['validated_by'] as String?,
      validatedAt: m['validated_at'] != null
          ? DateTime.parse(m['validated_at'] as String) : null,
      createdAt: DateTime.parse(m['created_at'] as String),
      mision: misionData is Map<String, dynamic> ? Mision.fromMap(misionData) : null,
      userName: profileData is Map ? profileData['full_name'] as String? : null,
      userAvatar: profileData is Map ? profileData['avatar_url'] as String? : null,
    );
  }
}
