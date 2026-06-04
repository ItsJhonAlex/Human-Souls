import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/config/theme.dart';
import '../../core/mock/mock_backend.dart';
import '../../main.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/buddy_dashboard_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/rueda_vida_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/soul_button.dart';
import '../../widgets/common/soul_text_field.dart';
import '../../widgets/profile/stat_tile.dart';
import '../../widgets/profile/xp_bar.dart';
import '../../widgets/rueda/rueda_vida_chart.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) => _PerfilBody(profile: profile),
        ),
      ),
    );
  }
}

class _PerfilBody extends ConsumerWidget {
  final Profile profile;
  const _PerfilBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider);
    final rueda = ref.watch(ruedaActualProvider);

    return RefreshIndicator(
      color: SoulColors.turquoise,
      backgroundColor: SoulColors.midnight,
      onRefresh: () async {
        ref.invalidate(currentProfileProvider);
        ref.invalidate(profileStatsProvider);
        ref.invalidate(ruedaActualProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          _PerfilHeader(profile: profile),
          const SizedBox(height: 20),
          if (AppConfig.useMock) ...[
            const _DemoPersonaCard(),
            const SizedBox(height: 16),
          ],
          _AvatarBlock(profile: profile),
          const SizedBox(height: 16),
          _LevelCard(profile: profile),
          const SizedBox(height: 16),
          _StatsRow(stats: stats),
          const SizedBox(height: 16),
          _RuedaPreviewCard(
            ruedaAsync: rueda,
            onTap: () => context.push('/perfil/rueda'),
          ),
          const SizedBox(height: 16),
          _MembershipCard(profile: profile),
          if (profile.isBuddy) ...[
            const SizedBox(height: 12),
            _BuddyDashboardCard(isFounder: profile.isFounderBuddy),
          ],
          const SizedBox(height: 12),
          _MessagesCard(),
          const SizedBox(height: 24),
          _LogoutButton(),
        ],
      ),
    );
  }
}

// =====================================================================
// HEADER con acción editar
// =====================================================================
class _PerfilHeader extends ConsumerWidget {
  final Profile profile;
  const _PerfilHeader({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text('Mi Perfil', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: SoulColors.glass,
            shape: BoxShape.circle,
            border: Border.all(color: SoulColors.glassBorder),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showEditProfileSheet(context, ref, profile),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// AVATAR + NOMBRE + USERNAME + BIO
// =====================================================================
class _AvatarBlock extends ConsumerStatefulWidget {
  final Profile profile;
  const _AvatarBlock({required this.profile});

  @override
  ConsumerState<_AvatarBlock> createState() => _AvatarBlockState();
}

class _AvatarBlockState extends ConsumerState<_AvatarBlock> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (AppConfig.useMock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subir foto estará disponible al conectar el backend'),
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 82,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final user = supabase.auth.currentUser!;
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final path = '${user.id}/avatar.$ext';

      await supabase.storage
          .from('avatars')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(upsert: true),
          );
      final url = supabase.storage.from('avatars').getPublicUrl(path);
      // Agregar cache-buster para que la UI tome la imagen nueva.
      final urlWithBuster = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await supabase
          .from('profiles')
          .update({'avatar_url': urlWithBuster})
          .eq('id', user.id);

      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo subir: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final initial = (p.fullName ?? p.email).substring(0, 1).toUpperCase();

    return GlassCard(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  gradient: SoulColors.ctaGradient,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: SoulColors.deepBlue,
                  backgroundImage: p.avatarUrl != null
                      ? NetworkImage(p.avatarUrl!)
                      : null,
                  child: p.avatarUrl == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: SoulColors.ctaGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: SoulColors.deepBlue, width: 2),
                    ),
                    child: _uploading
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.fullName ?? 'Soul',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 20),
              ),
              if (p.isFounderBuddy) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.verified_rounded,
                  color: SoulColors.gold,
                  size: 20,
                ),
              ],
            ],
          ),
          if (p.username != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '@${p.username}',
                style: const TextStyle(
                  color: SoulColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          if (p.bio != null && p.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              p.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SoulColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (p.isBuddy) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SoulColors.gold.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: SoulColors.gold.withValues(alpha: .5),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 14, color: SoulColors.gold),
                  SizedBox(width: 6),
                  Text(
                    'SOUL BUDDY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: SoulColors.gold,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =====================================================================
// LEVEL CARD
// =====================================================================
class _LevelCard extends StatelessWidget {
  final Profile profile;
  const _LevelCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final (_, high) = profile.xpBounds();
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          SoulColors.violet.withValues(alpha: .35),
          SoulColors.cyan.withValues(alpha: .25),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NIVEL ${profile.level}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: SoulColors.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: SoulColors.pink,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.soulPoints} SP',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            profile.levelName,
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 14),
          XpBar(progress: profile.xpProgress, xp: profile.xp, nextXp: high),
        ],
      ),
    );
  }
}

