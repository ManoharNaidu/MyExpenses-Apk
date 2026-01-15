import 'package:flutter/material.dart';

class AppTheme {
  static const cream = Color(0xFFF7F3EE);
  static const card = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF3F3A36);
  static const textSoft = Color(0xFF6E645C);
  static const accent = Color(0xFFD9A86C);
  static const accentDark = Color(0xFFB38B59);

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(seedColor: accent),
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        bodyMedium: const TextStyle(fontSize: 14, color: textSoft),
      ),
    );
  }
}
