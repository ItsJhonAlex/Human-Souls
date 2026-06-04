import 'package:flutter/foundation.dart';

/// Id fijo del usuario demo. Se usa en todo el MockBackend para que "mis"
/// posts/mensajes se reconozcan como propios.
const kDemoUserId = 'demo-user-0001';

/// Sesión simulada que reemplaza a `supabase.auth` cuando `AppConfig.useMock`.
class MockSession extends ChangeNotifier {
  MockSession._();
  static final MockSession instance = MockSession._();

  bool _loggedIn = false;
  bool _onboardingDone = false;

  bool get isLoggedIn => _loggedIn;
  bool get onboardingDone => _onboardingDone;
  String get userId => kDemoUserId;

  void signIn() {
    _loggedIn = true;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingDone = true;
    notifyListeners();
  }

  void signOut() {
    _loggedIn = false;
    _onboardingDone = false;
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    _loggedIn = false;
    _onboardingDone = false;
  }
}
