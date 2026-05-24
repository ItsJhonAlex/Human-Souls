import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/soul_button.dart';
import '../../widgets/common/soul_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);

    try {
      if (_isSignUp) {
        await auth.signUpWithEmail(
          email: _emailCtrl.text,
          password: _passCtrl.text,
          fullName: _nameCtrl.text,
        );
      } else {
        await auth.signInWithEmail(
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );
      }
      // El router escucha authStateChanges y redirige solo.
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Algo salió mal. Probá de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      setState(() => _error = 'No se pudo abrir Google. Probá con email.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Brand(),
                  const SizedBox(height: 28),
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isSignUp ? 'Crear cuenta' : 'Entrar',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isSignUp
                                ? 'Sumate al mundo de Human Souls.'
                                : 'Volvé a conectarte con tu camino.',
                            style: const TextStyle(
                              color: SoulColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (_isSignUp) ...[
                            SoulTextField(
                              controller: _nameCtrl,
                              label: 'NOMBRE',
                              hint: '¿Cómo te llamás?',
                              prefixIcon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Contanos tu nombre'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          SoulTextField(
                            controller: _emailCtrl,
                            label: 'EMAIL',
                            hint: 'tu@email.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Falta el email';
                              }
                              if (!v.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          SoulTextField(
                            controller: _passCtrl,
                            label: 'CONTRASEÑA',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(alpha: .4),
                                ),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SoulButton(
                            label: _isSignUp ? 'Crear cuenta' : 'Entrar',
                            loading: _loading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            children: [
                              Expanded(
                                child: Divider(color: SoulColors.glassBorder),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'o',
                                  style: TextStyle(color: SoulColors.textMuted),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: SoulColors.glassBorder),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SoulButton(
                            label: 'Continuar con Google',
                            icon: Icons.g_mobiledata_rounded,
                            variant: SoulButtonVariant.light,
                            loading: _loading,
                            onPressed: _signInWithGoogle,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _isSignUp = !_isSignUp;
                        _error = null;
                      }),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: SoulColors.textSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: _isSignUp
                                  ? '¿Ya tenés cuenta? '
                                  : '¿Primera vez? ',
                            ),
                            TextSpan(
                              text: _isSignUp ? 'Entrá' : 'Creá tu cuenta',
                              style: const TextStyle(
                                color: SoulColors.turquoise,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: SoulColors.ctaGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: SoulColors.turquoise.withValues(alpha: .4),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, size: 38, color: Colors.white),
        ),
        const SizedBox(height: 18),
        Text('Human Souls', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 6),
        const Text(
          'Conocerte por dentro crea valor afuera.',
          style: TextStyle(color: SoulColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
