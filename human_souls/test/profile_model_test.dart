import 'package:flutter_test/flutter_test.dart';
import 'package:human_souls/models/profile.dart';

void main() {
  test('Profile.fromMap lee membership_provider', () {
    final p = Profile.fromMap({
      'id': 'u1',
      'email': 'a@b.com',
      'membership_provider': 'stripe',
    });
    expect(p.membershipProvider, 'stripe');
  });

  test('membershipProvider es null cuando no viene', () {
    final p = Profile.fromMap({'id': 'u1', 'email': 'a@b.com'});
    expect(p.membershipProvider, isNull);
  });
}
