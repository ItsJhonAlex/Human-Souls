import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:human_souls/app.dart';
import 'package:human_souls/core/config/app_config.dart';

void main() {
  testWidgets('La app arranca en modo mock y muestra el login', (tester) async {
    // Sanity: el preview corre en modo mock.
    expect(AppConfig.useMock, isTrue);

    await tester.pumpWidget(const ProviderScope(child: HumanSoulsApp()));
    await tester.pump(const Duration(milliseconds: 100));

    // El brand del login está presente.
    expect(find.text('Human Souls'), findsWidgets);
    expect(find.text('Entrar'), findsWidgets);
  });
}
