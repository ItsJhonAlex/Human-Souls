class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final int level;
  final String levelName;
  final int xp;
  final int soulPoints;
  final bool isBuddy;
  final bool isFounderBuddy;
  final String membershipStatus; // free, active, cancelled, trialing
  final String? membershipPlan;
  final String? membershipProvider; // stripe | mercadopago
  final DateTime? membershipExpiresAt;
  final bool onboardingCompleted;

  const Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.bio,
    this.level = 1,
    this.levelName = 'Explorador',
    this.xp = 0,
    this.soulPoints = 0,
    this.isBuddy = false,
    this.isFounderBuddy = false,
    this.membershipStatus = 'free',
    this.membershipPlan,
    this.membershipProvider,
    this.membershipExpiresAt,
    this.onboardingCompleted = false,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        email: m['email'] as String,
        fullName: m['full_name'] as String?,
        username: m['username'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        bio: m['bio'] as String?,
        level: (m['level'] ?? 1) as int,
        levelName: (m['level_name'] ?? 'Explorador') as String,
        xp: (m['xp'] ?? 0) as int,
        soulPoints: (m['soul_points'] ?? 0) as int,
        isBuddy: (m['is_buddy'] ?? false) as bool,
        isFounderBuddy: (m['is_founder_buddy'] ?? false) as bool,
        membershipStatus: (m['membership_status'] ?? 'free') as String,
        membershipPlan: m['membership_plan'] as String?,
        membershipProvider: m['membership_provider'] as String?,
        membershipExpiresAt: m['membership_expires_at'] != null
            ? DateTime.parse(m['membership_expires_at'] as String)
            : null,
        onboardingCompleted: (m['onboarding_completed'] ?? false) as bool,
      );

  /// XP mínimo del nivel actual y del siguiente — para el progress bar.
  (int current, int next) xpBounds() {
    switch (level) {
      case 1: return (0, 100);
      case 2: return (100, 500);
      case 3: return (500, 1500);
      default: return (1500, 3000);
    }
  }

  double get xpProgress {
    final (low, high) = xpBounds();
    if (high == low) return 1.0;
    final p = (xp - low) / (high - low);
    return p.clamp(0.0, 1.0);
  }
}
