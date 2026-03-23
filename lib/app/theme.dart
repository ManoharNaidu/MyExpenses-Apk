import 'package:flutter/material.dart';

class AppTheme {
  // User-provided Sandstone Palette
  static const cream = Color(0xFFF7F3EE);
  static const card = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF3F3A36);
  static const textSoft = Color(0xFF6E645C);
  static const accent = Color(0xFFD9A86C);
  static const accentDark = Color(0xFFB38B59);

  // Aliases for compatibility during migration
  static const sandCream = cream;
  static const sandBeige = accent;
  static const coffeeDark = textDark;
  static const earthSoft = textSoft;
  static const white = card;

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: textDark,
        secondary: accent,
        surface: card,
        onSurface: textDark,
      ),
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: textDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cream,
        indicatorColor: accent.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: textDark);
          }
          return const IconThemeData(color: textSoft);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: textSoft,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
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

  static ThemeData get darkTheme {
    // Dark variant using the same accent tone
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E1C1A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        primary: accent,
        surface: const Color(0xFF2B2825),
      ),
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1C1A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2B2825),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        bodyMedium: const TextStyle(fontSize: 14, color: Colors.white70),
      ),
    );
  }
}
