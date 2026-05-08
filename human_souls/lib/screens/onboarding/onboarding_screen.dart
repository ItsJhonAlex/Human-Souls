import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/theme.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/soul_button.dart';
import '../../widgets/common/soul_text_field.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _intentionCtrl = TextEditingController();

  int _page = 0;
  bool _saving = false;
  String? _error;
  int _awardedXp = 0;
  int _awardedSp = 0;

  static const _totalPages = 4;

  @override
  void initState() {
    super.initState();
    // Prefill con lo que venga del provider OAuth o del signup.
    final user = supabase.auth.currentUser;
    final metaName = user?.userMetadata?['full_name'] as String?;
    if (metaName != null && metaName.isNotEmpty) {
      _nameCtrl.text = metaName;
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _intentionCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _saveProfileAndAdvance() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Contanos cómo te llamás');
      return;
    }
    if (username.isEmpty || username.length < 3) {
      setState(() => _error = 'Tu @usuario necesita al menos 3 caracteres');
      return;
    }
    if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(username.toLowerCase())) {
      setState(() => _error = 'Solo letras, números, _ y .');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = supabase.auth.currentUser!;
      await supabase.from('profiles').update({
        'full_name': name,
        'username': username.toLowerCase(),
      }).eq('id', user.id);
      _next();
    } catch (e) {
      setState(() => _error = e.toString().contains('duplicate')
          ? 'Ese @usuario ya está tomado'
          : 'No pudimos guardar, probá de nuevo');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitIntentionAndFinish() async {
    final intention = _intentionCtrl.text.trim();
    if (intention.length < 10) {
      setState(() => _error = 'Contanos un poquito más (mínimo 10 caracteres)');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = supabase.auth.currentUser!;

      // 1. Buscar la misión "Escribí tu intención"
      final mision = await supabase
          .from('misiones')
          .select('id, xp_reward, soul_points_reward')
          .ilike('title', 'Escribí tu intención')
          .limit(1)
          .maybeSingle();

      // 2. Crear post público en el feed
      await supabase
          .from('posts')
          .insert({
            'user_id': user.id,
            'content': intention,
            if (mision != null) 'mission_id': mision['id'],
          })
          .select()
          .single();

      // 3. Registrar misión completada (el trigger otorga XP + SP y sube nivel)
      if (mision != null) {
        final now = DateTime.now().toUtc();
        final periodKey = '${now.year}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';
        await supabase.from('mision_completadas').insert({
          'user_id': user.id,
          'mision_id': mision['id'],
          'period_key': periodKey,
          'evidence_url': null,
          'evidence_text': intention,
          'validated': true,
          'validated_at': DateTime.now().toIso8601String(),
        });
        _awardedXp = mision['xp_reward'] as int? ?? 15;
        _awardedSp = mision['soul_points_reward'] as int? ?? 5;
      }

      // 4. Marcar onboarding completado
      await supabase.from('profiles').update({
        'onboarding_completed': true,
      }).eq('id', user.id);

      ref.read(onboardingFlagProvider).markCompleted();

      if (mounted) _next();
    } catch (e) {
      setState(() => _error = 'Hubo un problema al guardar. Probá otra vez.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(
              page: _page,
              total: _totalPages,
              onBack: _page > 0 && _page < _totalPages - 1 ? _back : null,
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() {
                  _page = i;
                  _error = null;
                }),
                children: [
                  _WelcomePage(onNext: _next),
                  _ProfilePage(
                    nameCtrl: _nameCtrl,
                    usernameCtrl: _usernameCtrl,
                    error: _error,
                    loading: _saving,
                    onContinue: _saveProfileAndAdvance,
                  ),
                  _IntentionPage(
                    intentionCtrl: _intentionCtrl,
                    error: _error,
                    loading: _saving,
                    onContinue: _submitIntentionAndFinish,
                  ),
                  _CelebrationPage(
                    xp: _awardedXp,
                    sp: _awardedSp,
                    onEnter: () => context.go('/mundo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// PROGRESS HEADER
// =====================================================================
class _ProgressHeader extends StatelessWidget {
  final int page, total;
  final VoidCallback? onBack;
  const _ProgressHeader({required this.page, required this.total, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: onBack != null ? Colors.white : Colors.transparent,
              size: 18),
        ),
        Expanded(
          child: Row(
              children: List.generate(total, (i) {
            final active = i <= page;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: active ? SoulColors.ctaGradient : null,
                  color: active ? null : Colors.white.withValues(alpha: .15),
                ),
              ),
            );
          })),
        ),
        const SizedBox(width: 48),
      ]),
    );
  }
}

