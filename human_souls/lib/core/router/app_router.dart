import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/buddy/buddy_dashboard_screen.dart';
import '../../screens/buddy/create_capsula_screen.dart';
import '../../screens/capsulas/capsula_detail_screen.dart';
import '../../screens/capsulas/capsulas_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/chat/chats_list_screen.dart';
import '../../screens/comunidad/comunidad_screen.dart';
import '../../screens/comunidad/create_post_screen.dart';
import '../../screens/comunidad/post_detail_screen.dart';
import '../../screens/membership/membership_screen.dart';
import '../../screens/misiones/misiones_screen.dart';
import '../../screens/mundo/mundo_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/perfil/perfil_screen.dart';
import '../../screens/perfil/rueda_vida_screen.dart';
import '../../screens/shell/main_shell.dart';

/// Escucha cambios de auth de Supabase y notifica al router para que
/// re-ejecute la lógica de redirect.
class _AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;
  _AuthRefreshNotifier() {
    _sub = supabase.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefreshNotifier();
  final flag = ref.watch(onboardingFlagProvider);
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([authRefresh, flag]),
    redirect: (context, state) async {
      final user = supabase.auth.currentUser;
      final loc = state.uri.path;

      final isLogin = loc == '/login';
      final isSplash = loc == '/splash';
      final isOnboarding = loc == '/onboarding';

      // 1. Sin sesión → login
      if (user == null) {
        return isLogin ? null : '/login';
      }

      // 2. Con sesión: resolver onboarding
      final done = await flag.ensure(user.id);

      if (!done) {
        return isOnboarding ? null : '/onboarding';
      }

      // 3. Onboarding completo: sacar de pantallas de boot
      if (isLogin || isSplash || isOnboarding) return '/mundo';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(
        path: '/perfil/rueda',
        builder: (c, s) => const RuedaVidaScreen(),
      ),
      GoRoute(
        path: '/comunidad/crear',
        builder: (c, s) => const CreatePostScreen(),
      ),
      GoRoute(path: '/membresia', builder: (c, s) => const MembershipScreen()),
      GoRoute(path: '/buddy', builder: (c, s) => const BuddyDashboardScreen()),
      GoRoute(
        path: '/buddy/nueva-capsula',
        builder: (c, s) => const CreateCapsulaScreen(),
      ),
      GoRoute(path: '/chat', builder: (c, s) => const ChatsListScreen()),
      GoRoute(
        path: '/chat/:chatId',
        builder: (c, s) => ChatScreen(
          chatId: s.pathParameters['chatId']!,
          otherUserId: s.uri.queryParameters['userId'] ?? '',
        ),
      ),
      ShellRoute(
        builder: (c, s, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/mundo', builder: (c, s) => const MundoScreen()),
          GoRoute(path: '/misiones', builder: (c, s) => const MisionesScreen()),
          GoRoute(
            path: '/experiencias',
            builder: (c, s) => const CapsulasScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (c, s) =>
                    CapsulaDetailScreen(capsulaId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/comunidad',
            builder: (c, s) => const ComunidadScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (c, s) =>
                    PostDetailScreen(postId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/perfil', builder: (c, s) => const PerfilScreen()),
        ],
      ),
    ],
  );
});
