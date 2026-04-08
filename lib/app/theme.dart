import 'package:flutter/material.dart';

class AppTheme {
  // Sandstone Palette
  static const cream = Color(0xFFF7F3EE);
  static const card = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF3F3A36);
  static const textSoft = Color(0xFF6E645C);
  static const accent = Color(0xFFD9A86C);
  static const accentDark = Color(0xFFB38B59);

  // Aliases
  static const sandCream = cream;
  static const sandBeige = accent;
  static const coffeeDark = textDark;
  static const earthSoft = textSoft;
  static const white = card;

  // Design system
  static const indigo = Color(0xFF4F46E5);
  static const indigoLight = Color(0xFFE0E7FF);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);

  // Dark palette
  static const darkBg = Color(0xFF141210);
  static const darkSurface = Color(0xFF1E1C1A);
  static const darkCard = Color(0xFF2B2825);
  static const darkField = Color(0xFF3A3633);
  static const darkTextPrimary = Color(0xFFF5F0EB);
  static const darkTextSecondary = Color(0xFF9A8E84);
  static const darkDivider = Color(0xFF3A3633);
  static const darkBottomBar = Color(0xFF1E1C1A);

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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
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
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: textDark,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: cream,
        elevation: 8,
        shadowColor: Color(0x14000000),
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
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEDE8E3),
        thickness: 1,
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
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        primary: accent,
        secondary: accent,
        surface: darkCard,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkField,
      ),
      fontFamily: 'Roboto',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: const TextStyle(
          color: darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: textDark,
        elevation: 4,
        shape: CircleBorder(),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: darkSurface,
        elevation: 8,
        shadowColor: Color(0x40000000),
      ),
      dividerTheme: const DividerThemeData(color: darkDivider, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: TextStyle(color: darkTextSecondary.withValues(alpha: 0.6)),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: darkTextPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        bodyMedium: const TextStyle(fontSize: 14, color: darkTextSecondary),
        bodyLarge: const TextStyle(fontSize: 16, color: darkTextPrimary),
        bodySmall: const TextStyle(fontSize: 12, color: darkTextSecondary),
      ),
    );
  }
}
