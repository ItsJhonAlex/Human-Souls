import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/theme.dart';
import '../../models/capsula.dart';
import '../../providers/capsulas_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/soul_button.dart';
import 'checkout_sheet.dart';

class CapsulaDetailScreen extends ConsumerWidget {
  final String capsulaId;
  const CapsulaDetailScreen({super.key, required this.capsulaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsulaAsync = ref.watch(capsulaDetailProvider(capsulaId));
    final inscripcionesAsync = ref.watch(myInscripcionesProvider);

    return GradientBackground(
      child: SafeArea(
        child: capsulaAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (c) {
            final inscripcion = inscripcionesAsync.asData?.value[c.id];
            return _Body(capsula: c, inscripcion: inscripcion);
          },
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final Capsula capsula;
  final CapsulaInscripcion? inscripcion;
  const _Body({required this.capsula, required this.inscripcion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final isMember = profile?.membershipStatus == 'active' ||
        profile?.membershipStatus == 'trialing';

    return Column(children: [
      _Header(onBack: () => context.pop()),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _HeroCard(capsula: capsula),
            const SizedBox(height: 16),
            if (capsula.description != null) ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sobre esta cápsula',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(capsula.description!,
                        style: const TextStyle(
                          color: SoulColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _RewardsCard(capsula: capsula),
            if (inscripcion != null && capsula.meetingLink != null) ...[
              const SizedBox(height: 16),
              _MeetingLinkCard(link: capsula.meetingLink!),
            ],
          ],
        ),
      ),
      _ActionBar(
        capsula: capsula,
        inscripcion: inscripcion,
        isMember: isMember,
      ),
    ]);
  }
}

// =====================================================================
// HEADER
// =====================================================================
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(children: [
        IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        const SizedBox(width: 4),
        Text('Cápsula',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 20)),
      ]),
    );
  }
}

// =====================================================================
// HERO CARD
// =====================================================================
class _HeroCard extends StatelessWidget {
  final Capsula capsula;
  const _HeroCard({required this.capsula});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat("EEEE d 'de' MMMM", 'es');
    final timeFmt = DateFormat.Hm('es');

    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          SoulColors.turquoise.withValues(alpha: .35),
          SoulColors.violet.withValues(alpha: .3),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (capsula.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, size: 8, color: Colors.white),
                SizedBox(width: 4),
                Text('EN VIVO AHORA',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ]),
            ),
          if (capsula.isLive) const SizedBox(height: 12),
          Text(capsula.title,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 26)),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: SoulColors.turquoise),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${dateFmt.format(capsula.startsAt)} · ${timeFmt.format(capsula.startsAt)} hs',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.schedule_rounded,
                size: 16, color: SoulColors.turquoise),
            const SizedBox(width: 8),
            Text('${capsula.duration.inMinutes} minutos',
                style: const TextStyle(
                    fontSize: 14, color: SoulColors.textSecondary)),
          ]),
          if (capsula.hostName != null) ...[
            const SizedBox(height: 14),
            const Divider(color: SoulColors.glassBorder),
            const SizedBox(height: 12),
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: SoulColors.violet,
                backgroundImage: capsula.hostAvatar != null
                    ? NetworkImage(capsula.hostAvatar!)
                    : null,
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('FACILITA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: SoulColors.textMuted,
                    )),
                Text(capsula.hostName!,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ]),
          ],
        ],
      ),
    );
  }
}

// =====================================================================
// REWARDS
// =====================================================================
class _RewardsCard extends StatelessWidget {
  final Capsula capsula;
  const _RewardsCard({required this.capsula});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Al participar ganás',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(children: [
            _Award(
                icon: Icons.bolt_rounded,
                color: SoulColors.gold,
                value: '+${capsula.xpReward}',
                label: 'XP'),
            const SizedBox(width: 12),
            _Award(
                icon: Icons.favorite_rounded,
                color: SoulColors.pink,
                value: '+${capsula.soulPointsReward}',
                label: 'Soul Points'),
          ]),
        ],
      ),
    );
  }
}

