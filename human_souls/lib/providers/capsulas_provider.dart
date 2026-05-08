import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/capsula.dart';

/// Próximas cápsulas (estado scheduled o live) ordenadas por fecha.
final upcomingCapsulasProvider = FutureProvider.autoDispose<List<Capsula>>((
  ref,
) async {
  final now = DateTime.now().toIso8601String();
  final rows = await supabase
      .from('capsulas')
      .select('*, host:host_id(full_name, avatar_url)')
      .gte('ends_at', now)
      .inFilter('status', ['scheduled', 'live'])
      .order('starts_at', ascending: true)
      .limit(40);
  return (rows as List).map((r) => Capsula.fromMap(r)).toList();
});

/// Cápsulas pasadas (solo las que asistí).
final pastCapsulasProvider = FutureProvider.autoDispose<List<Capsula>>((
  ref,
) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final rows = await supabase
      .from('capsula_inscripciones')
      .select('capsula:capsula_id(*, host:host_id(full_name, avatar_url))')
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(40);

  final list = <Capsula>[];
  for (final r in (rows as List)) {
    final c = r['capsula'];
    if (c is Map<String, dynamic>) {
      final capsula = Capsula.fromMap(c);
      if (capsula.isPast) list.add(capsula);
    }
  }
  return list;
});

/// Detalle de una cápsula por id.
final capsulaDetailProvider = FutureProvider.autoDispose
    .family<Capsula, String>((ref, id) async {
      final row = await supabase
          .from('capsulas')
          .select('*, host:host_id(full_name, avatar_url)')
          .eq('id', id)
          .single();
      return Capsula.fromMap(row);
    });

/// Mis inscripciones (map capsulaId -> inscripción).
final myInscripcionesProvider =
    FutureProvider.autoDispose<Map<String, CapsulaInscripcion>>((ref) async {
      final user = supabase.auth.currentUser;
      if (user == null) return {};
      final rows = await supabase
          .from('capsula_inscripciones')
          .select()
          .eq('user_id', user.id);
      return {
        for (final r in (rows as List))
          r['capsula_id'] as String: CapsulaInscripcion.fromMap(r),
      };
    });

/// Inscribirse gratis (cápsula incluida en membresía o precio 0).
Future<CapsulaInscripcion> inscribirGratis({
  required WidgetRef ref,
  required Capsula capsula,
}) async {
  final user = supabase.auth.currentUser!;
  final row = await supabase
      .from('capsula_inscripciones')
      .upsert({
        'user_id': user.id,
        'capsula_id': capsula.id,
        'paid': true, // incluida en membresía = cuenta como paga
      }, onConflict: 'user_id,capsula_id')
      .select()
      .single();
  ref.invalidate(myInscripcionesProvider);
  return CapsulaInscripcion.fromMap(row);
}

/// Cancela una inscripción.
Future<void> cancelarInscripcion({
  required WidgetRef ref,
  required String capsulaId,
}) async {
  final user = supabase.auth.currentUser!;
  await supabase
      .from('capsula_inscripciones')
      .delete()
      .eq('user_id', user.id)
      .eq('capsula_id', capsulaId);
  ref.invalidate(myInscripcionesProvider);
}
