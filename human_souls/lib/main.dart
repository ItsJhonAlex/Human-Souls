import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de locale para es (Rueda de la Vida, Cápsulas, etc.)
  await initializeDateFormatting('es', null);
  timeago.setLocaleMessages('es', timeago.EsMessages());

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
  );

  runApp(const ProviderScope(child: HumanSoulsApp()));
}

/// Acceso rápido al cliente de Supabase desde cualquier parte.
final supabase = Supabase.instance.client;
