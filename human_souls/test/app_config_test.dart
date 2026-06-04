import 'package:flutter_test/flutter_test.dart';
import 'package:human_souls/core/config/app_config.dart';

void main() {
  test('useMock está activo por defecto', () {
    expect(AppConfig.useMock, isTrue);
  });
}
