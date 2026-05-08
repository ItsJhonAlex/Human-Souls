import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/theme.dart';
import 'core/router/app_router.dart';

class HumanSoulsApp extends ConsumerWidget {
  const HumanSoulsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Human Souls',
      debugShowCheckedModeBanner: false,
      theme: SoulTheme.dark,
      routerConfig: router,
    );
  }
}
