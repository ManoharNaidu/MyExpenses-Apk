import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Wealth Palette
  static const indigoDeep = Color(0xFF2D3436);
  static const mintEmerald = Color(0xFF00B894);
  static const coralFlare = Color(0xFFD63031);
  static const iceWhite = Color(0xFFF1F2F6);
  
  static const cream = Color(0xFFF7F3EE); // Kept as base background for light
  static const card = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF2D3436); // Replaced with indigoDeep
  static const textSoft = Color(0xFF636E72); // Refined gray
  static const accent = Color(0xFF00B894); // Replaced with mintEmerald
  static const accentDark = Color(0xFF008967);

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: indigoDeep,
        primary: indigoDeep,
        secondary: mintEmerald,
        error: coralFlare,
        surface: card,
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSoft),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: mintEmerald,
        brightness: Brightness.dark,
        primary: mintEmerald,
        surface: const Color(0xFF2D2D2D),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14),
      ),
    );
  }
}
