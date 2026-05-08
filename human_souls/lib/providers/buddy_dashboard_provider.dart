import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/buddy_dashboard.dart';

/// Dashboard con totales del Buddy actual.
final buddyDashboardProvider =
    FutureProvider.autoDispose<BuddyDashboard>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw StateError('No hay sesión');
  final row = await supabase
      .from('buddy_dashboard')
      .select()
      .eq('buddy_id', user.id)
      .maybeSingle();
  if (row == null) {
    throw StateError('No sos Soul Buddy todavía');
  }
  return BuddyDashboard.fromMap(row);
});

/// Ingresos mensuales — últimos 12 meses con datos.
final buddyMonthlyIncomeProvider =
    FutureProvider.autoDispose<List<BuddyMonthlyIncome>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  final rows = await supabase
      .from('buddy_monthly_income')
      .select()
      .eq('buddy_id', user.id)
      .order('month', ascending: false)
      .limit(12);
  return (rows as List).map((r) => BuddyMonthlyIncome.fromMap(r)).toList();
});

/// Próximas cápsulas que facilita el Buddy.
final buddyUpcomingCapsulasProvider =
    FutureProvider.autoDispose<List<BuddyUpcomingCapsula>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  final rows = await supabase
      .from('buddy_upcoming_capsulas')
      .select()
      .eq('buddy_id', user.id)
      .order('starts_at', ascending: true);
  return (rows as List).map((r) => BuddyUpcomingCapsula.fromMap(r)).toList();
});

/// Crea una cápsula nueva (solo Buddies gracias a la policy capsulas_buddy_insert).
Future<String> createCapsula({
  required WidgetRef ref,
  required String title,
  String? description,
  required DateTime startsAt,
  required Duration duration,
  required int capacity,
  required double priceUsd,
  required bool includedInMembership,
  String? meetingLink,
}) async {
  final user = supabase.auth.currentUser!;
  final inserted = await supabase.from('capsulas').insert({
    'host_id': user.id,
    'title': title,
    'description': description,
    'starts_at': startsAt.toIso8601String(),
    'ends_at': startsAt.add(duration).toIso8601String(),
    'capacity': capacity,
    'price_usd': priceUsd,
    'included_in_membership': includedInMembership,
    'meeting_link': meetingLink,
    'status': 'scheduled',
  }).select('id').single();

  ref.invalidate(buddyUpcomingCapsulasProvider);
  ref.invalidate(buddyDashboardProvider);
  return inserted['id'] as String;
}
