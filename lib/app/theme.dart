import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Sandstone Minimalist Palette
  static const sandCream = Color(0xFFFDF8F5);
  static const sandBeige = Color(0xFFF9DCC4);
  static const coffeeDark = Color(0xFF413620);
  static const earthSoft = Color(0xFF8C7D6B);
  static const white = Color(0xFFFFFFFF);

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: sandCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sandBeige,
        primary: coffeeDark,
        secondary: sandBeige,
        surface: white,
        onSurface: coffeeDark,
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: sandCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: coffeeDark),
        titleTextStyle: GoogleFonts.outfit(
          color: coffeeDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: coffeeDark.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: coffeeDark.withValues(alpha: 0.05), width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: sandBeige,
        foregroundColor: coffeeDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: sandCream,
        indicatorColor: sandBeige,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: coffeeDark);
          }
          return const IconThemeData(color: earthSoft);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: coffeeDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return GoogleFonts.inter(
            color: earthSoft,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: coffeeDark),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: coffeeDark),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: coffeeDark),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: coffeeDark),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: coffeeDark),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: coffeeDark),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: coffeeDark,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: coffeeDark,
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: earthSoft),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Dark variant of the Sandstone theme (Mocha/Night)
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1714),
      colorScheme: ColorScheme.fromSeed(
        seedColor: sandBeige,
        brightness: Brightness.dark,
        primary: sandBeige,
        surface: const Color(0xFF2D2924),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A1714),
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
        color: const Color(0xFF2D2924),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
      ),
    );
  }
}