class _Award extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;
  const _Award(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

// =====================================================================
// MEETING LINK (solo visible para inscriptos)
// =====================================================================
class _MeetingLinkCard extends StatelessWidget {
  final String link;
  const _MeetingLinkCard({required this.link});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () =>
          launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
      gradient: LinearGradient(
        colors: [
          SoulColors.cyan.withValues(alpha: .3),
          SoulColors.violet.withValues(alpha: .3)
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.videocam_rounded, color: SoulColors.deepBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Link del encuentro',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 15)),
              const SizedBox(height: 2),
              Text(link,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: SoulColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 18),
      ]),
    );
  }
}

// =====================================================================
// ACTION BAR
// =====================================================================
class _ActionBar extends ConsumerStatefulWidget {
  final Capsula capsula;
  final CapsulaInscripcion? inscripcion;
  final bool isMember;
  const _ActionBar({
    required this.capsula,
    required this.inscripcion,
    required this.isMember,
  });

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _working = false;

  Future<void> _inscribirGratis() async {
    setState(() => _working = true);
    try {
      await inscribirGratis(ref: ref, capsula: widget.capsula);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: SoulColors.turquoise,
            content: Text('¡Inscripción confirmada! ✨',
                style: TextStyle(
                    color: SoulColors.deepBlue, fontWeight: FontWeight.w700)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo inscribir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _cancelar() async {
    setState(() => _working = true);
    try {
      await cancelarInscripcion(ref: ref, capsulaId: widget.capsula.id);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.capsula;
    final i = widget.inscripcion;

    if (c.isPast) {
      return _Bar(
          child: SoulButton(
        label: i != null
            ? (i.attended ? 'Ya asististe' : 'Cápsula finalizada')
            : 'Cápsula finalizada',
        icon: i?.attended == true ? Icons.check_rounded : Icons.history_rounded,
        variant: SoulButtonVariant.ghost,
        onPressed: null,
      ));
    }

    if (i != null) {
      // Ya inscripto → botón en vivo / unirse / cancelar
      if (c.isLive && c.meetingLink != null) {
        return _Bar(
            child: Row(children: [
          Expanded(
            child: SoulButton(
              label: 'Unirme ahora',
              icon: Icons.videocam_rounded,
              onPressed: () => launchUrl(
                Uri.parse(c.meetingLink!),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        ]));
      }
      return _Bar(
          child: Row(children: [
        Expanded(
          flex: 1,
          child: SoulButton(
            label: 'Cancelar',
            variant: SoulButtonVariant.ghost,
            loading: _working,
            onPressed: _cancelar,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          flex: 2,
          child: SoulButton(
            label: 'Estás inscripto',
            icon: Icons.check_circle_rounded,
            variant: SoulButtonVariant.light,
            onPressed: null,
          ),
        ),
      ]));
    }

    // No inscripto aún
    // Caso A: incluida en membresía
    if (c.includedInMembership && c.priceUsd == 0) {
      if (widget.isMember) {
        return _Bar(
            child: SoulButton(
          label: 'Inscribirme gratis',
          icon: Icons.auto_awesome,
          loading: _working,
          onPressed: _inscribirGratis,
        ));
      }
      // No-member: ofrecer pago individual con el precio que definas,
      // o redirigir a membresía. Para MVP mostramos pago individual con
      // precio sugerido 15 USD si no hay price definido.
      return _Bar(
          child: SoulButton(
        label: 'Hacerme miembro',
        icon: Icons.workspace_premium_rounded,
        onPressed: () => context.push('/membresia'),
      ));
    }

    // Caso B: cápsula con precio individual
    return _Bar(
        child: SoulButton(
      label: 'Comprar · USD ${c.priceUsd.toStringAsFixed(0)}',
      icon: Icons.bolt_rounded,
      onPressed: () {
        showCheckoutSheet(context, ref, widget.capsula);
      },
    ));
  }
}

class _Bar extends StatelessWidget {
  final Widget child;
  const _Bar({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: SoulColors.deepBlue.withValues(alpha: .8),
        border: const Border(top: BorderSide(color: SoulColors.glassBorder)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
