import 'package:flutter/material.dart';

class AppTheme {
  // ─── Light-mode palette ───────────────────────────────────────────
  static const cream = Color(0xFFF7F3EE); // scaffold background
  static const card = Color(0xFFFFFFFF); // card surface
  static const fieldFill = Color(0xFFF3EDE5); // text field fill
  static const accent = Color(0xFFC9924A); // primary CTA, FAB, highlights
  static const accentDark = Color(0xFFA67338); // pressed accent, links
  static const textDark = Color(0xFF2B2420); // primary text
  static const textSoft = Color(0xFF7A6355); // secondary text
  static const divider = Color(0xFFEDE8E3); // separators
  static const incomeGreen = Color(0xFF2D7A4F); // income amounts, positive
  static const expenseRed = Color(0xFFC0392B); // expense amounts, negative
  static const budgetAmber = Color(0xFFD97706); // budget warning 80%+
  static const background = cream;

  // ─── Dark-mode palette (warm-tinted) ──────────────────────────────
  static const darkBg = Color(0xFF141210); // scaffold — warm near-black
  static const darkSurface = Color(0xFF1E1B18); // AppBar, BottomBar
  static const darkCard = Color(0xFF272320); // cards, list items
  static const darkElevated = Color(0xFF312D2A); // dialogs, sheets
  static const darkField = Color(0xFF3A3531); // input backgrounds
  static const darkTextPri = Color(0xFFF0EBE4); // primary text — warm white
  static const darkTextSec = Color(0xFF9A8A7A); // secondary text — warm grey
  static const darkDivider = Color(0xFF332F2B); // separators
  static const darkAccent = Color(0xFFE0A85A); // brighter accent for dark bg
  static const darkIncome = Color(0xFF4CAF7D); // income on dark
  static const darkExpense = Color(0xFFE05C5C); // expense on dark
  static const darkBudgetAmber = Color(0xFFF5A623); // budget warning on dark
  static const budgetGreen = Color(0xFF2D7A4F); // under-budget (= incomeGreen)
  static const darkBudgetGreen = Color(0xFF4CAF7D); // under-budget on dark

  // ─── Backward-compatible aliases ──────────────────────────────────
  // Existing code references these names; keep them wired to the new values.
  static const darkTextPrimary = darkTextPri;
  static const darkTextSecondary = darkTextSec;
  static const darkBottomBar = darkSurface;
  static const white = card;

  // ═══════════════════════════════════════════════════════════════════
  // Light ThemeData
  // ═══════════════════════════════════════════════════════════════════
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: textDark,
        elevation: 4,
        shape: CircleBorder(),
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        labelStyle: const TextStyle(color: textSoft),
        hintStyle: TextStyle(color: textSoft.withValues(alpha: 0.6)),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
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
        bodyLarge: const TextStyle(fontSize: 16, color: textDark),
        bodyMedium: const TextStyle(fontSize: 14, color: textSoft),
        bodySmall: const TextStyle(fontSize: 12, color: textSoft),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Dark ThemeData
  // ═══════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        primary: darkAccent,
        secondary: darkAccent,
        surface: darkCard,
        onSurface: darkTextPri,
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
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextPri),
        titleTextStyle: TextStyle(
          color: darkTextPri,
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
        color: darkSurface, // ← DARK MODE FOOTER FIX
        elevation: 8,
        shadowColor: Color(0x40000000),
      ),
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
        labelStyle: const TextStyle(color: darkTextSec),
        hintStyle: TextStyle(color: darkTextSec.withValues(alpha: 0.6)),
      ),
      dividerTheme: const DividerThemeData(color: darkDivider, thickness: 1),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: darkTextPri,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: darkTextPri,
        ),
        bodyLarge: const TextStyle(fontSize: 16, color: darkTextPri),
        bodyMedium: const TextStyle(fontSize: 14, color: darkTextSec),
        bodySmall: const TextStyle(fontSize: 12, color: darkTextSec),
      ),
    );
  }
}
