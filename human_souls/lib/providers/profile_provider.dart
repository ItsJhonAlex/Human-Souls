import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/mock/mock_backend.dart';
import '../main.dart';
import '../models/profile.dart';

/// Perfil del usuario actual. Lanza si no hay sesión (el router garantiza
/// que esta pantalla solo se muestra a usuarios autenticados).
final currentProfileProvider = FutureProvider<Profile>((ref) async {
  if (AppConfig.useMock) return MockBackend.instance.profile;
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw StateError('No hay usuario autenticado');
  }
  final row = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();
  return Profile.fromMap(row);
});

/// Stream en vivo del perfil para reflejar XP / nivel / Soul Points
/// apenas cambian en la base.
final profileStreamProvider = StreamProvider<Profile?>((ref) {
  if (AppConfig.useMock) {
    return MockBackend.instance.profileStream;
  }
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value(null);
  return supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((rows) => rows.isEmpty ? null : Profile.fromMap(rows.first));
});
