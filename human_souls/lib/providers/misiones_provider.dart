import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../models/mision.dart';

/// Todas las misiones activas agrupadas por tipo.
final misionesPorTipoProvider =
    FutureProvider.autoDispose<Map<MisionTipo, List<Mision>>>((ref) async {
      final rows = await supabase
          .from('misiones')
          .select()
          .eq('active', true)
          .order('created_at');

      final all = (rows as List).map((r) => Mision.fromMap(r)).toList();
      return {
        MisionTipo.daily: all.where((m) => m.tipo == MisionTipo.daily).toList(),
        MisionTipo.weekly: all
            .where((m) => m.tipo == MisionTipo.weekly)
            .toList(),
        MisionTipo.monthly: all
            .where((m) => m.tipo == MisionTipo.monthly)
            .toList(),
      };
    });

/// Mis completadas del período vigente de cada misión.
/// Devuelve un Map misionId -> MisionCompletada (la última del período).
final misCompletadasDelPeriodoProvider =
    FutureProvider.autoDispose<Map<String, MisionCompletada>>((ref) async {
      final user = supabase.auth.currentUser;
      if (user == null) return {};

      final misiones = await ref.watch(misionesPorTipoProvider.future);
      final allMisiones = misiones.values.expand((l) => l).toList();
      if (allMisiones.isEmpty) return {};

      // Para simplificar traigo todas las completadas del usuario en los últimos 45
      // días y filtro en cliente por period_key. Con volumen bajo alcanza.
      final since = DateTime.now().subtract(const Duration(days: 45));
      final rows = await supabase
          .from('mision_completadas')
          .select()
          .eq('user_id', user.id)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false);

      final result = <String, MisionCompletada>{};
      for (final r in (rows as List)) {
        final mc = MisionCompletada.fromMap(r);
        // Quiero la del período actual de cada misión.
        final mision = allMisiones.firstWhere(
          (m) => m.id == mc.misionId,
          orElse: () => allMisiones.first,
        );
        final currentKey = periodKeyFor(mision.tipo, DateTime.now());
        if (mc.periodKey == currentKey && !result.containsKey(mc.misionId)) {
          result[mc.misionId] = mc;
        }
      }
      return result;
    });

/// Cola de validación para Buddies: completadas ajenas pendientes.
final validationQueueProvider =
    FutureProvider.autoDispose<List<MisionCompletada>>((ref) async {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final rows = await supabase
          .from('mision_completadas')
          .select('*, misiones(*), profiles:user_id(full_name, avatar_url)')
          .eq('validated', false)
          .neq('user_id', user.id)
          .order('created_at', ascending: true)
          .limit(50);

      return (rows as List).map((r) => MisionCompletada.fromMap(r)).toList();
    });

/// Envía una misión completada. Para type='none' queda auto-validada.
/// Para otros, queda `validated=false` esperando a un Buddy.
Future<MisionCompletada> submitMision({
  required WidgetRef ref,
  required Mision mision,
  String? evidenceText,
  Uint8List? evidenceFileBytes,
  String? evidenceFileExt,
}) async {
  final user = supabase.auth.currentUser!;
  String? evidenceUrl;

  // Subir evidencia binaria si hay
  if (evidenceFileBytes != null && evidenceFileExt != null) {
    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$evidenceFileExt';
    await supabase.storage
        .from('evidence')
        .uploadBinary(
          path,
          evidenceFileBytes,
          fileOptions: const FileOptions(upsert: false),
        );
    // Bucket privado: firmamos una URL para poder previsualizar si hace falta.
    evidenceUrl = await supabase.storage
        .from('evidence')
        .createSignedUrl(path, 60 * 60 * 24 * 30); // 30 días
  }

  final isAutoValidated = mision.evidenceType == EvidenceType.none;
  final inserted = await supabase
      .from('mision_completadas')
      .insert({
        'user_id': user.id,
        'mision_id': mision.id,
        'period_key': periodKeyFor(mision.tipo, DateTime.now()),
        'evidence_url': evidenceUrl,
        'evidence_text': evidenceText,
        'validated': isAutoValidated,
        if (isAutoValidated) 'validated_at': DateTime.now().toIso8601String(),
      })
      .select()
      .single();

  // Refrescar estado
  ref.invalidate(misCompletadasDelPeriodoProvider);

  return MisionCompletada.fromMap(inserted);
}

/// Un Buddy valida (o rechaza) una misión. La RLS `mc_buddy_validate` permite
/// a perfiles con `is_buddy=true` hacer el update.
Future<void> validateMision({
  required WidgetRef ref,
  required String completionId,
  required bool approve,
}) async {
  final user = supabase.auth.currentUser!;

  if (approve) {
    await supabase
        .from('mision_completadas')
        .update({
          'validated': true,
          'validated_by': user.id,
          'validated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', completionId);
  } else {
    // Rechazo = eliminar la completada para que el usuario pueda reintentar.
    await supabase.from('mision_completadas').delete().eq('id', completionId);
  }
  ref.invalidate(validationQueueProvider);
}

/// Pick de imagen de galería usando image_picker.
Future<({Uint8List bytes, String ext})?> pickImageForEvidence() async {
  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    imageQuality: 82,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final ext = file.name.split('.').last.toLowerCase();
  return (bytes: bytes, ext: ext);
}
