import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

enum SoulButtonVariant { primary, ghost, light }

class SoulButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SoulButtonVariant variant;
  final bool loading;
  final bool expanded;

  const SoulButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = SoulButtonVariant.primary,
    this.loading = false,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: _fg),
          const SizedBox(width: 8),
        ],
        Text(label,
          style: TextStyle(
            color: _fg, fontSize: 15, fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          )),
      ],
    );

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: _decoration,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Color get _fg => switch (variant) {
        SoulButtonVariant.primary => Colors.white,
        SoulButtonVariant.ghost => SoulColors.textPrimary,
        SoulButtonVariant.light => SoulColors.deepBlue,
      };

  BoxDecoration get _decoration => switch (variant) {
        SoulButtonVariant.primary => BoxDecoration(
            gradient: SoulColors.ctaGradient,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: SoulColors.violet.withValues(alpha: .35),
                blurRadius: 24, offset: const Offset(0, 10),
              ),
            ],
          ),
        SoulButtonVariant.ghost => BoxDecoration(
            color: SoulColors.glass,
            border: Border.all(color: SoulColors.glassBorder),
            borderRadius: BorderRadius.circular(100),
          ),
        SoulButtonVariant.light => BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
          ),
      };
}