// =====================================================================
// PAGE 1 — WELCOME
// =====================================================================
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: SoulColors.capsulaGradient,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: SoulColors.turquoise.withValues(alpha: .35),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.favorite_rounded,
                size: 56, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text('Bienvenida\nal mundo de\nHuman Souls ✨',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(height: 1.1)),
          const SizedBox(height: 18),
          const Text(
            'Nos conectamos para aprender.\nAprendemos para transformarnos.\nNos transformamos para cambiar el mundo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: SoulColors.textSecondary,
            ),
          ),
          const Spacer(flex: 2),
          SoulButton(label: 'Empezar mi camino', onPressed: onNext),
        ],
      ),
    );
  }
}

// =====================================================================
// PAGE 2 — PROFILE
// =====================================================================
class _ProfilePage extends StatelessWidget {
  final TextEditingController nameCtrl, usernameCtrl;
  final String? error;
  final bool loading;
  final VoidCallback onContinue;
  const _ProfilePage({
    required this.nameCtrl,
    required this.usernameCtrl,
    required this.error,
    required this.loading,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text('¿Cómo te reconocemos?',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 28)),
          const SizedBox(height: 8),
          const Text(
            'Así te van a ver otros Souls cuando compartas en la comunidad.',
            style: TextStyle(
                color: SoulColors.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),
          GlassCard(
            child: Column(children: [
              SoulTextField(
                controller: nameCtrl,
                label: 'TU NOMBRE',
                hint: 'Ej: Daia Ramírez',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              SoulTextField(
                controller: usernameCtrl,
                label: '@USUARIO',
                hint: 'daia',
                prefixIcon: Icons.alternate_email_rounded,
                textInputAction: TextInputAction.done,
                maxLength: 24,
              ),
            ]),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(error!),
          ],
          const SizedBox(height: 28),
          SoulButton(
            label: 'Continuar',
            loading: loading,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// PAGE 3 — FIRST MISSION
// =====================================================================
class _IntentionPage extends StatelessWidget {
  final TextEditingController intentionCtrl;
  final String? error;
  final bool loading;
  final VoidCallback onContinue;
  const _IntentionPage({
    required this.intentionCtrl,
    required this.error,
    required this.loading,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SoulColors.turquoise.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(100),
              border:
                  Border.all(color: SoulColors.turquoise.withValues(alpha: .5)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bolt_rounded, size: 14, color: SoulColors.turquoise),
              SizedBox(width: 6),
              Text('TU PRIMERA MISIÓN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: SoulColors.turquoise,
                  )),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Compartí tu intención',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 28)),
          const SizedBox(height: 10),
          const Text(
            '¿Qué te trajo a Human Souls? ¿Qué querés empezar a transformar? '
            'Escribilo en tus palabras — no hace falta que sea perfecto.',
            style: TextStyle(
                color: SoulColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: SoulTextField(
              controller: intentionCtrl,
              hint: 'Quiero conectar con gente que…',
              maxLines: 6,
              maxLength: 500,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(error!),
          ],
          const SizedBox(height: 20),
          const Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: SoulColors.textMuted),
            SizedBox(width: 6),
            Expanded(
              child: Text('Esto se va a publicar en el feed de la comunidad.',
                  style: TextStyle(color: SoulColors.textMuted, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 20),
          SoulButton(
            label: 'Publicar y continuar',
            icon: Icons.send_rounded,
            loading: loading,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// PAGE 4 — CELEBRATION
// =====================================================================
class _CelebrationPage extends StatelessWidget {
  final int xp, sp;
  final VoidCallback onEnter;
  const _CelebrationPage({
    required this.xp,
    required this.sp,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, t, _) => Transform.scale(
                scale: t,
                child: Container(
                  width: 140,
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        SoulColors.gold,
                        SoulColors.pink,
                        SoulColors.violet
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SoulColors.gold.withValues(alpha: .5),
                        blurRadius: 48,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome,
                      size: 70, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('¡Ya sos parte!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 10),
          const Text(
            'Tu camino arranca en el primer nivel:\nExplorador ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: SoulColors.textSecondary, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AwardChip(
                label: 'XP',
                value: '+$xp',
                icon: Icons.bolt_rounded,
                color: SoulColors.gold,
              ),
              const SizedBox(width: 12),
              _AwardChip(
                label: 'Soul Points',
                value: '+$sp',
                icon: Icons.favorite_rounded,
                color: SoulColors.pink,
              ),
            ],
          ),
          const Spacer(flex: 2),
          SoulButton(
            label: 'Entrar al Mundo',
            icon: Icons.public_rounded,
            onPressed: onEnter,
          ),
        ],
      ),
    );
  }
}

class _AwardChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AwardChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            )),
        Text(label,
            style: const TextStyle(
              fontSize: 11,
              color: SoulColors.textMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            )),
      ]),
    );
  }
}

// =====================================================================
// ERROR BANNER
// =====================================================================
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: .4)),
      ),
      child: Text(message,
          style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
    );
  }
}
