import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/mock/mock_session.dart';
import '../core/services/auth_service.dart';
import '../main.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(AppConfig.useMock ? null : supabase),
);

/// Stream de cambios de autenticación. Lo consume el router con refreshListenable.
final authStateProvider = StreamProvider<AuthState>((ref) {
  if (AppConfig.useMock) return const Stream.empty();
  return ref.read(authServiceProvider).authStateChanges;
});

/// Flag cacheado de onboarding completado. En mock lee de [MockSession].
class OnboardingFlag extends ChangeNotifier {
  bool? _done;

  bool? get value => _done;

  Future<bool> ensure(String userId) async {
    if (AppConfig.useMock) {
      _done = MockSession.instance.onboardingDone;
      return _done!;
    }
    if (_done != null) return _done!;
    try {
      final row = await supabase
          .from('profiles')
          .select('onboarding_completed')
          .eq('id', userId)
          .maybeSingle();
      _done = (row?['onboarding_completed'] as bool?) ?? false;
    } catch (_) {
      _done = false;
    }
    notifyListeners();
    return _done!;
  }

  void markCompleted() {
    _done = true;
    if (AppConfig.useMock) MockSession.instance.completeOnboarding();
    notifyListeners();
  }

  void reset() {
    _done = null;
    notifyListeners();
  }
}

final onboardingFlagProvider = Provider<OnboardingFlag>((ref) {
  final flag = OnboardingFlag();
  ref.onDispose(flag.dispose);
  return flag;
});
