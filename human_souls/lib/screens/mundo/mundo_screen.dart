import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/theme.dart';
import '../../models/profile.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/profile/xp_bar.dart';

class MundoScreen extends ConsumerWidget {
  const MundoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) => _MundoBody(profile: profile),
        ),
      ),
    );
  }
}

class _MundoBody extends StatelessWidget {
  final Profile profile;
  const _MundoBody({required this.profile});

  String get _saludo {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buen día';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _Header(profile: profile, saludo: _saludo),
        const SizedBox(height: 20),
        _LevelHero(profile: profile),
        const SizedBox(height: 16),
        const _TodayMissionCard(),
        const SizedBox(height: 16),
        const _NextCapsulaCard(),
        const SizedBox(height: 16),
        const _RuedaVidaCta(),
        const SizedBox(height: 16),
        _CommunityHighlight(onTap: () => context.go('/comunidad')),
      ],
    );
  }
}

// =====================================================================
// HEADER
// =====================================================================
class _Header extends StatelessWidget {
  final Profile profile;
  final String saludo;
  const _Header({required this.profile, required this.saludo});

  @override
  Widget build(BuildContext context) {
    final name = profile.fullName?.split(' ').first ?? 'Soul';
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          gradient: SoulColors.ctaGradient,
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: SoulColors.deepBlue,
          backgroundImage: profile.avatarUrl != null
              ? NetworkImage(profile.avatarUrl!)
              : null,
          child: profile.avatarUrl == null
              ? Text(
                  name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(saludo,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: SoulColors.textSecondary,
                    )),
            Text(name, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
      _NotifButton(),
    ]);
  }
}

class _NotifButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SoulColors.glass,
        shape: BoxShape.circle,
        border: Border.all(color: SoulColors.glassBorder),
      ),
      child: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.notifications_none_rounded),
        color: Colors.white,
      ),
    );
  }
}

// =====================================================================
// LEVEL HERO
// =====================================================================
class _LevelHero extends StatelessWidget {
  final Profile profile;
  const _LevelHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final (low, high) = profile.xpBounds();

    return GlassCard(
      padding: const EdgeInsets.all(22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          SoulColors.violet.withValues(alpha: .45),
          SoulColors.cyan.withValues(alpha: .35),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _LevelBadge(level: profile.level, name: profile.levelName),
            const Spacer(),
            if (profile.isFounderBuddy) const _FounderBadge(),
          ]),
          const SizedBox(height: 18),
          Text(profile.levelName,
              style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 4),
          Text('Nivel ${profile.level} · Tu camino de Soul',
              style: const TextStyle(
                  color: SoulColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 18),
          XpBar(progress: profile.xpProgress, xp: profile.xp, nextXp: high),
          const SizedBox(height: 14),
          Row(children: [
            _SoulPointsChip(points: profile.soulPoints),
            const SizedBox(width: 10),
            _MembershipChip(status: profile.membershipStatus),
          ]),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final String name;
  const _LevelBadge({required this.level, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: .25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.auto_awesome, size: 14, color: SoulColors.gold),
        const SizedBox(width: 6),
        Text('LVL $level',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            )),
      ]),
    );
  }
}

class _FounderBadge extends StatelessWidget {
  const _FounderBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(colors: [SoulColors.gold, SoulColors.pink]),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.diamond_outlined, size: 14, color: Colors.black87),
        SizedBox(width: 6),
        Text('FUNDADOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 1.3,
            )),
      ]),
    );
  }
}

class _SoulPointsChip extends StatelessWidget {
  final int points;
  const _SoulPointsChip({required this.points});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.favorite_rounded, size: 16, color: SoulColors.pink),
        const SizedBox(width: 6),
        Text('$points SP',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _MembershipChip extends StatelessWidget {
  final String status;
  const _MembershipChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final active = status == 'active' || status == 'trialing';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? SoulColors.turquoise.withValues(alpha: .25)
            : Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: active ? SoulColors.turquoise : Colors.white24,
        ),
      ),
      child: Text(active ? 'Miembro activo' : 'Free',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? SoulColors.turquoise : Colors.white70,
            letterSpacing: 0.5,
          )),
    );
  }
}

// =====================================================================
// MISIÓN DE HOY
// =====================================================================
class _TodayMissionCard extends StatelessWidget {
  const _TodayMissionCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.go('/misiones'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bolt_rounded,
                color: SoulColors.turquoise, size: 18),
            const SizedBox(width: 6),
            Text('MISIÓN DE HOY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: SoulColors.turquoise,
                      letterSpacing: 1.5,
                    )),
            const Spacer(),
            const Text('+15 XP',
                style: TextStyle(
                  fontSize: 12,
                  color: SoulColors.gold,
                  fontWeight: FontWeight.w700,
                )),
          ]),
          const SizedBox(height: 12),
          Text('Escribí tu intención',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Compartí en el feed una intención que quieras sostener esta semana.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .75),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerRight,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Empezar',
                  style: TextStyle(
                    color: SoulColors.turquoise,
                    fontWeight: FontWeight.w700,
                  )),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: SoulColors.turquoise),
            ]),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// PRÓXIMA CÁPSULA
// =====================================================================
class _NextCapsulaCard extends StatelessWidget {
  const _NextCapsulaCard();

  @override
  Widget build(BuildContext context) {
    // TODO: conectar con Supabase (capsulas where starts_at > now order asc limit 1)
    final date = DateTime.now().add(const Duration(days: 2, hours: 3));
    final fmt = DateFormat("EEE d 'a las' HH:mm", 'es');

    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          SoulColors.turquoise.withValues(alpha: .35),
          SoulColors.violet.withValues(alpha: .35),
        ],
      ),
      onTap: () => context.go('/experiencias'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text('PRÓXIMA CÁPSULA EN VIVO',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 12),
          Text('Círculo de Soul Buddies',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.schedule_rounded, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(fmt.format(date),
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Incluida en tu membresía',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => context.go('/experiencias'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: SoulColors.deepBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
              child: const Text('Inscribirme',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        ],
      ),
    );
  }
}

// =====================================================================
// RUEDA DE LA VIDA CTA
// =====================================================================
class _RuedaVidaCta extends StatelessWidget {
  const _RuedaVidaCta();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.go('/perfil'),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            gradient: SoulColors.ctaGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.radar_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rueda de la Vida',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text('Actualizá tu evaluación de este mes',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .7),
                    fontSize: 13,
                  )),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Colors.white70),
      ]),
    );
  }
}

// =====================================================================
// DESTACADOS DE LA COMUNIDAD
// =====================================================================
class _CommunityHighlight extends StatelessWidget {
  final VoidCallback onTap;
  const _CommunityHighlight({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.forum_rounded, size: 18, color: SoulColors.aurora),
            const SizedBox(width: 6),
            Text('DESDE LA COMUNIDAD',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: SoulColors.aurora,
                      letterSpacing: 1.5,
                    )),
          ]),
          const SizedBox(height: 14),
          const Row(children: [
            _AvatarStack(),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '12 souls compartieron su intención esta semana',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();
  @override
  Widget build(BuildContext context) {
    final colors = [SoulColors.violet, SoulColors.turquoise, SoulColors.pink];
    return SizedBox(
      width: 66,
      height: 28,
      child: Stack(
        children: List.generate(
            3,
            (i) => Positioned(
                  left: i * 18.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: SoulColors.deepBlue, width: 2),
                    ),
                  ),
                )),
      ),
    );
  }
}