// =====================================================================
// STATS ROW
// =====================================================================
class _StatsRow extends StatelessWidget {
  final AsyncValue<ProfileStats> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return stats.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (s) => Row(
        children: [
          Expanded(
            child: StatTile(
              icon: Icons.bolt_rounded,
              value: '${s.misionesCompletadas}',
              label: 'MISIONES',
              color: SoulColors.turquoise,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatTile(
              icon: Icons.auto_awesome,
              value: '${s.capsulasAsistidas}',
              label: 'CÁPSULAS',
              color: SoulColors.violet,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatTile(
              icon: Icons.wb_sunny_rounded,
              value: '${s.diasEnSouls}',
              label: 'DÍAS',
              color: SoulColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// RUEDA PREVIEW
// =====================================================================
class _RuedaPreviewCard extends StatelessWidget {
  final AsyncValue ruedaAsync;
  final VoidCallback onTap;
  const _RuedaPreviewCard({required this.ruedaAsync, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: ruedaAsync.when(
        loading: () => const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (rueda) {
          final allZero = (rueda.values as List<int>).every((v) => v == 0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.radar_rounded,
                    color: SoulColors.turquoise,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'RUEDA DE LA VIDA',
                    style: TextStyle(
                      color: SoulColors.turquoise,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat.yMMMM('es').format(DateTime.now()),
                    style: const TextStyle(
                      color: SoulColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (allZero) ...[
                const SizedBox(height: 10),
                Text(
                  'Todavía no completaste la Rueda de este mes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tomate 3 minutos para evaluar cómo estás hoy en cada área de tu vida.',
                  style: TextStyle(
                    color: SoulColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Completar ahora',
                        style: TextStyle(
                          color: SoulColors.turquoise,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: SoulColors.turquoise,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Center(
                  child: RuedaVidaChart(
                    values: rueda.values,
                    size: 240,
                    showLabels: false,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: SoulColors.turquoise,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Promedio ${rueda.average.toStringAsFixed(1)} / 10',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: SoulColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver y editar',
                        style: TextStyle(
                          color: SoulColors.turquoise,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: SoulColors.turquoise,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// MEMBERSHIP CARD
// =====================================================================
class _MembershipCard extends StatelessWidget {
  final Profile profile;
  const _MembershipCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final active =
        profile.membershipStatus == 'active' ||
        profile.membershipStatus == 'trialing';

    return GlassCard(
      onTap: () => context.push('/membresia'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: active ? SoulColors.ctaGradient : null,
              color: active ? null : Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              active
                  ? Icons.workspace_premium_rounded
                  : Icons.lock_outline_rounded,
              color: active ? Colors.white : SoulColors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'Miembro activo' : 'Plan Free',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  active
                      ? 'Acceso completo a cápsulas + comunidad'
                      : 'Hacete miembro para acceder a cápsulas en vivo',
                  style: const TextStyle(
                    color: SoulColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

// =====================================================================
// BUDDY DASHBOARD CARD (solo para Soul Buddies)
// =====================================================================
class _BuddyDashboardCard extends StatelessWidget {
  final bool isFounder;
  const _BuddyDashboardCard({required this.isFounder});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push('/buddy'),
      gradient: LinearGradient(
        colors: [
          SoulColors.gold.withValues(alpha: .25),
          SoulColors.violet.withValues(alpha: .2),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [SoulColors.gold, SoulColors.pink],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Dashboard Buddy',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (isFounder) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.diamond_outlined,
                        size: 16,
                        color: SoulColors.gold,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ingresos, sesiones y split 70/30',
                  style: TextStyle(
                    color: SoulColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

// =====================================================================
// MESSAGES CARD
// =====================================================================
class _MessagesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push('/chat'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SoulColors.turquoise.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: SoulColors.turquoise,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis mensajes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Conversaciones 1:1 con otros Souls',
                  style: TextStyle(
                    color: SoulColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

// =====================================================================
// LOGOUT
// =====================================================================
class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoulButton(
      label: 'Cerrar sesión',
      icon: Icons.logout_rounded,
      variant: SoulButtonVariant.ghost,
      onPressed: () async {
        await ref.read(authServiceProvider).signOut();
        ref.read(onboardingFlagProvider).reset();
      },
    );
  }
}

// =====================================================================
// SELECTOR DE PERSONA (solo modo demo)
// =====================================================================
class _DemoPersonaCard extends ConsumerWidget {
  const _DemoPersonaCard();

  void _select(WidgetRef ref, DemoPersona persona) {
    MockBackend.instance.setPersona(persona);
    ref.invalidate(currentProfileProvider);
    ref.invalidate(profileStatsProvider);
    ref.invalidate(buddyDashboardProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final isBuddy = profile?.isBuddy ?? false;
    final isMember = profile?.membershipStatus == 'active';
    final current = isBuddy
        ? DemoPersona.buddy
        : (isMember ? DemoPersona.member : DemoPersona.free);

    Widget chip(String label, DemoPersona p) {
      final selected = current == p;
      return Expanded(
        child: GestureDetector(
          onTap: () => _select(ref, p),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? SoulColors.ctaGradient : null,
              color: selected ? null : SoulColors.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? Colors.transparent : SoulColors.glassBorder,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : SoulColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: SoulColors.gold),
              SizedBox(width: 6),
              Text(
                'MODO DEMO · PERSONA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: SoulColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              chip('Free', DemoPersona.free),
              chip('Miembro', DemoPersona.member),
              chip('Buddy', DemoPersona.buddy),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// EDIT PROFILE SHEET
// =====================================================================
void _showEditProfileSheet(
  BuildContext context,
  WidgetRef ref,
  Profile profile,
) {
  final nameCtrl = TextEditingController(text: profile.fullName ?? '');
  final bioCtrl = TextEditingController(text: profile.bio ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          bool saving = false;
          String? error;

          Future<void> save() async {
            setLocal(() {
              saving = true;
              error = null;
            });
            try {
              if (AppConfig.useMock) {
                MockBackend.instance.updateProfile(
                  fullName: nameCtrl.text.trim(),
                  bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                );
                ref.invalidate(currentProfileProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                return;
              }
              await supabase
                  .from('profiles')
                  .update({
                    'full_name': nameCtrl.text.trim(),
                    'bio': bioCtrl.text.trim().isEmpty
                        ? null
                        : bioCtrl.text.trim(),
                  })
                  .eq('id', profile.id);
              ref.invalidate(currentProfileProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              setLocal(() => error = 'No se pudo guardar');
            } finally {
              setLocal(() => saving = false);
            }
          }

          final mq = MediaQuery.of(ctx);
          return Padding(
            padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: SoulColors.midnight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + mq.viewPadding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Editar perfil',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  SoulTextField(
                    controller: nameCtrl,
                    label: 'NOMBRE',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  SoulTextField(
                    controller: bioCtrl,
                    label: 'BIO',
                    hint: 'Contanos en una línea quién sos…',
                    maxLines: 3,
                    maxLength: 140,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SoulButton(
                    label: 'Guardar',
                    loading: saving,
                    onPressed: save,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
