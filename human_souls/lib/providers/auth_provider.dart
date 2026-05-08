import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/auth_service.dart';
import '../main.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(supabase),
);

/// Stream de cambios de autenticación. Lo consume el router con refreshListenable.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

/// Flag cacheado de onboarding completado. Se lee en la redirect del router
/// sin tener que esperar a una query en cada navegación después de la primera.
class OnboardingFlag extends ChangeNotifier {
  bool? _done;

  bool? get value => _done;

  Future<bool> ensure(String userId) async {
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
