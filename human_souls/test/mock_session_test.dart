import 'package:flutter_test/flutter_test.dart';
import 'package:human_souls/core/mock/mock_session.dart';

void main() {
  setUp(() => MockSession.instance.resetForTest());

  test('arranca sin sesión', () {
    expect(MockSession.instance.isLoggedIn, isFalse);
  });

  test('signIn inicia sesión con el usuario demo', () {
    MockSession.instance.signIn();
    expect(MockSession.instance.isLoggedIn, isTrue);
    expect(MockSession.instance.userId, kDemoUserId);
  });

  test('signOut cierra sesión y resetea onboarding', () {
    MockSession.instance.signIn();
    MockSession.instance.completeOnboarding();
    MockSession.instance.signOut();
    expect(MockSession.instance.isLoggedIn, isFalse);
    expect(MockSession.instance.onboardingDone, isFalse);
  });
}
