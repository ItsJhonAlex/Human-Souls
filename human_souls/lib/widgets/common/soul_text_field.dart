import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class SoulTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;

  const SoulTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: SoulColors.textSecondary,
              )),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          validator: validator,
          onChanged: onChanged,
          textInputAction: textInputAction,
          style: const TextStyle(color: SoulColors.textPrimary, fontSize: 15),
          cursorColor: SoulColors.turquoise,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: SoulColors.textMuted),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: SoulColors.textSecondary, size: 20)
                : null,
            filled: true,
            fillColor: SoulColors.glass,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: _border(SoulColors.glassBorder),
            enabledBorder: _border(SoulColors.glassBorder),
            focusedBorder: _border(SoulColors.turquoise, width: 1.5),
            errorBorder: _border(Colors.redAccent),
            focusedErrorBorder: _border(Colors.redAccent, width: 1.5),
            counterText: '',
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
