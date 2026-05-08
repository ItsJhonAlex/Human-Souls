import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.public_rounded, label: 'Mundo', path: '/mundo'),
    (icon: Icons.bolt_rounded, label: 'Misiones', path: '/misiones'),
    (
      icon: Icons.auto_awesome_rounded,
      label: 'Cápsulas',
      path: '/experiencias',
    ),
    (icon: Icons.forum_rounded, label: 'Comunidad', path: '/comunidad'),
    (icon: Icons.person_rounded, label: 'Perfil', path: '/perfil'),
  ];

  int _indexForLocation(String loc) => _tabs
      .indexWhere((t) => loc.startsWith(t.path))
      .clamp(0, _tabs.length - 1);

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _indexForLocation(location);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: SoulColors.deepBlue.withValues(alpha: .55),
              border: const Border(
                top: BorderSide(color: SoulColors.glassBorder),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_tabs.length, (i) {
                    final t = _tabs[i];
                    final active = i == idx;
                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.go(t.path),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: active ? SoulColors.ctaGradient : null,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                t.icon,
                                size: 22,
                                color: active
                                    ? Colors.white
                                    : SoulColors.textMuted,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: active
                                      ? Colors.white
                                      : SoulColors.textMuted,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
