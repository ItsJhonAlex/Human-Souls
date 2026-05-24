import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/config/theme.dart';
import '../../core/mock/mock_backend.dart';
import '../../core/services/membership_service.dart';
import '../../providers/profile_provider.dart';
import '../capsulas/checkout_sheet.dart' show showCheckoutWebView;
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/soul_button.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  String _selectedPlan = 'monthly';
  bool _busy = false;

  Future<void> _subscribe(String provider) async {
    setState(() => _busy = true);
    try {
      final session = provider == 'stripe'
          ? await membershipService.createStripeSubscription(
              plan: _selectedPlan,
            )
          : await membershipService.createMercadoPagoSubscription(
              plan: _selectedPlan,
            );

      if (AppConfig.useMock) {
        MockBackend.instance.activateMembership(_selectedPlan);
        ref.invalidate(currentProfileProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membresía simulada activada ✨')),
        );
        return;
      }

      if (!mounted) return;

      if (kIsWeb) {
        await launchUrl(Uri.parse(session.url), webOnlyWindowName: '_self');
      } else {
        final approved = await showCheckoutWebView(context, url: session.url);
        if (approved == true) ref.invalidate(currentProfileProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo iniciar: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SoulColors.midnight,
        title: const Text('¿Cancelar membresía?'),
        content: const Text(
          'Vas a conservar tu acceso hasta el final del período ya pagado. '
          'Después quedás con acceso free.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir siendo miembro'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      if (AppConfig.useMock) {
        MockBackend.instance.cancelMembership();
        ref.invalidate(currentProfileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Suscripción cancelada (demo).')),
          );
        }
        setState(() => _busy = false);
        return;
      }
      await membershipService.cancelSubscription();
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Suscripción cancelada. Acceso activo hasta el fin del período.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo cancelar: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return GradientBackground(
      child: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) {
            final isMember = profile.membershipStatus == 'active' ||
                profile.membershipStatus == 'trialing';
            return Column(
              children: [
                _Header(onBack: () => context.pop()),
                Expanded(
                  child: isMember
                      ? _ActiveMembershipView(
                          profile: profile,
                          onCancel: _cancel,
                          busy: _busy,
                        )
                      : _SubscribeView(
                          selectedPlan: _selectedPlan,
                          onChangePlan: (p) =>
                              setState(() => _selectedPlan = p),
                          onSubscribe: _subscribe,
                          busy: _busy,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const SizedBox(width: 4),
          Text(
            'Membresía',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// SUBSCRIBE VIEW
// =====================================================================
class _SubscribeView extends StatelessWidget {
  final String selectedPlan;
  final ValueChanged<String> onChangePlan;
  final void Function(String provider) onSubscribe;
  final bool busy;

  const _SubscribeView({
    required this.selectedPlan,
    required this.onChangePlan,
    required this.onSubscribe,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _Hero(),
        const SizedBox(height: 20),
        Text('Elegí tu plan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _PlanCard(
          plan: 'monthly',
          title: 'Mensual',
          price: 'USD 15',
          subtitle: 'por mes',
          badge: null,
          selected: selectedPlan == 'monthly',
          onTap: () => onChangePlan('monthly'),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          plan: 'quarterly',
          title: 'Trimestral',
          price: 'USD 39',
          subtitle: 'cada 3 meses · ahorrás USD 6',
          badge: '–13%',
          selected: selectedPlan == 'quarterly',
          onTap: () => onChangePlan('quarterly'),
        ),
        const SizedBox(height: 22),
        Text('Lo que incluye', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        _BenefitsCard(),
        const SizedBox(height: 22),
        Text('Cómo pagar', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        _ProviderTile(
          title: 'Tarjeta internacional',
          subtitle: 'Stripe · Visa, Mastercard, Amex (en USD)',
          emoji: '💳',
          isPrimary: true,
          onTap: busy ? null : () => onSubscribe('stripe'),
        ),
        const SizedBox(height: 10),
        _ProviderTile(
          title: 'MercadoPago',
          subtitle: 'Débito automático · Argentina (en ARS)',
          emoji: '🇦🇷',
          onTap: busy ? null : () => onSubscribe('mercadopago'),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: CircularProgressIndicator(color: SoulColors.turquoise),
            ),
          ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Podés cancelar cuando quieras. Sin letra chica.',
            style: TextStyle(color: SoulColors.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          SoulColors.gold.withValues(alpha: .3),
          SoulColors.pink.withValues(alpha: .25),
          SoulColors.violet.withValues(alpha: .3),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 14,
                  color: SoulColors.gold,
                ),
                SizedBox(width: 6),
                Text(
                  'HACETE MIEMBRO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tu camino merece\nacompañamiento real',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 24, height: 1.15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acceso a todas las cápsulas en vivo, misiones exclusivas y el ecosistema completo.',
            style: TextStyle(
              color: SoulColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String plan, title, price, subtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard({
    required this.plan,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      SoulColors.violet.withValues(alpha: .3),
                      SoulColors.turquoise.withValues(alpha: .2),
                    ],
                  )
                : null,
            color: selected ? null : SoulColors.glass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? SoulColors.turquoise : SoulColors.glassBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected ? SoulColors.ctaGradient : null,
                  border: selected ? null : Border.all(color: Colors.white38),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [SoulColors.gold, SoulColors.pink],
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: SoulColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: SoulColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  static const _items = [
    ('Acceso a todas las cápsulas en vivo', Icons.auto_awesome),
    ('Misiones semanales y mensuales', Icons.bolt_rounded),
    ('Comunidad de Souls y chat 1:1', Icons.diversity_3_rounded),
    ('Validación personalizada de un Soul Buddy', Icons.verified_rounded),
    ('Ganás XP, Soul Points y subís de nivel', Icons.trending_up_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: _items
            .map(
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: SoulColors.turquoise.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(i.$2, size: 16, color: SoulColors.turquoise),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        i.$1,
                        style: const TextStyle(fontSize: 14, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final String title, subtitle, emoji;
  final bool isPrimary;
  final VoidCallback? onTap;
  const _ProviderTile({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isPrimary ? SoulColors.ctaGradient : null,
            color: isPrimary ? null : SoulColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? Colors.transparent : SoulColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isPrimary ? Colors.white70 : SoulColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// ACTIVE MEMBERSHIP VIEW
// =====================================================================
class _ActiveMembershipView extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onCancel;
  final bool busy;
  const _ActiveMembershipView({
    required this.profile,
    required this.onCancel,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final expiresAt = profile.membershipExpiresAt as DateTime?;
    final planLabel =
        profile.membershipPlan == 'quarterly' ? 'Trimestral' : 'Mensual';
    final provider = profile.membershipProvider as String?;
    final providerLabel = provider == 'mercadopago' ? 'MercadoPago' : 'Stripe';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        GlassCard(
          gradient: LinearGradient(
            colors: [
              SoulColors.turquoise.withValues(alpha: .3),
              SoulColors.violet.withValues(alpha: .3),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SoulColors.gold, SoulColors.pink],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SoulColors.gold.withValues(alpha: .4),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Sos Miembro Activo',
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                'Plan $planLabel · $providerLabel',
                style: const TextStyle(color: SoulColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (expiresAt != null)
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.event_rounded, color: SoulColors.turquoise),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Próxima renovación',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          color: SoulColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          "d 'de' MMMM 'de' y",
                          'es',
                        ).format(expiresAt),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _BenefitsCard(),
        const SizedBox(height: 24),
        SoulButton(
          label: 'Cancelar suscripción',
          variant: SoulButtonVariant.ghost,
          loading: busy,
          onPressed: onCancel,
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Tu acceso continúa hasta el final del período ya pagado.',
            style: TextStyle(color: SoulColors.textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
