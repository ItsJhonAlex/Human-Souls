import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/mock/mock_backend.dart';
import '../main.dart';

class ProfileStats {
  final int misionesCompletadas;
  final int capsulasAsistidas;
  final int diasEnSouls;

  const ProfileStats({
    required this.misionesCompletadas,
    required this.capsulasAsistidas,
    required this.diasEnSouls,
  });
}

final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((
  ref,
) async {
  if (AppConfig.useMock) {
    final s = MockBackend.instance.statsSnapshot();
    return ProfileStats(
      misionesCompletadas: s.misiones,
      capsulasAsistidas: s.capsulas,
      diasEnSouls: s.dias,
    );
  }
  final user = supabase.auth.currentUser;
  if (user == null) throw StateError('No hay sesión');

  final misResponse = await supabase
      .from('mision_completadas')
      .select()
      .eq('user_id', user.id)
      .eq('validated', true);

  final capResponse = await supabase
      .from('capsula_inscripciones')
      .select()
      .eq('user_id', user.id)
      .eq('attended', true);

  final profile = await supabase
      .from('profiles')
      .select('created_at')
      .eq('id', user.id)
      .single();

  final createdAt = DateTime.parse(profile['created_at'] as String);
  final dias = DateTime.now().difference(createdAt).inDays;

  return ProfileStats(
    misionesCompletadas: misResponse.length,
    capsulasAsistidas: capResponse.length,
    diasEnSouls: dias < 1 ? 1 : dias,
  );
});
