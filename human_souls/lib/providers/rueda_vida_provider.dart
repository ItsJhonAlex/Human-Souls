import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/rueda_vida.dart';

/// Primer día del mes actual.
DateTime _currentMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}

String _fmtMonth(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-01';

/// Rueda del mes en curso. Si no existe registro, devuelve una vacía.
final ruedaActualProvider = FutureProvider.autoDispose<RuedaVida>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw StateError('No hay sesión');

  final month = _currentMonth();
  final row = await supabase
      .from('rueda_vida')
      .select()
      .eq('user_id', user.id)
      .eq('month', _fmtMonth(month))
      .maybeSingle();

  if (row == null) return RuedaVida.empty(user.id, month);
  return RuedaVida.fromMap(row);
});

/// Historial de ruedas (últimos 12 meses).
final ruedaHistoryProvider = FutureProvider.autoDispose<List<RuedaVida>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return const [];

  final rows = await supabase
      .from('rueda_vida')
      .select()
      .eq('user_id', user.id)
      .order('month', ascending: false)
      .limit(12);

  return (rows as List).map((r) => RuedaVida.fromMap(r)).toList();
});

/// Upsert (insert o update por user_id + month). Luego invalida los providers.
Future<void> saveRueda(WidgetRef ref, RuedaVida rueda) async {
  await supabase
      .from('rueda_vida')
      .upsert(rueda.toUpsert(), onConflict: 'user_id,month');
  ref.invalidate(ruedaActualProvider);
  ref.invalidate(ruedaHistoryProvider);
}
