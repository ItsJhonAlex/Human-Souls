import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta oficial Human Souls.
class SoulColors {
  SoulColors._();

  // Núcleo
  static const deepBlue   = Color(0xFF0B1238);
  static const midnight   = Color(0xFF121A44);
  static const violet     = Color(0xFF6A2DFF);
  static const turquoise  = Color(0xFF00D4C8);
  static const cyan       = Color(0xFF3FA7FF);

  // Acentos
  static const pink       = Color(0xFFFF6AC1);
  static const gold       = Color(0xFFFFD166);
  static const aurora     = Color(0xFFB388FF);

  // Superficies glass
  static const glass        = Color(0x1AFFFFFF); // 10% white
  static const glassStrong  = Color(0x26FFFFFF); // 15%
  static const glassBorder  = Color(0x33FFFFFF); // 20%

  // Texto
  static const textPrimary   = Color(0xFFF4F6FF);
  static const textSecondary = Color(0xB3F4F6FF); // 70%
  static const textMuted     = Color(0x80F4F6FF); // 50%

  // Gradiente principal
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepBlue, violet, turquoise],
    stops: [0.0, 0.55, 1.0],
  );

  // Gradiente de acento para CTAs
  static const ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cyan, violet],
  );

  // Gradiente para la cápsula hero
  static const capsulaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [turquoise, cyan, violet],
  );
}

class SoulTheme {
  SoulTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: SoulColors.deepBlue,
      colorScheme: const ColorScheme.dark(
        primary: SoulColors.violet,
        secondary: SoulColors.turquoise,
        surface: SoulColors.midnight,
        onPrimary: Colors.white,
        onSurface: SoulColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: SoulColors.textPrimary,
        displayColor: SoulColors.textPrimary,
      ).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400, height: 1.45,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2,
        ),
      ),
      iconTheme: const IconThemeData(color: SoulColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
